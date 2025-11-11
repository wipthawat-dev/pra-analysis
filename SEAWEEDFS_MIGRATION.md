# SeaweedFS Migration and Operations Guide

This document covers the migration from Ceph RGW to SeaweedFS, comparison, best practices, and operational procedures.

## Table of Contents

- [Why SeaweedFS](#why-seaweedfs)
- [Migration Overview](#migration-overview)
- [Data Migration](#data-migration)
- [Ceph RGW vs SeaweedFS](#ceph-rgw-vs-seaweedfs)
- [SeaweedFS Operations](#seaweedfs-operations)
- [Performance Tuning](#performance-tuning)
- [Disaster Recovery](#disaster-recovery)
- [Advanced Configuration](#advanced-configuration)

## Why SeaweedFS

### Licensing

- **Ceph RGW**: LGPL (Limited General Public License)
  - Copyleft license with linking restrictions
  - May require source disclosure in some scenarios
  - Less permissive for commercial use

- **SeaweedFS**: Apache 2.0
  - Permissive, business-friendly license
  - Compatible with commercial use
  - No copyleft requirements
  - Aligns with "Safe OSS" policy (Apache-2.0, MIT, BSD-3)

### Technical Advantages

1. **Simpler Architecture**
   - Fewer components (no RADOS, Monitors, OSDs)
   - Easier to understand and troubleshoot
   - Lower operational complexity

2. **Better Performance**
   - Faster startup time (30s vs 60-90s for Ceph)
   - Lower resource consumption
   - Optimized for small to medium files (images, documents)

3. **High Availability**
   - Built-in master-master replication using Raft
   - Automatic failover
   - Consistent metadata management

4. **S3 Compatibility**
   - Full S3 API compatibility
   - Works with existing boto3 code (no changes needed)
   - Compatible with AWS SDKs

5. **Scalability**
   - Easy horizontal scaling
   - Add volume servers without downtime
   - Distributed data placement

## Migration Overview

### Migration Path

Since the Pra Analysis system is new (no existing data), the migration is straightforward:

1. ✅ **Code Migration**: Already using boto3 (S3-compatible API)
   - No application code changes required
   - Storage client (`storage_client.py`) works with both systems

2. ✅ **Configuration Migration**: Update environment variables
   - Change `S3_ENDPOINT` from `ceph-rgw:9000` to `seaweedfs-s3:8333`
   - Update access keys and secrets

3. ✅ **Infrastructure Migration**: Replace Docker services
   - Remove Ceph RGW containers
   - Add SeaweedFS cluster (masters, volumes, filer, s3)

### For Future Data Migration

If you need to migrate existing data from Ceph RGW to SeaweedFS:

#### Option 1: Using S3 Sync Tools

```bash
# Install s3cmd or rclone
sudo apt install -y s3cmd

# Configure source (Ceph RGW)
s3cmd --configure --profile=ceph
# Enter: Ceph endpoint, access key, secret key

# Configure destination (SeaweedFS)
s3cmd --configure --profile=seaweedfs
# Enter: SeaweedFS endpoint, access key, secret key

# Sync all buckets
for bucket in images datasets models results metadata logs; do
    echo "Syncing bucket: $bucket"
    s3cmd sync --profile=ceph s3://$bucket/ --profile=seaweedfs s3://$bucket/
done
```

#### Option 2: Using rclone (Recommended for Large Data)

```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure rclone
rclone config

# Create 'ceph' remote (S3 type)
# Create 'seaweedfs' remote (S3 type)

# Sync data with progress
rclone sync ceph:images seaweedfs:images --progress --transfers 10 --checkers 20
rclone sync ceph:datasets seaweedfs:datasets --progress --transfers 10 --checkers 20
rclone sync ceph:models seaweedfs:models --progress --transfers 10 --checkers 20
rclone sync ceph:results seaweedfs:results --progress --transfers 10 --checkers 20

# Verify data integrity
rclone check ceph:images seaweedfs:images
```

#### Option 3: Application-Level Migration

```python
# Python migration script
import boto3
from tqdm import tqdm

# Source (Ceph RGW)
ceph_client = boto3.client(
    's3',
    endpoint_url='http://ceph-rgw:9000',
    aws_access_key_id='ceph_access_key',
    aws_secret_access_key='ceph_secret_key'
)

# Destination (SeaweedFS)
seaweedfs_client = boto3.client(
    's3',
    endpoint_url='http://seaweedfs-s3:8333',
    aws_access_key_id='seaweedfs_admin',
    aws_secret_access_key='seaweedfs_secret'
)

def migrate_bucket(bucket_name):
    """Migrate all objects from one bucket to another"""
    print(f"Migrating bucket: {bucket_name}")
    
    # List all objects
    paginator = ceph_client.get_paginator('list_objects_v2')
    pages = paginator.paginate(Bucket=bucket_name)
    
    objects = []
    for page in pages:
        if 'Contents' in page:
            objects.extend(page['Contents'])
    
    # Migrate each object
    for obj in tqdm(objects, desc=bucket_name):
        key = obj['Key']
        
        # Download from Ceph
        response = ceph_client.get_object(Bucket=bucket_name, Key=key)
        data = response['Body'].read()
        
        # Upload to SeaweedFS
        seaweedfs_client.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=data,
            ContentType=response.get('ContentType', 'application/octet-stream')
        )
    
    print(f"Migrated {len(objects)} objects from {bucket_name}")

# Migrate all buckets
buckets = ['images', 'datasets', 'models', 'results', 'metadata', 'logs']
for bucket in buckets:
    migrate_bucket(bucket)
```

## Ceph RGW vs SeaweedFS

### Feature Comparison

| Feature | Ceph RGW | SeaweedFS | Winner |
|---------|----------|-----------|--------|
| **License** | LGPL | Apache 2.0 | SeaweedFS |
| **Startup Time** | 60-90s | 10-30s | SeaweedFS |
| **Memory Usage** | ~2GB+ | ~500MB | SeaweedFS |
| **S3 Compatibility** | Good | Excellent | SeaweedFS |
| **Setup Complexity** | High | Low | SeaweedFS |
| **Multi-DC Replication** | Yes | Yes | Tie |
| **Erasure Coding** | Yes | No | Ceph |
| **Small File Performance** | Good | Excellent | SeaweedFS |
| **Large File Performance** | Excellent | Good | Ceph |
| **Enterprise Support** | Red Hat | Commercial | Tie |
| **Community** | Large | Growing | Ceph |

### Use Case Recommendations

**Choose SeaweedFS for:**
- ✅ Small to medium files (images, documents, logs)
- ✅ Simpler operations and maintenance
- ✅ Apache 2.0 licensing requirements
- ✅ Quick startup and development
- ✅ S3 API primary use case

**Choose Ceph for:**
- Large files (videos, backups)
- Erasure coding requirements
- Block and object storage unified platform
- Extreme scale (PB+ storage)
- Existing Ceph expertise

## SeaweedFS Operations

### Cluster Management

#### Check Cluster Status

```bash
# Master cluster status
curl http://localhost:9333/cluster/status | jq

# Volume status
curl http://localhost:9333/vol/status | jq

# Directory status
curl http://localhost:9333/dir/status | jq
```

#### Add Volume Server

```yaml
# Add to docker-compose.production.yml
seaweedfs-volume3:
  image: chrislusf/seaweedfs:latest
  container_name: seaweedfs-volume3-prod
  command: 'volume -mserver=seaweedfs-master1:9333,seaweedfs-master2:9334,seaweedfs-master3:9335 -ip=seaweedfs-volume3 -port=8080 -max=500 -dir=/data'
  ports:
    - "8082:8080"
  volumes:
    - seaweedfs_volume3:/data
  depends_on:
    - seaweedfs-master1
    - seaweedfs-master2
    - seaweedfs-master3
  restart: unless-stopped
```

```bash
# Deploy new volume server
docker compose -f docker-compose.production.yml up -d seaweedfs-volume3

# Rebalance data
docker exec seaweedfs-master1 weed shell <<EOF
volume.balance -collection="" -force
EOF
```

#### Remove Volume Server

```bash
# Mark volume server as readonly
docker exec seaweedfs-master1 weed shell <<EOF
volume.unmount -node seaweedfs-volume2:8080
EOF

# Wait for data to migrate (can take hours for large data)
# Monitor progress
curl http://localhost:9333/vol/status | jq

# Stop and remove container
docker stop seaweedfs-volume2
docker rm seaweedfs-volume2
```

### Bucket Operations

#### Create Bucket via API

```bash
# Create bucket using AWS CLI
aws --endpoint-url http://localhost:8333 \
    --region us-east-1 \
    s3 mb s3://new-bucket

# Or using curl
curl -X PUT http://localhost:8333/new-bucket
```

#### List All Buckets

```bash
aws --endpoint-url http://localhost:8333 s3 ls
```

#### Set Bucket Policy

```bash
# Create policy file
cat > bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::public-bucket/*"
    }
  ]
}
EOF

# Apply policy
aws --endpoint-url http://localhost:8333 \
    s3api put-bucket-policy \
    --bucket public-bucket \
    --policy file://bucket-policy.json
```

### Data Integrity

#### Verify Data Integrity

```bash
# Check volume integrity
docker exec seaweedfs-volume1 weed shell <<EOF
volume.fsck -v
EOF

# Fix replication issues
docker exec seaweedfs-master1 weed shell <<EOF
volume.fix.replication
EOF
```

#### Compact Volumes

```bash
# Compact to reclaim space
docker exec seaweedfs-volume1 weed shell <<EOF
volume.compact -collection="" -volumeId=1
EOF

# Auto-compact on all volumes
curl "http://localhost:8080/admin/vacuum?threshold=0.3"
```

## Performance Tuning

### Master Optimization

```yaml
# docker-compose.production.yml
command: 'master ... 
  -volumePreallocate=true           # Preallocate volumes for better performance
  -volumeSizeLimitMB=30000          # Increase volume size for fewer volumes
  -pulseSeconds=5                   # Heartbeat interval (default 5)
  -garbageThreshold=0.3'            # Garbage collection threshold
```

### Volume Server Optimization

```yaml
command: 'volume ...
  -max=1000                          # Increase max volumes
  -compactionMBps=100                # Faster compaction
  -readMode=local                    # Prefer local reads
  -dataCenter=dc1                    # Set datacenter for geo-replication
  -rack=rack1'                       # Set rack for rack-aware replication
```

### S3 Gateway Optimization

```yaml
command: 's3 ...
  -concurrent.uploads=64             # Increase concurrent uploads
  -allowEmptyFolder=true             # Allow empty folder operations
  -auditLogMode=readable'            # Audit logging
```

### Network Optimization

```bash
# Enable jumbo frames (if network supports)
sudo ip link set eth0 mtu 9000

# Increase TCP buffer sizes
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
sudo sysctl -w net.ipv4.tcp_rmem='4096 87380 67108864'
sudo sysctl -w net.ipv4.tcp_wmem='4096 65536 67108864'
```

### Application-Level Optimization

```python
# Use connection pooling
from botocore.config import Config

config = Config(
    max_pool_connections=50,          # Increase pool size
    retries={'max_attempts': 3},
    connect_timeout=5,
    read_timeout=30
)

s3_client = boto3.client('s3', config=config, ...)

# Multipart uploads for large files
from boto3.s3.transfer import TransferConfig

transfer_config = TransferConfig(
    multipart_threshold=8 * 1024 * 1024,    # 8 MB
    max_concurrency=10,
    multipart_chunksize=8 * 1024 * 1024,
    use_threads=True
)

s3_client.upload_file(
    'large-file.dat',
    'my-bucket',
    'large-file.dat',
    Config=transfer_config
)
```

## Disaster Recovery

### Backup Strategy

#### 1. Master Metadata Backup

```bash
# Backup master metadata
docker exec seaweedfs-master1 tar czf - /data > master1-backup.tar.gz
docker exec seaweedfs-master2 tar czf - /data > master2-backup.tar.gz
docker exec seaweedfs-master3 tar czf - /data > master3-backup.tar.gz
```

#### 2. Volume Data Backup

```bash
# Snapshot volume data
docker exec seaweedfs-volume1 weed shell <<EOF
volume.snapshot -volumeId=1 -destination=/backup/
EOF

# Or backup entire volume directory
tar czf volume1-backup.tar.gz /var/lib/pra-analysis/seaweedfs/volume1/
```

#### 3. Incremental Backup

```bash
# Use rsync for incremental backups
rsync -av --delete \
    /var/lib/pra-analysis/seaweedfs/ \
    backup-server:/backups/seaweedfs-$(date +%Y%m%d)/
```

### Disaster Recovery Procedures

#### Scenario 1: Single Master Failure

```bash
# No action needed - automatic failover
# Leader election happens automatically within 10 seconds

# Verify new leader
curl http://localhost:9333/cluster/status | jq '.Leader'

# Replace failed master
docker stop seaweedfs-master2
docker rm seaweedfs-master2

# Clean data directory
sudo rm -rf /var/lib/pra-analysis/seaweedfs/master2/*

# Restart master
docker compose -f docker-compose.production.yml up -d seaweedfs-master2

# It will automatically sync from leader
```

#### Scenario 2: Multiple Masters Failure (2 or 3)

```bash
# Stop all services
docker compose -f docker-compose.production.yml down

# Restore master metadata from backup
cd /var/lib/pra-analysis/seaweedfs/
tar xzf /backup/master1-backup.tar.gz -C master1/
tar xzf /backup/master2-backup.tar.gz -C master2/
tar xzf /backup/master3-backup.tar.gz -C master3/

# Start masters one by one
docker compose -f docker-compose.production.yml up -d seaweedfs-master1
sleep 10
docker compose -f docker-compose.production.yml up -d seaweedfs-master2
sleep 10
docker compose -f docker-compose.production.yml up -d seaweedfs-master3

# Verify cluster
curl http://localhost:9333/cluster/status
```

#### Scenario 3: Volume Server Failure

```bash
# If replication > 1, data is still available from other volumes
# No immediate action needed

# Check replication status
curl http://localhost:9333/vol/status | jq

# Fix under-replicated volumes
docker exec seaweedfs-master1 weed shell <<EOF
volume.fix.replication
EOF

# Replace failed volume server
docker stop seaweedfs-volume1
sudo rm -rf /var/lib/pra-analysis/seaweedfs/volume1/*
docker compose -f docker-compose.production.yml up -d seaweedfs-volume1

# Rebalance
docker exec seaweedfs-master1 weed shell <<EOF
volume.balance -force
EOF
```

#### Scenario 4: Complete Cluster Loss

```bash
# Restore from offsite backup
# 1. Restore master metadata
# 2. Restore volume data
# 3. Restore filer data

# Follow backup restoration procedure
sudo bash /opt/pra-analysis/scripts/restore-seaweedfs.sh <backup-timestamp>

# Verify data integrity
docker exec seaweedfs-master1 weed shell <<EOF
volume.fsck -v
volume.fix.replication
EOF
```

## Advanced Configuration

### Geo-Replication

Configure datacenters for multi-region deployment:

```yaml
# Master in DC1
seaweedfs-master1:
  command: 'master ... -dataCenter=dc1'

# Volume in DC1
seaweedfs-volume1:
  command: 'volume ... -dataCenter=dc1 -rack=rack1'

# Volume in DC2
seaweedfs-volume2:
  command: 'volume ... -dataCenter=dc2 -rack=rack1'
```

Set replication to span datacenters:

```bash
# 100 = 1 copy in different datacenter
# 200 = 2 copies in different datacenters
curl "http://localhost:9333/vol/grow?count=10&replication=100"
```

### Custom Replication Strategies

```bash
# Replication format: XYZ
# X = copies in different datacenters
# Y = copies in different racks
# Z = copies on different servers

# Examples:
# 000 = no replication
# 001 = 1 copy on different server (same rack, same DC)
# 010 = 1 copy on different rack (same DC)
# 100 = 1 copy in different datacenter
# 200 = 2 copies in different datacenters

# Set default replication
docker exec seaweedfs-master1 weed shell <<EOF
volume.configure.replication -replication 010
EOF
```

### Authentication and Authorization

Create custom S3 credentials:

```json
// config/seaweedfs/s3.json
{
  "identities": [
    {
      "name": "admin",
      "credentials": [
        {
          "accessKey": "admin_access_key",
          "secretKey": "admin_secret_key"
        }
      ],
      "actions": ["Admin", "Read", "List", "Tagging", "Write"]
    },
    {
      "name": "readonly",
      "credentials": [
        {
          "accessKey": "readonly_key",
          "secretKey": "readonly_secret"
        }
      ],
      "actions": ["Read", "List"]
    },
    {
      "name": "app_user",
      "credentials": [
        {
          "accessKey": "app_access_key",
          "secretKey": "app_secret_key"
        }
      ],
      "actions": ["Read", "Write", "List"],
      "buckets": [
        {"bucket": "images", "prefix": "uploads/"},
        {"bucket": "results"}
      ]
    }
  ]
}
```

### Monitoring and Alerting

Setup Prometheus monitoring:

```yaml
# docker-compose.production.yml
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
```

```yaml
# config/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'seaweedfs-master'
    static_configs:
      - targets: 
        - 'seaweedfs-master1:19333'
        - 'seaweedfs-master2:19334'
        - 'seaweedfs-master3:19335'

  - job_name: 'seaweedfs-volume'
    static_configs:
      - targets:
        - 'seaweedfs-volume1:18080'
        - 'seaweedfs-volume2:18081'

  - job_name: 'seaweedfs-filer'
    static_configs:
      - targets: ['seaweedfs-filer:18888']
```

### Maintenance Mode

```bash
# Put cluster in maintenance mode (stop accepting writes)
docker exec seaweedfs-master1 weed shell <<EOF
lock
EOF

# Perform maintenance
# ...

# Resume operations
docker exec seaweedfs-master1 weed shell <<EOF
unlock
EOF
```

## Troubleshooting Guide

### Issue: High Memory Usage

```bash
# Check memory usage
docker stats

# Reduce volume server cache
# In docker-compose.production.yml:
command: 'volume ... -memprofile=/tmp/mem.prof'

# Analyze memory profile
docker exec seaweedfs-volume1 go tool pprof /tmp/mem.prof
```

### Issue: Slow Performance

```bash
# Check disk I/O
iostat -x 1

# Check SeaweedFS metrics
curl http://localhost:19333/metrics | grep seaweedfs_

# Enable profiling
curl http://localhost:9333/debug/pprof/profile?seconds=30 > cpu.prof
go tool pprof cpu.prof
```

### Issue: Data Inconsistency

```bash
# Verify and fix volumes
docker exec seaweedfs-master1 weed shell <<EOF
volume.fsck -v -volumeId=all
volume.fix.replication
EOF
```

## Best Practices

1. **Always use 3 masters** for production (Raft requires odd number)
2. **Set replication ≥ 010** for data durability
3. **Regular backups** (automated daily backups to offsite storage)
4. **Monitor disk space** (SeaweedFS needs space for compaction)
5. **Use separate disks** for masters and volumes if possible
6. **Enable authentication** in production
7. **Set resource limits** to prevent resource exhaustion
8. **Regular health checks** (use automated monitoring)
9. **Test disaster recovery** procedures regularly
10. **Keep SeaweedFS updated** (check releases quarterly)

## References

- **SeaweedFS Documentation**: https://github.com/seaweedfs/seaweedfs/wiki
- **S3 API Compatibility**: https://github.com/seaweedfs/seaweedfs/wiki/Amazon-S3-API
- **Performance Tuning**: https://github.com/seaweedfs/seaweedfs/wiki/Performance-Tuning
- **Architecture**: https://github.com/seaweedfs/seaweedfs/wiki/Architecture

## Conclusion

SeaweedFS provides a simpler, more license-friendly alternative to Ceph RGW while maintaining S3 compatibility and providing excellent performance for the Pra Analysis use case. The migration is straightforward due to the S3-compatible API, and the operational benefits (faster startup, lower resource usage, simpler architecture) make it an ideal choice for this application.

