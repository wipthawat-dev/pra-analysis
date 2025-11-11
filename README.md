# Pra Analysis (Safe OSS) — Dev Quickstart

Pra Analysis is an AI-powered image authenticity analysis system built with Next.js, FastAPI, NVIDIA Triton, Qdrant, PostgreSQL, and SeaweedFS.

## Prerequisites

- **Docker Desktop** (for containerized services)
- **Python 3.11+** (for local API development)
- **Node.js 18+** and **pnpm** or **npm** (for local web development)
- **PowerShell** (Windows) or **Make** (Linux/Mac/WSL)

## Quick Start

### 1. Environment Setup

Copy the example environment file and adjust if needed:

```powershell
Copy-Item .env.example .env
```

Or on Linux/Mac:
```bash
cp .env.example .env
```

### 2. Start Docker Services

**For GPU (with NVIDIA Triton):**
```powershell
.\make.ps1 up-gpu
```

**For CPU (mock Triton, development):**
```powershell
.\make.ps1 up-cpu
```

### 3. Initialize Vector Database

```powershell
.\make.ps1 qdrant-init
.\make.ps1 embed-index
```

### 4. Access Services

- **Next.js Frontend**: http://localhost:3000
- **FastAPI Backend**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **API Health Check**: http://localhost:8000/health
- **SeaweedFS S3 Gateway**: http://localhost:8333 (S3-compatible API)
- **SeaweedFS Filer**: http://localhost:8888 (File system interface)
- **SeaweedFS Master**: http://localhost:9333 (Cluster status)
- **Qdrant Dashboard**: http://localhost:6333/dashboard

### 5. Check System Health

```powershell
.\make.ps1 health
```

**CPU Mode should have 11 containers:**
```powershell
docker ps
```

You should see:
- ✅ pra-analysis-web-1
- ✅ pra-analysis-api-1
- ✅ pra-analysis-postgres-1
- ✅ pra-analysis-qdrant-1
- ✅ seaweedfs-master1, seaweedfs-master2, seaweedfs-master3 (HA cluster)
- ✅ seaweedfs-volume1, seaweedfs-volume2 (Storage nodes)
- ✅ seaweedfs-filer (File system interface)
- ✅ seaweedfs-s3 (S3-compatible gateway)

**GPU Mode should have 12 containers** (adds Triton)

## Available Commands

### PowerShell (Windows)

Since `make` is not available on Windows by default, use `.\make.ps1 <command>`:

#### Docker Commands
- `.\make.ps1 up-gpu` - Start Docker containers (GPU version with Triton)
- `.\make.ps1 up-cpu` - Start Docker containers (CPU version, mock Triton)
- `.\make.ps1 up-prod` - Start Docker containers (Production mode)
- `.\make.ps1 down` - Stop Docker containers and remove volumes
- `.\make.ps1 logs` - Show Docker logs (follow mode)

#### Development Commands
- `.\make.ps1 api` - Run API server locally (requires Python deps)
- `.\make.ps1 web` - Run Next.js dev server locally (requires Node.js deps)
- `.\make.ps1 fmt` - Format code (black, ruff, prettier)

#### Database Commands
- `.\make.ps1 qdrant-init` - Initialize Qdrant vector database collection
- `.\make.ps1 embed-index` - Embed and index sample data (100 samples)

#### SeaweedFS Commands
- `.\make.ps1 backup` - Backup SeaweedFS data and PostgreSQL
- `.\make.ps1 restore` - Restore from backup
- `.\make.ps1 health` - Check system health status

#### Utility Commands
- `.\make.ps1 clean` - Clean build artifacts and cache files
- `.\make.ps1 help` - Show all available commands

### Make (Linux/Mac/WSL)

If you have `make` installed (via Chocolatey, WSL, or Git Bash):

```bash
make up-cpu      # Start containers (CPU)
make up-gpu      # Start containers (GPU)
make down        # Stop containers
make logs        # Show logs
make api         # Run API locally
make web         # Run web locally
make qdrant-init # Initialize Qdrant
make embed-index # Index sample data
make clean       # Clean artifacts
make help        # Show help
```

## Project Structure

```
pra-analysis/
├── apps/
│   ├── amulet-ai-service/    # FastAPI backend
│   │   ├── main.py           # API entry point
│   │   ├── routes/           # API routes
│   │   ├── services/         # Business logic
│   │   └── models/           # Database models
│   └── web-next/             # Next.js frontend
│       ├── app/              # App router pages
│       ├── components/       # React components
│       └── lib/              # Utilities
├── ml/                       # ML models and inference
│   ├── inference/            # Triton model repository
│   ├── training/             # Training scripts
│   └── xai/                  # Explainable AI utilities
├── scripts/                  # Utility scripts
│   ├── qdrant_init.py       # Initialize Qdrant
│   └── embed_and_index.py   # Embed and index data
├── shared/                   # Shared schemas and types
├── docker-compose.cpu.yml   # CPU Docker compose
├── docker-compose.gpu.yml   # GPU Docker compose
├── make.ps1                 # PowerShell make script
└── Makefile                 # Unix make script
```

