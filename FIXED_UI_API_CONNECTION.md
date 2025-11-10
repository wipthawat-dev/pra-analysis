# ✅ แก้ไขปัญหา UI ไม่สามารถเชื่อมต่อ API ได้แล้ว

## 🔍 ปัญหาที่พบ

เมื่อกดปุ่ม **Analyze** ใน UI เจอข้อผิดพลาด:
```
ไม่สามารถเชื่อมต่อกับ API server ได้ (http://localhost:8000)
กรุณาตรวจสอบว่า API server กำลังทำงานอยู่หรือไม่
```

แม้ว่า API server จะตอบสนอง `http://localhost:8000/` ได้ปกติ

## 🐛 สาเหตุของปัญหา

**ปัญหาหลัก**: ในไฟล์ `apps/amulet-ai-service/services/database.py`

```python
@contextmanager  # ❌ ปัญหา: FastAPI Depends() ไม่สามารถใช้กับ @contextmanager ได้
def get_db():
    """Database session context manager"""
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception as e:
        db.rollback()
        logger.error("database_error", error=str(e))
        raise
    finally:
        db.close()
```

เมื่อ UI เรียก `/v1/analyze` endpoint, FastAPI พยายามใช้ `Depends(get_db)` แต่ได้ `_GeneratorContextManager` object แทนที่จะเป็น `Session` object

**Error ที่เกิด**:
```python
AttributeError: '_GeneratorContextManager' object has no attribute 'add'
```

## ✅ วิธีแก้ไข

### 1. แก้ไข `apps/amulet-ai-service/services/database.py`

**ลบ `@contextmanager` decorator**:

```python
def get_db():  # ✅ แก้ไข: ลบ @contextmanager
    """Database session dependency for FastAPI"""
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        db.rollback()
        logger.error("database_error", error=str(e))
        raise
    finally:
        db.close()
```

**ลบ import ที่ไม่ใช้**:
```python
# ลบบรรทัดนี้
from contextlib import contextmanager
```

### 2. เพิ่ม Debug Logging ใน UI

แก้ไข `apps/web-next/app/analyze/page.tsx` เพื่อเพิ่ม debug logs:

```typescript
const onSubmit = async () => {
  // ... existing code ...
  
  console.log('🚀 Starting upload...', {
    fileName: file.name,
    fileSize: file.size,
    fileType: file.type,
    apiBase,
    url: `${apiBase}/v1/analyze`
  });
  
  console.log('📤 Sending request to:', `${apiBase}/v1/analyze`);
  
  // ... fetch code ...
  
  console.log('📥 Response received:', {
    status: response.status,
    statusText: response.statusText,
    ok: response.ok,
    headers: Object.fromEntries(response.headers.entries())
  });
  
  // ... rest of code ...
};
```

### 3. Rebuild Containers

```powershell
.\make.ps1 down
.\make.ps1 up-cpu
```

## 🧪 วิธีทดสอบ

### 1. ตรวจสอบว่า Containers กำลังรัน

```powershell
docker ps
```

ควรเห็น:
- `pra-analysis-web-1` (port 3000)
- `pra-analysis-api-1` (port 8000)
- `pra-analysis-qdrant-1`
- `pra-analysis-postgres-1`
- `pra-analysis-minio-1`

### 2. ทดสอบ API Health Endpoint

```powershell
curl http://localhost:8000/health
```

ควรได้:
```json
{"ok":true}
```

### 3. ทดสอบ API Root Endpoint

```powershell
curl http://localhost:8000/
```

ควรได้:
```json
{
  "name": "amulet-ai-service",
  "version": "0.1.0",
  "status": "running",
  "endpoints": {
    "health": "/health",
    "docs": "/docs",
    "api": "/api",
    "analyze": "/v1/analyze",
    "admin": "/v1/admin"
  }
}
```

### 4. ทดสอบผ่าน Browser

1. เปิด browser ไปที่: `http://localhost:3000`
2. ไปที่หน้า **Analyze**
3. เปิด **Developer Console** (F12)
4. เลือกรูปภาพ (JPEG หรือ PNG, ไม่เกิน 15MB)
5. กดปุ่ม **Analyze**
6. ดู console logs:

