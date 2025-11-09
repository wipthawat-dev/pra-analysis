from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import List
from uuid import UUID
from sqlalchemy.orm import Session
from datetime import datetime
import structlog
import uuid
from PIL import Image as PILImage
import io

from apps.amulet_ai_service.services.database import get_db
from apps.amulet_ai_service.services.minio_client import minio_client
from apps.amulet_ai_service.models.database_models import ImportJob, Dataset, Image, DatasetImage
from apps.amulet_ai_service.schemas.admin_schemas import ImportJobCreate, ImportJobResponse

logger = structlog.get_logger()
router = APIRouter(prefix="/v1/admin/import", tags=["import"])

async def process_import_job(job_id: UUID, db: Session):
    """Background task to process MinIO import"""
    try:
        job = db.query(ImportJob).filter(ImportJob.id == job_id).first()
        if not job:
            return
        
        job.status = "running"
        job.started_at = datetime.utcnow()
        db.commit()
        
        bucket = job.minio_bucket
        prefix = job.minio_prefix or ""
        
        # List all objects in MinIO bucket with prefix
        objects = minio_client.list_objects(bucket, prefix=prefix)
        
        # Filter image files
        image_extensions = {".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"}
        image_objects = [obj for obj in objects if any(obj.endswith(ext) for ext in image_extensions)]
        
        job.total_files = len(image_objects)
        db.commit()
        
        imported_count = 0
        failed_count = 0
        errors = []
        
        for obj_name in image_objects:
            try:
                # Download image from MinIO
                image_data = minio_client.download_file(bucket, obj_name)
                
                # Validate image
                img = PILImage.open(io.BytesIO(image_data))
                img.verify()
                img = PILImage.open(io.BytesIO(image_data))  # Reopen after verify
                
                # Determine MIME type
                mime = "image/jpeg" if obj_name.lower().endswith((".jpg", ".jpeg")) else "image/png"
                
                # Create image record
                image_id = uuid.uuid4()
                db_image = Image(
                    id=image_id,
                    source="minio_import",
                    dataset_id=job.dataset_id,
                    mime=mime,
                    minio_path=f"{bucket}/{obj_name}"
                )
                db.add(db_image)
                
                # Link to dataset if provided
                if job.dataset_id:
                    db_dataset_image = DatasetImage(
                        dataset_id=job.dataset_id,
                        image_id=image_id
                    )
                    db.add(db_dataset_image)
                
                imported_count += 1
                
                # Update progress every 10 images
                if imported_count % 10 == 0:
                    job.imported_files = imported_count
                    job.failed_files = failed_count
                    db.commit()
                    
            except Exception as e:
                failed_count += 1
                errors.append({"object": obj_name, "error": str(e)})
                logger.error("import_image_failed", object=obj_name, error=str(e))
        
        # Final commit
        db.commit()
        
        # Update job status
        job.status = "completed"
        job.imported_files = imported_count
        job.failed_files = failed_count
        job.error_log = {"errors": errors[:100]} if errors else None  # Limit to 100 errors
        job.completed_at = datetime.utcnow()
        db.commit()
        
        logger.info("import_job_completed", job_id=str(job_id), imported=imported_count, failed=failed_count)
        
    except Exception as e:
        logger.error("import_job_failed", job_id=str(job_id), error=str(e))
        job = db.query(ImportJob).filter(ImportJob.id == job_id).first()
        if job:
            job.status = "failed"
            job.completed_at = datetime.utcnow()
            job.error_log = {"error": str(e)}
            db.commit()

@router.post("/minio", response_model=ImportJobResponse)
async def create_import_job(
    import_job: ImportJobCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Create a new import job from MinIO"""
    # Validate dataset if provided
    if import_job.dataset_id:
        dataset = db.query(Dataset).filter(Dataset.id == import_job.dataset_id).first()
        if not dataset:
            raise HTTPException(status_code=404, detail="Dataset not found")
    
    # Check if bucket exists
    try:
        if not minio_client.client.bucket_exists(import_job.minio_bucket):
            raise HTTPException(status_code=404, detail=f"MinIO bucket '{import_job.minio_bucket}' not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to check bucket: {str(e)}")
    
    # Create import job
    db_job = ImportJob(
        dataset_id=import_job.dataset_id,
        minio_bucket=import_job.minio_bucket,
        minio_prefix=import_job.minio_prefix,
        status="pending"
    )
    db.add(db_job)
    db.commit()
    db.refresh(db_job)
    
    # Start background import task
    background_tasks.add_task(process_import_job, db_job.id, db)
    
    logger.info("import_job_created", job_id=str(db_job.id), bucket=import_job.minio_bucket)
    return db_job

@router.get("/jobs", response_model=List[ImportJobResponse])
async def list_import_jobs(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """List all import jobs"""
    jobs = db.query(ImportJob).offset(skip).limit(limit).order_by(ImportJob.created_at.desc()).all()
    return jobs

@router.get("/jobs/{job_id}", response_model=ImportJobResponse)
async def get_import_job(job_id: UUID, db: Session = Depends(get_db)):
    """Get import job details"""
    job = db.query(ImportJob).filter(ImportJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Import job not found")
    return job

