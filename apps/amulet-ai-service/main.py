from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os, io
from PIL import Image
import numpy as np
import uvicorn
from qdrant_client import QdrantClient
from qdrant_client.http.models import Distance, VectorParams

API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", 8000))
TRITON_URL = os.getenv("TRITON_GRPC_URL", "mock://cpu-only")
QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
QDRANT_COLLECTION = os.getenv("QDRANT_COLLECTION", "amulet_clip_v1")
EMBED_DIM = int(os.getenv("EMBED_DIM", 768))

app = FastAPI(title="amulet-ai-service", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

qdrant = QdrantClient(url=QDRANT_URL)

class AnalyzeResponse(BaseModel):
    verdict: str
    score: float
    model_version: str
    topk: list
    heatmaps: list

@app.on_event("startup")
def ensure_collection():
    if QDRANT_COLLECTION not in [c.name for c in qdrant.get_collections().collections]:
        qdrant.recreate_collection(
            collection_name=QDRANT_COLLECTION,
            vectors_config=VectorParams(size=EMBED_DIM, distance=Distance.COSINE),
        )

@app.get("/health")
def health():
    return {"ok": True}

@app.post("/v1/analyze", response_model=AnalyzeResponse)
async def analyze(file: UploadFile = File(...)):
    if file.content_type not in {"image/jpeg", "image/png"}:
        raise HTTPException(400, detail="Unsupported file type")
    data = await file.read()
    img = Image.open(io.BytesIO(data)).convert("RGB")

    # MOCK pipeline; replace with Triton calls
    rng = np.random.default_rng(42)
    embedding = rng.normal(0, 1, size=EMBED_DIM).astype(np.float32)

    results = [
        {"id": f"ref_{i}", "similarity": float(1 - i * 0.1), "thumb_url": ""}
        for i in range(5)
    ]

    return AnalyzeResponse(
        verdict="uncertain",
        score=0.65,
        model_version="v0-mock",
        topk=results,
        heatmaps=[],
    )

if __name__ == "__main__":
    uvicorn.run(app, host=API_HOST, port=API_PORT)
