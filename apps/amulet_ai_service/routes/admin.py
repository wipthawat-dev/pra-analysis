from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, BackgroundTasks
from typing import List, Optional
from uuid import UUID
from sqlalchemy.orm import Session
from sqlalchemy import func

from apps.amulet_ai_service.services.database import get_db
from apps.amulet_ai_service.services.storage_client import storage_client
from apps.amulet_ai_service.models.database_models import Dataset, Image, DatasetImage, ImportJob
from apps.amulet_ai_service.schemas.admin_schemas import (
    DatasetCreate, DatasetResponse,
    ImportJobCreate, ImportJobResponse
)
import structlog
import uuid
from datetime import datetime

logger = structlog.get_logger()
router = APIRouter(prefix="/v1/admin", tags=["admin"])

@router.get("")
def admin_root():
    """Admin API root endpoint"""
    return {
        "name": "Admin API",
        "endpoints": {
            "datasets": "/v1/admin/datasets",
            "models": "/v1/admin/models",
            "training": "/v1/admin/training",
            "labeling": "/v1/admin/labeling",
            "import": "/v1/admin/import",
            "feedback": "/v1/admin/feedback"
        }
    }

@router.post("/datasets", response_model=DatasetResponse)
async def create_dataset(dataset: DatasetCreate, db: Session = Depends(get_db)):
    """Create a new dataset"""
    try:
        # Generate bucket name if not provided
        bucket_name = dataset.minio_bucket or f"dataset-{uuid.uuid4().hex[:8]}"
        
        # Ensure bucket exists in MinIO
        try:
            storage_client.client.head_bucket(Bucket=bucket_name)
        except:
            storage_client.client.create_bucket(Bucket=bucket_name)
            logger.info("created_dataset_bucket", bucket=bucket_name)
        
        db_dataset = Dataset(
            name=dataset.name,
            description=dataset.description,
            minio_bucket=bucket_name
        )
        db.add(db_dataset)
        db.commit()
        db.refresh(db_dataset)
        
        logger.info("dataset_created", dataset_id=str(db_dataset.id), name=dataset.name)
        return db_dataset
    except Exception as e:
        logger.error("dataset_creation_failed", error=str(e))
        raise HTTPException(status_code=500, detail=f"Failed to create dataset: {str(e)}")

@router.get("/datasets", response_model=List[DatasetResponse])
async def list_datasets(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """List all datasets"""
    try:
        datasets = db.query(Dataset).offset(skip).limit(limit).all()
        return datasets
    except Exception as e:
        logger.error("list_datasets_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/datasets/{dataset_id}", response_model=DatasetResponse)
async def get_dataset(dataset_id: UUID, db: Session = Depends(get_db)):
    """Get dataset details"""
    dataset = db.query(Dataset).filter(Dataset.id == dataset_id).first()
    if not dataset:
        raise HTTPException(status_code=404, detail="Dataset not found")
    return dataset

@router.delete("/datasets/{dataset_id}")
async def delete_dataset(dataset_id: UUID, db: Session = Depends(get_db)):
    """Delete a dataset"""
    dataset = db.query(Dataset).filter(Dataset.id == dataset_id).first()
    if not dataset:
        raise HTTPException(status_code=404, detail="Dataset not found")
    
    try:
        db.delete(dataset)
        db.commit()
        logger.info("dataset_deleted", dataset_id=str(dataset_id))
        return {"message": "Dataset deleted successfully"}
    except Exception as e:
        logger.error("dataset_deletion_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/datasets/{dataset_id}/images")
async def upload_images_to_dataset(
    dataset_id: UUID,
    files: List[UploadFile] = File(...),
    db: Session = Depends(get_db)
):
    """Upload images to a dataset"""
    dataset = db.query(Dataset).filter(Dataset.id == dataset_id).first()
    if not dataset:
        raise HTTPException(status_code=404, detail="Dataset not found")
    
    bucket = dataset.minio_bucket or "images"
    uploaded_images = []
    
    try:
        for file in files:
            # Validate file type
            if file.content_type not in ["image/jpeg", "image/png"]:
                continue
            
            # Read file data
            data = await file.read()
            
            # Generate object name
            image_id = uuid.uuid4()
            object_name = f"{dataset_id}/{image_id}.{file.filename.split('.')[-1]}"
            
            # Upload to MinIO
            storage_path = storage_client.upload_image(bucket, object_name, data, file.content_type)
            
            # Save to database
            db_image = Image(
                id=image_id,
                source="dataset",
                dataset_id=dataset_id,
                mime=file.content_type,
                minio_path=storage_path
            )
            db.add(db_image)
            
            # Link to dataset
            db_dataset_image = DatasetImage(
                dataset_id=dataset_id,
                image_id=image_id
            )
            db.add(db_dataset_image)
            
            uploaded_images.append({
                "id": str(image_id),
                "filename": file.filename,
                "minio_path": minio_path
            })
        
        db.commit()
        logger.info("images_uploaded", dataset_id=str(dataset_id), count=len(uploaded_images))
        return {"uploaded": len(uploaded_images), "images": uploaded_images}
    except Exception as e:
        db.rollback()
        logger.error("image_upload_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/datasets/{dataset_id}/images")
async def list_dataset_images(
    dataset_id: UUID,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """List images in a dataset"""
    dataset = db.query(Dataset).filter(Dataset.id == dataset_id).first()
    if not dataset:
        raise HTTPException(status_code=404, detail="Dataset not found")
    
    try:
        images = db.query(Image).join(DatasetImage).filter(
            DatasetImage.dataset_id == dataset_id
        ).offset(skip).limit(limit).all()
        
        return [{
            "id": str(img.id),
            "minio_path": img.minio_path,
            "mime": img.mime,
            "is_labeled": img.is_labeled,
            "upload_ts": img.upload_ts
        } for img in images]
    except Exception as e:
        logger.error("list_images_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

