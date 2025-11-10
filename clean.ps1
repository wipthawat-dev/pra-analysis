# Clean script for pra-analysis project
# This script removes all build artifacts, cache files, and Docker resources

Write-Host "🧹 Starting cleanup process..." -ForegroundColor Cyan

# Stop Docker containers and remove volumes
Write-Host "`n📦 Stopping Docker containers..." -ForegroundColor Yellow
docker compose -f docker-compose.gpu.yml down -v 2>$null
docker compose -f docker-compose.cpu.yml down -v 2>$null

# Remove Docker images (optional - uncomment if needed)
# Write-Host "`n🗑️  Removing Docker images..." -ForegroundColor Yellow
# docker rmi pra-analysis-web pra-analysis-api 2>$null

# Clean Next.js build artifacts
Write-Host "`n🌐 Cleaning Next.js artifacts..." -ForegroundColor Yellow
$nextPath = "apps\web-next"
if (Test-Path "$nextPath\.next") {
    Remove-Item -Recurse -Force "$nextPath\.next" -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed .next directory" -ForegroundColor Green
}
if (Test-Path "$nextPath\node_modules") {
    Write-Host "  ⚠️  node_modules exists (may be locked by running process)" -ForegroundColor Yellow
    Write-Host "  💡 Try: Stop any running Node.js processes, then manually delete node_modules" -ForegroundColor Yellow
}
if (Test-Path "$nextPath\package-lock.json") {
    Remove-Item -Force "$nextPath\package-lock.json" -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed package-lock.json" -ForegroundColor Green
}
if (Test-Path "$nextPath\.vercel") {
    Remove-Item -Recurse -Force "$nextPath\.vercel" -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed .vercel directory" -ForegroundColor Green
}

# Clean Python cache files
Write-Host "`n🐍 Cleaning Python cache files..." -ForegroundColor Yellow
$pycacheCount = (Get-ChildItem -Path . -Recurse -Include "__pycache__" -Directory -ErrorAction SilentlyContinue).Count
if ($pycacheCount -gt 0) {
    Get-ChildItem -Path . -Recurse -Include "__pycache__" -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed $pycacheCount __pycache__ directories" -ForegroundColor Green
}

$pycCount = (Get-ChildItem -Path . -Recurse -Include "*.pyc" -ErrorAction SilentlyContinue).Count
if ($pycCount -gt 0) {
    Get-ChildItem -Path . -Recurse -Include "*.pyc" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed $pycCount .pyc files" -ForegroundColor Green
}

# Clean other cache directories
Write-Host "`n🗂️  Cleaning other cache files..." -ForegroundColor Yellow
$cacheDirs = @(".pytest_cache", ".ruff_cache", ".mypy_cache")
foreach ($dir in $cacheDirs) {
    $found = Get-ChildItem -Path . -Recurse -Include $dir -Directory -ErrorAction SilentlyContinue
    if ($found) {
        $found | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed $dir directories" -ForegroundColor Green
    }
}

# Clean TypeScript build info
$tsbuildCount = (Get-ChildItem -Path . -Recurse -Include "*.tsbuildinfo" -ErrorAction SilentlyContinue).Count
if ($tsbuildCount -gt 0) {
    Get-ChildItem -Path . -Recurse -Include "*.tsbuildinfo" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed $tsbuildCount .tsbuildinfo files" -ForegroundColor Green
}

Write-Host "`n✅ Cleanup completed!" -ForegroundColor Green
Write-Host "`n📝 Next steps:" -ForegroundColor Cyan
Write-Host "  1. If node_modules is locked, stop Node.js processes and delete manually" -ForegroundColor White
Write-Host "  2. Run: cd apps\web-next && npm install (or pnpm install)" -ForegroundColor White
Write-Host "  3. Start Docker: .\make.ps1 up-cpu or .\make.ps1 up-gpu" -ForegroundColor White

