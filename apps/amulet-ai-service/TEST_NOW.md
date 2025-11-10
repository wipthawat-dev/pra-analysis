# ✅ พร้อมรัน Tests แล้ว!

ตอนนี้ import paths แก้ไขเรียบร้อยแล้ว

## 🚀 รัน Tests

```powershell
# ต้องอยู่ในโฟลเดอร์นี้
cd C:\wat\pra-analysis\pra-analysis\apps\amulet-ai-service

# Activate venv
.\venv\Scripts\Activate.ps1

# รัน tests
pytest tests/ -v

# หรือรัน tests บางส่วน
pytest tests/ -v -m "api"
pytest tests/ -v -m "database"
```

## ถ้ายังมี Error

ถ้ายังมี import errors ในไฟล์ services/* รัน:
```powershell
.\fix_imports.ps1
```

จากนั้นรัน tests อีกครั้ง

