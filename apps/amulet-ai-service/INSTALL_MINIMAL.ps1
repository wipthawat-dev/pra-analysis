# Minimal Installation - เฉพาะ packages ที่จำเป็นสำหรับ tests

Write-Host "=== Minimal Package Installation ===" -ForegroundColor Cyan
Write-Host "ติดตั้งเฉพาะ packages ที่จำเป็นสำหรับ testing" -ForegroundColor Yellow
Write-Host ""

# ตรวจสอบ venv
if (-not (Test-Path "venv\Scripts\python.exe")) {
    Write-Host "สร้าง virtual environment..." -ForegroundColor Yellow
    python -m venv venv
}

# Activate
Write-Host "Activate virtual environment..." -ForegroundColor Cyan
& .\venv\Scripts\Activate.ps1

# Upgrade pip
Write-Host ""
Write-Host "Upgrade pip..." -ForegroundColor Cyan
python -m pip install --upgrade pip setuptools wheel
Write-Host ""

# List of essential packages
$essentialPackages = @(
    @{name="fastapi"; version="0.115.0"},
    @{name="uvicorn"; version="0.30.6"},
    @{name="pydantic"; version="2.9.2"},
    @{name="sqlalchemy"; version="2.0.30"},  # Use newer version for Python 3.13
    @{name="pytest"; version="7.4.3"},
    @{name="pytest-asyncio"; version="0.21.1"},
    @{name="pytest-cov"; version="4.1.0"},
    @{name="httpx"; version="0.25.2"},
    @{name="psycopg2-binary"; version="2.9.9"},
    @{name="pillow"; version="10.4.0"},
    @{name="python-multipart"; version="0.0.12"},
    @{name="structlog"; version="24.1.0"},
    @{name="qdrant-client"; version="1.9.2"},
    @{name="minio"; version="7.2.0"}
)

$installed = 0
$failed = 0

Write-Host "ติดตั้ง packages ทีละตัว..." -ForegroundColor Cyan
Write-Host ""

foreach ($pkg in $essentialPackages) {
    $packageSpec = "$($pkg.name)==$($pkg.version)"
    Write-Host "[$($installed+$failed+1)/$($essentialPackages.Count)] Installing $($pkg.name)..." -ForegroundColor Yellow
    
    pip install $packageSpec --no-cache-dir 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $($pkg.name) installed" -ForegroundColor Green
        $installed++
    } else {
        Write-Host "  ✗ $($pkg.name) failed" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "✓ Installed: $installed packages" -ForegroundColor Green
Write-Host "✗ Failed: $failed packages" -ForegroundColor $(if ($failed -eq 0) {"Green"} else {"Red"})
Write-Host ""

if ($failed -gt 0) {
    Write-Host "⚠ Some packages failed to install" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "คุณยังคงรัน tests ได้ถ้า packages สำคัญติดตั้งแล้ว" -ForegroundColor White
}

# Verify critical packages
Write-Host "Verifying critical packages..." -ForegroundColor Cyan
$critical = @("fastapi", "pytest", "sqlalchemy", "minio")
$allOk = $true

foreach ($pkg in $critical) {
    pip show $pkg 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $version = (pip show $pkg | Select-String "Version:").ToString().Split(":")[1].Trim()
        Write-Host "  ✓ $pkg ($version)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $pkg - MISSING!" -ForegroundColor Red
        $allOk = $false
    }
}

Write-Host ""

if ($allOk) {
    Write-Host "=== SUCCESS ===" -ForegroundColor Green
    Write-Host "ทุกอย่างพร้อมแล้ว!" -ForegroundColor Green
    Write-Host ""
    Write-Host "รัน tests เลย:" -ForegroundColor Cyan
    Write-Host "  pytest tests/ -v --no-cov" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "=== FAILED ===" -ForegroundColor Red
    Write-Host "Packages สำคัญบางตัวยังไม่ได้ติดตั้ง" -ForegroundColor Red
    Write-Host ""
    Write-Host "ลองติดตั้ง manually:" -ForegroundColor Yellow
    Write-Host "  pip install fastapi pytest sqlalchemy minio" -ForegroundColor Gray
    exit 1
}

