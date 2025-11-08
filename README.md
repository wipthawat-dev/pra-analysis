# Pra Analysis (Safe OSS) — Dev Quickstart

1. Copy `.env.example` → `.env` and adjust if needed
2. GPU: `make up-gpu`  or  CPU: `make up-cpu`
3. Initialize vector DB: `make qdrant-init` then seed: `make embed-index`
4. Open Next.js: http://localhost:3000
5. API health: http://localhost:8000/health

Replace Triton stubs with real ONNX/TensorRT models and wire FastAPI → Triton.
