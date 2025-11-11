#!/bin/bash

###############################################################################
# Pra Analysis - Health Check Script
# This script monitors the health of all system components
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERBOSE=false
ALERT_MODE=false
SLACK_WEBHOOK=""
EMAIL_ALERT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -a|--alert)
            ALERT_MODE=true
            shift
            ;;
        --slack)
            SLACK_WEBHOOK="$2"
            shift 2
            ;;
        --email)
            EMAIL_ALERT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Health check results
HEALTH_STATUS=0  # 0 = healthy, 1 = warning, 2 = critical
HEALTH_MESSAGES=()

# Function to print colored messages
print_status() {
    local status=$1
    local component=$2
    local message=$3
    
    case $status in
        "OK")
            echo -e "${GREEN}✓${NC} ${component}: ${message}"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} ${component}: ${message}"
            HEALTH_MESSAGES+=("WARNING: ${component} - ${message}")
            [ $HEALTH_STATUS -lt 1 ] && HEALTH_STATUS=1
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} ${component}: ${message}"
            HEALTH_MESSAGES+=("CRITICAL: ${component} - ${message}")
            HEALTH_STATUS=2
            ;;
    esac
}

# Function to check HTTP endpoint
check_http() {
    local url=$1
    local timeout=${2:-5}
    
    if curl -sf --max-time "$timeout" "$url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check Docker container
check_container() {
    local container_name=$1
    
    if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
        local status=$(docker inspect --format='{{.State.Status}}' "$container_name")
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")
        
        if [ "$status" = "running" ]; then
            if [ "$health" = "healthy" ] || [ "$health" = "none" ]; then
                return 0
            else
                return 2  # Unhealthy
            fi
        else
            return 1  # Not running
        fi
    else
        return 1  # Container not found
    fi
}

# Function to check SeaweedFS Master
check_seaweedfs_master() {
    local master_num=$1
    local port=$((9332 + master_num))
    local container_name="seaweedfs-master${master_num}"
    
    if check_container "$container_name"; then
        if check_http "http://localhost:${port}/cluster/status"; then
            # Get cluster status
            local leader=$(curl -s "http://localhost:${port}/cluster/status" | grep -o '"Leader":"[^"]*"' | cut -d'"' -f4)
            if [ -n "$leader" ]; then
                print_status "OK" "SeaweedFS Master ${master_num}" "Running (Leader: ${leader})"
            else
                print_status "OK" "SeaweedFS Master ${master_num}" "Running"
            fi
        else
            print_status "WARN" "SeaweedFS Master ${master_num}" "Container running but not responding"
        fi
    else
        print_status "FAIL" "SeaweedFS Master ${master_num}" "Container not running"
    fi
}

# Function to check SeaweedFS Volume
check_seaweedfs_volume() {
    local volume_num=$1
    local port=$((8079 + volume_num))
    local container_name="seaweedfs-volume${volume_num}"
    
    if check_container "$container_name"; then
        if check_http "http://localhost:${port}/status"; then
            print_status "OK" "SeaweedFS Volume ${volume_num}" "Running"
        else
            print_status "WARN" "SeaweedFS Volume ${volume_num}" "Container running but not responding"
        fi
    else
        print_status "FAIL" "SeaweedFS Volume ${volume_num}" "Container not running"
    fi
}

# Function to check SeaweedFS Filer
check_seaweedfs_filer() {
    local container_name="seaweedfs-filer"
    
    if check_container "$container_name"; then
        if check_http "http://localhost:8888/"; then
            print_status "OK" "SeaweedFS Filer" "Running"
        else
            print_status "WARN" "SeaweedFS Filer" "Container running but not responding"
        fi
    else
        print_status "FAIL" "SeaweedFS Filer" "Container not running"
    fi
}

# Function to check SeaweedFS S3
check_seaweedfs_s3() {
    local container_name="seaweedfs-s3"
    
    if check_container "$container_name"; then
        if check_http "http://localhost:8333/"; then
            print_status "OK" "SeaweedFS S3" "Running"
        else
            print_status "WARN" "SeaweedFS S3" "Container running but not responding"
        fi
    else
        print_status "FAIL" "SeaweedFS S3" "Container not running"
    fi
}

# Function to check PostgreSQL
check_postgres() {
    local container_name=$(docker ps --filter "name=postgres" --format "{{.Names}}" | head -n1)
    
    if [ -z "$container_name" ]; then
        print_status "FAIL" "PostgreSQL" "Container not found"
        return
    fi
    
    if check_container "$container_name"; then
        # Try to connect to database
        if docker exec "$container_name" pg_isready -U postgres > /dev/null 2>&1; then
            # Get database size if verbose
            if [ "$VERBOSE" = true ]; then
                local db_size=$(docker exec "$container_name" psql -U postgres -t -c "SELECT pg_size_pretty(pg_database_size('amulet_db'));" 2>/dev/null | xargs)
                print_status "OK" "PostgreSQL" "Running (DB size: ${db_size})"
            else
                print_status "OK" "PostgreSQL" "Running"
            fi
        else
            print_status "WARN" "PostgreSQL" "Container running but not accepting connections"
        fi
    else
        print_status "FAIL" "PostgreSQL" "Container not running"
    fi
}

# Function to check Qdrant
check_qdrant() {
    local container_name=$(docker ps --filter "name=qdrant" --format "{{.Names}}" | head -n1)
    
    if [ -z "$container_name" ]; then
        print_status "FAIL" "Qdrant" "Container not found"
        return
    fi
    
    if check_container "$container_name"; then
        if check_http "http://localhost:6333/healthz"; then
            # Get collection info if verbose
            if [ "$VERBOSE" = true ]; then
                local collections=$(curl -s "http://localhost:6333/collections" | grep -o '"name":"[^"]*"' | wc -l)
                print_status "OK" "Qdrant" "Running (Collections: ${collections})"
            else
                print_status "OK" "Qdrant" "Running"
            fi
        else
            print_status "WARN" "Qdrant" "Container running but not responding"
        fi
    else
        print_status "FAIL" "Qdrant" "Container not running"
    fi
}

# Function to check API
check_api() {
    local container_name=$(docker ps --filter "name=amulet-ai-service" --format "{{.Names}}" | head -n1)
    
    if [ -z "$container_name" ]; then
        container_name=$(docker ps --filter "name=api" --format "{{.Names}}" | head -n1)
    fi
    
    if [ -z "$container_name" ]; then
        print_status "FAIL" "API" "Container not found"
        return
    fi
    
    if check_container "$container_name"; then
        if check_http "http://localhost:8000/health"; then
            print_status "OK" "API" "Running"
        else
            print_status "WARN" "API" "Container running but not responding"
        fi
    else
        print_status "FAIL" "API" "Container not running"
    fi
}

# Function to check Web
check_web() {
    local container_name=$(docker ps --filter "name=web" --format "{{.Names}}" | head -n1)
    
    if [ -z "$container_name" ]; then
        print_status "FAIL" "Web" "Container not found"
        return
    fi
    
    if check_container "$container_name"; then
        if check_http "http://localhost:3000"; then
            print_status "OK" "Web" "Running"
        else
            print_status "WARN" "Web" "Container running but not responding"
        fi
    else
        print_status "FAIL" "Web" "Container not running"
    fi
}

# Function to check Triton (optional)
check_triton() {
    local container_name=$(docker ps --filter "name=triton" --format "{{.Names}}" | head -n1)
    
    if [ -z "$container_name" ]; then
        [ "$VERBOSE" = true ] && print_status "WARN" "Triton" "Container not found (optional)"
        return
    fi
    
    if check_container "$container_name"; then
        # Triton health check endpoint
        if check_http "http://localhost:8000/v2/health/ready" 10; then
            print_status "OK" "Triton" "Running"
        else
            print_status "WARN" "Triton" "Container running but not ready"
        fi
    else
        print_status "WARN" "Triton" "Container not running"
    fi
}

# Function to check disk space
check_disk_space() {
    local warning_threshold=80
    local critical_threshold=90
    
    # Check data directory
    if [ -d "/var/lib/pra-analysis" ]; then
        local usage=$(df -h /var/lib/pra-analysis | awk 'NR==2 {print $5}' | sed 's/%//')
        
        if [ "$usage" -ge "$critical_threshold" ]; then
            print_status "FAIL" "Disk Space" "Critical: ${usage}% used"
        elif [ "$usage" -ge "$warning_threshold" ]; then
            print_status "WARN" "Disk Space" "Warning: ${usage}% used"
        else
            print_status "OK" "Disk Space" "${usage}% used"
        fi
    fi
}

# Function to check memory
check_memory() {
    local warning_threshold=80
    local critical_threshold=90
    
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    
    if [ "$mem_usage" -ge "$critical_threshold" ]; then
        print_status "FAIL" "Memory" "Critical: ${mem_usage}% used"
    elif [ "$mem_usage" -ge "$warning_threshold" ]; then
        print_status "WARN" "Memory" "Warning: ${mem_usage}% used"
    else
        print_status "OK" "Memory" "${mem_usage}% used"
    fi
}

# Function to send alert
send_alert() {
    local message="$1"
    
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"${message}\"}" \
            "$SLACK_WEBHOOK" > /dev/null 2>&1
    fi
    
    if [ -n "$EMAIL_ALERT" ]; then
        echo "$message" | mail -s "Pra Analysis Health Alert" "$EMAIL_ALERT" 2>/dev/null
    fi
    
    # Log to syslog
    logger -t "pra-analysis-health" "$message"
}

# Function to display summary
display_summary() {
    echo ""
    echo "========================================================================="
    
    case $HEALTH_STATUS in
        0)
            echo -e "${GREEN}System Status: HEALTHY${NC}"
            ;;
        1)
            echo -e "${YELLOW}System Status: WARNING${NC}"
            ;;
        2)
            echo -e "${RED}System Status: CRITICAL${NC}"
            ;;
    esac
    
    echo "========================================================================="
    
    if [ ${#HEALTH_MESSAGES[@]} -gt 0 ]; then
        echo ""
        echo "Issues detected:"
        for msg in "${HEALTH_MESSAGES[@]}"; do
            echo "  - $msg"
        done
    fi
    
    echo ""
}

# Main health check flow
main() {
    echo "Pra Analysis - System Health Check"
    echo "$(date)"
    echo "========================================================================="
    echo ""
    
    # Check SeaweedFS components
    echo "SeaweedFS Cluster:"
    check_seaweedfs_master 1
    check_seaweedfs_master 2
    check_seaweedfs_master 3
    check_seaweedfs_volume 1
    check_seaweedfs_volume 2
    check_seaweedfs_filer
    check_seaweedfs_s3
    echo ""
    
    # Check databases
    echo "Databases:"
    check_postgres
    check_qdrant
    echo ""
    
    # Check application services
    echo "Application Services:"
    check_api
    check_web
    [ "$VERBOSE" = true ] && check_triton
    echo ""
    
    # Check system resources
    if [ "$VERBOSE" = true ]; then
        echo "System Resources:"
        check_disk_space
        check_memory
        echo ""
    fi
    
    # Display summary
    display_summary
    
    # Send alerts if needed
    if [ "$ALERT_MODE" = true ] && [ $HEALTH_STATUS -gt 0 ]; then
        local alert_msg="Pra Analysis Health Alert: "
        [ $HEALTH_STATUS -eq 1 ] && alert_msg+="WARNING"
        [ $HEALTH_STATUS -eq 2 ] && alert_msg+="CRITICAL"
        alert_msg+=$'\n'"${HEALTH_MESSAGES[*]}"
        send_alert "$alert_msg"
    fi
    
    # Exit with health status
    exit $HEALTH_STATUS
}

# Run main function
main "$@"

