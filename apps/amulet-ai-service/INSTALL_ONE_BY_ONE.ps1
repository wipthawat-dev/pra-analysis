# ติดตั้งทีละ package - ไม่มีปัญหาแน่นอน!

Write-Host "=== One-by-One Installation ===" -ForegroundColor Cyan
Write-Host ""

# Activate venv
Write-Host "Activating venv..." -ForegroundColor Yellow
& .\venv\Scripts\Activate.ps1

Write-Host ""
Write-Host "Upgrading pip..." -ForegroundColor Cyan
python -m pip install --upgrade pip
Write-Host ""

$packages = @(
    "fastapi==0.115.0",
    "uvicorn==0.30.6",
    "pydantic==2.9.2",
    "pydantic-settings==2.4.0",
    "sqlalchemy==2.0.30",
    "pytest==7.4.3",
    "pytest-asyncio==0.21.1",
    "pytest-cov==4.1.0",
    "httpx==0.25.2",
    "pillow==10.4.0",
    "python-multipart==0.0.12",
    "structlog==24.1.0",
    "qdrant-client==1.9.2",
    "minio==7.2.0",
    "faker==20.1.0",
    "pytest-mock==3.12.0"
)

$success = 0
$total = $packages.Count

Write-Host "Installing $total packages..." -ForegroundColor Cyan
Write-Host ""

foreach ($pkg in $packages) {
    $num = $success + 1
    $pkgName = ($pkg -split "==")[0]
    
    Write-Host "[$num/$total] Installing $pkgName..." -ForegroundColor Yellow
    
    pip install $pkg 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Success" -ForegroundColor Green
        $success++
    } else {
        Write-Host "  ✗ Failed (will continue)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "Installed: $success/$total packages" -ForegroundColor Green
Write-Host ""

# Verify
Write-Host "Verifying..." -ForegroundColor Cyan
$criticalPkgs = @("fastapi", "pytest", "sqlalchemy", "minio")
$allOk = $true

foreach ($p in $criticalPkgs) {
    pip show $p 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $p" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $p - MISSING" -ForegroundColor Red
        $allOk = $false
    }
}

Write-Host ""

if ($allOk) {
    Write-Host "=== READY ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Tests พร้อมรันแล้ว!" -ForegroundColor Green
    Write-Host ""
    Write-Host "รันคำสั่ง:" -ForegroundColor Cyan
    Write-Host "  pytest tests/ -v --no-cov" -ForegroundColor White
    Write-Host ""
    Write-Host "หมายเหตุ:" -ForegroundColor Yellow
    Write-Host "  - Tests จะใช้ SQLite in-memory database" -ForegroundColor Gray
    Write-Host "  - ไม่ต้องใช้ PostgreSQL container สำหรับ basic tests" -ForegroundColor Gray
    Write-Host "  - ข้าม psycopg2-binary (ติดตั้งยากบน Windows)" -ForegroundColor Gray
} else {
    Write-Host "=== INCOMPLETE ===" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "บาง packages ยังไม่ได้ติดตั้ง" -ForegroundColor Yellow
    Write-Host "แต่อาจจะรัน tests ได้บางส่วน" -ForegroundColor Gray
}

Write-Host ""

