# วิธีรัน Tests - ขั้นตอนสำคัญ

## ✅ Pre-requisites

### 1. Python Version
- ✅ **แนะนำ:** Python 3.11 หรือ 3.12
- ⚠️ **หลีกเลี่ยง:** Python 3.13 (SQLAlchemy incompatible)

```powershell
# ตรวจสอบ version
python --version

# ถ้าเป็น Python 3.13 ให้ติดตั้ง Python 3.11
# https://www.python.org/downloads/release/python-3119/
```

### 2. Dependencies
```powershell
cd apps\amulet-ai-service

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# ตรวจสอบว่า packages สำคัญติดตั้งแล้ว
pip show fastapi sqlalchemy pytest

# ถ้ายังไม่ได้ติดตั้ง รัน
.\install_windows.ps1
```

### 3. Test Containers
```powershell
# จาก project root
cd ..\..
docker-compose -f docker-compose.test.yml up -d

# รอให้ services พร้อม
Start-Sleep -Seconds 10

# ตรวจสอบว่า containers ทำงาน
docker ps

# ควรเห็น:
# - postgres-test (port 5433)
# - minio-test (port 9010)
# - qdrant-test (port 6334)
```

---

## 🚀 รัน Tests

```powershell
# ไปที่โฟลเดอร์ backend
cd apps\amulet-ai-service

# Activate venv (ถ้ายังไม่ได้ activate)
.\venv\Scripts\Activate.ps1

# รัน tests
pytest tests/ -v
```

---

## 📊 รัน Tests แบบเจาะจง

### รัน tests ตาม marker

```powershell
# API tests only
pytest tests/ -v -m "api"

# Database tests only
pytest tests/ -v -m "database"

# Security tests only  
pytest tests/ -v -m "security"

# Integration tests only
pytest tests/ -v -m "integration"

# API + Database tests
pytest tests/ -v -m "api or database"

# ข้าม slow tests
pytest tests/ -v -m "not slow"
```

### รัน test file เดียว

```powershell
pytest tests/test_api_analyze.py -v
pytest tests/test_database.py -v
pytest tests/test_integration.py -v
```

### รัน test function เดียว

```powershell
pytest tests/test_api_analyze.py::TestAnalyzeEndpoint::test_analyze_valid_jpeg -v
```

---

## 📈 Coverage Report

```powershell
# HTML coverage report
pytest tests/ -v --cov --cov-report=html

# เปิดดู report
start htmlcov/index.html
```

```powershell
# Terminal coverage report
pytest tests/ -v --cov --cov-report=term-missing
```

---

## 🐛 Troubleshooting

### Error: `No module named 'apps'`
**แก้แล้ว!** Import paths ถูกแก้ไขเป็น relative imports แล้ว

### Error: `ModuleNotFoundError: No module named 'fastapi'`
```powershell
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1
.\install_windows.ps1
```

### Error: Python 3.13 Incompatibility
```powershell
# อ่านคู่มือ
cat PYTHON_VERSION_FIX.md

# หรือรัน
.\fix_python_version.ps1
```

### Error: Database connection refused
```powershell
# เริ่ม test containers
cd ..\..
docker-compose -f docker-compose.test.yml down
docker-compose -f docker-compose.test.yml up -d
Start-Sleep -Seconds 10
```

### Error: Port already in use
```powershell
# Stop และ restart containers
docker-compose -f docker-compose.test.yml down
docker-compose -f docker-compose.test.yml up -d
```

---

## 🧹 Clean Up

```powershell
# Stop test containers
cd ..\..
docker-compose -f docker-compose.test.yml down

# ลบ volumes ด้วย
docker-compose -f docker-compose.test.yml down -v

# ลบ Python cache
cd apps\amulet-ai-service
Remove-Item -Recurse -Force __pycache__
Remove-Item -Recurse -Force .pytest_cache
Remove-Item -Force .coverage
Remove-Item -Recurse -Force htmlcov
```

---

## ✅ Checklist ก่อนรัน Tests

- [ ] Python 3.11 หรือ 3.12 (ไม่ใช่ 3.13)
- [ ] Virtual environment activated (`(venv)` ใน prompt)
- [ ] Dependencies ติดตั้งแล้ว
- [ ] Test containers ทำงานอยู่ (`docker ps`)
- [ ] อยู่ในโฟลเดอร์ที่ถูกต้อง (`apps/amulet-ai-service`)

---

## 🎯 Quick Commands

```powershell
# Setup ครั้งแรก (run once)
cd apps\amulet-ai-service
py -3.11 -m venv venv
.\venv\Scripts\Activate.ps1
.\install_windows.ps1
cd ..\..
docker-compose -f docker-compose.test.yml up -d
Start-Sleep -Seconds 10

# รัน tests (ทุกครั้ง)
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1
pytest tests/ -v -m "api or database"
```

---

## 📝 Tips

1. **รัน tests บ่อยๆ** ขณะพัฒนา
2. **ใช้ markers** เพื่อรัน tests เฉพาะส่วน (เร็วกว่า)
3. **ตรวจ coverage** หลังเพิ่ม features ใหม่
4. **Keep venv activated** ตลอดเวลาที่พัฒนา
5. **ใช้ `-v` flag** เพื่อเห็นรายละเอียดมากขึ้น

---

## 📚 เอกสารเพิ่มเติม

- **คู่มือละเอียด:** `tests/README.md`
- **Python Version Issues:** `PYTHON_VERSION_FIX.md`
- **Quick Start:** `../../TESTING_QUICKSTART.md`

---

**อัพเดทล่าสุด:** 2024-11-09
**สถานะ:** ✅ Import paths แก้ไขแล้ว - พร้อมใช้งาน

