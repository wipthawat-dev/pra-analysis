# Windows-specific dependency installation script
# This script handles known Windows compatibility issues

Write-Host "=== Windows Dependency Installer ===" -ForegroundColor Cyan
Write-Host ""

# Navigate to correct directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
Write-Host ""

# Check Python version
Write-Host "Checking Python version..." -ForegroundColor Cyan
$pythonVersion = python --version 2>&1
Write-Host $pythonVersion -ForegroundColor Green

if ($pythonVersion -match "Python 3\.13") {
    Write-Host ""
    Write-Host "⚠️  WARNING: Python 3.13 detected!" -ForegroundColor Red
    Write-Host "SQLAlchemy 2.0.23 is not compatible with Python 3.13" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Recommended: Use Python 3.11 or 3.12" -ForegroundColor Yellow
    Write-Host "Or we can try upgrading SQLAlchemy to 2.0.30+" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway and try newer SQLAlchemy? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host ""
        Write-Host "Please install Python 3.11 or 3.12 from:" -ForegroundColor Cyan
        Write-Host "https://www.python.org/downloads/" -ForegroundColor White
        exit 1
    }
    $usePython313 = $true
} elseif ($pythonVersion -notmatch "Python 3\.(1[0-9]|[2-9][0-9])") {
    Write-Host "Warning: Python 3.10+ is recommended" -ForegroundColor Yellow
    Write-Host "Current: $pythonVersion" -ForegroundColor Yellow
    $usePython313 = $false
} else {
    $usePython313 = $false
}
Write-Host ""

# Create or check virtual environment
if (Test-Path "venv") {
    Write-Host "Virtual environment exists" -ForegroundColor Green
} else {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create virtual environment" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Cyan
& .\venv\Scripts\Activate.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to activate virtual environment" -ForegroundColor Red
    Write-Host "Try running manually: .\venv\Scripts\Activate.ps1" -ForegroundColor Yellow
    exit 1
}

# Verify activation
$pythonPath = (Get-Command python).Source
Write-Host "Python path: $pythonPath" -ForegroundColor Green

if ($pythonPath -notmatch "venv") {
    Write-Host "Warning: Virtual environment may not be activated correctly!" -ForegroundColor Red
    Write-Host "Current Python: $pythonPath" -ForegroundColor Yellow
}
Write-Host ""

# Upgrade pip, setuptools, wheel
Write-Host "Upgrading pip and build tools..." -ForegroundColor Cyan
python -m pip install --upgrade pip setuptools wheel

if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Failed to upgrade pip" -ForegroundColor Yellow
}
Write-Host ""

# Install packages one by one to identify problems
Write-Host "Installing packages individually (this helps identify issues)..." -ForegroundColor Cyan
Write-Host ""

# Adjust SQLAlchemy version based on Python version
if ($usePython313) {
    $sqlalchemyVersion = "sqlalchemy>=2.0.30"
} else {
    $sqlalchemyVersion = "sqlalchemy==2.0.23"
}

$packages = @(
    "fastapi==0.115.0",
    "uvicorn[standard]==0.30.6",
    "pydantic==2.9.2",
    "pydantic-settings==2.4.0",
    "structlog==24.1.0",
    "python-multipart==0.0.12",
    "minio==7.2.0",
    "psycopg2-binary==2.9.9",
    $sqlalchemyVersion,
    "aiosqlite==0.19.0",
    "qdrant-client==1.9.2",
    "pillow==10.4.0"
)

# NumPy is optional - add it last
$optionalPackages = @(
    "numpy>=1.24.0"
)

$failed = @()
$installed = @()

foreach ($package in $packages) {
    $packageName = $package -replace "==.*", "" -replace "\[.*\]", ""
    Write-Host "Installing $packageName..." -ForegroundColor Yellow
    
    pip install $package --no-cache-dir 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $packageName installed" -ForegroundColor Green
        $installed += $packageName
    } else {
        Write-Host "  ✗ $packageName failed" -ForegroundColor Red
        $failed += $packageName
        
        # Try alternative approaches
        if ($packageName -eq "psycopg2-binary") {
            Write-Host "  Trying psycopg2-binary from wheel..." -ForegroundColor Yellow
            pip install psycopg2-binary --only-binary :all: 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Installed via wheel" -ForegroundColor Green
                $failed = $failed | Where-Object { $_ -ne $packageName }
                $installed += $packageName
            }
        }
    }
}

Write-Host ""

