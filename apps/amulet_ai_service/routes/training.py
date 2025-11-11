from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import List, Optional
from uuid import UUID
from sqlalchemy.orm import Session
from datetime import datetime
import structlog
import uuid

from apps.amulet_ai_service.services.database import get_db
from apps.amulet_ai_service.services.storage_client import storage_client
from apps.amulet_ai_service.models.database_models import TrainingJob, Dataset, Image, Label
from apps.amulet_ai_service.schemas.admin_schemas import TrainingJobCreate, TrainingJobResponse

logger = structlog.get_logger()
router = APIRouter(prefix="/v1/admin/training", tags=["training"])

async def run_training_job_async(job_id: UUID, db: Session):
    """Background task to run training job"""
    try:
        job = db.query(TrainingJob).filter(TrainingJob.id == job_id).first()
        if not job:
            return
        
        job.status = "running"
        job.started_at = datetime.utcnow()
        db.commit()
        
        # TODO: Implement actual training logic
        # This is a placeholder that simulates training
        logger.info("training_started", job_id=str(job_id), model_type=job.model_type)
        
        # Simulate training process
        import time
        import random
        time.sleep(2)  # Simulate training time
        
        # Generate mock metrics
        metrics = {
            "accuracy": random.uniform(0.85, 0.95),
            "loss": random.uniform(0.1, 0.3),
            "epochs": job.config.get("epochs", 10)
        }
        
        # Generate model version
        model_version = f"{job.model_type}-v{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
        
        # Save model artifacts to MinIO (mock)
        model_path = f"models/{model_version}/model.pth"
        logs_path = f"logs/{job_id}/training.log"
        
        # Upload mock model file
        storage_client.upload_json("models", f"{model_version}/config.json", job.config)
        
        # Update job
        job.status = "completed"
        job.completed_at = datetime.utcnow()
        job.metrics = metrics
        job.model_version = model_version
        job.model_path = f"models/{model_path}"
        job.logs_path = f"logs/{logs_path}"
        db.commit()
        
        logger.info("training_completed", job_id=str(job_id), model_version=model_version)
        
    except Exception as e:
        logger.error("training_failed", job_id=str(job_id), error=str(e))
        job = db.query(TrainingJob).filter(TrainingJob.id == job_id).first()
        if job:
            job.status = "failed"
            job.completed_at = datetime.utcnow()
            db.commit()

@router.post("/jobs", response_model=TrainingJobResponse)
async def create_training_job(
    job: TrainingJobCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Create a new training job"""
    # Validate dataset
    dataset = db.query(Dataset).filter(Dataset.id == job.dataset_id).first()
    if not dataset:
        raise HTTPException(status_code=404, detail="Dataset not found")
    
    # Check if dataset has enough labeled images
    labeled_count = db.query(Image).filter(
        Image.dataset_id == job.dataset_id,
        Image.is_labeled == True
    ).count()
    
    if labeled_count < 10:  # Minimum threshold
        raise HTTPException(
            status_code=400,
            detail=f"Dataset needs at least 10 labeled images. Currently has {labeled_count}"
        )
    
    try:
        db_job = TrainingJob(
            dataset_id=job.dataset_id,
            model_type=job.model_type,
            config=job.config,
            status="pending"
        )
        db.add(db_job)
        db.commit()
        db.refresh(db_job)
        
        # Start training in background
        from apps.amulet_ai_service.services.training_service import TrainingService
        training_service = TrainingService(db)
        background_tasks.add_task(
            training_service.run_training_job,
            db_job.id,
            db_job.model_type,
            db_job.config
        )
        
        logger.info("training_job_created", job_id=str(db_job.id), model_type=job.model_type)
        return db_job
    except Exception as e:
        db.rollback()
        logger.error("training_job_creation_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/jobs", response_model=List[TrainingJobResponse])
async def list_training_jobs(
    skip: int = 0,
    limit: int = 100,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """List all training jobs"""
    try:
        query = db.query(TrainingJob)
        if status:
            query = query.filter(TrainingJob.status == status)
        
        jobs = query.order_by(TrainingJob.created_at.desc()).offset(skip).limit(limit).all()
        return jobs
    except Exception as e:
        logger.error("list_jobs_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/jobs/{job_id}", response_model=TrainingJobResponse)
async def get_training_job(job_id: UUID, db: Session = Depends(get_db)):
    """Get training job details"""
    job = db.query(TrainingJob).filter(TrainingJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Training job not found")
    return job

@router.get("/jobs/{job_id}/logs")
async def get_training_logs(job_id: UUID, db: Session = Depends(get_db)):
    """Get training logs"""
    job = db.query(TrainingJob).filter(TrainingJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Training job not found")
    
    if not job.logs_path:
        return {"logs": "No logs available yet"}
    
    try:
        # Download logs from MinIO
        bucket, object_name = job.logs_path.split("/", 1)
        logs_data = storage_client.download_file(bucket, object_name)
        return {"logs": logs_data.decode('utf-8')}
    except Exception as e:
        logger.error("get_logs_failed", error=str(e))
        return {"logs": f"Failed to retrieve logs: {str(e)}"}

@router.get("/jobs/{job_id}/metrics")
async def get_training_metrics(job_id: UUID, db: Session = Depends(get_db)):
    """Get training metrics"""
    job = db.query(TrainingJob).filter(TrainingJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Training job not found")
    
    return job.metrics or {}

@router.post("/jobs/{job_id}/cancel")
async def cancel_training_job(job_id: UUID, db: Session = Depends(get_db)):
    """Cancel a training job"""
    job = db.query(TrainingJob).filter(TrainingJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Training job not found")
    
    if job.status not in ["pending", "running"]:
        raise HTTPException(status_code=400, detail=f"Cannot cancel job with status: {job.status}")
    
    try:
        job.status = "cancelled"
        job.completed_at = datetime.utcnow()
        db.commit()
        
        logger.info("training_job_cancelled", job_id=str(job_id))
        return {"message": "Training job cancelled successfully"}
    except Exception as e:
        db.rollback()
        logger.error("cancel_job_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

