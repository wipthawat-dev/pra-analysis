import os
from typing import List, Dict, Any
from uuid import UUID
from sqlalchemy.orm import Session
import structlog
from datetime import datetime

logger = structlog.get_logger()

class RetrainingService:
    """Service for automated retraining based on feedback"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def collect_misclassified_images(self, limit: int = 100) -> List[UUID]:
        """Collect images that were misclassified based on feedback"""
        try:
            from models.database_models import Feedback, Prediction, Image
            
            # Get feedback where prediction was incorrect
            incorrect_feedbacks = self.db.query(Feedback).filter(
                Feedback.is_correct == False,
                Feedback.reviewed_at.isnot(None)
            ).limit(limit).all()
            
            image_ids = []
            for feedback in incorrect_feedbacks:
                prediction = self.db.query(Prediction).filter(
                    Prediction.id == feedback.prediction_id
                ).first()
                if prediction:
                    image_ids.append(prediction.image_id)
            
            logger.info("misclassified_images_collected", count=len(image_ids))
            return image_ids
            
        except Exception as e:
            logger.error("collect_misclassified_failed", error=str(e))
            return []
    
    def create_retraining_dataset(self, dataset_name: str, image_ids: List[UUID]) -> UUID:
        """Create a new dataset version for retraining"""
        try:
            from models.database_models import Dataset, DatasetImage, Image
            from apps.amulet_ai_service.services.storage_client import storage_client
            import uuid
            
            # Create new dataset
            bucket_name = f"retrain-{uuid.uuid4().hex[:8]}"
            try:
                storage_client.client.head_bucket(Bucket=bucket_name)
            except:
                storage_client.client.create_bucket(Bucket=bucket_name)
            
            db_dataset = Dataset(
                name=dataset_name,
                description=f"Retraining dataset created from feedback at {datetime.utcnow().isoformat()}",
                minio_bucket=bucket_name,
                status="active"
            )
            self.db.add(db_dataset)
            self.db.commit()
            self.db.refresh(db_dataset)
            
            # Link images to dataset
            for image_id in image_ids:
                image = self.db.query(Image).filter(Image.id == image_id).first()
                if image:
                    db_dataset_image = DatasetImage(
                        dataset_id=db_dataset.id,
                        image_id=image_id
                    )
                    self.db.add(db_dataset_image)
            
            self.db.commit()
            
            logger.info("retraining_dataset_created", dataset_id=str(db_dataset.id), image_count=len(image_ids))
            return db_dataset.id
            
        except Exception as e:
            self.db.rollback()
            logger.error("create_retraining_dataset_failed", error=str(e))
            raise
    
    def trigger_retraining(self, dataset_id: UUID, model_type: str, config: Dict[str, Any]) -> UUID:
        """Trigger a retraining job"""
        try:
            from models.database_models import TrainingJob
            
            # Create training job
            db_job = TrainingJob(
                dataset_id=dataset_id,
                model_type=model_type,
                config=config,
                status="pending"
            )
            self.db.add(db_job)
            self.db.commit()
            self.db.refresh(db_job)
            
            logger.info("retraining_triggered", job_id=str(db_job.id), dataset_id=str(dataset_id))
            return db_job.id
            
        except Exception as e:
            self.db.rollback()
            logger.error("trigger_retraining_failed", error=str(e))
            raise
    
    def auto_retrain_from_feedback(self, model_type: str = "classifier", min_feedback: int = 10):
        """Automatically trigger retraining if enough incorrect feedback is collected"""
        try:
            from models.database_models import Feedback
            
            # Count incorrect feedback
            incorrect_count = self.db.query(Feedback).filter(
                Feedback.is_correct == False,
                Feedback.reviewed_at.isnot(None)
            ).count()
            
            if incorrect_count < min_feedback:
                logger.info("insufficient_feedback_for_retraining", count=incorrect_count, min_required=min_feedback)
                return None
            
            # Collect misclassified images
            image_ids = self.collect_misclassified_images(limit=1000)
            
            if len(image_ids) < min_feedback:
                logger.info("insufficient_images_for_retraining", count=len(image_ids))
                return None
            
            # Create retraining dataset
            dataset_name = f"retrain-{model_type}-{datetime.utcnow().strftime('%Y%m%d')}"
            dataset_id = self.create_retraining_dataset(dataset_name, image_ids)
            
            # Trigger training job
            config = {
                "epochs": 20,
                "batch_size": 32,
                "learning_rate": 0.001,
                "retrain": True
            }
            
            job_id = self.trigger_retraining(dataset_id, model_type, config)
            
            logger.info("auto_retraining_triggered", job_id=str(job_id), dataset_id=str(dataset_id))
            return job_id
            
        except Exception as e:
            logger.error("auto_retrain_failed", error=str(e))
            return None

