# PowerShell script to replace Makefile commands
# Usage: .\make.ps1 <command>
# Example: .\make.ps1 up-cpu

param(
    [Parameter(Mandatory=$true)]
    [string]$Command
)

function Show-Help {
    Write-Host "Available commands:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Docker Commands:" -ForegroundColor Yellow
    Write-Host "  up-gpu       - Start Docker containers (GPU version with Triton)" -ForegroundColor White
    Write-Host "  up-cpu       - Start Docker containers (CPU version, mock Triton)" -ForegroundColor White
    Write-Host "  down         - Stop Docker containers and remove volumes" -ForegroundColor White
    Write-Host "  logs         - Show Docker logs (follow mode)" -ForegroundColor White
    Write-Host ""
    Write-Host "Development Commands:" -ForegroundColor Yellow
    Write-Host "  api          - Run API server locally (requires Python deps)" -ForegroundColor White
    Write-Host "  web          - Run Next.js dev server locally (requires Node.js deps)" -ForegroundColor White
    Write-Host "  fmt          - Format code (black, ruff, prettier)" -ForegroundColor White
    Write-Host ""
    Write-Host "Database Commands:" -ForegroundColor Yellow
    Write-Host "  qdrant-init  - Initialize Qdrant vector database collection" -ForegroundColor White
    Write-Host "  embed-index  - Embed and index sample data (100 samples)" -ForegroundColor White
    Write-Host ""
    Write-Host "Utility Commands:" -ForegroundColor Yellow
    Write-Host "  clean        - Clean build artifacts and cache files" -ForegroundColor White
    Write-Host "  help         - Show this help message" -ForegroundColor White
}

