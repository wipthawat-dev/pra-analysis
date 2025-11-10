# แก้ไขปัญหา Python 3.13 Compatibility

## ปัญหาที่พบ

```
AssertionError: Class <class 'sqlalchemy.sql.elements.SQLCoreOperations'> 
directly inherits TypingOnly but has additional attributes 
{'__static_attributes__', '__firstlineno__'}.
```

**สาเหตุ:** SQLAlchemy 2.0.23 ไม่รองรับ Python 3.13

---

## วิธีแก้ไข (เลือก 1 วิธี)

### 🎯 วิธีที่ 1: ใช้ Python 3.11 หรือ 3.12 (แนะนำที่สุด)

#### ขั้นตอน:

**1. ดาวน์โหลด Python 3.11 หรือ 3.12:**
- Python 3.11: https://www.python.org/downloads/release/python-3119/
- Python 3.12: https://www.python.org/downloads/release/python-3129/

**2. ติดตั้ง Python**
- เลือก "Add Python to PATH" ตอนติดตั้ง
- ติดตั้งใน path เช่น `C:\Python311` หรือ `C:\Python312`

**3. สร้าง virtual environment ใหม่:**

```powershell
# ไปที่โฟลเดอร์ backend
cd apps\amulet-ai-service

# ลบ venv เก่า
Remove-Item -Path venv -Recurse -Force

# สร้าง venv ใหม่ด้วย Python 3.11
py -3.11 -m venv venv

# หรือถ้าติดตั้งเป็น default
python -m venv venv

# Activate
.\venv\Scripts\Activate.ps1

# ติดตั้ง dependencies
.\install_windows.ps1
```

**4. รัน tests:**
```powershell
pytest tests/ -v -m "api or database"
```

---

### 🔧 วิธีที่ 2: อัพเกรด SQLAlchemy (ใช้กับ Python 3.13)

**ข้อควรระวัง:** อาจมี breaking changes

```powershell
cd apps\amulet-ai-service

# รัน script ตรวจสอบ
.\fix_python_version.ps1

# หรือติดตั้ง SQLAlchemy เวอร์ชันใหม่
.\venv\Scripts\Activate.ps1
pip install "sqlalchemy>=2.0.30" --upgrade

# ติดตั้ง dependencies อื่น
.\install_windows.ps1
```

---

### ⚡ วิธีที่ 3: Quick Fix (สำหรับ Python 3.13)

```powershell
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1

# อัพเกรด pip
python -m pip install --upgrade pip

# ติดตั้ง packages ทีละตัว
pip install "sqlalchemy>=2.0.30"
pip install fastapi==0.115.0
pip install uvicorn==0.30.6
pip install pydantic==2.9.2
pip install pytest==7.4.3
pip install pytest-cov==4.1.0
pip install pytest-asyncio==0.21.1
pip install httpx==0.25.2
pip install psycopg2-binary==2.9.9
pip install pillow==10.4.0
pip install python-multipart==0.0.12
pip install structlog==24.1.0
pip install qdrant-client==1.9.2
pip install minio==7.2.0

# ลอง numpy (อาจจะติดตั้งไม่ได้ แต่ไม่จำเป็นมากสำหรับ tests)
pip install numpy

# รัน tests
pytest tests/ -v -m "api or database"
```

---

## ตรวจสอบ Python Version

```powershell
# ดู Python version ปัจจุบัน
python --version

# ดู Python ทั้งหมดในระบบ
py --list

# ใช้ Python 3.11 โดยเฉพาะ
py -3.11 --version

# ใช้ Python 3.12 โดยเฉพาะ
py -3.12 --version
```

---

## สรุปการเลือกวิธี

| วิธี | ข้อดี | ข้อเสีย | แนะนำ |
|------|-------|---------|--------|
| **Python 3.11/3.12** | ✅ เสถียร, ทดสอบแล้ว | ต้องติดตั้ง Python ใหม่ | ⭐⭐⭐⭐⭐ |
| **อัพเกรด SQLAlchemy** | ใช้ Python 3.13 ได้ | อาจมี breaking changes | ⭐⭐⭐ |
| **Quick Fix** | เร็ว | ต้องติดตั้งทีละ package | ⭐⭐⭐⭐ |

---

## Troubleshooting

### ยังพบ error หลังแก้ไข?

```powershell
# 1. ลบ venv เก่าทั้งหมด
cd apps\amulet-ai-service
Remove-Item -Path venv -Recurse -Force

# 2. ลบ cache
Remove-Item -Path __pycache__ -Recurse -Force
Remove-Item -Path .pytest_cache -Recurse -Force

# 3. สร้าง venv ใหม่ด้วย Python ที่ต้องการ
py -3.11 -m venv venv  # หรือ py -3.12 -m venv venv

# 4. Activate
.\venv\Scripts\Activate.ps1

# 5. Verify Python version
python --version  # ควรเห็น 3.11 หรือ 3.12

# 6. ติดตั้ง dependencies
.\install_windows.ps1
```

### ตรวจสอบว่า packages ติดตั้งถูก version

```powershell
pip show sqlalchemy
# ควรเห็น Version: 2.0.30 หรือสูงกว่า (สำหรับ Python 3.13)
# หรือ Version: 2.0.23 (สำหรับ Python 3.11/3.12)
```

---

## คำแนะนำสำหรับ Production

สำหรับการ deploy production แนะนำใช้:
- **Python 3.11** - มีเสถียรภาพสูงสุด
- **Python 3.12** - ใหม่กว่าแต่ยังเสถียร

หลีกเลี่ยง Python 3.13 สำหรับ production จนกว่า dependencies ทั้งหมดจะรองรับอย่างเต็มที่

---

## Links

- Python Downloads: https://www.python.org/downloads/
- SQLAlchemy Changelog: https://docs.sqlalchemy.org/en/20/changelog/
- Python 3.13 Release Notes: https://docs.python.org/3.13/whatsnew/3.13.html

