# PowerShell script to run tests

Write-Host "=== Pra Analysis Test Suite ===" -ForegroundColor Cyan
Write-Host ""

# Check if test containers are running
Write-Host "Checking test environment..." -ForegroundColor Yellow
$postgresRunning = docker ps --filter "name=postgres-test" --filter "status=running" -q
$minioRunning = docker ps --filter "name=minio-test" --filter "status=running" -q
$qdrantRunning = docker ps --filter "name=qdrant-test" --filter "status=running" -q

if (-not $postgresRunning -or -not $minioRunning -or -not $qdrantRunning) {
    Write-Host "Starting test containers..." -ForegroundColor Yellow
    docker-compose -f docker-compose.test.yml up -d
    
    Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

Write-Host "Test environment ready!" -ForegroundColor Green
Write-Host ""

# Run backend tests
Write-Host "=== Running Backend Tests ===" -ForegroundColor Cyan
Set-Location apps/amulet-ai-service

# Install test dependencies if needed
if (-not (Test-Path "venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
}

.\venv\Scripts\Activate.ps1

Write-Host "Installing dependencies..." -ForegroundColor Yellow

# Check if requirements files exist
if (-not (Test-Path "requirements.txt")) {
    Write-Host "Error: requirements.txt not found!" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path "requirements-test.txt")) {
    Write-Host "Error: requirements-test.txt not found!" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

# Install dependencies with error handling
Write-Host "Installing main dependencies from requirements.txt..." -ForegroundColor Cyan
pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install requirements.txt" -ForegroundColor Red
    exit 1
}

Write-Host "Installing test dependencies from requirements-test.txt..." -ForegroundColor Cyan
pip install -r requirements-test.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install requirements-test.txt" -ForegroundColor Red
    exit 1
}

Write-Host "Dependencies installed successfully!" -ForegroundColor Green

Write-Host ""
Write-Host "Running unit tests..." -ForegroundColor Yellow
pytest tests/ -v -m "unit or api or database" --cov --cov-report=html --cov-report=term

Write-Host ""
Write-Host "Running integration tests..." -ForegroundColor Yellow
pytest tests/ -v -m "integration" --tb=short

Write-Host ""
Write-Host "Test coverage report generated in htmlcov/" -ForegroundColor Green

Set-Location ../..

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Backend tests completed!" -ForegroundColor Green
Write-Host ""
Write-Host "To view coverage report, open: apps/amulet-ai-service/htmlcov/index.html" -ForegroundColor Yellow
Write-Host ""
Write-Host "To stop test containers: docker-compose -f docker-compose.test.yml down" -ForegroundColor Yellow

