from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from uuid import UUID
from sqlalchemy.orm import Session
from datetime import datetime
import structlog

from apps.amulet_ai_service.services.database import get_db
from apps.amulet_ai_service.models.database_models import Feedback, Prediction
from apps.amulet_ai_service.schemas.admin_schemas import FeedbackCreate, FeedbackResponse

logger = structlog.get_logger()
router = APIRouter(prefix="/v1", tags=["feedback"])

@router.post("/feedback", response_model=FeedbackResponse)
async def create_feedback(
    feedback: FeedbackCreate,
    user_id: Optional[UUID] = None,
    db: Session = Depends(get_db)
):
    """Create feedback for a prediction"""
    # Verify prediction exists
    prediction = db.query(Prediction).filter(Prediction.id == feedback.prediction_id).first()
    if not prediction:
        raise HTTPException(status_code=404, detail="Prediction not found")
    
    try:
        db_feedback = Feedback(
            prediction_id=feedback.prediction_id,
            user_id=user_id,
            is_correct=feedback.is_correct,
            correct_verdict=feedback.correct_verdict,
            notes=feedback.notes
        )
        db.add(db_feedback)
        db.commit()
        db.refresh(db_feedback)
        
        logger.info("feedback_created", feedback_id=str(db_feedback.id), prediction_id=str(feedback.prediction_id))
        return db_feedback
    except Exception as e:
        db.rollback()
        logger.error("feedback_creation_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/admin/feedback", response_model=List[FeedbackResponse])
async def list_feedback(
    skip: int = 0,
    limit: int = 100,
    reviewed: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    """List all feedback"""
    try:
        query = db.query(Feedback)
        
        if reviewed is not None:
            if reviewed:
                query = query.filter(Feedback.reviewed_at.isnot(None))
            else:
                query = query.filter(Feedback.reviewed_at.is_(None))
        
        feedbacks = query.order_by(Feedback.created_at.desc()).offset(skip).limit(limit).all()
        return feedbacks
    except Exception as e:
        logger.error("list_feedback_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/admin/feedback/{feedback_id}/approve")
async def approve_feedback(
    feedback_id: UUID,
    reviewer_id: Optional[UUID] = None,
    auto_retrain: bool = False,
    db: Session = Depends(get_db)
):
    """Approve/review feedback"""
    feedback = db.query(Feedback).filter(Feedback.id == feedback_id).first()
    if not feedback:
        raise HTTPException(status_code=404, detail="Feedback not found")
    
    try:
        feedback.reviewed_at = datetime.utcnow()
        feedback.reviewed_by = reviewer_id
        db.commit()
        
        # Trigger auto-retraining if requested
        if auto_retrain:
            from services.retraining_service import RetrainingService
            retraining_service = RetrainingService(db)
            retraining_service.auto_retrain_from_feedback()
        
        logger.info("feedback_approved", feedback_id=str(feedback_id), auto_retrain=auto_retrain)
        return {"message": "Feedback approved successfully"}
    except Exception as e:
        db.rollback()
        logger.error("approve_feedback_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/admin/feedback/stats")
async def get_feedback_stats(db: Session = Depends(get_db)):
    """Get feedback statistics"""
    try:
        total = db.query(Feedback).count()
        reviewed = db.query(Feedback).filter(Feedback.reviewed_at.isnot(None)).count()
        unreviewed = total - reviewed
        
        # Incorrect predictions
        incorrect = db.query(Feedback).filter(Feedback.is_correct == False).count()
        correct = db.query(Feedback).filter(Feedback.is_correct == True).count()
        
        return {
            "total": total,
            "reviewed": reviewed,
            "unreviewed": unreviewed,
            "incorrect": incorrect,
            "correct": correct
        }
    except Exception as e:
        logger.error("get_feedback_stats_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

