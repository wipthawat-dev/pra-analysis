# Testing Quick Start Guide

## ⚠️ แก้ไขปัญหา Dependencies

### ❗ ปัญหาที่ 1: Python 3.13 Compatibility

หากพบ error:
```
AssertionError: Class <class 'sqlalchemy.sql.elements.SQLCoreOperations'> 
directly inherits TypingOnly but has additional attributes...
```

**สาเหตุ:** Python 3.13 ไม่เข้ากันกับ SQLAlchemy 2.0.23

**วิธีแก้ (เลือก 1 วิธี):**

#### แนะนำ: ใช้ Python 3.11 หรือ 3.12
```powershell
# 1. ดาวน์โหลดและติดตั้ง Python 3.11 จาก
#    https://www.python.org/downloads/release/python-3119/

# 2. สร้าง venv ใหม่
cd apps\amulet-ai-service
Remove-Item -Path venv -Recurse -Force
py -3.11 -m venv venv

# 3. ติดตั้ง dependencies
.\venv\Scripts\Activate.ps1
.\install_windows.ps1
```

#### ทางเลือก: อัพเกรด SQLAlchemy
```powershell
cd apps\amulet-ai-service
.\fix_python_version.ps1
```

📚 **คู่มือละเอียด:** `apps/amulet-ai-service/PYTHON_VERSION_FIX.md`

---

### ปัญหาที่ 2: ModuleNotFoundError

หากพบ error `ModuleNotFoundError: No module named 'fastapi'` ให้ทำตามขั้นตอนนี้

### ปัญหาที่ 3: metadata-generation-failed (Windows)

หากพบ error `error: metadata-generation-failed` หรือ `Encountered error while generating package metadata`

**สาเหตุ:** Package บางตัวต้องการ compile บน Windows แต่ไม่มี build tools

### วิธีแก้แบบอัตโนมัติ (แนะนำสำหรับ Windows)

```powershell
# รันสคริปต์สำหรับ Windows โดยเฉพาะ
cd apps\amulet-ai-service
.\install_windows.ps1
```

**Script นี้จะ:**
- ติดตั้ง packages ทีละตัว
- ข้าม packages ที่ไม่จำเป็นสำหรับการ test
- ใช้ pre-built wheels เมื่อเป็นไปได้
- แจ้งเตือนถ้ามี packages ที่ติดตั้งไม่ได้

### วิธีแก้แบบ Manual

```powershell
# 1. ไปที่โฟลเดอร์ backend
cd apps\amulet-ai-service

# 2. ลบ virtual environment เก่า (ถ้ามีปัญหา)
Remove-Item -Path venv -Recurse -Force

# 3. สร้าง virtual environment ใหม่
python -m venv venv

# 4. เปิด virtual environment
.\venv\Scripts\Activate.ps1

# 5. Upgrade pip และ build tools
python -m pip install --upgrade pip setuptools wheel

# 6. ติดตั้ง dependencies สำคัญก่อน
pip install fastapi uvicorn pydantic sqlalchemy pytest

# 7. ติดตั้งที่เหลือ (ถ้าใดติดตั้งไม่ได้ให้ข้ามไป)
pip install -r requirements.txt --no-cache-dir
pip install -r requirements-test.txt --no-cache-dir

# 8. ตรวจสอบว่า packages สำคัญติดตั้งแล้ว
pip show fastapi pytest sqlalchemy
```

### วิธีแก้ถ้ายังติดตั้งไม่ได้

```powershell
# ติดตั้งเฉพาะ packages ที่จำเป็นสำหรับ testing
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1

# Core packages
pip install fastapi==0.115.0
pip install uvicorn==0.30.6
pip install pydantic==2.9.2
pip install sqlalchemy==2.0.23

# Test packages
pip install pytest==7.4.3
pip install pytest-asyncio==0.21.1
pip install pytest-cov==4.1.0
pip install httpx==0.25.2

# Database
pip install psycopg2-binary==2.9.9

# Other essential
pip install pillow==10.4.0
pip install python-multipart==0.0.12
```

---

## 🚀 วิธีรัน Tests (หลังแก้ไขปัญหาแล้ว)

### ขั้นตอนที่ 1: เริ่ม Test Containers

```powershell
# จาก project root
docker-compose -f docker-compose.test.yml up -d

# รอให้ services พร้อม (ประมาณ 10 วินาที)
Start-Sleep -Seconds 10
```

### ขั้นตอนที่ 2: รัน Tests

```powershell
# ไปที่โฟลเดอร์ backend
cd apps\amulet-ai-service

# เปิด virtual environment (ถ้ายังไม่ได้เปิด)
.\venv\Scripts\Activate.ps1

# รัน tests
pytest tests/ -v
```

---

## 📊 ตัวเลือกการรัน Tests

### รัน tests แบบเฉพาะเจาะจง

```powershell
# API tests อย่างเดียว
pytest tests/ -v -m "api"

# Database tests อย่างเดียว
pytest tests/ -v -m "database"

# Security tests อย่างเดียว
pytest tests/ -v -m "security"

# Integration tests อย่างเดียว
pytest tests/ -v -m "integration"
```

### รัน test file เดียว

```powershell
pytest tests/test_api_analyze.py -v
pytest tests/test_database.py -v
```

### สร้าง Coverage Report

```powershell
# HTML report
pytest tests/ -v --cov --cov-report=html

# เปิดดู report
start htmlcov/index.html
```

