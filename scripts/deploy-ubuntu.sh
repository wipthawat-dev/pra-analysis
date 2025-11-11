#!/bin/bash

###############################################################################
# Pra Analysis - Ubuntu Production Deployment Script
# This script automates the deployment of Pra Analysis system on Ubuntu
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
APP_DIR="/opt/${APP_NAME}"
DATA_DIR="/var/lib/${APP_NAME}"
BACKUP_DIR="/backup/${APP_NAME}"
LOG_FILE="/var/log/${APP_NAME}-deploy.log"

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

# Function to check Ubuntu version
check_ubuntu_version() {
    print_info "Checking Ubuntu version..."
    
    if [ ! -f /etc/os-release ]; then
        print_error "Cannot detect OS version"
        exit 1
    fi
    
    . /etc/os-release
    
    if [ "$ID" != "ubuntu" ]; then
        print_warning "This script is designed for Ubuntu. Detected: $ID"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "OS: $PRETTY_NAME"
}

# Function to install Docker
install_docker() {
    print_info "Checking Docker installation..."
    
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed: $(docker --version)"
        return 0
    fi
    
    print_info "Installing Docker..."
    
    # Update package index
    apt-get update
    
    # Install prerequisites
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    print_success "Docker installed successfully: $(docker --version)"
}

# Function to install Docker Compose
install_docker_compose() {
    print_info "Checking Docker Compose installation..."
    
    if docker compose version &> /dev/null; then
        print_success "Docker Compose is already installed: $(docker compose version)"
        return 0
    fi
    
    print_error "Docker Compose plugin not found. Please install Docker Engine first."
    exit 1
}

# Function to install NVIDIA Container Toolkit (for GPU support)
install_nvidia_toolkit() {
    print_info "Checking for NVIDIA GPU..."
    
    if ! command -v nvidia-smi &> /dev/null; then
        print_warning "nvidia-smi not found. Skipping NVIDIA Container Toolkit installation."
        print_warning "GPU support will not be available."
        return 0
    fi
    
    print_info "NVIDIA GPU detected. Installing NVIDIA Container Toolkit..."
    
    # Add NVIDIA Container Toolkit repository
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    apt-get update
    apt-get install -y nvidia-container-toolkit
    
    # Configure Docker to use NVIDIA runtime
    nvidia-ctk runtime configure --runtime=docker
    systemctl restart docker
    
    print_success "NVIDIA Container Toolkit installed successfully"
}

# Function to create directories
create_directories() {
    print_info "Creating application directories..."
    
    # Create data directories
    mkdir -p "${DATA_DIR}"/{qdrant,postgres,seaweedfs/{master1,master2,master3,volume1,volume2,filer}}
    
    # Create backup directories
    mkdir -p "${BACKUP_DIR}"/{postgres,seaweedfs/{master1,master2,master3,volume1,volume2}}
    
    # Create log directory
    mkdir -p /var/log/${APP_NAME}
    
    # Set permissions
    chmod -R 755 "${DATA_DIR}"
    chmod -R 755 "${BACKUP_DIR}"
    
    print_success "Directories created successfully"
}

# Function to configure firewall
configure_firewall() {
    print_info "Configuring firewall rules..."
    
    if ! command -v ufw &> /dev/null; then
        print_warning "UFW not found. Skipping firewall configuration."
        return 0
    fi
    
    # Allow SSH
    ufw allow 22/tcp
    
    # Allow web traffic
    ufw allow 3000/tcp comment "Next.js Web"
    ufw allow 8000/tcp comment "FastAPI Backend"
    
    # Allow SeaweedFS
    ufw allow 8333/tcp comment "SeaweedFS S3"
    ufw allow 8888/tcp comment "SeaweedFS Filer"
    ufw allow 9333/tcp comment "SeaweedFS Master 1"
    ufw allow 9334/tcp comment "SeaweedFS Master 2"
    ufw allow 9335/tcp comment "SeaweedFS Master 3"
    
    # Allow PostgreSQL (only from localhost by default)
    # ufw allow from 127.0.0.1 to any port 5432 proto tcp
    
    # Enable UFW if not already enabled
    if ! ufw status | grep -q "Status: active"; then
        print_warning "UFW is not active. To enable it, run: sudo ufw enable"
    fi
    
    print_success "Firewall rules configured"
}

# Function to create .env file
create_env_file() {
    print_info "Creating .env file..."
    
    if [ -f "${APP_DIR}/.env" ]; then
        print_warning ".env file already exists. Backing up to .env.backup"
        cp "${APP_DIR}/.env" "${APP_DIR}/.env.backup"
    fi
    
    cat > "${APP_DIR}/.env" <<EOF
# Pra Analysis - Production Environment Configuration
# Generated on $(date)

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
NEXT_PUBLIC_API_BASE=http://$(hostname -I | awk '{print $1}'):8000

# Triton Inference Server
TRITON_GRPC_URL=triton:8001

# Qdrant Vector Database
QDRANT_URL=http://qdrant:6333
QDRANT_COLLECTION=amulet_clip_v1
EMBED_DIM=768

# SeaweedFS S3-Compatible Storage
S3_ENDPOINT=seaweedfs-s3:8333
S3_ACCESS_KEY=seaweedfs_admin
S3_SECRET_KEY=$(openssl rand -base64 32)
S3_SECURE=false
S3_REGION=us-east-1

# PostgreSQL Database
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=amulet_db
POSTGRES_USER=amulet_user
POSTGRES_PASSWORD=$(openssl rand -base64 32)
EOF
    
    chmod 600 "${APP_DIR}/.env"
    print_success ".env file created with random passwords"
    print_warning "IMPORTANT: Save the credentials from ${APP_DIR}/.env"
}