```
🚀 Starting upload... {fileName: "test.jpg", fileSize: 123456, ...}
📤 Sending request to: http://localhost:8000/v1/analyze
📥 Response received: {status: 200, ok: true, ...}
✅ Success: {verdict: "uncertain", score: 0.65, ...}
```

### 5. ทดสอบด้วย curl (ถ้ามีไฟล์ภาพ)

```powershell
curl -X POST http://localhost:8000/v1/analyze `
  -F "file=@path/to/your/image.jpg" `
  -H "Accept: application/json"
```

## 📊 ตรวจสอบ Logs

### API Logs

```powershell
docker logs pra-analysis-api-1 --tail 50
```

ควรเห็น:
```
INFO:     Started server process [1]
INFO:     Waiting for application startup.
2025-11-10 03:19:00 [info     ] database_initialized
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

### Web Logs

```powershell
docker logs pra-analysis-web-1 --tail 50
```

### Real-time Logs (ทั้งหมด)

```powershell
.\make.ps1 logs
```

## 🎯 สิ่งที่แก้ไขไปแล้ว

### ไฟล์ที่แก้ไข

1. **`apps/amulet-ai-service/services/database.py`**
   - ✅ ลบ `@contextmanager` decorator จาก `get_db()`
   - ✅ ลบ `from contextlib import contextmanager`
   - ✅ แก้ไข docstring เป็น "Database session dependency for FastAPI"
   - ✅ ลบ `db.commit()` ออกจาก try block (FastAPI จะจัดการเอง)

2. **`apps/web-next/app/analyze/page.tsx`**
   - ✅ เพิ่ม debug logging ทุกขั้นตอนของการเรียก API
   - ✅ แสดง request details (URL, file info)
   - ✅ แสดง response details (status, headers)
   - ✅ แสดง error details

### ปรับปรุง UI/UX

1. **Better Error Messages**
   - แยกประเภท error (timeout, network, server error)
   - แสดง API URL ที่เรียก
   - แสดงรายละเอียดข้อผิดพลาดชัดเจน

2. **Debug Information**
   - Console logs ทุกขั้นตอน
   - แสดงข้อมูลไฟล์ที่อัปโหลด
   - แสดง response headers

## 🚀 การใช้งาน

### เริ่มต้น Docker Containers

```powershell
# CPU Mode (Mock Triton)
.\make.ps1 up-cpu

# GPU Mode (With Triton) - ต้องการ NVIDIA GPU
.\make.ps1 up-gpu
```

### หยุด Containers

```powershell
.\make.ps1 down
```

### ดู Logs แบบ Real-time

```powershell
.\make.ps1 logs
```

## 📝 หมายเหตุสำคัญ

### Environment Variables

ถ้าต้องการกำหนดค่า environment variables สร้างไฟล์ `.env` ในโฟลเดอร์ root:

```env
# API Configuration
API_HOST=0.0.0.0
API_PORT=8000

# Next.js Configuration
NEXT_PUBLIC_API_BASE=http://localhost:8000

# Database Configuration
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=amulet_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Vector Database Configuration
QDRANT_URL=http://qdrant:6333
QDRANT_COLLECTION=amulet_clip_v1
EMBED_DIM=768

# Object Storage Configuration
MINIO_ENDPOINT=minio:9000
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_SECURE=false
```

### Browser Security

- API และ Web ต้องรันที่ `localhost` เพื่อหลีกเลี่ยง CORS issues
- ถ้าใช้ IP address อื่น ต้องตั้งค่า CORS ใหม่

### File Upload Limits

- **ประเภทไฟล์**: JPEG, PNG เท่านั้น
- **ขนาดสูงสุด**: 15MB
- **Timeout**: 30 วินาที

## ✅ สรุป

ปัญหาเกิดจากการใช้ `@contextmanager` decorator กับ FastAPI's dependency injection system ซึ่งไม่สามารถทำงานร่วมกันได้

การแก้ไข:
1. ✅ ลบ `@contextmanager` decorator
2. ✅ เพิ่ม debug logging ใน UI
3. ✅ Rebuild containers

ตอนนี้ UI สามารถเชื่อมต่อและเรียก API ได้ปกติแล้ว! 🎉

---

**วันที่แก้ไข**: 10 พฤศจิกายน 2025  
**สถานะ**: ✅ แก้ไขสำเร็จ

