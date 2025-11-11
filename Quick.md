# Quick Start Guide - Pra Analysis

## 📋 สารบัญ

1. [เริ่มต้นใช้งาน](#เริ่มต้นใช้งาน)
2. [รัน Docker Containers](#รัน-docker-containers)
3. [รัน Tests](#รัน-tests)
4. [Services & URLs](#services--urls)
5. [Troubleshooting](#troubleshooting)
6. [คำสั่งที่ใช้บ่อย](#คำสั่งที่ใช้บ่อย)

---

## 🚀 เริ่มต้นใช้งาน

### ความต้องการของระบบ

- **Docker Desktop** (สำหรับรัน containers)
- **Python 3.11 หรือ 3.12** (สำหรับพัฒนา/ทดสอบ - **ห้ามใช้ 3.13!**)
- **Node.js 18+** และ **npm/pnpm** (สำหรับ frontend)
- **PowerShell** (Windows)

### ⚠️ หมายเหตุสำคัญ: Python Version

**ใช้ Python 3.11 หรือ 3.12 เท่านั้น!**
- ❌ **Python 3.13 มีปัญหา compatibility กับ SQLAlchemy**
- ✅ แนะนำ: Python 3.11.9 หรือ 3.12.x

### การตั้งค่า Environment

```powershell
# คัดลอกไฟล์ environment
Copy-Item .env.example .env

# แก้ไขค่าตามต้องการ (optional)
notepad .env
```

---

## 🐳 รัน Docker Containers

### CPU Mode (Development - ไม่ต้องใช้ GPU)

```powershell
.\make.ps1 up-cpu
```

### GPU Mode (Production - ต้องการ NVIDIA GPU)

```powershell
.\make.ps1 up-gpu
```

### หยุด Containers

```powershell
.\make.ps1 down
```

### ตรวจสอบสถานะ

```powershell
# ดู running containers
docker ps

# ดู logs
.\make.ps1 logs

# ดู logs ของ API เฉพาะ
docker logs pra-analysis-api-1

# ดู logs ของ Web เฉพาะ
docker logs pra-analysis-web-1
```

---

## 🧪 รัน Tests

### Quick Start

```powershell
# ไปที่โฟลเดอร์ backend
cd apps\amulet-ai-service

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# รัน tests
pytest tests/ -v --no-cov
```

### ติดตั้ง Dependencies (ถ้ายังไม่ได้ติดตั้ง)

```powershell
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1

# Upgrade pip
python -m pip install --upgrade pip

# ติดตั้ง packages
pip install fastapi uvicorn pydantic sqlalchemy pytest httpx minio structlog qdrant-client pillow python-multipart pytest-asyncio pytest-cov
```

หรือใช้ script:

```powershell
.\INSTALL_ONE_BY_ONE.ps1
```

### รัน Tests แบบต่างๆ

```powershell
# รัน tests ทั้งหมด
pytest tests/ -v --no-cov

# รัน tests พร้อม coverage
pytest tests/ -v

# รัน test เฉพาะไฟล์
pytest tests/test_api_analyze.py -v

# รัน test เฉพาะ function
pytest tests/test_api_analyze.py::TestAnalyzeEndpoint::test_analyze_valid_jpeg -v
```

### สถิติ Tests

- **Automated Tests:** 230+ test cases
- **Backend Coverage:** 87% ✅
- **Frontend Coverage:** 75% ✅
- **Manual Test Cases:** 200+ cases

📚 **ดูเพิ่มเติม:** `README_TESTING.md`, `START_HERE_คำสั่งสุดท้าย.md`

---

## 🎯 Services & URLs

### Docker Containers (CPU Mode)

เมื่อรัน `.\make.ps1 up-cpu` จะมี **11 containers** ทั้งหมด:

| Service | Port | URL | Container Name |
|---------|------|-----|----------------|
| **Next.js Frontend** | 3000 | http://localhost:3000 | pra-analysis-web-1 |
| **FastAPI Backend** | 8000 | http://localhost:8000 | pra-analysis-api-1 |
| **API Documentation** | 8000 | http://localhost:8000/docs | pra-analysis-api-1 |
| **API Health Check** | 8000 | http://localhost:8000/health | pra-analysis-api-1 |
| **SeaweedFS S3 Gateway** | 8333 | http://localhost:8333 | seaweedfs-s3 |
| **SeaweedFS Filer** | 8888 | http://localhost:8888 | seaweedfs-filer |
| **SeaweedFS Master 1** | 9333 | http://localhost:9333/cluster/status | seaweedfs-master1 |
| **SeaweedFS Master 2** | 9334 | http://localhost:9334/cluster/status | seaweedfs-master2 |
| **SeaweedFS Master 3** | 9335 | http://localhost:9335/cluster/status | seaweedfs-master3 |
| **SeaweedFS Volume 1** | 8080 | http://localhost:8080/status | seaweedfs-volume1 |
| **SeaweedFS Volume 2** | 8081 | http://localhost:8081/status | seaweedfs-volume2 |
| **Qdrant Dashboard** | 6333 | http://localhost:6333/dashboard | pra-analysis-qdrant-1 |
| **PostgreSQL** | 5432 | localhost:5432 | pra-analysis-postgres-1 |

### Docker Containers (GPU Mode)

เมื่อรัน `.\make.ps1 up-gpu` จะมี **12 containers** ทั้งหมด (เพิ่ม Triton Inference Server):

- ทั้งหมดจาก CPU Mode
- **Triton Inference Server** (port 8001) - container: triton

### Credentials

**SeaweedFS (S3 Storage):**
- Access Key: `seaweedfs_admin` (default)
- Secret Key: `seaweedfs_secret` (default)
- S3 Endpoint: http://localhost:8333

**PostgreSQL:**
- Database: `amulet_db`
- User: `postgres`
- Password: `postgres`

### ตรวจสอบการทำงาน

```powershell
# Test API health
curl http://localhost:8000/health
# ควรได้: {"ok":true}

# เปิด API documentation
start http://localhost:8000/docs

# เปิด Frontend
start http://localhost:3000
```

---

## 🔧 คำสั่งที่ใช้บ่อย

### Docker Commands

```powershell
# เริ่ม services (CPU mode)
.\make.ps1 up-cpu

# เริ่ม services (GPU mode)
.\make.ps1 up-gpu

# หยุด services
.\make.ps1 down

# ดู logs (real-time)
.\make.ps1 logs

# ดู logs ของ service เดียว
docker logs pra-analysis-api-1 -f
```

### Development Commands

```powershell
# รัน API locally (นอก Docker)
.\make.ps1 api

# รัน Web locally (นอก Docker)
.\make.ps1 web

# Format code (Black, Ruff, Prettier)
.\make.ps1 fmt

# Clean build artifacts
.\make.ps1 clean
```

### Database Commands

```powershell
# Initialize Qdrant vector database
.\make.ps1 qdrant-init

# Embed and index sample data
.\make.ps1 embed-index
```

### SeaweedFS Commands

```powershell
# Check system health
.\make.ps1 health

# Backup data (Linux/Ubuntu only)
# sudo bash scripts/backup-seaweedfs.sh

# Restore from backup (Linux/Ubuntu only)
# sudo bash scripts/restore-seaweedfs.sh <timestamp>
```

### Utility Commands

```powershell
# Show all available commands
.\make.ps1 help

# Check Docker container status
docker ps

# View all containers (including stopped)
docker ps -a

# Restart a specific container
docker restart pra-analysis-api-1
```

---

## 🎓 โครงสร้างโปรเจค

```
pra-analysis/
├── apps/
│   ├── amulet-ai-service/      # FastAPI backend (Python 3.11+)
│   │   ├── main.py             # API entry point
│   │   ├── routes/             # API route handlers
│   │   ├── services/           # Business logic layer
│   │   ├── models/             # Database models (SQLAlchemy)
│   │   ├── schemas/            # Pydantic schemas
│   │   └── tests/              # Test suite (230+ tests)
│   └── web-next/               # Next.js 14 frontend
│       ├── app/                # App Router pages
│       ├── components/         # React components
│       └── lib/                # Utilities and API client
├── ml/                         # ML models and inference
│   ├── inference/              # Triton model repository
│   └── xai/                    # Explainable AI utilities
├── scripts/                    # Utility scripts
│   ├── qdrant_init.py         # Initialize Qdrant
│   └── embed_and_index.py     # Embed and index data
├── shared/                     # Shared schemas and types
│   └── schemas/sql.sql        # Database schema
├── docker-compose.cpu.yml     # Docker config (CPU mode)
├── docker-compose.gpu.yml     # Docker config (GPU mode)
├── docker-compose.test.yml    # Docker config (Testing)
└── make.ps1                   # PowerShell automation script
```

---

## 📚 เอกสารอ้างอิง

### สำหรับผู้เริ่มต้น
- **README.md** - Overview และ quick start
- **Quick.md** (ไฟล์นี้) - คู่มือเริ่มต้นฉบับย่อ
- **START_HERE_คำสั่งสุดท้าย.md** - คำสั่งติดตั้ง dependencies

### สำหรับการทดสอบ
- **README_TESTING.md** - Testing guide ฉบับสมบูรณ์
- **apps/amulet-ai-service/tests/README.md** - Test suite documentation
- **apps/amulet-ai-service/RUN_TESTS.md** - วิธีรัน tests

### สำหรับการพัฒนา
- **docs/MANUAL_TESTING_CHECKLIST.md** - 200+ manual test cases
- **docs/PERFORMANCE_TESTING.md** - Performance testing guide
- **docs/PRODUCTION_READINESS_CHECKLIST.md** - Production checklist

---

## ⚠️ สิ่งที่ต้องรู้

### Python Version ⚠️

**สำคัญมาก:**
- ✅ ใช้ **Python 3.11** หรือ **3.12**
- ❌ **อย่าใช้ Python 3.13** - SQLAlchemy มีปัญหา compatibility

ถ้าใช้ Python 3.13 อยู่แล้ว:
```powershell
# ติดตั้ง Python 3.11 จาก python.org
# จากนั้นสร้าง venv ใหม่
cd apps\amulet-ai-service
Remove-Item venv -Recurse -Force
py -3.11 -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Import Paths (สำหรับนักพัฒนา)

ระบบใช้ **Absolute Imports** สำหรับ Python:

```python
# ✅ ถูกต้อง - Absolute imports
from apps.amulet_ai_service.services.database import get_db
from apps.amulet_ai_service.models.database_models import Image

# ❌ ผิด - Relative imports
from services.database import get_db
from models.database_models import Image
```

**เหตุผล:** Docker container ตั้งค่า `PYTHONPATH=/app` และเรียก modules แบบ absolute path

### Storage Service

โปรเจคใช้ **SeaweedFS** ซึ่งเป็น distributed object storage พร้อม S3-compatible API:
- **S3 API:** http://localhost:8333 (เหมือน AWS S3 ทุกประการ)
- **Filer API:** http://localhost:8888 (file system interface)
- **Master Cluster:** http://localhost:9333 (HA cluster status)
- **License:** Apache 2.0 (business-friendly, เหมาะสำหรับ production)
- **High Availability:** 3-master cluster with Raft consensus
- **Credentials:** `seaweedfs_admin` / `seaweedfs_secret` (default)

### CPU vs GPU Mode

**CPU Mode** (Development):
- ใช้ mock Triton responses
- ไม่ต้องการ GPU
- เหมาะสำหรับการพัฒนา
- รันเร็วกว่า

**GPU Mode** (Production):
- ใช้ NVIDIA Triton จริง
- ต้องการ NVIDIA GPU + Docker GPU support
- ใช้ ONNX/TensorRT models
- เหมาะสำหรับ production

---

## 🔧 Troubleshooting

### ตรวจสอบสถานะ Containers

**ตรวจสอบว่ามี 11 containers (CPU mode) หรือ 12 containers (GPU mode):**

```powershell
# ดู containers ทั้งหมด
docker ps

# หรือใช้ health check
.\make.ps1 health
```

**ต้องเห็น containers เหล่านี้:**
- ✅ pra-analysis-web-1 (Up)
- ✅ pra-analysis-api-1 (Up)
- ✅ pra-analysis-postgres-1 (Up)
- ✅ pra-analysis-qdrant-1 (Up)
- ✅ seaweedfs-master1, seaweedfs-master2, seaweedfs-master3 (Up, healthy)
- ✅ seaweedfs-volume1, seaweedfs-volume2 (Up, healthy)
- ✅ seaweedfs-filer (Up, healthy)
- ✅ seaweedfs-s3 (Up, healthy) - **ใช้เวลา 30-45 วินาทีในการ start cluster**
- ✅ triton (Up) - สำหรับ GPU mode เท่านั้น

### ปัญหา: GPU Mode ไม่ทำงาน (WSL/Windows)

**Error:** `nvidia-container-cli: initialization error: WSL environment detected but no adapters were found`

**สาเหตุ:** ระบบไม่มี NVIDIA GPU หรือยังไม่ได้ติดตั้ง NVIDIA Container Toolkit

**วิธีแก้:**

```powershell
# Option 1: ใช้ CPU Mode แทน (แนะนำสำหรับ Development)
.\make.ps1 down
.\make.ps1 up-cpu
```

```powershell
# Option 2: ตรวจสอบและติดตั้ง GPU drivers (สำหรับ Production)
# 1. ตรวจสอบ GPU
nvidia-smi

# 2. ติดตั้ง NVIDIA Container Toolkit (ถ้ายังไม่มี)
# ดูคู่มือที่: https://docs.nvidia.com/datacenter/cloud-native/
```

### ปัญหา: seaweedfs-s3 Container หยุดทำงาน

**Error:** `flag provided but not defined: -ip`

**สาเหตุ:** SeaweedFS S3 ใช้ flag ไม่ถูกต้อง (ควรใช้ `-ip.bind` แทน `-ip`)

**วิธีแก้:** (แก้ไขแล้วใน version ล่าสุด)

ตรวจสอบว่า `docker-compose.cpu.yml` มีค่าถูกต้อง:

```yaml
seaweedfs-s3:
  command: 's3 -filer=seaweedfs-filer:8888 -ip.bind=0.0.0.0 -port=8333 -config=/etc/seaweedfs/s3.json'
```

ถ้ายังมีปัญหา:
```powershell
# Rebuild และ restart
.\make.ps1 down
docker-compose -f docker-compose.cpu.yml build
.\make.ps1 up-cpu
```

### ปัญหา: API Container หยุดทำงาน (EndpointConnectionError)

**Error:** `Could not connect to the endpoint URL: "http://seaweedfs-s3:8333/images"`

**สาเหตุ:** API เริ่มต้นเร็วกว่า SeaweedFS S3 จะพร้อมใช้งาน

**วิธีแก้:** (แก้ไขแล้วใน version ล่าสุด - API จะ log warning แทน crash)

```powershell
# Option 1: รอให้ SeaweedFS พร้อม แล้ว restart API
Start-Sleep -Seconds 30
docker restart pra-analysis-api-1

# Option 2: Rebuild API image ด้วยโค้ดล่าสุด
.\make.ps1 down
docker-compose -f docker-compose.cpu.yml build api
.\make.ps1 up-cpu
```

**หมายเหตุ:** Version ล่าสุดแก้ไขแล้วให้ API สามารถเริ่มต้นได้แม้ S3 ยังไม่พร้อม

### ปัญหา: Container บางตัวไม่ Start

**อาการ:** หลังรัน `.\make.ps1 up-cpu` มี container ที่ `Exited (1)` หรือไม่ start

**วิธีแก้:**

1. ดู logs ของ container ที่มีปัญหา:
   ```powershell
   docker logs pra-analysis-api-1 --tail 50
   docker logs seaweedfs-master1 --tail 50
   docker logs seaweedfs-s3 --tail 50
   ```

2. ถ้า SeaweedFS cluster ไม่ start:
   ```powershell
   # ลบ volumes เก่า
   .\make.ps1 down
   docker volume prune -f
   .\make.ps1 up-cpu
   # รอ 30-45 วินาทีสำหรับ SeaweedFS cluster initialization
   ```

3. ถ้า API ไม่ start (ไม่สามารถเชื่อมต่อ SeaweedFS):
   ```powershell
   # ตรวจสอบว่า SeaweedFS cluster start แล้ว
   .\make.ps1 health
   # หรือ
   docker ps | findstr seaweedfs
   
   # ถ้า SeaweedFS ยังไม่ ready ให้รอ 30-45 วินาที แล้ว restart API
   docker restart pra-analysis-api-1
   ```

4. Rebuild ทุก containers:
   ```powershell
   .\make.ps1 down
   docker system prune -f
   .\make.ps1 up-cpu
   ```

### ปัญหา: Port ถูกใช้งานแล้ว

**Error:** `Bind for 0.0.0.0:8000 failed: port is already allocated`

**วิธีแก้:**

```powershell
# หา process ที่ใช้ port 8000
netstat -ano | findstr :8000

# หยุด process (แทน <PID> ด้วยเลขที่ได้)
taskkill /PID <PID> /F

# หรือหยุด container เก่าทั้งหมด
.\make.ps1 down
```

### ปัญหา: Tests ไม่ทำงาน - ModuleNotFoundError

**Error:** `ModuleNotFoundError: No module named 'fastapi'`

**วิธีแก้:**

```powershell
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1

# ติดตั้ง dependencies
pip install -r requirements.txt

# หรือใช้ script
.\INSTALL_ONE_BY_ONE.ps1
```

### ปัญหา: Python 3.13 Compatibility

**Error:** `TypeError: Can't replace canonical symbol`

**วิธีแก้:**

```powershell
# Option 1: ติดตั้ง SQLAlchemy เวอร์ชันล่าสุด (pre-release)
pip install --pre sqlalchemy

# Option 2: ใช้ Python 3.11 แทน (แนะนำ)
# ดาวน์โหลด Python 3.11 จาก python.org
cd apps\amulet-ai-service
Remove-Item venv -Recurse -Force
py -3.11 -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### ปัญหา: Docker Desktop ไม่ทำงาน

**อาการ:** คำสั่ง docker ไม่ทำงาน

**วิธีแก้:**

1. เปิด Docker Desktop
2. รอจนกว่า Docker engine จะเริ่มต้นเสร็จ (icon สีเขียว)
3. ตรวจสอบ: `docker ps`
4. รันคำสั่งใหม่อีกครั้ง

### ปัญหา: Database Connection Failed

**Error:** `could not connect to server: Connection refused`

**วิธีแก้:**

```powershell
# ตรวจสอบว่า PostgreSQL container ทำงานอยู่
docker ps | findstr postgres

# ถ้าไม่ทำงาน - restart
docker restart pra-analysis-postgres-1

# หรือ restart ทั้งหมด
.\make.ps1 down
.\make.ps1 up-cpu
```

### ปัญหา: Qdrant Connection Failed

**วิธีแก้:**

```powershell
# ตรวจสอบ Qdrant container
docker ps | findstr qdrant

# Initialize Qdrant collection
.\make.ps1 qdrant-init

# Test connection
curl http://localhost:6333/collections
```

### ปัญหา: Frontend ไม่แสดงผล

**วิธีแก้:**

```powershell
# ตรวจสอบ environment variable
# แก้ไข .env ให้ NEXT_PUBLIC_API_BASE ถูกต้อง
notepad .env

# Rebuild frontend
cd apps\web-next
Remove-Item .next -Recurse -Force
cd ..\..
.\make.ps1 down
.\make.ps1 up-cpu
```

---

## 💡 Tips & Best Practices

### สำหรับนักพัฒนา

1. **ใช้ CPU Mode** สำหรับการพัฒนา - รันเร็วกว่า
2. **Activate venv เสมอ** ก่อนรัน tests หรือ scripts
3. **ตรวจสอบ logs** เมื่อมีปัญหา - `.\make.ps1 logs`
4. **Clean artifacts** เป็นประจำ - `.\make.ps1 clean`

### สำหรับการทดสอบ

1. **รัน tests ก่อน commit** - ตรวจสอบว่าไม่ทำลายอะไร
2. **ใช้ `--no-cov`** เพื่อรัน tests เร็วขึ้น
3. **ใช้ SQLite** สำหรับ unit tests - ไม่ต้องการ PostgreSQL
4. **ตรวจสอบ coverage** เป็นประจำ - target 80%+

### สำหรับ Production

1. **ใช้ GPU Mode** สำหรับ production deployment
2. **ตั้งค่า environment variables** ให้ถูกต้อง
3. **ใช้ strong passwords** สำหรับ database และ storage
4. **Monitor logs** และตั้ง alerts สำหรับ errors

---

## 🎯 Quick Reference

### One-Liners

```powershell
# รัน Docker + Tests แบบ one-shot
.\make.ps1 up-cpu; Start-Sleep 10; cd apps\amulet-ai-service; .\venv\Scripts\Activate.ps1; pytest tests/ -v --no-cov

# Clean everything และเริ่มใหม่
.\make.ps1 down; .\make.ps1 clean; docker system prune -f; .\make.ps1 up-cpu

# ติดตั้ง dependencies แบบครบ
cd apps\amulet-ai-service; .\venv\Scripts\Activate.ps1; pip install --upgrade pip; pip install -r requirements.txt
```

### สถิติโปรเจค

- **Total Files:** 1,000+ files
- **Backend Tests:** 230+ automated tests
- **Test Coverage:** 87% (backend), 75% (frontend)
- **API Endpoints:** 50+ endpoints
- **Docker Services:** 11 services (api, web, db, qdrant, seaweedfs cluster)
- **SeaweedFS:** 3 masters + 2 volumes + filer + s3 gateway (HA cluster)
- **Documentation Files:** 18+ guides

---

## 📞 ช่วยเหลือเพิ่มเติม

### เอกสารสำคัญ
- **README.md** - Project overview
- **README_TESTING.md** - Complete testing guide
- **START_HERE_คำสั่งสุดท้าย.md** - Setup instructions
- **DEPLOYMENT_UBUNTU.md** - Ubuntu production deployment guide
- **SEAWEEDFS_MIGRATION.md** - SeaweedFS operations and migration guide

### API Documentation
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

### Community & Support
- Check `docs/KNOWN_ISSUES.md` for known problems
- Review `docs/PRODUCTION_READINESS_CHECKLIST.md` before deployment

---

## 🆕 สิ่งที่เพิ่มใหม่

### SeaweedFS Migration (พฤศจิกายน 2025)

โปรเจคได้เปลี่ยนจาก **Ceph RGW** มาใช้ **SeaweedFS** แล้ว:

✅ **ข้อดี:**
- License ที่ดีกว่า: Apache 2.0 (แทน LGPL)
- Start เร็วขึ้น: 30s (แทน 60-90s)
- ใช้ memory น้อยกว่า: ~500MB (แทน ~2GB)
- High Availability: 3-master cluster with Raft
- เหมาะกับ production และ commercial use

✅ **ไม่มีผลต่อ:**
- Application code (ยังใช้ boto3 S3 API เหมือนเดิม)
- API endpoints (เหมือนเดิมทั้งหมด)
- Database schema (ไม่มีการเปลี่ยนแปลง)

📚 **เอกสารเพิ่มเติม:**
- `DEPLOYMENT_UBUNTU.md` - วิธี deploy บน Ubuntu
- `SEAWEEDFS_MIGRATION.md` - รายละเอียด SeaweedFS

### Bug Fixes (11 พฤศจิกายน 2025)

✅ **แก้ไขแล้ว:**
1. **SeaweedFS S3 Flag Error**
   - ปัญหา: `flag provided but not defined: -ip`
   - แก้ไข: เปลี่ยนจาก `-ip=seaweedfs-s3` เป็น `-ip.bind=0.0.0.0` ใน `docker-compose.cpu.yml`

2. **API Startup Crash เมื่อ S3 ไม่พร้อม**
   - ปัญหา: API crash ด้วย `EndpointConnectionError` เมื่อ SeaweedFS ยังไม่พร้อม
   - แก้ไข: เปลี่ยนให้ API log warning และดำเนินการต่อแทนการ crash ใน `storage_client.py`

3. **GPU Mode Error บน WSL**
   - ปัญหา: `nvidia-container-cli: WSL environment detected but no adapters were found`
   - วิธีแก้: ใช้ CPU Mode สำหรับ development (แนะนำ)

---

**อัปเดตล่าสุด:** 11 พฤศจิกายน 2025 (v1.1.0)  
**สถานะ:** ✅ ทำงานสมบูรณ์ | 230+ Tests | 87% Coverage  
**Storage:** SeaweedFS (Apache 2.0) with HA cluster  
**Python Version:** 3.11 หรือ 3.12 (ห้าม 3.13!)  
**Docker Mode:** CPU (development) / GPU (production)  
**Bugs Fixed:** SeaweedFS S3, API startup resilience, GPU mode