# Function to deploy application
deploy_application() {
    print_info "Deploying application..."
    
    cd "${APP_DIR}"
    
    # Pull latest images
    print_info "Pulling Docker images..."
    docker compose -f docker-compose.production.yml pull
    
    # Build custom images
    print_info "Building application images..."
    docker compose -f docker-compose.production.yml build
    
    # Start services
    print_info "Starting services..."
    docker compose -f docker-compose.production.yml up -d
    
    print_success "Application deployed successfully"
}

# Function to check service health
check_services() {
    print_info "Checking service health..."
    
    sleep 10  # Wait for services to start
    
    # Check Docker containers
    print_info "Container status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "seaweedfs|postgres|qdrant|api|web"
    
    # Check SeaweedFS master cluster
    print_info "Checking SeaweedFS cluster status..."
    curl -s http://localhost:9333/cluster/status || print_warning "SeaweedFS master 1 not responding"
    
    # Check API health
    print_info "Checking API health..."
    sleep 30  # Wait for API to be ready
    curl -s http://localhost:8000/health || print_warning "API not responding"
    
    print_success "Service health check completed"
}

# Function to setup systemd service (optional)
setup_systemd() {
    print_info "Creating systemd service..."
    
    cat > /etc/systemd/system/${APP_NAME}.service <<EOF
[Unit]
Description=Pra Analysis System
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/docker compose -f docker-compose.production.yml up -d
ExecStop=/usr/bin/docker compose -f docker-compose.production.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable ${APP_NAME}.service
    
    print_success "Systemd service created and enabled"
}

# Function to display deployment info
display_info() {
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo "========================================================================="
    echo -e "${GREEN}Pra Analysis Deployment Completed Successfully!${NC}"
    echo "========================================================================="
    echo ""
    echo "Server Information:"
    echo "  - Server IP: ${SERVER_IP}"
    echo "  - Web Interface: http://${SERVER_IP}:3000"
    echo "  - API Endpoint: http://${SERVER_IP}:8000"
    echo "  - API Docs: http://${SERVER_IP}:8000/docs"
    echo ""
    echo "SeaweedFS Information:"
    echo "  - S3 Endpoint: http://${SERVER_IP}:8333"
    echo "  - Filer: http://${SERVER_IP}:8888"
    echo "  - Master 1: http://${SERVER_IP}:9333"
    echo "  - Master 2: http://${SERVER_IP}:9334"
    echo "  - Master 3: http://${SERVER_IP}:9335"
    echo ""
    echo "Management Commands:"
    echo "  - View logs: docker compose -f ${APP_DIR}/docker-compose.production.yml logs -f"
    echo "  - Stop services: docker compose -f ${APP_DIR}/docker-compose.production.yml down"
    echo "  - Restart services: docker compose -f ${APP_DIR}/docker-compose.production.yml restart"
    echo "  - Service status: systemctl status ${APP_NAME}"
    echo ""
    echo "Important Files:"
    echo "  - Environment: ${APP_DIR}/.env"
    echo "  - Data directory: ${DATA_DIR}"
    echo "  - Backup directory: ${BACKUP_DIR}"
    echo "  - Logs: /var/log/${APP_NAME}/"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Review and save credentials from ${APP_DIR}/.env"
    echo "  2. Configure backup schedule using ${APP_DIR}/scripts/backup-seaweedfs.sh"
    echo "  3. Setup SSL/TLS if exposing to internet"
    echo "  4. Configure monitoring and alerting"
    echo "========================================================================="
}

# Main deployment flow
main() {
    print_info "Starting Pra Analysis deployment on Ubuntu..."
    print_info "Log file: ${LOG_FILE}"
    
    # Pre-deployment checks
    check_root
    check_ubuntu_version
    
    # Install dependencies
    install_docker
    install_docker_compose
    
    # Optional: Install NVIDIA toolkit for GPU support
    read -p "Install NVIDIA Container Toolkit for GPU support? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_nvidia_toolkit
    fi
    
    # Create directories
    create_directories
    
    # Configure firewall
    read -p "Configure UFW firewall rules? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        configure_firewall
    fi
    
    # Copy application files
    if [ ! -d "${APP_DIR}" ]; then
        print_error "Application directory ${APP_DIR} not found!"
        print_info "Please clone the repository to ${APP_DIR} first:"
        print_info "  git clone <repository-url> ${APP_DIR}"
        exit 1
    fi
    
    # Create environment file
    create_env_file
    
    # Deploy application
    deploy_application
    
    # Check services
    check_services
    
    # Setup systemd service
    read -p "Setup systemd service for auto-start? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_systemd
    fi
    
    # Display deployment information
    display_info
    
    print_success "Deployment completed successfully!"
}

# Run main function
main "$@"