switch ($Command) {
    "up-gpu" {
        Write-Host "🚀 Starting Docker containers (GPU)..." -ForegroundColor Cyan
        
        # Check if Docker is running
        try {
            docker ps 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "⚠️  Docker Desktop is not running!" -ForegroundColor Red
                Write-Host "   Please start Docker Desktop first, then try again." -ForegroundColor Yellow
                return
            }
        } catch {
            Write-Host "⚠️  Docker Desktop is not running!" -ForegroundColor Red
            Write-Host "   Please start Docker Desktop first, then try again." -ForegroundColor Yellow
            return
        }
        
        docker compose -f docker-compose.gpu.yml up -d --build
    }
    "up-cpu" {
        Write-Host "🚀 Starting Docker containers (CPU)..." -ForegroundColor Cyan
        
        # Check if Docker is running
        try {
            docker ps 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "⚠️  Docker Desktop is not running!" -ForegroundColor Red
                Write-Host "   Please start Docker Desktop first, then try again." -ForegroundColor Yellow
                return
            }
        } catch {
            Write-Host "⚠️  Docker Desktop is not running!" -ForegroundColor Red
            Write-Host "   Please start Docker Desktop first, then try again." -ForegroundColor Yellow
            return
        }
        
        docker compose -f docker-compose.cpu.yml up -d --build
    }
    "down" {
        Write-Host "🛑 Stopping Docker containers..." -ForegroundColor Yellow
        
        # Check if Docker is running
        $dockerRunning = $false
        try {
            docker ps 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $dockerRunning = $true
            }
        } catch {
            $dockerRunning = $false
        }
        
        if (-not $dockerRunning) {
            Write-Host "⚠️  Docker Desktop is not running or not connected!" -ForegroundColor Yellow
            Write-Host "   Please start Docker Desktop first, then try again." -ForegroundColor Yellow
            return
        }
        
        # Check for running containers
        $runningContainers = docker ps --format "{{.Names}}" 2>$null
        if ($runningContainers) {
            Write-Host "📋 Found running containers:" -ForegroundColor Cyan
            $runningContainers | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
        } else {
            Write-Host "ℹ️  No containers are currently running" -ForegroundColor Cyan
        }
        
        # Stop containers
        Write-Host "`n🛑 Stopping GPU compose..." -ForegroundColor Yellow
        $gpuResult = docker compose -f docker-compose.gpu.yml down -v 2>&1
        if ($LASTEXITCODE -ne 0 -and $gpuResult -notmatch "No such file") {
            Write-Host "   GPU compose: $($gpuResult -join ' ')" -ForegroundColor Gray
        }
        
        Write-Host "🛑 Stopping CPU compose..." -ForegroundColor Yellow
        $cpuResult = docker compose -f docker-compose.cpu.yml down -v 2>&1
        if ($LASTEXITCODE -ne 0 -and $cpuResult -notmatch "No such file") {
            Write-Host "   CPU compose: $($cpuResult -join ' ')" -ForegroundColor Gray
        }
        
        Write-Host "`n✅ Docker cleanup completed!" -ForegroundColor Green
        
        # Show remaining containers
        $remaining = docker ps -a --format "{{.Names}}" 2>$null
        if ($remaining) {
            Write-Host "`n📋 Remaining containers (stopped):" -ForegroundColor Cyan
            $remaining | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
        }
    }
    "logs" {
        Write-Host "📋 Showing Docker logs..." -ForegroundColor Cyan
        # Try to detect which compose file is being used
        if (Test-Path "docker-compose.gpu.yml") {
            docker compose -f docker-compose.gpu.yml logs -f --tail=200
        } elseif (Test-Path "docker-compose.cpu.yml") {
            docker compose -f docker-compose.cpu.yml logs -f --tail=200
        } else {
            docker compose logs -f --tail=200
        }
    }
    "fmt" {
        Write-Host "✨ Formatting code..." -ForegroundColor Cyan
        black apps/amulet-ai-service ml 2>$null
        ruff check --fix apps/amulet-ai-service ml 2>$null
        prettier -w apps/web-next 2>$null
        Write-Host "✅ Code formatting completed" -ForegroundColor Green
    }
    "api" {
        Write-Host "🔧 Starting API server..." -ForegroundColor Cyan
        Write-Host "   Make sure you have Python dependencies installed:" -ForegroundColor Yellow
        Write-Host "   pip install -r apps/amulet-ai-service/requirements.txt" -ForegroundColor Gray
        Set-Location $PSScriptRoot
        $env:PYTHONPATH = "."
        uvicorn apps.amulet_ai_service.main:app --reload --host 0.0.0.0 --port 8000
    }
    "web" {
        Write-Host "🌐 Starting Next.js dev server..." -ForegroundColor Cyan
        Write-Host "   Make sure you have Node.js dependencies installed:" -ForegroundColor Yellow
        Write-Host "   cd apps/web-next && npm install (or pnpm install)" -ForegroundColor Gray
        Set-Location apps/web-next
        if (Get-Command pnpm -ErrorAction SilentlyContinue) {
            pnpm dev
        } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
            npm run dev
        } else {
            Write-Host "❌ Neither pnpm nor npm found. Please install Node.js." -ForegroundColor Red
            exit 1
        }
    }
    "qdrant-init" {
        Write-Host "🗄️  Initializing Qdrant..." -ForegroundColor Cyan
        # Try both compose files
        $result = docker compose -f docker-compose.cpu.yml exec -T api python /app/scripts/qdrant_init.py 2>&1
        if ($LASTEXITCODE -ne 0) {
            $result = docker compose -f docker-compose.gpu.yml exec -T api python /app/scripts/qdrant_init.py 2>&1
        }
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Qdrant initialized successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to initialize Qdrant. Make sure containers are running." -ForegroundColor Red
            Write-Host "   Run: .\make.ps1 up-cpu or .\make.ps1 up-gpu" -ForegroundColor Yellow
        }
    }
    "embed-index" {
        Write-Host "📊 Embedding and indexing data..." -ForegroundColor Cyan
        # Try both compose files
        $result = docker compose -f docker-compose.cpu.yml exec -T api python /app/scripts/embed_and_index.py --sample 100 2>&1
        if ($LASTEXITCODE -ne 0) {
            $result = docker compose -f docker-compose.gpu.yml exec -T api python /app/scripts/embed_and_index.py --sample 100 2>&1
        }
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Data embedded and indexed successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to embed and index data. Make sure containers are running." -ForegroundColor Red
            Write-Host "   Run: .\make.ps1 up-cpu or .\make.ps1 up-gpu" -ForegroundColor Yellow
        }
    }
    "clean" {
        Write-Host "🧹 Cleaning project..." -ForegroundColor Cyan
        if (Test-Path "clean.ps1") {
            & .\clean.ps1
        } else {
            Write-Host "⚠️  clean.ps1 not found. Running basic cleanup..." -ForegroundColor Yellow
            # Basic cleanup
            if (Test-Path "apps\web-next\.next") {
                Remove-Item -Recurse -Force "apps\web-next\.next" -ErrorAction SilentlyContinue
            }
            Get-ChildItem -Path . -Recurse -Include "__pycache__" -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path . -Recurse -Include "*.pyc" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "✅ Basic cleanup completed" -ForegroundColor Green
        }
    }
    "help" {
        Show-Help
    }
    default {
        Write-Host "❌ Unknown command: $Command" -ForegroundColor Red
        Write-Host ""
        Show-Help
        exit 1
    }
}

