# Migration from MinIO to Ceph RGW - Complete Guide

## Overview

โปรเจค Pra Analysis ได้ทำการ migrate จาก **MinIO (AGPL-3.0 license)** ไปใช้ **Ceph RADOS Gateway (LGPL-2.1/LGPL-3.0 license)** เพื่อความเหมาะสมด้าน licensing สำหรับการใช้งาน production

## Why Ceph RGW?

### License Comparison

| Feature | MinIO | Ceph RGW |
|---------|-------|----------|
| **License** | AGPL-3.0 | LGPL-2.1/LGPL-3.0 |
| **Commercial Use** | ⚠️ ต้องเปิดเผย source code | ✅ ไม่ต้องเปิดเผย |
| **Network Service** | ⚠️ Requires source disclosure | ✅ No disclosure required |
| **Production Ready** | ✅ Yes | ✅ Yes |
| **S3 Compatible** | ✅ Full | ✅ Full |
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Enterprise Support** | 💰 Paid | ✅ Available |

### Key Benefits

1. **License Freedom**: LGPL allows commercial use without source disclosure
2. **Enterprise Grade**: Ceph is battle-tested in large-scale deployments
3. **S3 Compatibility**: 100% compatible with AWS S3 API via boto3
4. **Scalability**: Built for distributed storage from the ground up
5. **Community**: Large open-source community and support

## What Changed?

### 1. Docker Compose Files

**Before (MinIO):**
```yaml
minio:
  image: minio/minio:latest
  command: server /data --console-address ":9001"
  environment:
    - MINIO_ROOT_USER=minioadmin
    - MINIO_ROOT_PASSWORD=minioadmin
  ports:
    - "9000:9000"
    - "9001:9001"
```

**After (Ceph RGW):**
```yaml
ceph-rgw:
  image: ceph/daemon:latest
  environment:
    - CEPH_DAEMON=demo
    - DEMO_DAEMONS=osd,mds,mon,rgw
    - NETWORK_AUTO_DETECT=4
    - RGW_NAME=ceph-rgw
    - CIVETWEB_PORT=9000
  ports:
    - "9000:9000"
```

### 2. Storage Client

**File**: `apps/amulet-ai-service/services/storage_client.py`

**Before (minio library):**
```python
from minio import Minio
client = Minio(endpoint, access_key, secret_key, secure)
```

**After (boto3 library):**
```python
import boto3
client = boto3.client('s3',
    endpoint_url=f"http://{endpoint}",
    aws_access_key_id=access_key,
    aws_secret_access_key=secret_key
)
```

### 3. Environment Variables

**Before:**
```bash
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
```

**After:**
```bash
S3_ENDPOINT=ceph-rgw:9000
S3_ACCESS_KEY=ceph_access_key
S3_SECRET_KEY=ceph_secret_key
S3_REGION=us-east-1
```

### 4. Dependencies

**requirements.txt:**
- ❌ Removed: `minio==7.2.0`
- ✅ Added: `boto3>=1.34.0`

## Files Modified

### Docker Infrastructure
- ✅ `docker-compose.cpu.yml` - CPU mode with Ceph RGW
- ✅ `docker-compose.gpu.yml` - GPU mode with Ceph RGW
- ✅ `docker-compose.test.yml` - Test mode with Ceph RGW

### Backend Code
- ✅ `apps/amulet-ai-service/services/storage_client.py` - New boto3-based client
- ✅ `apps/amulet-ai-service/requirements.txt` - Updated dependencies
- ✅ `apps/amulet-ai-service/tests/conftest.py` - Updated test configuration

### Documentation
- ✅ `README.md` - Updated service descriptions
- ✅ `Quick.md` - Updated quick start guide
- ✅ `ARCHITECTURE.md` - Updated architecture diagrams
- ✅ `DEVELOPMENT_GUIDE.md` - Updated code examples

## How to Use

### Starting Services

```powershell
# CPU Mode (Development)
.\make.ps1 up-cpu

# GPU Mode (Production)
.\make.ps1 up-gpu
```

### Important Notes

⚠️ **Ceph RGW takes 30-60 seconds to initialize** on first start:
- Monitor startup: `docker logs ceph-rgw -f`
- Wait for message: `RGW is ready`
- Then start/restart API: `docker restart pra-analysis-api-1`

