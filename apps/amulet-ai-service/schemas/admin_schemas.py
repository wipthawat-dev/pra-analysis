from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from uuid import UUID

# Dataset Schemas
class DatasetCreate(BaseModel):
    name: str
    description: Optional[str] = None
    minio_bucket: Optional[str] = None

class DatasetResponse(BaseModel):
    id: UUID
    name: str
    description: Optional[str]
    status: str
    minio_bucket: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Import Job Schemas
class ImportJobCreate(BaseModel):
    dataset_id: Optional[UUID] = None
    minio_bucket: str
    minio_prefix: Optional[str] = None

class ImportJobResponse(BaseModel):
    id: UUID
    dataset_id: Optional[UUID]
    minio_bucket: str
    minio_prefix: Optional[str]
    status: str
    total_files: Optional[int]
    imported_files: int
    failed_files: int
    error_log: Optional[Dict[str, Any]]
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True

# Labeling Schemas
class LabelCreate(BaseModel):
    image_id: UUID
    verdict: str = Field(..., pattern="^(authentic|fake|uncertain)$")
    bbox: Optional[Dict[str, Any]] = None
    confidence: Optional[float] = Field(None, ge=0, le=1)
    notes: Optional[str] = None

class LabelResponse(BaseModel):
    id: UUID
    image_id: UUID
    labeler_id: Optional[UUID]
    verdict: str
    bbox: Optional[Dict[str, Any]]
    confidence: Optional[float]
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ImageLabelingResponse(BaseModel):
    id: UUID
    minio_path: Optional[str]
    mime: Optional[str]
    is_labeled: bool
    labels: List[LabelResponse]

    class Config:
        from_attributes = True

# Training Job Schemas
class TrainingJobCreate(BaseModel):
    dataset_id: UUID
    model_type: str = Field(..., pattern="^(detector|embedder|classifier)$")
    config: Dict[str, Any]

class TrainingJobResponse(BaseModel):
    id: UUID
    dataset_id: Optional[UUID]
    model_type: str
    config: Dict[str, Any]
    status: str
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    metrics: Optional[Dict[str, Any]]
    model_version: Optional[str]
    model_path: Optional[str]
    logs_path: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

# Model Schemas
class ModelResponse(BaseModel):
    id: UUID
    version: str
    model_type: str
    training_job_id: Optional[UUID]
    minio_path: str
    config: Optional[Dict[str, Any]]
    metrics: Optional[Dict[str, Any]]
    is_deployed: bool
    deployed_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True

class ModelEvaluateRequest(BaseModel):
    test_dataset_id: UUID
    metrics: Optional[List[str]] = None

class EvaluationResult(BaseModel):
    accuracy: Optional[float] = None
    precision: Optional[float] = None
    recall: Optional[float] = None
    f1_score: Optional[float] = None
    roc_auc: Optional[float] = None
    confusion_matrix: Optional[List[List[int]]] = None
    result_path: Optional[str] = None  # Path to full results in MinIO

# Feedback Schemas
class FeedbackCreate(BaseModel):
    prediction_id: UUID
    is_correct: bool
    correct_verdict: Optional[str] = None
    notes: Optional[str] = None

class FeedbackResponse(BaseModel):
    id: UUID
    prediction_id: UUID
    user_id: Optional[UUID]
    is_correct: Optional[bool]
    correct_verdict: Optional[str]
    notes: Optional[str]
    created_at: datetime
    reviewed_at: Optional[datetime]
    reviewed_by: Optional[UUID]

    class Config:
        from_attributes = True

