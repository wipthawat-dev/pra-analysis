#!/bin/bash

###############################################################################
# Pra Analysis - SeaweedFS Backup Script
# This script backs up SeaweedFS data and metadata
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
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_ROOT="${BACKUP_DIR}/backups/${TIMESTAMP}"
LOG_FILE="${BACKUP_DIR}/logs/backup_${TIMESTAMP}.log"

# Retention settings (days)
RETENTION_DAYS=30

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

# Function to create backup directories
create_backup_dirs() {
    print_info "Creating backup directories..."
    
    mkdir -p "${BACKUP_ROOT}"/{seaweedfs,postgres,metadata}
    mkdir -p "${BACKUP_DIR}/logs"
    
    print_success "Backup directories created: ${BACKUP_ROOT}"
}

# Function to backup SeaweedFS masters
backup_seaweedfs_masters() {
    print_info "Backing up SeaweedFS master servers..."
    
    for master in master1 master2 master3; do
        if [ -d "${DATA_DIR}/seaweedfs/${master}" ]; then
            print_info "Backing up ${master}..."
            rsync -av --delete "${DATA_DIR}/seaweedfs/${master}/" "${BACKUP_ROOT}/seaweedfs/${master}/" >> "$LOG_FILE" 2>&1
            print_success "${master} backed up successfully"
        else
            print_warning "${master} directory not found, skipping"
        fi
    done
}

# Function to backup SeaweedFS volumes
backup_seaweedfs_volumes() {
    print_info "Backing up SeaweedFS volume servers..."
    
    for volume in volume1 volume2; do
        if [ -d "${DATA_DIR}/seaweedfs/${volume}" ]; then
            print_info "Backing up ${volume}..."
            rsync -av --delete "${DATA_DIR}/seaweedfs/${volume}/" "${BACKUP_ROOT}/seaweedfs/${volume}/" >> "$LOG_FILE" 2>&1
            print_success "${volume} backed up successfully"
        else
            print_warning "${volume} directory not found, skipping"
        fi
    done
}

# Function to backup SeaweedFS filer
backup_seaweedfs_filer() {
    print_info "Backing up SeaweedFS filer..."
    
    if [ -d "${DATA_DIR}/seaweedfs/filer" ]; then
        rsync -av --delete "${DATA_DIR}/seaweedfs/filer/" "${BACKUP_ROOT}/seaweedfs/filer/" >> "$LOG_FILE" 2>&1
        print_success "Filer backed up successfully"
    else
        print_warning "Filer directory not found, skipping"
    fi
}

# Function to export SeaweedFS metadata
export_seaweedfs_metadata() {
    print_info "Exporting SeaweedFS cluster metadata..."
    
    # Get cluster status from master
    if curl -s http://localhost:9333/cluster/status > "${BACKUP_ROOT}/metadata/cluster_status.json"; then
        print_success "Cluster status exported"
    else
        print_warning "Failed to export cluster status"
    fi
    
    # Get volume locations
    if curl -s http://localhost:9333/dir/status > "${BACKUP_ROOT}/metadata/dir_status.json"; then
        print_success "Directory status exported"
    else
        print_warning "Failed to export directory status"
    fi
    
    # Export topology
    if curl -s http://localhost:9333/vol/status > "${BACKUP_ROOT}/metadata/vol_status.json"; then
        print_success "Volume status exported"
    else
        print_warning "Failed to export volume status"
    fi
}

# Function to backup PostgreSQL
backup_postgres() {
    print_info "Backing up PostgreSQL database..."
    
    # Get container name
    POSTGRES_CONTAINER=$(docker ps --filter "name=postgres" --format "{{.Names}}" | head -n1)
    
    if [ -z "$POSTGRES_CONTAINER" ]; then
        print_warning "PostgreSQL container not found, skipping database backup"
        return 0
    fi
    
    # Backup using pg_dump
    docker exec "$POSTGRES_CONTAINER" pg_dumpall -U postgres > "${BACKUP_ROOT}/postgres/all_databases.sql"
    
    if [ $? -eq 0 ]; then
        print_success "PostgreSQL backup completed"
        
        # Compress SQL dump
        gzip "${BACKUP_ROOT}/postgres/all_databases.sql"
        print_success "PostgreSQL backup compressed"
    else
        print_error "PostgreSQL backup failed"
    fi
}

