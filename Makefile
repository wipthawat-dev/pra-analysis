.PHONY: up-gpu up-cpu down logs fmt api web qdrant-init embed-index clean help

up-gpu:
	@echo "🚀 Starting Docker containers (GPU)..."
	docker compose -f docker-compose.gpu.yml up -d --build

up-cpu:
	@echo "🚀 Starting Docker containers (CPU)..."
	docker compose -f docker-compose.cpu.yml up -d --build

down:
	@echo "🛑 Stopping Docker containers..."
	docker compose -f docker-compose.gpu.yml down -v || true
	docker compose -f docker-compose.cpu.yml down -v || true
	@echo "✅ Docker cleanup completed!"

logs:
	@echo "📋 Showing Docker logs..."
	@docker compose -f docker-compose.cpu.yml logs -f --tail=200 || \
	 docker compose -f docker-compose.gpu.yml logs -f --tail=200 || \
	 docker compose logs -f --tail=200

fmt:
	@echo "✨ Formatting code..."
	black apps/amulet_ai_service ml || true
	ruff check --fix apps/amulet_ai_service ml || true
	prettier -w apps/web-next || true
	@echo "✅ Code formatting completed"

api:
	@echo "🔧 Starting API server..."
	@echo "   Make sure you have Python dependencies installed:"
	@echo "   pip install -r apps/amulet_ai_service/requirements.txt"
	PYTHONPATH=. uvicorn apps.amulet_ai_service.main:app --reload --host 0.0.0.0 --port 8000

web:
	@echo "🌐 Starting Next.js dev server..."
	@echo "   Make sure you have Node.js dependencies installed:"
	@echo "   cd apps/web-next && npm install (or pnpm install)"
	cd apps/web-next && pnpm dev || npm run dev

qdrant-init:
	@echo "🗄️  Initializing Qdrant..."
	@docker compose -f docker-compose.cpu.yml exec -T api python /app/scripts/qdrant_init.py || \
	 docker compose -f docker-compose.gpu.yml exec -T api python /app/scripts/qdrant_init.py || \
	 (echo "❌ Failed to initialize Qdrant. Make sure containers are running." && exit 1)
	@echo "✅ Qdrant initialized successfully"

embed-index:
	@echo "📊 Embedding and indexing data..."
	@docker compose -f docker-compose.cpu.yml exec -T api python /app/scripts/embed_and_index.py --sample 100 || \
	 docker compose -f docker-compose.gpu.yml exec -T api python /app/scripts/embed_and_index.py --sample 100 || \
	 (echo "❌ Failed to embed and index data. Make sure containers are running." && exit 1)
	@echo "✅ Data embedded and indexed successfully"

clean:
	@echo "🧹 Cleaning project..."
	@powershell -ExecutionPolicy Bypass -File clean.ps1 || \
	 (echo "⚠️  PowerShell not available. Running basic cleanup..." && \
	  rm -rf apps/web-next/.next apps/web-next/node_modules/.cache && \
	  find . -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true && \
	  find . -type f -name "*.pyc" -delete 2>/dev/null || true)

help:
	@echo "Available commands:"
	@echo ""
	@echo "Docker Commands:"
	@echo "  make up-gpu       - Start Docker containers (GPU version with Triton)"
	@echo "  make up-cpu       - Start Docker containers (CPU version, mock Triton)"
	@echo "  make down         - Stop Docker containers and remove volumes"
	@echo "  make logs         - Show Docker logs (follow mode)"
	@echo ""
	@echo "Development Commands:"
	@echo "  make api          - Run API server locally (requires Python deps)"
	@echo "  make web          - Run Next.js dev server locally (requires Node.js deps)"
	@echo "  make fmt          - Format code (black, ruff, prettier)"
	@echo ""
	@echo "Database Commands:"
	@echo "  make qdrant-init  - Initialize Qdrant vector database collection"
	@echo "  make embed-index  - Embed and index sample data (100 samples)"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make clean        - Clean build artifacts and cache files"
	@echo "  make help         - Show this help message"
