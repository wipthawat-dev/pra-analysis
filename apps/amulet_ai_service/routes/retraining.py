from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import Optional
from uuid import UUID
from sqlalchemy.orm import Session
import structlog

from apps.amulet_ai_service.services.database import get_db
from apps.amulet_ai_service.services.retraining_service import RetrainingService
from apps.amulet_ai_service.services.training_service import TrainingService

logger = structlog.get_logger()
router = APIRouter(prefix="/v1/admin/training", tags=["retraining"])

@router.post("/retrain")
async def trigger_retraining(
    model_type: str = "classifier",
    min_feedback: int = 10,
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db)
):
    """Trigger automated retraining from feedback"""
    try:
        retraining_service = RetrainingService(db)
        job_id = retraining_service.auto_retrain_from_feedback(model_type, min_feedback)
        
        if not job_id:
            return {
                "message": "Insufficient feedback for retraining",
                "triggered": False
            }
        
        # Start training in background
        if background_tasks:
            training_service = TrainingService(db)
            from apps.amulet_ai_service.models.database_models import TrainingJob
            job = db.query(TrainingJob).filter(TrainingJob.id == job_id).first()
            if job:
                background_tasks.add_task(
                    training_service.run_training_job,
                    job_id,
                    job.model_type,
                    job.config
                )
        
        return {
            "message": "Retraining triggered successfully",
            "job_id": str(job_id),
            "triggered": True
        }
    except Exception as e:
        logger.error("retraining_trigger_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

