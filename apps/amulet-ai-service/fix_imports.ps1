# Fix Import Paths Script
# แก้ไข import paths จาก apps.amulet_ai_service เป็น relative imports

Write-Host "=== Fix Import Paths ===" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

$files = @(
    "main.py",
    "routes\admin.py",
    "routes\feedback.py",
    "routes\import_route.py",
    "routes\labeling.py",
    "routes\models.py",
    "routes\training.py",
    "routes\retraining.py",
    "services\training_service.py",
    "services\retraining_service.py"
)

$replacements = @{
    "from apps.amulet_ai_service.services.database import" = "from services.database import"
    "from apps.amulet_ai_service.services.minio_client import" = "from services.minio_client import"
    "from apps.amulet_ai_service.models.database_models import" = "from models.database_models import"
    "from apps.amulet_ai_service.schemas.admin_schemas import" = "from schemas.admin_schemas import"
    "from apps.amulet_ai_service.routes import" = "from routes import"
    "from apps.amulet_ai_service.services.training_service import" = "from services.training_service import"
    "from apps.amulet_ai_service.services.retraining_service import" = "from services.retraining_service import"
}

$totalFixed = 0

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing $file..." -ForegroundColor Yellow
        $content = Get-Content $file -Raw
        $originalContent = $content
        $fileFixed = 0
        
        foreach ($old in $replacements.Keys) {
            $new = $replacements[$old]
            $matches = [regex]::Matches($content, [regex]::Escape($old))
            if ($matches.Count -gt 0) {
                $content = $content -replace [regex]::Escape($old), $new
                $fileFixed += $matches.Count
                Write-Host "  Replaced: $old" -ForegroundColor Gray
            }
        }
        
        if ($content -ne $originalContent) {
            Set-Content -Path $file -Value $content -NoNewline
            Write-Host "  ✓ Fixed $fileFixed imports in $file" -ForegroundColor Green
            $totalFixed += $fileFixed
        } else {
            Write-Host "  - No changes needed" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ⚠ File not found: $file" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total imports fixed: $totalFixed" -ForegroundColor Green
Write-Host ""

if ($totalFixed -gt 0) {
    Write-Host "✓ Import paths have been fixed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step:" -ForegroundColor Cyan
    Write-Host "  pytest tests/ -v" -ForegroundColor White
} else {
    Write-Host "All import paths are already correct!" -ForegroundColor Green
}

Write-Host ""

