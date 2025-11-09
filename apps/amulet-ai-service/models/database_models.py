from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Text, JSON
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from apps.amulet_ai_service.services.database import Base

class Image(Base):
    __tablename__ = "images"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=True)
    upload_ts = Column(DateTime(timezone=True), server_default=func.now())
    mime = Column(String, nullable=True)
    exif = Column(JSONB, nullable=True)
    c2pa_status = Column(String, nullable=True)
    source = Column(String, nullable=True)  # 'upload', 'minio_import', 'dataset'
    dataset_id = Column(UUID(as_uuid=True), ForeignKey("datasets.id"), nullable=True)
    is_labeled = Column(Boolean, default=False)
    minio_path = Column(String, nullable=True)
    metadata_path = Column(String, nullable=True)
    
    # Relationships
    dataset = relationship("Dataset", back_populates="images")
    predictions = relationship("Prediction", back_populates="image")
    labels = relationship("Label", back_populates="image")
    dataset_images = relationship("DatasetImage", back_populates="image")

class Prediction(Base):
    __tablename__ = "predictions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    image_id = Column(UUID(as_uuid=True), ForeignKey("images.id"), nullable=False)
    model_version = Column(String, nullable=True)
    verdict = Column(String, nullable=True)
    score = Column(Integer, nullable=True)
    topk = Column(JSONB, nullable=True)
    heatmaps = Column(JSONB, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    result_path = Column(String, nullable=True)  # Path to full result JSON in MinIO
    
    # Relationships
    image = relationship("Image", back_populates="predictions")
    feedback = relationship("Feedback", back_populates="prediction")

class Dataset(Base):
    __tablename__ = "datasets"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    status = Column(String, default="active")
    minio_bucket = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationships
    images = relationship("Image", back_populates="dataset")
    dataset_images = relationship("DatasetImage", back_populates="dataset")
    training_jobs = relationship("TrainingJob", back_populates="dataset")
    import_jobs = relationship("ImportJob", back_populates="dataset")

class DatasetImage(Base):
    __tablename__ = "dataset_images"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dataset_id = Column(UUID(as_uuid=True), ForeignKey("datasets.id", ondelete="CASCADE"), nullable=False)
    image_id = Column(UUID(as_uuid=True), ForeignKey("images.id", ondelete="CASCADE"), nullable=False)
    metadata = Column(JSONB, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    dataset = relationship("Dataset", back_populates="dataset_images")
    image = relationship("Image", back_populates="dataset_images")

class Label(Base):
    __tablename__ = "labels"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    image_id = Column(UUID(as_uuid=True), ForeignKey("images.id", ondelete="CASCADE"), nullable=False)
    labeler_id = Column(UUID(as_uuid=True), nullable=True)
    verdict = Column(String, nullable=False)  # 'authentic', 'fake', 'uncertain'
    bbox = Column(JSONB, nullable=True)
    confidence = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationships
    image = relationship("Image", back_populates="labels")

class LabelingSession(Base):
    __tablename__ = "labeling_sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    labeler_id = Column(UUID(as_uuid=True), nullable=True)
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)
    images_labeled = Column(Integer, default=0)

class TrainingJob(Base):
    __tablename__ = "training_jobs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dataset_id = Column(UUID(as_uuid=True), ForeignKey("datasets.id"), nullable=True)
    model_type = Column(String, nullable=False)  # 'detector', 'embedder', 'classifier'
    config = Column(JSONB, nullable=False)
    status = Column(String, default="pending")  # 'pending', 'running', 'completed', 'failed', 'cancelled'
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    metrics = Column(JSONB, nullable=True)
    model_version = Column(String, nullable=True)
    model_path = Column(String, nullable=True)  # Path to model artifacts in MinIO
    logs_path = Column(String, nullable=True)  # Path to training logs in MinIO
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    dataset = relationship("Dataset", back_populates="training_jobs")
    model = relationship("Model", back_populates="training_job", uselist=False)

class Model(Base):
    __tablename__ = "models"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    version = Column(String, nullable=False, unique=True)
    model_type = Column(String, nullable=False)  # 'detector', 'embedder', 'classifier'
    training_job_id = Column(UUID(as_uuid=True), ForeignKey("training_jobs.id"), nullable=True)
    minio_path = Column(String, nullable=False)  # Path to model files in MinIO
    config = Column(JSONB, nullable=True)
    metrics = Column(JSONB, nullable=True)
    is_deployed = Column(Boolean, default=False)
    deployed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    training_job = relationship("TrainingJob", back_populates="model")

class Feedback(Base):
    __tablename__ = "feedback"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    prediction_id = Column(UUID(as_uuid=True), ForeignKey("predictions.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(UUID(as_uuid=True), nullable=True)
    is_correct = Column(Boolean, nullable=True)
    correct_verdict = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    reviewed_by = Column(UUID(as_uuid=True), nullable=True)
    
    # Relationships
    prediction = relationship("Prediction", back_populates="feedback")

class ImportJob(Base):
    __tablename__ = "import_jobs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dataset_id = Column(UUID(as_uuid=True), ForeignKey("datasets.id"), nullable=True)
    minio_bucket = Column(String, nullable=False)
    minio_prefix = Column(String, nullable=True)
    status = Column(String, default="pending")  # 'pending', 'running', 'completed', 'failed'
    total_files = Column(Integer, nullable=True)
    imported_files = Column(Integer, default=0)
    failed_files = Column(Integer, default=0)
    error_log = Column(JSONB, nullable=True)
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    dataset = relationship("Dataset", back_populates="import_jobs")