# Try optional packages
Write-Host "Installing optional packages..." -ForegroundColor Cyan
foreach ($package in $optionalPackages) {
    $packageName = $package -replace ">=.*", "" -replace "==.*", ""
    Write-Host "Installing $packageName (optional)..." -ForegroundColor Yellow
    
    pip install $package --no-cache-dir 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $packageName installed" -ForegroundColor Green
        $installed += $packageName
    } else {
        Write-Host "  ℹ $packageName skipped (optional)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "Installed: $($installed.Count) packages" -ForegroundColor Green
Write-Host "Failed: $($failed.Count) packages" -ForegroundColor $(if ($failed.Count -eq 0) { "Green" } else { "Red" })

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed packages:" -ForegroundColor Red
    foreach ($pkg in $failed) {
        Write-Host "  - $pkg" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "=== Troubleshooting ===" -ForegroundColor Yellow
    Write-Host "Some packages failed to install. This is usually due to:" -ForegroundColor White
    Write-Host "1. Missing Microsoft C++ Build Tools" -ForegroundColor White
    Write-Host "2. Package incompatibility with Windows" -ForegroundColor White
    Write-Host ""
    Write-Host "Solutions:" -ForegroundColor Cyan
    Write-Host "1. Install Microsoft C++ Build Tools:" -ForegroundColor White
    Write-Host "   https://visualstudio.microsoft.com/visual-cpp-build-tools/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. For testing, you can skip problematic packages:" -ForegroundColor White
    Write-Host "   Most tests don't require tritonclient (it's mocked)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Install from wheels only:" -ForegroundColor White
    Write-Host "   pip install <package> --only-binary :all:" -ForegroundColor Gray
}

Write-Host ""

# Install test dependencies
Write-Host "Installing test dependencies..." -ForegroundColor Cyan

if (Test-Path "requirements-test.txt") {
    pip install -r requirements-test.txt
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Test dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "✗ Some test dependencies failed" -ForegroundColor Yellow
        Write-Host "Trying essential test packages only..." -ForegroundColor Yellow
        
        $testPackages = @(
            "pytest==7.4.3",
            "pytest-asyncio==0.21.1",
            "pytest-cov==4.1.0",
            "pytest-mock==3.12.0",
            "httpx==0.25.2",
            "faker==20.1.0"
        )
        
        foreach ($pkg in $testPackages) {
            pip install $pkg --no-cache-dir 2>&1 | Out-Null
        }
    }
} else {
    Write-Host "requirements-test.txt not found, skipping test dependencies" -ForegroundColor Yellow
}

Write-Host ""

# Verify critical packages for testing
Write-Host "Verifying critical packages for testing..." -ForegroundColor Cyan
$criticalPackages = @("fastapi", "pytest", "sqlalchemy", "pydantic")

$allCriticalInstalled = $true
foreach ($pkg in $criticalPackages) {
    $check = pip show $pkg 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $pkg" -ForegroundColor Green
    } else {
        Write-Host "✗ $pkg - REQUIRED!" -ForegroundColor Red
        $allCriticalInstalled = $false
    }
}

Write-Host ""

if ($allCriticalInstalled -and $failed.Count -eq 0) {
    Write-Host "=== SUCCESS ===" -ForegroundColor Green
    Write-Host "All dependencies installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Start test containers:" -ForegroundColor White
    Write-Host "   cd ..\.." -ForegroundColor Gray
    Write-Host "   docker-compose -f docker-compose.test.yml up -d" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Run tests:" -ForegroundColor White
    Write-Host "   cd apps\amulet-ai-service" -ForegroundColor Gray
    Write-Host "   pytest tests\ -v" -ForegroundColor Gray
} elseif ($allCriticalInstalled) {
    Write-Host "=== PARTIAL SUCCESS ===" -ForegroundColor Yellow
    Write-Host "Critical packages installed. Some optional packages failed." -ForegroundColor Yellow
    Write-Host "You can proceed with testing, but some features may not work." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To run tests anyway:" -ForegroundColor Cyan
    Write-Host "   pytest tests\ -v" -ForegroundColor Gray
} else {
    Write-Host "=== FAILED ===" -ForegroundColor Red
    Write-Host "Critical packages missing. Cannot proceed with testing." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Microsoft C++ Build Tools and try again." -ForegroundColor Yellow
    Write-Host "Download: https://visualstudio.microsoft.com/visual-cpp-build-tools/" -ForegroundColor Cyan
    exit 1
}

Write-Host ""

