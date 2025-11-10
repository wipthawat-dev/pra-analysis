# Pra Analysis (Safe OSS) — Dev Quickstart

Pra Analysis is an AI-powered image authenticity analysis system built with Next.js, FastAPI, NVIDIA Triton, Qdrant, and PostgreSQL.

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
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)
- **Qdrant Dashboard**: http://localhost:6333/dashboard

## Available Commands

### PowerShell (Windows)

Since `make` is not available on Windows by default, use `.\make.ps1 <command>`:

#### Docker Commands
- `.\make.ps1 up-gpu` - Start Docker containers (GPU version with Triton)
- `.\make.ps1 up-cpu` - Start Docker containers (CPU version, mock Triton)
- `.\make.ps1 down` - Stop Docker containers and remove volumes
- `.\make.ps1 logs` - Show Docker logs (follow mode)

#### Development Commands
- `.\make.ps1 api` - Run API server locally (requires Python deps)
- `.\make.ps1 web` - Run Next.js dev server locally (requires Node.js deps)
- `.\make.ps1 fmt` - Format code (black, ruff, prettier)

#### Database Commands
- `.\make.ps1 qdrant-init` - Initialize Qdrant vector database collection
- `.\make.ps1 embed-index` - Embed and index sample data (100 samples)

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
- **Object Storage**: MinIO
- **ML Inference**: NVIDIA Triton (GPU) or Mock (CPU)

### Frontend (Next.js)
- **Port**: 3000
- **Framework**: Next.js 14 with App Router
- **UI**: Shadcn UI + Tailwind CSS
- **State**: Server Components + nuqs for URL state

### Infrastructure Services
- **PostgreSQL**: Port 5432
- **Qdrant**: Port 6333
- **MinIO**: Ports 9000 (API), 9001 (Console)
- **Triton** (GPU only): Port 8001

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
- `MINIO_*` - Object storage configuration
- `POSTGRES_*` - Database configuration
- `NEXT_PUBLIC_API_BASE` - Frontend API base URL

## Troubleshooting

### Docker Issues
- Ensure Docker Desktop is running
- Check if ports are already in use
- Try `.\make.ps1 down` then restart

### API Issues
- Verify Python dependencies are installed
- Check environment variables in `.env`
- Ensure PostgreSQL and Qdrant containers are running

### Web Issues
- Verify Node.js dependencies are installed
- Check `NEXT_PUBLIC_API_BASE` matches your API URL
- Clear `.next` cache: `.\make.ps1 clean`

## Notes

- **CPU Mode**: Uses mock Triton responses for development without GPU
- **GPU Mode**: Requires NVIDIA GPU with Docker GPU support
- **Database**: PostgreSQL schema is auto-initialized from `shared/schemas/sql.sql`
- **Vector DB**: Qdrant collection is auto-created on API startup
- **Future**: Replace Triton stubs with real ONNX/TensorRT models

## License

Safe OSS - Apache-2.0, MIT, BSD-3 compatible licenses only.
