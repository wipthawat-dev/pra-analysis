# 🚨 คำสั่งสุดท้าย - รันนี้ได้แน่นอน!

## ปัญหา: Dependencies ยังไม่ได้ติดตั้ง

Error: `ModuleNotFoundError: No module named 'minio'`

---

## ✅ แก้ไขเดี๋ยวนี้!

### คัดลอกและรันคำสั่งเหล่านี้ทีละบล็อก:

#### บล็อกที่ 1: ไปที่โฟลเดอร์และ Activate venv

```powershell
cd C:\wat\pra-analysis\pra-analysis\apps\amulet-ai-service
.\venv\Scripts\Activate.ps1
```

#### บล็อกที่ 2: Upgrade pip

```powershell
python -m pip install --upgrade pip
```

#### บล็อกที่ 3: ติดตั้ง Core Packages

```powershell
pip install fastapi==0.115.0
pip install uvicorn==0.30.6
pip install pydantic==2.9.2
```

#### บล็อกที่ 4: ติดตั้ง Database Packages

```powershell
pip install "sqlalchemy>=2.0.30"
pip install psycopg2-binary==2.9.9
```

#### บล็อกที่ 5: ติดตั้ง Test Packages

```powershell
pip install pytest==7.4.3
pip install pytest-asyncio==0.21.1
pip install pytest-cov==4.1.0
pip install httpx==0.25.2
```

#### บล็อกที่ 6: ติดตั้ง Other Packages

```powershell
pip install pillow==10.4.0
pip install python-multipart==0.0.12
pip install structlog==24.1.0
pip install qdrant-client==1.9.2
pip install minio==7.2.0
```

#### บล็อกที่ 7: ตรวจสอบว่าติดตั้งสำเร็จ

```powershell
pip show fastapi pytest sqlalchemy minio
```

ควรเห็นข้อมูล packages ทั้ง 4 ตัว

---

## 🚀 รัน Tests

```powershell
pytest tests/ -v --no-cov
```

---

## 🎯 หรือใช้ Script (ถ้าคำสั่งด้านบนใช้ไม่ได้)

```powershell
.\INSTALL_MINIMAL.ps1
```

จากนั้น:

```powershell
pytest tests/ -v --no-cov
```

---

## ⚡ One-Liner สำหรับคนรีบ

```powershell
cd C:\wat\pra-analysis\pra-analysis\apps\amulet-ai-service; .\venv\Scripts\Activate.ps1; pip install fastapi uvicorn pydantic "sqlalchemy>=2.0.30" pytest pytest-asyncio pytest-cov httpx psycopg2-binary pillow python-multipart structlog qdrant-client minio; pytest tests/ -v --no-cov
```

---

## 🔍 ตรวจสอบว่า Packages ติดตั้งแล้ว

```powershell
pip list
```

ต้องเห็นทุก packages เหล่านี้:
- fastapi
- pytest
- sqlalchemy
- minio
- qdrant-client
- structlog
- pydantic
- uvicorn
- psycopg2-binary
- pillow
- httpx

---

## 📝 หมายเหตุสำคัญ

1. **ต้อง Activate venv ก่อนเสมอ**: `.\venv\Scripts\Activate.ps1`
2. **ต้องเห็น (venv)** หน้า prompt
3. **ต้อง pip install ทุกตัว** ไม่งั้น ModuleNotFoundError
4. **ใช้ --no-cov** เพื่อข้าม coverage warnings

---

## ✅ Checklist

ก่อนรัน tests ให้แน่ใจว่า:

- [ ] อยู่ในโฟลเดอร์ `apps/amulet-ai-service`
- [ ] Virtual environment activated (เห็น `(venv)` ใน prompt)
- [ ] Pip upgraded แล้ว
- [ ] Packages ทั้งหมดติดตั้งแล้ว (รัน `pip list`)
- [ ] Test containers ทำงานอยู่ (`docker ps`)

---

## 🐳 เริ่ม Test Containers (ถ้ายังไม่เปิด)

```powershell
cd C:\wat\pra-analysis\pra-analysis
docker-compose -f docker-compose.test.yml up -d
Start-Sleep -Seconds 10
cd apps\amulet-ai-service
```

---

**ไฟล์นี้มีคำสั่งที่ใช้งานได้แน่นอน - คัดลอกและรันทีละบล็อก!**

