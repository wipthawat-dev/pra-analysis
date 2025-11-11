# Pra Analysis - Ubuntu Production Deployment Guide

This guide covers deploying Pra Analysis system on Ubuntu 20.04/22.04/24.04 with SeaweedFS high availability configuration.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Deployment](#quick-deployment)
- [Manual Deployment](#manual-deployment)
- [SeaweedFS Architecture](#seaweedfs-architecture)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Backup and Recovery](#backup-and-recovery)
- [Troubleshooting](#troubleshooting)
- [Security Hardening](#security-hardening)

## Prerequisites

### System Requirements

**Minimum (Development/Testing):**
- CPU: 4 cores
- RAM: 8 GB
- Disk: 100 GB SSD
- Ubuntu 20.04+ (64-bit)

**Recommended (Production):**
- CPU: 8+ cores
- RAM: 16+ GB
- Disk: 500 GB+ SSD (RAID recommended)
- Ubuntu 22.04 LTS (64-bit)
- Dedicated storage disk for SeaweedFS volumes

**For GPU Support:**
- NVIDIA GPU with 8+ GB VRAM
- NVIDIA Driver 525+ installed
- CUDA 12.0+ compatible

### Network Requirements

Open firewall ports:
- `3000` - Next.js web interface
- `8000` - FastAPI backend
- `8333` - SeaweedFS S3 API
- `8888` - SeaweedFS Filer (optional, for administration)
- `9333-9335` - SeaweedFS Master cluster (optional, for cluster management)
- `5432` - PostgreSQL (localhost only recommended)
- `6333` - Qdrant (localhost only recommended)

## Quick Deployment

### Automated Installation

1. **Clone Repository**

```bash
sudo mkdir -p /opt/pra-analysis
sudo chown $USER:$USER /opt/pra-analysis
git clone <repository-url> /opt/pra-analysis
cd /opt/pra-analysis
```

2. **Run Deployment Script**

```bash
sudo bash scripts/deploy-ubuntu.sh
```

The script will:
- Install Docker and Docker Compose
- Optionally install NVIDIA Container Toolkit (for GPU support)
- Create necessary directories
- Configure firewall rules (optional)
- Generate secure credentials
- Deploy all services
- Setup systemd service (optional)

3. **Verify Deployment**

```bash
# Check all services
sudo bash scripts/health-check.sh -v

# Or check individual services
docker ps
curl http://localhost:8000/health
curl http://localhost:3000
```

## Manual Deployment

### Step 1: Install Docker

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
docker --version
docker compose version
```

### Step 2: Install NVIDIA Container Toolkit (GPU Only)

```bash
# Check NVIDIA GPU
nvidia-smi

# Add NVIDIA Container Toolkit repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install toolkit
sudo apt update
sudo apt install -y nvidia-container-toolkit

# Configure Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify GPU support
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

### Step 3: Create Directories

```bash
# Create data directories
sudo mkdir -p /var/lib/pra-analysis/{qdrant,postgres}
sudo mkdir -p /var/lib/pra-analysis/seaweedfs/{master1,master2,master3,volume1,volume2,filer}

# Create backup directories
sudo mkdir -p /backup/pra-analysis/{postgres,seaweedfs/{master1,master2,master3,volume1,volume2}}

# Create log directory
sudo mkdir -p /var/log/pra-analysis

# Set permissions
sudo chown -R $(id -u):$(id -g) /var/lib/pra-analysis
sudo chmod -R 755 /var/lib/pra-analysis
```

### Step 4: Configure Environment

```bash
cd /opt/pra-analysis

# Create .env file
cat > .env <<EOF
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

# Secure the file
chmod 600 .env

# IMPORTANT: Save these credentials securely!
cat .env
```

### Step 5: Deploy Services

```bash
# Pull images
docker compose -f docker-compose.production.yml pull

# Build application images
docker compose -f docker-compose.production.yml build

# Start services
docker compose -f docker-compose.production.yml up -d

# Wait for services to initialize
sleep 30

# Check status
docker ps
```

### Step 6: Configure Firewall

```bash
# Install UFW if not installed
sudo apt install -y ufw

# Allow SSH
sudo ufw allow 22/tcp

# Allow web services
sudo ufw allow 3000/tcp comment "Next.js Web"
sudo ufw allow 8000/tcp comment "FastAPI Backend"

# Allow SeaweedFS
sudo ufw allow 8333/tcp comment "SeaweedFS S3"
sudo ufw allow 8888/tcp comment "SeaweedFS Filer"
sudo ufw allow 9333/tcp comment "SeaweedFS Master 1"
sudo ufw allow 9334/tcp comment "SeaweedFS Master 2"
sudo ufw allow 9335/tcp comment "SeaweedFS Master 3"

# Enable firewall (careful with SSH!)
sudo ufw enable

# Check status
sudo ufw status
```

### Step 7: Setup Systemd Service

```bash
# Create systemd service file
sudo tee /etc/systemd/system/pra-analysis.service > /dev/null <<EOF
[Unit]
Description=Pra Analysis System
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/pra-analysis
ExecStart=/usr/bin/docker compose -f docker-compose.production.yml up -d
ExecStop=/usr/bin/docker compose -f docker-compose.production.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable pra-analysis.service

# Service commands:
# sudo systemctl start pra-analysis
# sudo systemctl stop pra-analysis
# sudo systemctl restart pra-analysis
# sudo systemctl status pra-analysis
```

## SeaweedFS Architecture

### High Availability Configuration

Pra Analysis uses a 3-master SeaweedFS cluster for high availability:

```
┌─────────────────────────────────────────────────────────┐
│                     Pra Analysis API                     │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
              ┌───────────────┐
              │  SeaweedFS S3 │  (Port 8333)
              │    Gateway    │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ SeaweedFS     │  (Port 8888)
              │    Filer      │
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌────────┐    ┌────────┐    ┌────────┐
   │Master 1│    │Master 2│    │Master 3│  (Ports 9333-9335)
   │(Leader)│◄──►│(Follwr)│◄──►│(Follwr)│  Raft Consensus
   └────┬───┘    └────┬───┘    └────┬───┘
        │             │             │
        └─────────────┼─────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
    ┌──────────┐            ┌──────────┐
    │ Volume 1 │            │ Volume 2 │  (Ports 8080-8081)
    │  Server  │            │  Server  │  Data Storage
    └──────────┘            └──────────┘
```

### Key Features

1. **Master High Availability**: 3 masters using Raft consensus
   - Automatic leader election
   - Survives single master failure
   - Consistent metadata management

2. **Data Replication**: Configurable replication (default: 010)
   - 010 = 1 copy on different rack
   - 001 = 1 copy on same rack
   - 100 = no replication

3. **S3 Compatibility**: Full S3 API support via SeaweedFS S3 gateway
   - Works with existing boto3 code
   - No code changes required

4. **Scalability**: Easily add more volume servers as needed

## Configuration

### SeaweedFS Tuning

Edit `docker-compose.production.yml` for performance tuning:

```yaml
# Master configuration
command: 'master -ip=seaweedfs-master1 -port=9333 \
  -peers=seaweedfs-master1:9333,seaweedfs-master2:9334,seaweedfs-master3:9335 \
  -mdir=/data \
  -defaultReplication=010 \          # Change replication strategy
  -volumeSizeLimitMB=30000'          # Max volume size (30GB)

# Volume server configuration
command: 'volume -mserver=... \
  -port=8080 \
  -max=500 \                          # Max number of volumes
  -dir=/data \
  -compactionMBps=50'                 # Compaction speed limit
```

### Resource Limits

Adjust Docker resource limits in `docker-compose.production.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'          # Maximum CPU cores
      memory: 8G         # Maximum memory
    reservations:
      cpus: '2'          # Minimum CPU cores
      memory: 4G         # Minimum memory
```

### SSL/TLS Configuration

For production with HTTPS, use a reverse proxy (Nginx or Traefik):

```nginx
# /etc/nginx/sites-available/pra-analysis
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/ssl/certs/your-domain.crt;
    ssl_certificate_key /etc/ssl/private/your-domain.key;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # API
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # SeaweedFS S3 (if exposing to public)
    location /s3/ {
        proxy_pass http://localhost:8333/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Monitoring

### Health Checks

```bash
# Automated health check
sudo bash /opt/pra-analysis/scripts/health-check.sh -v

# Manual checks
curl http://localhost:8000/health                # API
curl http://localhost:9333/cluster/status       # SeaweedFS cluster
curl http://localhost:6333/healthz              # Qdrant
docker exec postgres pg_isready -U postgres     # PostgreSQL
```

### Logging

```bash
# View all logs
docker compose -f /opt/pra-analysis/docker-compose.production.yml logs -f

# View specific service logs
docker logs seaweedfs-master1 -f
docker logs amulet-ai-service-prod -f

# System logs
sudo journalctl -u pra-analysis -f
tail -f /var/log/pra-analysis/*.log
```

### Metrics and Monitoring

SeaweedFS provides Prometheus-compatible metrics:

```bash
# Master metrics
curl http://localhost:19333/metrics

# Volume metrics
curl http://localhost:18080/metrics

# Filer metrics
curl http://localhost:18888/metrics
```

## Backup and Recovery

### Automated Backups

Setup automated backups using cron:

```bash
# Create backup script wrapper
sudo tee /usr/local/bin/pra-backup.sh > /dev/null <<'EOF'
#!/bin/bash
cd /opt/pra-analysis
bash scripts/backup-seaweedfs.sh 2>&1 | tee -a /var/log/pra-analysis/backup.log
EOF

sudo chmod +x /usr/local/bin/pra-backup.sh

# Add to crontab (daily at 2 AM)
sudo crontab -e
# Add this line:
0 2 * * * /usr/local/bin/pra-backup.sh
```

### Manual Backup

```bash
sudo bash /opt/pra-analysis/scripts/backup-seaweedfs.sh
```

Backup includes:
- SeaweedFS master metadata
- SeaweedFS volume data
- SeaweedFS filer data
- PostgreSQL database dump
- Qdrant vector database

### Restore from Backup

```bash
# List available backups
ls -lh /backup/pra-analysis/backups/

# Restore from specific backup
sudo bash /opt/pra-analysis/scripts/restore-seaweedfs.sh 20240101_120000

# Or restore from latest
sudo bash /opt/pra-analysis/scripts/restore-seaweedfs.sh
```

### Offsite Backup

Setup rsync or rclone for offsite backups:

```bash
# Example: Backup to remote server
rsync -avz --delete /backup/pra-analysis/ user@backup-server:/backups/pra-analysis/

# Example: Backup to S3 (using rclone)
rclone sync /backup/pra-analysis/ remote:pra-analysis-backups/
```

## Troubleshooting

### Common Issues

#### SeaweedFS Master Not Starting

```bash
# Check logs
docker logs seaweedfs-master1

# Common causes:
# 1. Port conflict
sudo netstat -tulpn | grep -E '9333|9334|9335'

# 2. Permission issues
sudo chown -R $(id -u):$(id -g) /var/lib/pra-analysis/seaweedfs/

# 3. Corrupted data - clean start
docker-compose -f /opt/pra-analysis/docker-compose.production.yml down
sudo rm -rf /var/lib/pra-analysis/seaweedfs/master*/*
docker-compose -f /opt/pra-analysis/docker-compose.production.yml up -d
```

#### API Cannot Connect to SeaweedFS

```bash
# Test S3 connectivity
docker exec amulet-ai-service-prod curl -v http://seaweedfs-s3:8333/

# Check S3 gateway logs
docker logs seaweedfs-s3-prod

# Restart S3 gateway
docker restart seaweedfs-s3-prod
docker restart amulet-ai-service-prod
```

#### Disk Space Issues

```bash
# Check disk usage
df -h /var/lib/pra-analysis/

# Check SeaweedFS volume usage
curl http://localhost:9333/vol/status | jq

# Compact volumes (reduces space)
docker exec seaweedfs-volume1-prod weed shell <<EOF
volume.balance -collection="" -force
volume.fix.replication
EOF
```

#### Performance Issues

```bash
# Check system resources
htop
docker stats

# Check SeaweedFS cluster health
curl http://localhost:9333/cluster/status | jq

# Check PostgreSQL performance
docker exec postgres-prod psql -U postgres -c "SELECT * FROM pg_stat_activity;"

# Analyze slow queries
docker logs amulet-ai-service-prod | grep "slow query"
```

### Debug Mode

Enable debug logging:

```bash
# Edit docker-compose.production.yml
environment:
  - LOG_LEVEL=DEBUG

# Restart services
docker compose -f /opt/pra-analysis/docker-compose.production.yml restart api
```

## Security Hardening

### 1. Change Default Credentials

```bash
# Generate strong passwords
NEW_S3_SECRET=$(openssl rand -base64 32)
NEW_PG_PASSWORD=$(openssl rand -base64 32)

# Update .env file
sed -i "s/S3_SECRET_KEY=.*/S3_SECRET_KEY=${NEW_S3_SECRET}/" /opt/pra-analysis/.env
sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${NEW_PG_PASSWORD}/" /opt/pra-analysis/.env

# Recreate services
cd /opt/pra-analysis
docker compose -f docker-compose.production.yml down
docker compose -f docker-compose.production.yml up -d
```

### 2. Limit Network Exposure

```bash
# Only expose necessary ports
# Edit docker-compose.production.yml to bind to localhost:
ports:
  - "127.0.0.1:5432:5432"  # PostgreSQL (local only)
  - "127.0.0.1:6333:6333"  # Qdrant (local only)
```

### 3. Enable SELinux/AppArmor

```bash
# Check SELinux status
sestatus

# Or AppArmor
sudo aa-status
```

### 4. Regular Updates

```bash
# Update Docker images
cd /opt/pra-analysis
docker compose -f docker-compose.production.yml pull
docker compose -f docker-compose.production.yml up -d

# Update system packages
sudo apt update && sudo apt upgrade -y
```

### 5. Setup Fail2ban

```bash
# Install fail2ban
sudo apt install -y fail2ban

# Configure for Nginx (if using reverse proxy)
sudo tee /etc/fail2ban/jail.d/nginx-pra.conf > /dev/null <<EOF
[nginx-pra]
enabled = true
port = http,https
filter = nginx-pra
logpath = /var/log/nginx/access.log
maxretry = 5
bantime = 3600
EOF

sudo systemctl restart fail2ban
```

## Performance Optimization

### Database Tuning

```bash
# PostgreSQL optimization
docker exec postgres-prod psql -U postgres <<EOF
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET effective_cache_size = '6GB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';
ALTER SYSTEM SET work_mem = '32MB';
EOF

docker restart postgres-prod
```

### SeaweedFS Optimization

```yaml
# In docker-compose.production.yml
command: 'volume ... -compactionMBps=100 -max=1000'
```

## Conclusion

Your Pra Analysis system should now be running in production mode with:
- ✅ High availability SeaweedFS cluster (3 masters)
- ✅ Automated backups
- ✅ Health monitoring
- ✅ Systemd service management
- ✅ Firewall configuration
- ✅ Resource limits

For additional help, see:
- `README.md` - General documentation
- `SEAWEEDFS_MIGRATION.md` - Migration guide and operations
- `scripts/health-check.sh` - Health monitoring script
- `scripts/backup-seaweedfs.sh` - Backup script
- `scripts/restore-seaweedfs.sh` - Restore script

