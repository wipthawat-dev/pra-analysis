#!/bin/bash

###############################################################################
# Pra Analysis - SeaweedFS Restore Script
# This script restores SeaweedFS data and metadata from backup
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="pra-analysis"
DATA_DIR="/var/lib/${APP_NAME}"
BACKUP_DIR="/backup/${APP_NAME}"
LOG_FILE="${BACKUP_DIR}/logs/restore_$(date +%Y%m%d_%H%M%S).log"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to list available backups
list_backups() {
    print_info "Available backups:"
    echo ""
    
    if [ -d "${BACKUP_DIR}/backups" ]; then
        # List backup directories
        ls -lhtr "${BACKUP_DIR}/backups" | grep "^d" | awk '{print $9, "(" $6, $7, $8 ")"}'
        
        # List backup archives
        ls -lhtr "${BACKUP_DIR}/backups"/*.tar.gz 2>/dev/null | awk '{print $9, "(" $5 ")"}'
    else
        print_error "Backup directory not found: ${BACKUP_DIR}/backups"
        exit 1
    fi
}

# Function to validate backup
validate_backup() {
    local BACKUP_PATH=$1
    
    print_info "Validating backup: ${BACKUP_PATH}"
    
    if [ ! -d "${BACKUP_PATH}" ]; then
        print_error "Backup directory not found: ${BACKUP_PATH}"
        exit 1
    fi
    
    # Check for manifest
    if [ ! -f "${BACKUP_PATH}/MANIFEST.txt" ]; then
        print_warning "Manifest file not found"
    else
        print_info "Manifest found:"
        cat "${BACKUP_PATH}/MANIFEST.txt"
        echo ""
    fi
    
    # Check for required components
    local COMPONENTS_OK=true
    
    if [ ! -d "${BACKUP_PATH}/seaweedfs" ]; then
        print_warning "SeaweedFS backup not found"
        COMPONENTS_OK=false
    fi
    
    if [ ! -f "${BACKUP_PATH}/postgres/all_databases.sql.gz" ] && [ ! -f "${BACKUP_PATH}/postgres/all_databases.sql" ]; then
        print_warning "PostgreSQL backup not found"
        COMPONENTS_OK=false
    fi
    
    if [ "$COMPONENTS_OK" = false ]; then
        print_warning "Some backup components are missing"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "Backup validation completed"
}

# Function to stop services
stop_services() {
    print_info "Stopping services..."
    
    # Try to stop using systemd
    if systemctl is-active --quiet ${APP_NAME}.service; then
        systemctl stop ${APP_NAME}.service
        print_success "Stopped via systemd"
        return 0
    fi
    
    # Try to stop using docker compose
    if [ -f "/opt/${APP_NAME}/docker-compose.production.yml" ]; then
        cd "/opt/${APP_NAME}"
        docker compose -f docker-compose.production.yml down
        print_success "Stopped via docker compose"
    else
        print_warning "Could not stop services automatically"
        print_warning "Please stop the services manually before continuing"
        read -p "Press Enter when services are stopped..."
    fi
}

# Function to backup current data
backup_current_data() {
    print_info "Creating safety backup of current data..."
    
    local SAFETY_BACKUP="${BACKUP_DIR}/safety_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${SAFETY_BACKUP}"
    
    if [ -d "${DATA_DIR}" ]; then
        rsync -av "${DATA_DIR}/" "${SAFETY_BACKUP}/" >> "$LOG_FILE" 2>&1
        print_success "Safety backup created: ${SAFETY_BACKUP}"
    else
        print_warning "No current data to backup"
    fi
}

# Function to restore SeaweedFS
restore_seaweedfs() {
    local BACKUP_PATH=$1
    
    print_info "Restoring SeaweedFS..."
    
    # Restore masters
    for master in master1 master2 master3; do
        if [ -d "${BACKUP_PATH}/seaweedfs/${master}" ]; then
            print_info "Restoring ${master}..."
            mkdir -p "${DATA_DIR}/seaweedfs/${master}"
            rsync -av --delete "${BACKUP_PATH}/seaweedfs/${master}/" "${DATA_DIR}/seaweedfs/${master}/" >> "$LOG_FILE" 2>&1
            print_success "${master} restored"
        else
            print_warning "${master} not found in backup, skipping"
        fi
    done
    
    # Restore volumes
    for volume in volume1 volume2; do
        if [ -d "${BACKUP_PATH}/seaweedfs/${volume}" ]; then
            print_info "Restoring ${volume}..."
            mkdir -p "${DATA_DIR}/seaweedfs/${volume}"
            rsync -av --delete "${BACKUP_PATH}/seaweedfs/${volume}/" "${DATA_DIR}/seaweedfs/${volume}/" >> "$LOG_FILE" 2>&1
            print_success "${volume} restored"
        else
            print_warning "${volume} not found in backup, skipping"
        fi
    done
    
    # Restore filer
    if [ -d "${BACKUP_PATH}/seaweedfs/filer" ]; then
        print_info "Restoring filer..."
        mkdir -p "${DATA_DIR}/seaweedfs/filer"
        rsync -av --delete "${BACKUP_PATH}/seaweedfs/filer/" "${DATA_DIR}/seaweedfs/filer/" >> "$LOG_FILE" 2>&1
        print_success "Filer restored"
    else
        print_warning "Filer not found in backup, skipping"
    fi
}

# Function to restore PostgreSQL
restore_postgres() {
    local BACKUP_PATH=$1
    
    print_info "Restoring PostgreSQL database..."
    
    local SQL_FILE=""
    
    if [ -f "${BACKUP_PATH}/postgres/all_databases.sql.gz" ]; then
        print_info "Decompressing PostgreSQL backup..."
        gunzip -c "${BACKUP_PATH}/postgres/all_databases.sql.gz" > /tmp/restore_postgres.sql
        SQL_FILE="/tmp/restore_postgres.sql"
    elif [ -f "${BACKUP_PATH}/postgres/all_databases.sql" ]; then
        SQL_FILE="${BACKUP_PATH}/postgres/all_databases.sql"
    else
        print_warning "PostgreSQL backup not found, skipping"
        return 0
    fi
    
    # Start PostgreSQL container temporarily
    print_info "Starting PostgreSQL container..."
    cd "/opt/${APP_NAME}"
    docker compose -f docker-compose.production.yml up -d postgres
    
    # Wait for PostgreSQL to be ready
    print_info "Waiting for PostgreSQL to be ready..."
    sleep 10
    
    # Get container name
    POSTGRES_CONTAINER=$(docker ps --filter "name=postgres" --format "{{.Names}}" | head -n1)
    
    if [ -z "$POSTGRES_CONTAINER" ]; then
        print_error "PostgreSQL container not found"
        return 1
    fi
    
    # Restore database
    print_info "Restoring database (this may take a while)..."
    docker exec -i "$POSTGRES_CONTAINER" psql -U postgres < "$SQL_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "PostgreSQL restored successfully"
    else
        print_error "PostgreSQL restore failed"
    fi
    
    # Cleanup temporary file
    if [ -f "/tmp/restore_postgres.sql" ]; then
        rm -f /tmp/restore_postgres.sql
    fi
}

# Function to restore Qdrant
restore_qdrant() {
    local BACKUP_PATH=$1
    
    print_info "Restoring Qdrant vector database..."
    
    if [ -d "${BACKUP_PATH}/qdrant" ]; then
        mkdir -p "${DATA_DIR}/qdrant"
        rsync -av --delete "${BACKUP_PATH}/qdrant/" "${DATA_DIR}/qdrant/" >> "$LOG_FILE" 2>&1
        print_success "Qdrant restored successfully"
    else
        print_warning "Qdrant backup not found, skipping"
    fi
}

# Function to start services
start_services() {
    print_info "Starting services..."
    
    # Try to start using systemd
    if systemctl list-unit-files | grep -q "${APP_NAME}.service"; then
        systemctl start ${APP_NAME}.service
        print_success "Started via systemd"
        return 0
    fi
    
    # Try to start using docker compose
    if [ -f "/opt/${APP_NAME}/docker-compose.production.yml" ]; then
        cd "/opt/${APP_NAME}"
        docker compose -f docker-compose.production.yml up -d
        print_success "Started via docker compose"
    else
        print_warning "Could not start services automatically"
        print_warning "Please start the services manually"
    fi
}

# Function to verify restore
verify_restore() {
    print_info "Verifying restore..."
    
    sleep 15  # Wait for services to start
    
    # Check SeaweedFS masters
    local MASTER_OK=0
    for port in 9333 9334 9335; do
        if curl -s http://localhost:${port}/cluster/status > /dev/null; then
            print_success "Master on port ${port} is responding"
            MASTER_OK=$((MASTER_OK + 1))
        else
            print_warning "Master on port ${port} is not responding"
        fi
    done
    
    if [ $MASTER_OK -gt 0 ]; then
        print_success "At least one master is operational"
    else
        print_error "No masters are responding"
    fi
    
    # Check API
    if curl -s http://localhost:8000/health > /dev/null; then
        print_success "API is responding"
    else
        print_warning "API is not responding yet (may need more time to start)"
    fi
    
    print_info "Verification completed"
}

# Function to display restore summary
display_summary() {
    echo ""
    echo "========================================================================="
    echo -e "${GREEN}Restore Completed!${NC}"
    echo "========================================================================="
    echo "Restore Log: ${LOG_FILE}"
    echo ""
    echo "Next Steps:"
    echo "  1. Verify all services are running:"
    echo "     docker ps"
    echo "  2. Check service logs for errors:"
    echo "     docker compose -f /opt/${APP_NAME}/docker-compose.production.yml logs -f"
    echo "  3. Test API endpoint:"
    echo "     curl http://localhost:8000/health"
    echo "  4. Check SeaweedFS cluster:"
    echo "     curl http://localhost:9333/cluster/status"
    echo "========================================================================="
}

# Main restore flow
main() {
    print_info "Starting Pra Analysis restore..."
    
    # Pre-restore checks
    check_root
    
    # Check arguments
    if [ $# -eq 0 ]; then
        print_info "No backup specified"
        list_backups
        echo ""
        read -p "Enter backup timestamp or path: " BACKUP_INPUT
    else
        BACKUP_INPUT=$1
    fi
    
    # Determine backup path
    if [ -d "$BACKUP_INPUT" ]; then
        BACKUP_PATH="$BACKUP_INPUT"
    elif [ -d "${BACKUP_DIR}/backups/${BACKUP_INPUT}" ]; then
        BACKUP_PATH="${BACKUP_DIR}/backups/${BACKUP_INPUT}"
    elif [ -f "${BACKUP_DIR}/backups/${BACKUP_INPUT}.tar.gz" ]; then
        print_info "Extracting backup archive..."
        cd "${BACKUP_DIR}/backups"
        tar -xzf "${BACKUP_INPUT}.tar.gz"
        BACKUP_PATH="${BACKUP_DIR}/backups/${BACKUP_INPUT}"
    else
        print_error "Backup not found: ${BACKUP_INPUT}"
        exit 1
    fi
    
    # Validate backup
    validate_backup "$BACKUP_PATH"
    
    # Confirmation
    echo ""
    print_warning "WARNING: This will replace all current data!"
    print_warning "Backup path: ${BACKUP_PATH}"
    read -p "Are you sure you want to continue? (yes/NO): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        print_info "Restore cancelled"
        exit 0
    fi
    
    # Stop services
    stop_services
    
    # Create safety backup
    backup_current_data
    
    # Restore components
    restore_seaweedfs "$BACKUP_PATH"
    restore_postgres "$BACKUP_PATH"
    restore_qdrant "$BACKUP_PATH"
    
    # Start services
    start_services
    
    # Verify restore
    verify_restore
    
    # Display summary
    display_summary
    
    print_success "Restore process completed!"
}

# Run main function
main "$@"

