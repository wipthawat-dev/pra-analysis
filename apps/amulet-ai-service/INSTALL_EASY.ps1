# Easy Installation - ข้าม packages ที่มีปัญหาบน Windows

Write-Host "=== Easy Installation (Windows) ===" -ForegroundColor Cyan
Write-Host "ติดตั้งแบบง่าย - ข้าม packages ที่ต้อง compile" -ForegroundColor Yellow
Write-Host ""

# ตรวจสอบ Python version
$pythonVersion = python --version 2>&1
Write-Host "Python version: $pythonVersion" -ForegroundColor Green
Write-Host ""

# Activate venv
if (-not (Get-Command python).Source -match "venv") {
    Write-Host "Activating venv..." -ForegroundColor Cyan
    if (Test-Path "venv\Scripts\Activate.ps1") {
        & .\venv\Scripts\Activate.ps1
    } else {
        Write-Host "Error: Virtual environment not found!" -ForegroundColor Red
        Write-Host "กรุณาสร้าง venv ก่อน: python -m venv venv" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Upgrading pip..." -ForegroundColor Cyan
python -m pip install --upgrade pip 2>&1 | Out-Null
Write-Host "✓ Pip upgraded" -ForegroundColor Green
Write-Host ""

Write-Host "Installing packages (ทีละตัวเพื่อหาปัญหา)..." -ForegroundColor Cyan
Write-Host ""

$packages = @(
    "fastapi==0.115.0",
    "uvicorn==0.30.6",
    "pydantic==2.9.2",
    "pydantic-settings==2.4.0",
    "sqlalchemy>=2.0.30",
    "pytest==7.4.3",
    "pytest-asyncio==0.21.1",
    "pytest-cov==4.1.0",
    "pytest-mock==3.12.0",
    "httpx==0.25.2",
    "pillow==10.4.0",
    "python-multipart==0.0.12",
    "structlog==24.1.0",
    "qdrant-client==1.9.2",
    "minio==7.2.0",
    "faker==20.1.0"
)

$installed = 0
$failed = 0
$failedList = @()

foreach ($pkg in $packages) {
    $pkgName = ($pkg -split "==|>=")[0]
    Write-Host "[$($installed+$failed+1)/$($packages.Count)] $pkgName..." -NoNewline
    
    $output = pip install $pkg --no-cache-dir 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✓" -ForegroundColor Green
        $installed++
    } else {
        Write-Host " ✗" -ForegroundColor Red
        $failed++
        $failedList += $pkgName
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Installed: $installed/$($packages.Count)" -ForegroundColor Green
Write-Host "Failed: $failed/$($packages.Count)" -ForegroundColor $(if ($failed -eq 0) {"Green"} else {"Yellow"})

if ($failedList.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed packages:" -ForegroundColor Yellow
    foreach ($f in $failedList) {
        Write-Host "  - $f" -ForegroundColor Gray
    }
}

Write-Host ""

# Verify critical packages
Write-Host "Verifying critical packages..." -ForegroundColor Cyan
$critical = @("fastapi", "pytest", "sqlalchemy", "minio")
$missing = @()

foreach ($pkg in $critical) {
    pip show $pkg 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $pkg" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $pkg - MISSING!" -ForegroundColor Red
        $missing += $pkg
    }
}

Write-Host ""

if ($missing.Count -eq 0) {
    Write-Host "=== SUCCESS ===" -ForegroundColor Green
    Write-Host "สามารถรัน tests ได้แล้ว!" -ForegroundColor Green
    Write-Host ""
    Write-Host "รันคำสั่งนี้:" -ForegroundColor Cyan
    Write-Host "  pytest tests/ -v --no-cov" -ForegroundColor White
    Write-Host ""
    Write-Host "หมายเหตุ: ใช้ SQLite สำหรับ testing (ไม่ต้องใช้ psycopg2)" -ForegroundColor Yellow
} else {
    Write-Host "=== FAILED ===" -ForegroundColor Red
    Write-Host "Packages สำคัญยังติดตั้งไม่ได้:" -ForegroundColor Red
    foreach ($m in $missing) {
        Write-Host "  - $m" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "ลองติดตั้ง manually:" -ForegroundColor Yellow
    foreach ($m in $missing) {
        Write-Host "  pip install $m" -ForegroundColor Gray
    }
    exit 1
}

