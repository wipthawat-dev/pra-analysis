from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import List, Optional
from uuid import UUID
from sqlalchemy.orm import Session
import structlog

from apps.amulet_ai_service.services.database import get_db
from apps.amulet_ai_service.services.minio_client import minio_client
from apps.amulet_ai_service.models.database_models import Model, TrainingJob
from apps.amulet_ai_service.schemas.admin_schemas import (
    ModelResponse, ModelEvaluateRequest, EvaluationResult
)

logger = structlog.get_logger()
router = APIRouter(prefix="/v1/admin/models", tags=["models"])

@router.get("", response_model=List[ModelResponse])
async def list_models(
    model_type: Optional[str] = None,
    is_deployed: Optional[bool] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """List all models"""
    try:
        query = db.query(Model)
        
        if model_type:
            query = query.filter(Model.model_type == model_type)
        if is_deployed is not None:
            query = query.filter(Model.is_deployed == is_deployed)
        
        models = query.order_by(Model.created_at.desc()).offset(skip).limit(limit).all()
        return models
    except Exception as e:
        logger.error("list_models_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{version}", response_model=ModelResponse)
async def get_model(version: str, db: Session = Depends(get_db)):
    """Get model details"""
    model = db.query(Model).filter(Model.version == version).first()
    if not model:
        raise HTTPException(status_code=404, detail="Model not found")
    return model

@router.post("/{version}/evaluate", response_model=EvaluationResult)
async def evaluate_model(
    version: str,
    request: ModelEvaluateRequest,
    db: Session = Depends(get_db)
):
    """Evaluate a model on a test dataset"""
    model = db.query(Model).filter(Model.version == version).first()
    if not model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    # TODO: Implement actual evaluation logic
    # This is a placeholder
    logger.info("evaluation_started", model_version=version, dataset_id=str(request.test_dataset_id))
    
    # Mock evaluation results
    import random
    results = {
        "accuracy": random.uniform(0.85, 0.95),
        "precision": random.uniform(0.80, 0.90),
        "recall": random.uniform(0.85, 0.95),
        "f1_score": random.uniform(0.85, 0.90),
        "roc_auc": random.uniform(0.90, 0.98),
        "confusion_matrix": [[100, 10], [5, 85]]
    }
    
    # Save results to MinIO
    result_path = f"results/evaluation/{version}/{request.test_dataset_id}/results.json"
    minio_client.upload_json("results", result_path, results)
    
    return EvaluationResult(
        **results,
        result_path=f"results/{result_path}"
    )

@router.post("/{version}/deploy")
async def deploy_model(version: str, db: Session = Depends(get_db)):
    """Deploy a model"""
    model = db.query(Model).filter(Model.version == version).first()
    if not model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    try:
        # Un-deploy currently deployed model of same type
        deployed_models = db.query(Model).filter(
            Model.model_type == model.model_type,
            Model.is_deployed == True
        ).all()
        
        for deployed in deployed_models:
            deployed.is_deployed = False
        
        # Deploy new model
        from datetime import datetime
        model.is_deployed = True
        model.deployed_at = datetime.utcnow()
        db.commit()
        
        logger.info("model_deployed", version=version)
        return {"message": f"Model {version} deployed successfully"}
    except Exception as e:
        db.rollback()
        logger.error("deploy_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{version}/metrics")
async def get_model_metrics(version: str, db: Session = Depends(get_db)):
    """Get model metrics"""
    model = db.query(Model).filter(Model.version == version).first()
    if not model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    return model.metrics or {}

