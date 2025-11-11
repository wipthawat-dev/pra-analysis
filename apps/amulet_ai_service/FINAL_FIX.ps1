# Final Fix for Python 3.13 + SQLAlchemy

Write-Host "=== Python 3.13 Final Fix ===" -ForegroundColor Cyan
Write-Host ""

# Check Python version
$pythonVersion = python --version 2>&1
Write-Host "Python version: $pythonVersion" -ForegroundColor Yellow

if ($pythonVersion -match "Python 3\.13") {
    Write-Host ""
    Write-Host "⚠️  Python 3.13 ตรวจพบ!" -ForegroundColor Red
    Write-Host ""
    Write-Host "SQLAlchemy มีปัญหากับ Python 3.13" -ForegroundColor Yellow
    Write-Host "Error: Can't replace canonical symbol for '__firstlineno__'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "=== วิธีแก้ ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "วิธีที่ 1: ใช้ SQLAlchemy เวอร์ชันใหม่สุด" -ForegroundColor Green
    Write-Host "  pip uninstall sqlalchemy -y" -ForegroundColor Gray
    Write-Host "  pip install --pre 'sqlalchemy>=2.0.35'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "วิธีที่ 2: ใช้ Python 3.11 หรือ 3.12 (แนะนำ)" -ForegroundColor Green
    Write-Host "  1. ติดตั้ง Python 3.11 จาก:" -ForegroundColor Gray
    Write-Host "     https://www.python.org/downloads/release/python-3119/" -ForegroundColor Gray
    Write-Host "  2. สร้าง venv ใหม่:" -ForegroundColor Gray
    Write-Host "     Remove-Item venv -Recurse -Force" -ForegroundColor Gray
    Write-Host "     py -3.11 -m venv venv" -ForegroundColor Gray
    Write-Host "     .\venv\Scripts\Activate.ps1" -ForegroundColor Gray
    Write-Host "     .\INSTALL_ONE_BY_ONE.ps1" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "ต้องการลองวิธีที่ 1 (ใช้ SQLAlchemy ใหม่สุด)? (y/N)"
    
    if ($choice -eq "y" -or $choice -eq "Y") {
        Write-Host ""
        Write-Host "กำลังอัพเกรด SQLAlchemy..." -ForegroundColor Cyan
        
        pip uninstall sqlalchemy -y 2>&1 | Out-Null
        pip install --pre "sqlalchemy>=2.0.35" 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ SQLAlchemy อัพเกรดแล้ว" -ForegroundColor Green
            
            $version = (pip show sqlalchemy | Select-String "Version:").ToString().Split(":")[1].Trim()
            Write-Host "Version: $version" -ForegroundColor Green
            Write-Host ""
            Write-Host "ลองรัน tests:" -ForegroundColor Cyan
            Write-Host "  pytest tests/ -v --no-cov" -ForegroundColor White
        } else {
            Write-Host "✗ ไม่สามารถอัพเกรด SQLAlchemy" -ForegroundColor Red
            Write-Host ""
            Write-Host "กรุณาใช้ Python 3.11 หรือ 3.12 แทน" -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "กรุณาดาวน์โหลดและติดตั้ง Python 3.11:" -ForegroundColor Yellow
        Write-Host "https://www.python.org/downloads/release/python-3119/" -ForegroundColor Cyan
    }
    
} else {
    Write-Host "✓ Python version เข้ากันได้" -ForegroundColor Green
    Write-Host ""
    Write-Host "หาก dependencies ยังไม่ได้ติดตั้ง รัน:" -ForegroundColor Cyan
    Write-Host "  .\INSTALL_ONE_BY_ONE.ps1" -ForegroundColor White
}

Write-Host ""

