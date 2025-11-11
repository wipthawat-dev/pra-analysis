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
    Write-Host "  up-prod      - Start Docker containers (Production mode)" -ForegroundColor White
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
    Write-Host "SeaweedFS Commands:" -ForegroundColor Yellow
    Write-Host "  backup       - Backup SeaweedFS data and PostgreSQL" -ForegroundColor White
    Write-Host "  restore      - Restore from backup" -ForegroundColor White
    Write-Host "  health       - Check system health status" -ForegroundColor White
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
        black apps/amulet_ai_service ml 2>$null
        ruff check --fix apps/amulet_ai_service ml 2>$null
        prettier -w apps/web-next 2>$null
        Write-Host "✅ Code formatting completed" -ForegroundColor Green
    }
    "api" {
        Write-Host "🔧 Starting API server..." -ForegroundColor Cyan
        Write-Host "   Make sure you have Python dependencies installed:" -ForegroundColor Yellow
        Write-Host "   pip install -r apps/amulet_ai_service/requirements.txt" -ForegroundColor Gray
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
    "up-prod" {
        Write-Host "🚀 Starting Docker containers (Production)..." -ForegroundColor Cyan
        
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
        
        if (-not (Test-Path "docker-compose.production.yml")) {
            Write-Host "⚠️  docker-compose.production.yml not found!" -ForegroundColor Red
            Write-Host "   This command is intended for production deployments." -ForegroundColor Yellow
            return
        }
        
        docker compose -f docker-compose.production.yml up -d --build
        
        Write-Host "`n✅ Production containers started!" -ForegroundColor Green
        Write-Host "   Wait a few moments for services to initialize, then check health:" -ForegroundColor Yellow
        Write-Host "   .\make.ps1 health" -ForegroundColor Gray
    }
    "backup" {
        Write-Host "💾 Starting backup..." -ForegroundColor Cyan
        
        if (Test-Path "scripts\backup-seaweedfs.sh") {
            Write-Host "⚠️  Backup script is designed for Linux/Ubuntu" -ForegroundColor Yellow
            Write-Host "   On Windows with Docker Desktop, you can backup manually:" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "   1. Stop containers: .\make.ps1 down" -ForegroundColor Gray
            Write-Host "   2. Copy Docker volumes from:" -ForegroundColor Gray
            Write-Host "      %USERPROFILE%\.docker\volumes\" -ForegroundColor Gray
            Write-Host "   3. Export PostgreSQL:" -ForegroundColor Gray
            Write-Host "      docker exec postgres pg_dumpall -U postgres > backup.sql" -ForegroundColor Gray
            Write-Host ""
            Write-Host "   For Linux/Ubuntu, use:" -ForegroundColor Yellow
            Write-Host "   sudo bash scripts/backup-seaweedfs.sh" -ForegroundColor Gray
        } else {
            Write-Host "❌ Backup script not found: scripts\backup-seaweedfs.sh" -ForegroundColor Red
        }
    }
    "restore" {
        Write-Host "📦 Starting restore..." -ForegroundColor Cyan
        
        if (Test-Path "scripts\restore-seaweedfs.sh") {
            Write-Host "⚠️  Restore script is designed for Linux/Ubuntu" -ForegroundColor Yellow
            Write-Host "   For Linux/Ubuntu, use:" -ForegroundColor Yellow
            Write-Host "   sudo bash scripts/restore-seaweedfs.sh <backup_timestamp>" -ForegroundColor Gray
            Write-Host ""
            Write-Host "   On Windows, restore manually from volume backups" -ForegroundColor Yellow
        } else {
            Write-Host "❌ Restore script not found: scripts\restore-seaweedfs.sh" -ForegroundColor Red
        }
    }
    "health" {
        Write-Host "🏥 Checking system health..." -ForegroundColor Cyan
        Write-Host ""
        
        # Check Docker
        try {
            docker ps 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ Docker is not running" -ForegroundColor Red
                return
            }
        } catch {
            Write-Host "❌ Docker is not running" -ForegroundColor Red
            return
        }
        
        # Check containers
        $containers = @(
            @{Name="seaweedfs-master1"; Port=9333; Endpoint="/cluster/status"},
            @{Name="seaweedfs-master2"; Port=9334; Endpoint="/cluster/status"},
            @{Name="seaweedfs-master3"; Port=9335; Endpoint="/cluster/status"},
            @{Name="seaweedfs-volume1"; Port=8080; Endpoint="/status"},
            @{Name="seaweedfs-volume2"; Port=8081; Endpoint="/status"},
            @{Name="seaweedfs-filer"; Port=8888; Endpoint="/"},
            @{Name="seaweedfs-s3"; Port=8333; Endpoint="/"},
            @{Name="postgres"; Port=5432; Endpoint=""},
            @{Name="qdrant"; Port=6333; Endpoint="/healthz"},
            @{Name="api"; Port=8000; Endpoint="/health"},
            @{Name="web"; Port=3000; Endpoint="/"}
        )
        
        $allHealthy = $true
        
        foreach ($container in $containers) {
            $running = docker ps --format "{{.Names}}" | Select-String -Pattern $container.Name -Quiet
            
            if ($running) {
                if ($container.Endpoint) {
                    try {
                        $response = Invoke-WebRequest -Uri "http://localhost:$($container.Port)$($container.Endpoint)" -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
                        if ($response.StatusCode -eq 200) {
                            Write-Host "✓ $($container.Name.PadRight(20))" -ForegroundColor Green -NoNewline
                            Write-Host " Running and healthy" -ForegroundColor Gray
                        } else {
                            Write-Host "⚠ $($container.Name.PadRight(20))" -ForegroundColor Yellow -NoNewline
                            Write-Host " Running but not responding" -ForegroundColor Gray
                            $allHealthy = $false
                        }
                    } catch {
                        Write-Host "⚠ $($container.Name.PadRight(20))" -ForegroundColor Yellow -NoNewline
                        Write-Host " Running but not responding" -ForegroundColor Gray
                        $allHealthy = $false
                    }
                } else {
                    Write-Host "✓ $($container.Name.PadRight(20))" -ForegroundColor Green -NoNewline
                    Write-Host " Running" -ForegroundColor Gray
                }
            } else {
                Write-Host "✗ $($container.Name.PadRight(20))" -ForegroundColor Red -NoNewline
                Write-Host " Not running" -ForegroundColor Gray
                $allHealthy = $false
            }
        }
        
        Write-Host ""
        if ($allHealthy) {
            Write-Host "✅ System is healthy!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Some components have issues" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "For detailed health check on Linux/Ubuntu:" -ForegroundColor Cyan
        Write-Host "  bash scripts/health-check.sh -v" -ForegroundColor Gray
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

