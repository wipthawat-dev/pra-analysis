.PHONY: up-gpu up-cpu down logs fmt api web qdrant-init embed-index

up-gpu:
	docker compose -f docker-compose.gpu.yml up -d --build

up-cpu:
	docker compose -f docker-compose.cpu.yml up -d --build

down:
	docker compose -f docker-compose.gpu.yml down || true
	docker compose -f docker-compose.cpu.yml down || true

logs:
	docker compose logs -f --tail=200

fmt:
	black apps/amulet-ai-service ml || true
	ruff check --fix apps/amulet-ai-service ml || true
	prettier -w apps/web-next || true

api:
	uvicorn apps.amulet_ai_service.main:app --reload --port 8000

web:
	cd apps/web-next && pnpm dev

qdrant-init:
	docker compose exec api python /app/scripts/qdrant_init.py

embed-index:
	docker compose exec api python /app/scripts/embed_and_index.py --sample 100
