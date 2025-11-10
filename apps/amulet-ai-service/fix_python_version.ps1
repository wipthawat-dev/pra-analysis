# Fix Python Version Compatibility
Write-Host "=== Python Version Compatibility Checker ===" -ForegroundColor Cyan
Write-Host ""

# Check Python version
$pythonVersion = python --version 2>&1
Write-Host "Current Python version: $pythonVersion" -ForegroundColor Yellow

if ($pythonVersion -match "Python 3\.13") {
    Write-Host ""
    Write-Host "⚠️  WARNING: Python 3.13 detected!" -ForegroundColor Red
    Write-Host ""
    Write-Host "SQLAlchemy 2.0.23 is not compatible with Python 3.13" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Solutions:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 1 (Recommended): Downgrade to Python 3.11 or 3.12" -ForegroundColor Green
    Write-Host "  1. Download Python 3.11: https://www.python.org/downloads/" -ForegroundColor White
    Write-Host "  2. Install Python 3.11" -ForegroundColor White
    Write-Host "  3. Recreate virtual environment:" -ForegroundColor White
    Write-Host "     py -3.11 -m venv venv" -ForegroundColor Gray
    Write-Host "     .\venv\Scripts\Activate.ps1" -ForegroundColor Gray
    Write-Host "     .\install_windows.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 2: Upgrade SQLAlchemy (may have breaking changes)" -ForegroundColor Yellow
    Write-Host "  pip install sqlalchemy>=2.0.30" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "Do you want to try upgrading SQLAlchemy? (y/N)"
    
    if ($choice -eq "y" -or $choice -eq "Y") {
        Write-Host ""
        Write-Host "Attempting to upgrade SQLAlchemy..." -ForegroundColor Cyan
        
        # Activate venv if not activated
        if (-not (Get-Command python).Source -match "venv") {
            if (Test-Path "venv\Scripts\Activate.ps1") {
                & .\venv\Scripts\Activate.ps1
            }
        }
        
        pip install "sqlalchemy>=2.0.30" --upgrade
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ SQLAlchemy upgraded successfully" -ForegroundColor Green
            Write-Host ""
            Write-Host "Now try running tests:" -ForegroundColor Cyan
            Write-Host "  pytest tests/ -v -m 'api or database'" -ForegroundColor Gray
        } else {
            Write-Host "✗ Failed to upgrade SQLAlchemy" -ForegroundColor Red
            Write-Host ""
            Write-Host "Please use Python 3.11 or 3.12 instead." -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "Please install Python 3.11 or 3.12 and recreate virtual environment." -ForegroundColor Yellow
    }
    
} elseif ($pythonVersion -match "Python 3\.(11|12)") {
    Write-Host "✓ Python version is compatible with SQLAlchemy 2.0.23" -ForegroundColor Green
    Write-Host ""
    Write-Host "If you're still having issues, try:" -ForegroundColor Cyan
    Write-Host "  .\install_windows.ps1" -ForegroundColor Gray
} else {
    Write-Host "⚠️  Python version may not be optimal" -ForegroundColor Yellow
    Write-Host "Recommended: Python 3.11 or 3.12" -ForegroundColor Yellow
}

Write-Host ""