## Services

### Backend (FastAPI)
- **Port**: 8000
- **Framework**: FastAPI with Python 3.11
- **Database**: PostgreSQL 15
- **Vector DB**: Qdrant
- **Object Storage**: SeaweedFS (S3-compatible, Apache-2.0)
- **ML Inference**: NVIDIA Triton (GPU) or Mock (CPU)

### Frontend (Next.js)
- **Port**: 3000
- **Framework**: Next.js 14 with App Router
- **UI**: Shadcn UI + Tailwind CSS
- **State**: Server Components + nuqs for URL state

### Infrastructure Services
- **PostgreSQL**: Port 5432 (Database)
- **Qdrant**: Port 6333 (Vector Database)
- **SeaweedFS Master Cluster**: Ports 9333, 9334, 9335 (HA cluster with 3 masters)
- **SeaweedFS Volume Servers**: Ports 8080, 8081 (Data storage)
- **SeaweedFS Filer**: Port 8888 (File system interface)
- **SeaweedFS S3**: Port 8333 (S3-compatible API)
- **Triton** (GPU only): Port 8001 (Inference Server)

## Development Setup

### Local API Development

1. Install Python dependencies:
```bash
pip install -r apps/amulet-ai-service/requirements.txt
```

2. Set environment variables (copy from `.env.example`)

3. Run API locally:
```powershell
.\make.ps1 api
```

### Local Web Development

1. Install Node.js dependencies:
```bash
cd apps/web-next
npm install  # or pnpm install
```

2. Run web server locally:
```powershell
.\make.ps1 web
```

## Environment Variables

See `.env.example` for all available environment variables. Key variables:

- `API_HOST`, `API_PORT` - API server configuration
- `TRITON_GRPC_URL` - Triton inference server URL
- `QDRANT_URL`, `QDRANT_COLLECTION`, `EMBED_DIM` - Vector database config
- `S3_ENDPOINT`, `S3_ACCESS_KEY`, `S3_SECRET_KEY` - SeaweedFS S3 configuration
- `POSTGRES_*` - Database configuration
- `NEXT_PUBLIC_API_BASE` - Frontend API base URL

## Troubleshooting

### Docker Issues
- Ensure Docker Desktop is running
- Check if ports are already in use (8000, 3000, 5432, 6333, 8333, 9333-9335)
- Verify all containers are running: `docker ps` or `.\make.ps1 health`
- Check logs: `.\make.ps1 logs` or `docker logs <container-name>`
- Try clean restart: `.\make.ps1 down` → `docker system prune -f` → `.\make.ps1 up-cpu`

### Container Not Starting
If a container shows `Exited (1)`:
```powershell
# Check system health
.\make.ps1 health

# Check specific container logs
docker logs seaweedfs-master1 --tail 50
docker logs pra-analysis-api-1 --tail 50

# If SeaweedFS cluster has issues
.\make.ps1 down
docker volume prune -f
.\make.ps1 up-cpu
# Wait for SeaweedFS cluster to initialize (30 seconds)

# If API can't connect to SeaweedFS
docker restart pra-analysis-api-1
```

### API Issues
- Verify Python dependencies are installed
- Check environment variables in `.env`
- Ensure PostgreSQL, Qdrant, and SeaweedFS containers are running
- Run `.\make.ps1 health` to check all services
- Wait 30-45 seconds for SeaweedFS cluster to be fully ready

### Web Issues
- Verify Node.js dependencies are installed
- Check `NEXT_PUBLIC_API_BASE` matches your API URL
- Clear `.next` cache: `.\make.ps1 clean`

## Production Deployment

For production deployment on Ubuntu with high availability:

1. Copy repository to server: `git clone <repo> /opt/pra-analysis`
2. Run deployment script: `sudo bash /opt/pra-analysis/scripts/deploy-ubuntu.sh`
3. Configure firewall and SSL/TLS as needed
4. Setup automated backups: `sudo bash /opt/pra-analysis/scripts/backup-seaweedfs.sh`

See `DEPLOYMENT_UBUNTU.md` for detailed production deployment guide.

## Notes

- **CPU Mode**: Uses mock Triton responses for development without GPU
- **GPU Mode**: Requires NVIDIA GPU with Docker GPU support
- **Database**: PostgreSQL schema is auto-initialized from `shared/schemas/sql.sql`
- **Vector DB**: Qdrant collection is auto-created on API startup
- **SeaweedFS**: Distributed storage with 3-master HA cluster for production reliability
- **Backups**: Automated backup and restore scripts available in `scripts/`
- **Future**: Replace Triton stubs with real ONNX/TensorRT models

## License

Safe OSS - Apache-2.0, MIT, BSD-3 compatible licenses only.
