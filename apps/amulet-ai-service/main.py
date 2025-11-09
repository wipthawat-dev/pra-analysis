from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os, io
from PIL import Image
import numpy as np
import uvicorn
from qdrant_client import QdrantClient
from qdrant_client.http.models import Distance, VectorParams
import uuid
from datetime import datetime
from typing import Optional

from apps.amulet_ai_service.services.database import get_db, init_db
from apps.amulet_ai_service.services.minio_client import minio_client
from apps.amulet_ai_service.models.database_models import Image as DBImage, Prediction
from apps.amulet_ai_service.routes import admin, import_route, labeling, training, models, feedback, retraining

API_HOST = os.getenv("API_HOST") or "0.0.0.0"
API_PORT = int(os.getenv("API_PORT") or 8000)
TRITON_URL = os.getenv("TRITON_GRPC_URL") or "mock://cpu-only"
QDRANT_URL = os.getenv("QDRANT_URL") or "http://qdrant:6333"
QDRANT_COLLECTION = os.getenv("QDRANT_COLLECTION") or "amulet_clip_v1"
EMBED_DIM = int(os.getenv("EMBED_DIM") or 768)

app = FastAPI(title="amulet-ai-service", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(admin.router)
app.include_router(import_route.router)
app.include_router(labeling.router)
app.include_router(training.router)
app.include_router(models.router)
app.include_router(feedback.router)
app.include_router(retraining.router)

qdrant = QdrantClient(url=QDRANT_URL)

class AnalyzeResponse(BaseModel):
    verdict: str
    score: float
    model_version: str
    topk: list
    heatmaps: list
    prediction_id: Optional[str] = None

@app.on_event("startup")
def startup_event():
    # Initialize database
    init_db()
    
    # Ensure Qdrant collection exists
    if QDRANT_COLLECTION not in [c.name for c in qdrant.get_collections().collections]:
        qdrant.recreate_collection(
            collection_name=QDRANT_COLLECTION,
            vectors_config=VectorParams(size=EMBED_DIM, distance=Distance.COSINE),
        )

@app.get("/health")
def health():
    return {"ok": True}

MAX_FILE_SIZE_MB = 15
MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024

@app.post("/v1/analyze", response_model=AnalyzeResponse)
async def analyze(file: UploadFile = File(...), db = None):
    from apps.amulet_ai_service.services.database import get_db as get_db_func
    db = next(get_db_func())
    
    # Validate content type
    if not file.content_type:
        raise HTTPException(400, detail="Missing content type")
    
    if file.content_type not in {"image/jpeg", "image/png"}:
        raise HTTPException(400, detail=f"Unsupported file type: {file.content_type}. Only JPEG and PNG are allowed.")
    
    # Read file data
    try:
        data = await file.read()
    except Exception as e:
        raise HTTPException(400, detail=f"Failed to read file: {str(e)}")
    
    # Validate file size
    if len(data) > MAX_FILE_SIZE_BYTES:
        size_mb = len(data) / (1024 * 1024)
        raise HTTPException(400, detail=f"File too large: {size_mb:.2f}MB. Maximum size is {MAX_FILE_SIZE_MB}MB.")
    
    # Validate and process image
    try:
        img = Image.open(io.BytesIO(data)).convert("RGB")
    except Exception as e:
        raise HTTPException(400, detail=f"Invalid image file: {str(e)}")

    # Upload image to MinIO
    image_id = uuid.uuid4()
    object_name = f"uploads/{image_id}.{file.filename.split('.')[-1]}"
    minio_path = minio_client.upload_image("images", object_name, data, file.content_type)
    
    # Save image record to database
    db_image = DBImage(
        id=image_id,
        source="upload",
        mime=file.content_type,
        minio_path=minio_path
    )
    db.add(db_image)
    db.commit()

    # MOCK pipeline; replace with Triton calls
    rng = np.random.default_rng(42)
    embedding = rng.normal(0, 1, size=EMBED_DIM).astype(np.float32)

    results = [
        {"id": f"ref_{i}", "similarity": float(1 - i * 0.1), "thumb_url": ""}
        for i in range(5)
    ]

    response_data = {
        "verdict": "uncertain",
        "score": 0.65,
        "model_version": "v0-mock",
        "topk": results,
        "heatmaps": [],
    }

    # Save prediction to database and MinIO
    prediction_id = uuid.uuid4()
    result_path = f"results/{prediction_id}/result.json"
    minio_client.upload_json("results", result_path, response_data)
    
    db_prediction = Prediction(
        id=prediction_id,
        image_id=image_id,
        model_version="v0-mock",
        verdict="uncertain",
        score=65,
        topk=results,
        heatmaps=[],
        result_path=f"results/{result_path}"
    )
    db.add(db_prediction)
    db.commit()

    response_data["prediction_id"] = str(prediction_id)
    return AnalyzeResponse(**response_data)

if __name__ == "__main__":
    uvicorn.run(app, host=API_HOST, port=API_PORT)
