# Fix Dependencies Script
# This script resolves common dependency installation issues

Write-Host "=== Dependency Fix Script ===" -ForegroundColor Cyan
Write-Host ""

# Navigate to correct directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
Write-Host ""

# Check Python version
Write-Host "Checking Python version..." -ForegroundColor Cyan
$pythonVersion = python --version
Write-Host $pythonVersion -ForegroundColor Green

if (-not $pythonVersion -match "Python 3\.(1[0-9]|[2-9][0-9])") {
    Write-Host "Warning: Python 3.10+ is recommended" -ForegroundColor Yellow
}
Write-Host ""

# Check if venv exists
if (Test-Path "venv") {
    Write-Host "Virtual environment exists" -ForegroundColor Green
    $createNew = Read-Host "Do you want to delete and recreate it? (y/N)"
    if ($createNew -eq "y" -or $createNew -eq "Y") {
        Write-Host "Removing old virtual environment..." -ForegroundColor Yellow
        Remove-Item -Path venv -Recurse -Force
        Write-Host "Creating new virtual environment..." -ForegroundColor Yellow
        python -m venv venv
    }
} else {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
}
Write-Host ""

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Cyan
& .\venv\Scripts\Activate.ps1

# Verify activation
$pythonPath = (Get-Command python).Source
Write-Host "Python path: $pythonPath" -ForegroundColor Green

if ($pythonPath -notmatch "venv") {
    Write-Host "Warning: Virtual environment may not be activated correctly!" -ForegroundColor Red
    Write-Host "Try running: .\venv\Scripts\Activate.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Upgrade pip
Write-Host "Upgrading pip..." -ForegroundColor Cyan
python -m pip install --upgrade pip
Write-Host ""

# Install wheel and setuptools
Write-Host "Installing build tools..." -ForegroundColor Cyan
python -m pip install --upgrade wheel setuptools
Write-Host ""

# Check requirements files
Write-Host "Checking requirements files..." -ForegroundColor Cyan
if (-not (Test-Path "requirements.txt")) {
    Write-Host "Error: requirements.txt not found!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ requirements.txt found" -ForegroundColor Green

if (-not (Test-Path "requirements-test.txt")) {
    Write-Host "Error: requirements-test.txt not found!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ requirements-test.txt found" -ForegroundColor Green
Write-Host ""

# Install main dependencies
Write-Host "Installing main dependencies (this may take a few minutes)..." -ForegroundColor Cyan
pip install -r requirements.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install requirements.txt" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Check your internet connection" -ForegroundColor White
    Write-Host "2. Try running: python -m pip install --upgrade pip" -ForegroundColor White
    Write-Host "3. Try installing packages individually to find the problematic one" -ForegroundColor White
    exit 1
}
Write-Host "✓ Main dependencies installed successfully" -ForegroundColor Green
Write-Host ""

# Install test dependencies
Write-Host "Installing test dependencies..." -ForegroundColor Cyan
pip install -r requirements-test.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install requirements-test.txt" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Test dependencies installed successfully" -ForegroundColor Green
Write-Host ""

# Verify critical packages
Write-Host "Verifying critical packages..." -ForegroundColor Cyan
$packages = @("fastapi", "pytest", "sqlalchemy", "pillow")

$allInstalled = $true
foreach ($package in $packages) {
    $installed = pip list | Select-String -Pattern "^$package\s"
    if ($installed) {
        Write-Host "✓ $package installed" -ForegroundColor Green
    } else {
        Write-Host "✗ $package NOT installed" -ForegroundColor Red
        $allInstalled = $false
    }
}
Write-Host ""

if ($allInstalled) {
    Write-Host "=== SUCCESS ===" -ForegroundColor Green
    Write-Host "All dependencies installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Make sure test containers are running:" -ForegroundColor White
    Write-Host "   cd ..\.." -ForegroundColor Gray
    Write-Host "   docker-compose -f docker-compose.test.yml up -d" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Run tests:" -ForegroundColor White
    Write-Host "   cd apps\amulet-ai-service" -ForegroundColor Gray
    Write-Host "   pytest tests/ -v" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "=== FAILED ===" -ForegroundColor Red
    Write-Host "Some packages failed to install. Please check the errors above." -ForegroundColor Red
    exit 1
}

