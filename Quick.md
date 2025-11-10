# Quick Fix Guide - Docker API-1 Container Issue

## ปัญหาที่พบ

เมื่อรันคำสั่ง `.\make.ps1 up-cpu` container `pra-analysis-api-1` ไม่สามารถเริ่มต้นได้ มีสถานะ `Exited (1)`

## สาเหตุ

**Import Path ไม่ถูกต้อง** - ไฟล์ Python ใช้ relative imports แต่ Docker container ตั้งค่า `PYTHONPATH=/app` และเรียก module แบบ absolute path

### Error ที่พบ:
```
ModuleNotFoundError: No module named 'services'
ModuleNotFoundError: No module named 'models'
ModuleNotFoundError: No module named 'schemas'
```

## วิธีแก้ไข

แก้ไข import statements ในไฟล์ Python ทั้งหมดจาก relative เป็น absolute imports

### ไฟล์ที่แก้ไข (10 ไฟล์):

1. `apps/amulet-ai-service/main.py`
2. `apps/amulet-ai-service/models/database_models.py`
3. `apps/amulet-ai-service/routes/admin.py`
4. `apps/amulet-ai-service/routes/feedback.py`
5. `apps/amulet-ai-service/routes/import.py`
6. `apps/amulet-ai-service/routes/import_route.py`
7. `apps/amulet-ai-service/routes/labeling.py`
8. `apps/amulet-ai-service/routes/models.py`
9. `apps/amulet-ai-service/routes/training.py`
10. `apps/amulet-ai-service/routes/retraining.py`

### การเปลี่ยนแปลง:

**เดิม (Relative Import):**
```python
from services.database import get_db, init_db
from services.minio_client import minio_client
from models.database_models import Image, Prediction
from schemas.admin_schemas import DatasetCreate
from routes import admin, import_route
```

**ใหม่ (Absolute Import):**
```python
from apps.amulet_ai_service.services.database import get_db, init_db
from apps.amulet_ai_service.services.minio_client import minio_client
from apps.amulet_ai_service.models.database_models import Image, Prediction
from apps.amulet_ai_service.schemas.admin_schemas import DatasetCreate
from apps.amulet_ai_service.routes import admin, import_route
```

## ผลลัพธ์

✅ **Container รันสำเร็จ**

```bash
CONTAINER ID   IMAGE                  STATUS         PORTS
4edb4482693b   pra-analysis-api       Up 17 seconds  0.0.0.0:8000->8000/tcp
0aa9172bb21e   pra-analysis-web       Up 17 seconds  0.0.0.0:3000->3000/tcp
ea6bcad282b5   postgres:15-alpine     Up 2 minutes   0.0.0.0:5432->5432/tcp
2dbbaef386c5   qdrant/qdrant:latest   Up 2 minutes   0.0.0.0:6333->6333/tcp
a5fe4b02d8d9   minio/minio:latest     Up 2 minutes   0.0.0.0:9000-9001->9000-9001/tcp
```

✅ **API ทำงานปกติ**

- Health Check: http://localhost:8000/health → `{"ok":true}`
- API Root: http://localhost:8000/ → ข้อมูล API endpoints
- API Docs: http://localhost:8000/docs

## คำสั่งที่ใช้

### เริ่ม Docker Containers

**CPU Mode (Mock Triton):**
```powershell
.\make.ps1 up-cpu
```

**GPU Mode (With Triton):**
```powershell
.\make.ps1 up-gpu
```

### หยุด Docker Containers

```powershell
.\make.ps1 down
```

### ตรวจสอบสถานะ

```powershell
# ดู running containers
docker ps

# ดู all containers (รวมที่หยุดแล้ว)
docker ps -a

# ดู logs ของ API
docker logs pra-analysis-api-1

# ดู logs ทั้งหมด (real-time)
.\make.ps1 logs
```

### ทดสอบ API

```powershell
# Health check
curl http://localhost:8000/health

# API info
curl http://localhost:8000/

# API documentation (เปิดใน browser)
start http://localhost:8000/docs
```

## Services ที่รันอยู่

| Service | Port | URL |
|---------|------|-----|
| Next.js Frontend | 3000 | http://localhost:3000 |
| FastAPI Backend | 8000 | http://localhost:8000 |
| API Documentation | 8000 | http://localhost:8000/docs |
| MinIO Console | 9001 | http://localhost:9001 |
| Qdrant Dashboard | 6333 | http://localhost:6333/dashboard |
| PostgreSQL | 5432 | localhost:5432 |

**MinIO Credentials:** minioadmin / minioadmin

## หมายเหตุ

- **CPU Mode**: ใช้ mock Triton responses สำหรับการพัฒนาโดยไม่ต้องใช้ GPU
- **GPU Mode**: ต้องการ NVIDIA GPU และ Docker GPU support
- **Environment Variables**: กำหนดค่าใน `.env` (สร้างจาก `.env.example`)

## คำสั่งเพิ่มเติม

```powershell
# Initialize Qdrant vector database
.\make.ps1 qdrant-init

# Embed and index sample data
.\make.ps1 embed-index

# Run API locally (นอก Docker)
.\make.ps1 api

# Run web locally (นอก Docker)
.\make.ps1 web

# Format code
.\make.ps1 fmt

# Clean build artifacts
.\make.ps1 clean

# Show help
.\make.ps1 help
```

## Troubleshooting

### ถ้า API ยังไม่ทำงาน

1. ตรวจสอบ logs:
   ```powershell
   docker logs pra-analysis-api-1
   ```

2. ตรวจสอบว่า dependencies ครบ:
   ```powershell
   docker exec -it pra-analysis-api-1 pip list
   ```

3. Rebuild containers:
   ```powershell
   .\make.ps1 down
   .\make.ps1 up-cpu
   ```

### ถ้า Port ถูกใช้งานแล้ว

```powershell
# หา process ที่ใช้ port 8000
netstat -ano | findstr :8000

# หยุด process (แทน PID ด้วยเลขที่ได้จากคำสั่งด้านบน)
taskkill /PID <PID> /F
```

### ถ้า Docker Desktop ไม่ทำงาน

1. เปิด Docker Desktop
2. รอจนกว่า Docker engine จะ start
3. รันคำสั่งใหม่อีกครั้ง

---

**วันที่แก้ไข:** 10 พฤศจิกายน 2025  
**สถานะ:** ✅ ทำงานสมบูรณ์