# Function to backup Qdrant
backup_qdrant() {
    print_info "Backing up Qdrant vector database..."
    
    if [ -d "${DATA_DIR}/qdrant" ]; then
        rsync -av --delete "${DATA_DIR}/qdrant/" "${BACKUP_ROOT}/qdrant/" >> "$LOG_FILE" 2>&1
        print_success "Qdrant backed up successfully"
    else
        print_warning "Qdrant directory not found, skipping"
    fi
}

# Function to create backup manifest
create_manifest() {
    print_info "Creating backup manifest..."
    
    cat > "${BACKUP_ROOT}/MANIFEST.txt" <<EOF
Pra Analysis Backup Manifest
========================================
Backup Date: $(date)
Hostname: $(hostname)
Backup Path: ${BACKUP_ROOT}

Components Backed Up:
- SeaweedFS Masters (master1, master2, master3)
- SeaweedFS Volumes (volume1, volume2)
- SeaweedFS Filer
- SeaweedFS Metadata
- PostgreSQL Database
- Qdrant Vector Database

Backup Size:
$(du -sh "${BACKUP_ROOT}" | awk '{print $1}')

Files:
$(find "${BACKUP_ROOT}" -type f | wc -l) files

Backup Command:
$0

========================================
EOF
    
    print_success "Manifest created"
}

# Function to compress backup
compress_backup() {
    print_info "Compressing backup (this may take a while)..."
    
    cd "${BACKUP_DIR}/backups"
    tar -czf "${TIMESTAMP}.tar.gz" "${TIMESTAMP}/"
    
    if [ $? -eq 0 ]; then
        ARCHIVE_SIZE=$(du -sh "${TIMESTAMP}.tar.gz" | awk '{print $1}')
        print_success "Backup compressed: ${TIMESTAMP}.tar.gz (${ARCHIVE_SIZE})"
        
        # Optionally remove uncompressed backup
        read -p "Remove uncompressed backup directory? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "${TIMESTAMP}/"
            print_info "Uncompressed backup removed"
        fi
    else
        print_error "Compression failed"
    fi
}

# Function to clean old backups
cleanup_old_backups() {
    print_info "Cleaning up old backups (retention: ${RETENTION_DAYS} days)..."
    
    # Find and remove old backup directories
    find "${BACKUP_DIR}/backups" -maxdepth 1 -type d -mtime +${RETENTION_DAYS} -exec rm -rf {} \;
    
    # Find and remove old backup archives
    find "${BACKUP_DIR}/backups" -maxdepth 1 -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete
    
    # Find and remove old logs
    find "${BACKUP_DIR}/logs" -name "backup_*.log" -mtime +${RETENTION_DAYS} -delete
    
    print_success "Old backups cleaned up"
}

# Function to send notification (optional)
send_notification() {
    local STATUS=$1
    local MESSAGE=$2
    
    # Add your notification logic here
    # Examples: email, Slack, webhook, etc.
    
    # Example: Log to syslog
    logger -t "pra-analysis-backup" "$STATUS: $MESSAGE"
}

# Function to display backup summary
display_summary() {
    local END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))
    local DURATION_MIN=$((DURATION / 60))
    local BACKUP_SIZE=$(du -sh "${BACKUP_ROOT}" 2>/dev/null | awk '{print $1}')
    
    echo ""
    echo "========================================================================="
    echo -e "${GREEN}Backup Completed Successfully!${NC}"
    echo "========================================================================="
    echo "Backup Location: ${BACKUP_ROOT}"
    echo "Backup Size: ${BACKUP_SIZE}"
    echo "Duration: ${DURATION_MIN} minutes"
    echo "Log File: ${LOG_FILE}"
    echo ""
    echo "To restore from this backup, run:"
    echo "  sudo ./restore-seaweedfs.sh ${TIMESTAMP}"
    echo "========================================================================="
}

# Main backup flow
main() {
    START_TIME=$(date +%s)
    
    print_info "Starting Pra Analysis backup..."
    print_info "Timestamp: ${TIMESTAMP}"
    
    # Pre-backup checks
    check_root
    
    # Create backup directories
    create_backup_dirs
    
    # Backup components
    backup_seaweedfs_masters
    backup_seaweedfs_volumes
    backup_seaweedfs_filer
    export_seaweedfs_metadata
    backup_postgres
    backup_qdrant
    
    # Create manifest
    create_manifest
    
    # Optional: Compress backup
    read -p "Compress backup? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        compress_backup
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Display summary
    display_summary
    
    # Send notification
    send_notification "SUCCESS" "Backup completed: ${TIMESTAMP}"
    
    print_success "Backup process completed!"
}

# Run main function
main "$@"

