# Quick Test Runner - แก้ไขปัญหาทั้งหมดแล้ว!

Write-Host "=== Pra Analysis Test Runner ===" -ForegroundColor Cyan
Write-Host ""

# ตรวจสอบว่าอยู่ในโฟลเดอร์ที่ถูกต้อง
if (-not (Test-Path "pytest.ini")) {
    Write-Host "Error: ต้องรันจากโฟลเดอร์ apps/amulet-ai-service" -ForegroundColor Red
    Write-Host "กรุณารัน: cd apps\amulet-ai-service" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ อยู่ในโฟลเดอร์ที่ถูกต้อง" -ForegroundColor Green
Write-Host ""

# ตรวจสอบ venv
if (-not (Test-Path "venv\Scripts\python.exe")) {
    Write-Host "Error: ไม่พบ virtual environment" -ForegroundColor Red
    Write-Host ""
    Write-Host "กรุณาสร้าง venv ก่อน:" -ForegroundColor Yellow
    Write-Host "  python -m venv venv" -ForegroundColor Gray
    Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor Gray
    Write-Host "  .\install_windows.ps1" -ForegroundColor Gray
    exit 1
}

Write-Host "✓ Virtual environment พบแล้ว" -ForegroundColor Green
Write-Host ""

# Activate venv
Write-Host "เปิด virtual environment..." -ForegroundColor Cyan
& .\venv\Scripts\Activate.ps1

# ตรวจสอบ packages
Write-Host "ตรวจสอบ packages..." -ForegroundColor Cyan
$packages = @("fastapi", "pytest", "sqlalchemy")
$missing = @()

foreach ($pkg in $packages) {
    pip show $pkg 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $pkg" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $pkg - MISSING!" -ForegroundColor Red
        $missing += $pkg
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Error: Packages ต้องติดตั้งก่อน" -ForegroundColor Red
    Write-Host "กรุณารัน: .\install_windows.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "✓ Packages ครบถ้วน" -ForegroundColor Green
Write-Host ""

# ตรวจสอบ test containers
Write-Host "ตรวจสอบ test containers..." -ForegroundColor Cyan
$postgresRunning = docker ps --filter "name=postgres-test" --filter "status=running" -q
$minioRunning = docker ps --filter "name=minio-test" --filter "status=running" -q
$qdrantRunning = docker ps --filter "name=qdrant-test" --filter "status=running" -q

if (-not $postgresRunning -or -not $minioRunning -or -not $qdrantRunning) {
    Write-Host "⚠ Test containers ไม่ทำงาน" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "เริ่ม test containers..." -ForegroundColor Cyan
    Set-Location ../..
    docker-compose -f docker-compose.test.yml up -d
    Write-Host "รอให้ services พร้อม..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    Set-Location apps/amulet-ai-service
    Write-Host "✓ Test containers เริ่มแล้ว" -ForegroundColor Green
} else {
    Write-Host "✓ Test containers ทำงานอยู่แล้ว" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== เริ่มรัน Tests ===" -ForegroundColor Cyan
Write-Host ""

# รัน tests
pytest tests/ -v --no-cov-on-fail

Write-Host ""
Write-Host "=== เสร็จสิ้น ===" -ForegroundColor Cyan
Write-Host ""