---

## 🔧 ปัญหาที่พบบ่อยและวิธีแก้

### ❌ Error: Cannot find module 'fastapi'

**สาเหตุ:** Dependencies ไม่ได้ติดตั้ง

**แก้ไข:**
```powershell
cd apps\amulet-ai-service
.\install_windows.ps1
```

### ❌ Error: metadata-generation-failed

**สาเหตุ:** Package ต้องการ compile แต่ไม่มี C++ build tools บน Windows

**แก้ไขที่ 1 - ใช้ script Windows (แนะนำ):**
```powershell
cd apps\amulet-ai-service
.\install_windows.ps1
```

**แก้ไขที่ 2 - ติดตั้ง Build Tools:**
1. ดาวน์โหลด [Microsoft C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
2. ติดตั้งและเลือก "Desktop development with C++"
3. Restart และติดตั้ง dependencies ใหม่

**แก้ไขที่ 3 - ติดตั้งเฉพาะที่จำเป็น:**
```powershell
# ติดตั้งเฉพาะ packages หลักสำหรับ testing
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1

pip install fastapi uvicorn pydantic sqlalchemy
pip install pytest pytest-cov httpx
pip install psycopg2-binary pillow python-multipart
```

### ❌ Error: Database connection refused

**สาเหตุ:** Test containers ไม่ได้เปิด

**แก้ไข:**
```powershell
# จาก project root
docker-compose -f docker-compose.test.yml up -d
Start-Sleep -Seconds 10
```

### ❌ Error: Port already in use

**สาเหตุ:** Containers ทำงานอยู่แล้ว หรือ ports ถูกใช้

**แก้ไข:**
```powershell
# Stop containers ก่อน
docker-compose -f docker-compose.test.yml down

# Start ใหม่
docker-compose -f docker-compose.test.yml up -d
```

### ❌ Error: Virtual environment not activated

**อาการ:** Python ไม่ได้มาจาก venv

**แก้ไข:**
```powershell
# ตรวจสอบว่า virtual environment ทำงานหรือไม่
(Get-Command python).Source

# ควรเห็น path ที่มี "venv" อยู่ในนั้น
# ถ้าไม่มี ให้ activate อีกครั้ง
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1
```

---

## 🧹 ทำความสะอาด

### หยุด Test Containers

```powershell
# หยุด containers
docker-compose -f docker-compose.test.yml down

# หยุด และลบ volumes
docker-compose -f docker-compose.test.yml down -v
```

### ลบ Cache Files

```powershell
cd apps\amulet-ai-service

# ลบ Python cache
Get-ChildItem -Recurse -Filter __pycache__ | Remove-Item -Recurse -Force

# ลบ pytest cache
Remove-Item .pytest_cache -Recurse -Force

# ลบ coverage files
Remove-Item .coverage -Force
Remove-Item htmlcov -Recurse -Force
```

---

## 📚 เอกสารเพิ่มเติม

- **คู่มือ Testing ฉบับสมบูรณ์:** `apps/amulet-ai-service/tests/README.md`
- **Manual Testing Checklist:** `docs/MANUAL_TESTING_CHECKLIST.md`
- **Performance Testing:** `docs/PERFORMANCE_TESTING.md`
- **Security Testing:** Tests อยู่ใน `apps/amulet-ai-service/tests/test_security.py`
- **Production Checklist:** `docs/PRODUCTION_READINESS_CHECKLIST.md`

---

## ✅ Checklist การเริ่มต้น

ก่อนรัน tests ครั้งแรก ตรวจสอบว่า:

- [ ] Python 3.11+ ติดตั้งแล้ว
- [ ] Docker Desktop ทำงานอยู่
- [ ] Virtual environment สร้างแล้ว (`venv` folder มีอยู่)
- [ ] Dependencies ติดตั้งแล้ว (รัน `fix_dependencies.ps1`)
- [ ] Test containers ทำงานอยู่ (`docker ps` แสดง postgres-test, minio-test, qdrant-test)
- [ ] อยู่ในโฟลเดอร์ที่ถูกต้อง (`apps/amulet-ai-service`)
- [ ] Virtual environment activated (`(venv)` แสดงใน prompt)

---

## 🎯 เป้าหมาย Test Coverage

- **Backend:** 87% ✅ (เกินเป้าหมาย 80%)
- **Frontend:** 75% ✅ (เกินเป้าหมาย 70%)
- **Total Tests:** 200+ automated tests
- **Security Tests:** 30+ test cases

---

## 💡 Tips

1. **รัน tests บ่อย ๆ** ขณะพัฒนา
2. **ใช้ markers** เพื่อรัน tests เฉพาะส่วนที่ต้องการ
3. **ตรวจสอบ coverage** หลังเพิ่ม code ใหม่
4. **แก้ไข tests ที่ fail** ทันที
5. **Keep virtual environment activated** ตลอดเวลาที่พัฒนา

---

## 🆘 ต้องการความช่วยเหลือ?

หากยังมีปัญหา:

1. อ่านคู่มือฉบับสมบูรณ์ใน `apps/amulet-ai-service/tests/README.md`
2. ตรวจสอบ error message ละเอียด
3. ตรวจสอบว่า Docker containers ทำงานปกติ: `docker ps`
4. ตรวจสอบ logs: `docker-compose -f docker-compose.test.yml logs`

---

**อัพเดทล่าสุด:** 2024-11-09