### Verifying Containers

```powershell
docker ps
```

Expected containers:
- ✅ pra-analysis-web-1
- ✅ pra-analysis-api-1
- ✅ pra-analysis-postgres-1
- ✅ pra-analysis-qdrant-1
- ✅ **ceph-rgw** (new!)

### Testing S3 Connectivity

```powershell
# Install AWS CLI
pip install awscli

# Configure
aws configure set aws_access_key_id ceph_access_key
aws configure set aws_secret_access_key ceph_secret_key

# Test connection
aws --endpoint-url http://localhost:9000 s3 ls
```

## API Compatibility

The storage client API remains **100% backward compatible**:

```python
from apps.amulet_ai_service.services.storage_client import storage_client

# Upload image
storage_client.upload_image(
    bucket="images",
    object_name="test.jpg",
    data=image_bytes,
    content_type="image/jpeg"
)

# Download image
data = storage_client.download_file(
    bucket="images",
    object_name="test.jpg"
)

# Generate presigned URL
url = storage_client.get_presigned_url(
    bucket="images",
    object_name="test.jpg",
    expires_seconds=3600
)
```

## Troubleshooting

### Issue: Ceph RGW not starting

**Solution:**
```powershell
# Clean and restart
.\make.ps1 down
docker volume rm pra-analysis_ceph_data
.\make.ps1 up-cpu

# Wait 60-90 seconds for initialization
```

### Issue: API can't connect to Ceph RGW

**Solution:**
```powershell
# Check Ceph RGW status
docker logs ceph-rgw --tail 50

# Restart API after Ceph is ready
docker restart pra-analysis-api-1
```

### Issue: boto3 not found

**Solution:**
```powershell
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1
pip install boto3>=1.34.0
```

## Performance Considerations

### Ceph RGW Performance Tips

1. **Initialization Time**: First start takes 60-90 seconds
2. **Subsequent Starts**: ~10-20 seconds after volume is created
3. **Demo Mode**: Suitable for development, use clustered mode for production
4. **Network**: Ensure sufficient bandwidth (100Mbps+ recommended)

### When to Restart

After these events, you may need to restart Ceph RGW:
- System reboot
- Docker Desktop restart
- Volume corruption
- Network configuration changes

## Migration Checklist

- [x] Replace MinIO with Ceph RGW in Docker Compose files
- [x] Update storage_client.py to use boto3
- [x] Update environment variables (MINIO_* → S3_*)
- [x] Update requirements.txt
- [x] Update test configuration
- [x] Update all documentation
- [x] Test bucket creation
- [x] Test file upload/download
- [x] Test presigned URLs
- [x] Test deletion operations
- [x] Verify backward compatibility

## Testing

### Run Tests

```powershell
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1
pytest tests/ -v --no-cov
```

### Manual Testing

```powershell
# Start services
.\make.ps1 up-cpu

# Wait for Ceph RGW (60 seconds)
Start-Sleep 60

# Test API health
curl http://localhost:8000/health

# Test image upload (via API docs)
start http://localhost:8000/docs
```

## Production Deployment

For production use:

1. **Use Ceph Cluster**: Deploy multi-node Ceph cluster (not demo mode)
2. **Configure Credentials**: Use strong access keys
3. **Enable SSL/TLS**: Set `S3_SECURE=true`
4. **Monitor Health**: Use `ceph health` command
5. **Backup Strategy**: Configure Ceph replication and backup policies

## References

- **Ceph Documentation**: https://docs.ceph.com/
- **RADOS Gateway**: https://docs.ceph.com/en/latest/radosgw/
- **boto3 Documentation**: https://boto3.amazonaws.com/v1/documentation/api/latest/index.html
- **S3 API Compatibility**: https://docs.ceph.com/en/latest/radosgw/s3/

## Support

For issues or questions:
- Check `docker logs ceph-rgw` for Ceph-specific errors
- Review `README.md` for general troubleshooting
- See `Quick.md` for quick start guide

---

**Migration Date**: November 11, 2025  
**Status**: ✅ Complete and Tested  
**License**: Compliant with Apache-2.0, MIT, BSD-3  
**Backward Compatibility**: ✅ 100% maintained

