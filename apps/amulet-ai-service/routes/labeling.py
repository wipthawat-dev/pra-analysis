from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from uuid import UUID
from sqlalchemy.orm import Session
from sqlalchemy import func

from apps.amulet_ai_service.services.database import get_db
from apps.amulet_ai_service.services.minio_client import minio_client
from apps.amulet_ai_service.models.database_models import Label, Image, LabelingSession
from apps.amulet_ai_service.schemas.admin_schemas import (
    LabelCreate, LabelResponse, ImageLabelingResponse
)
import structlog
from datetime import datetime

logger = structlog.get_logger()
router = APIRouter(prefix="/v1/admin/labeling", tags=["labeling"])

@router.get("/queue", response_model=List[ImageLabelingResponse])
async def get_labeling_queue(
    limit: int = 20,
    dataset_id: Optional[UUID] = None,
    db: Session = Depends(get_db)
):
    """Get images that need labeling"""
    try:
        query = db.query(Image).filter(Image.is_labeled == False)
        
        if dataset_id:
            query = query.filter(Image.dataset_id == dataset_id)
        
        images = query.limit(limit).all()
        
        result = []
        for img in images:
            # Get labels for this image
            labels = db.query(Label).filter(Label.image_id == img.id).all()
            
            # Generate presigned URL for image
            presigned_url = None
            if img.minio_path:
                try:
                    bucket, object_name = img.minio_path.split("/", 1)
                    presigned_url = minio_client.get_presigned_url(bucket, object_name)
                except:
                    pass
            
            result.append({
                "id": str(img.id),
                "minio_path": img.minio_path,
                "presigned_url": presigned_url,
                "mime": img.mime,
                "is_labeled": img.is_labeled,
                "labels": [LabelResponse.from_orm(l) for l in labels]
            })
        
        return result
    except Exception as e:
        logger.error("get_labeling_queue_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{image_id}", response_model=LabelResponse)
async def create_label(
    image_id: UUID,
    label: LabelCreate,
    labeler_id: Optional[UUID] = None,
    db: Session = Depends(get_db)
):
    """Create a label for an image"""
    # Verify image exists
    image = db.query(Image).filter(Image.id == image_id).first()
    if not image:
        raise HTTPException(status_code=404, detail="Image not found")
    
    try:
        db_label = Label(
            image_id=image_id,
            labeler_id=labeler_id or label.labeler_id if hasattr(label, 'labeler_id') else None,
            verdict=label.verdict,
            bbox=label.bbox,
            confidence=label.confidence,
            notes=label.notes
        )
        db.add(db_label)
        
        # Mark image as labeled
        image.is_labeled = True
        db.commit()
        db.refresh(db_label)
        
        logger.info("label_created", label_id=str(db_label.id), image_id=str(image_id))
        return db_label
    except Exception as e:
        db.rollback()
        logger.error("label_creation_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{image_id}/labels", response_model=List[LabelResponse])
async def get_image_labels(image_id: UUID, db: Session = Depends(get_db)):
    """Get all labels for an image"""
    image = db.query(Image).filter(Image.id == image_id).first()
    if not image:
        raise HTTPException(status_code=404, detail="Image not found")
    
    labels = db.query(Label).filter(Label.image_id == image_id).all()
    return labels

@router.post("/batch", response_model=List[LabelResponse])
async def create_batch_labels(
    labels: List[LabelCreate],
    labeler_id: Optional[UUID] = None,
    db: Session = Depends(get_db)
):
    """Create multiple labels at once"""
    created_labels = []
    
    try:
        for label_data in labels:
            image = db.query(Image).filter(Image.id == label_data.image_id).first()
            if not image:
                continue
            
            db_label = Label(
                image_id=label_data.image_id,
                labeler_id=labeler_id,
                verdict=label_data.verdict,
                bbox=label_data.bbox,
                confidence=label_data.confidence,
                notes=label_data.notes
            )
            db.add(db_label)
            image.is_labeled = True
            created_labels.append(db_label)
        
        db.commit()
        for label in created_labels:
            db.refresh(label)
        
        logger.info("batch_labels_created", count=len(created_labels))
        return created_labels
    except Exception as e:
        db.rollback()
        logger.error("batch_label_creation_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/stats")
async def get_labeling_stats(
    dataset_id: Optional[UUID] = None,
    db: Session = Depends(get_db)
):
    """Get labeling statistics"""
    try:
        query = db.query(Image)
        if dataset_id:
            query = query.filter(Image.dataset_id == dataset_id)
        
        total_images = query.count()
        labeled_images = query.filter(Image.is_labeled == True).count()
        unlabeled_images = total_images - labeled_images
        
        # Label distribution
        label_query = db.query(Label.verdict, func.count(Label.id))
        if dataset_id:
            label_query = label_query.join(Image).filter(Image.dataset_id == dataset_id)
        
        label_dist = label_query.group_by(Label.verdict).all()
        
        return {
            "total_images": total_images,
            "labeled_images": labeled_images,
            "unlabeled_images": unlabeled_images,
            "label_distribution": {verdict: count for verdict, count in label_dist}
        }
    except Exception as e:
        logger.error("get_stats_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

