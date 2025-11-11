import pytest
import os
import sys
import uuid
from typing import Generator
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool
from io import BytesIO
from PIL import Image as PILImage

# Add parent directory to path so we can import from the package
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Set test environment variables
os.environ["USE_SQLITE"] = "true"  # Use SQLite for testing (no psycopg2 needed)
os.environ["API_HOST"] = "0.0.0.0"
os.environ["API_PORT"] = "8001"
os.environ["TRITON_GRPC_URL"] = "mock://test"
os.environ["QDRANT_URL"] = "http://localhost:6334"
os.environ["QDRANT_COLLECTION"] = "test_collection"
os.environ["EMBED_DIM"] = "768"
os.environ["POSTGRES_USER"] = "testuser"
os.environ["POSTGRES_PASSWORD"] = "testpass"
os.environ["POSTGRES_DB"] = "testdb"
os.environ["POSTGRES_HOST"] = "localhost"
os.environ["POSTGRES_PORT"] = "5433"
os.environ["S3_ENDPOINT"] = "localhost:9010"
os.environ["S3_ACCESS_KEY"] = "testminio"
os.environ["S3_SECRET_KEY"] = "testminio123"
os.environ["S3_SECURE"] = "false"
os.environ["S3_REGION"] = "us-east-1"

from services.database import Base, get_db, engine
from models.database_models import (
    Image, Prediction, Dataset, DatasetImage, Label, TrainingJob, Model, Feedback, ImportJob
)

# Use the engine from services.database (already configured with SQLite for testing)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="session", autouse=True)
def setup_test_database():
    """Setup test database schema before all tests"""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    """Create a fresh database session for each test"""
    connection = engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db_session: Session) -> Generator[TestClient, None, None]:
    """Create a test client with database override"""
    from main import app
    
    def override_get_db():
        try:
            yield db_session
        finally:
            pass
    
    app.dependency_overrides[get_db] = override_get_db
    
    with TestClient(app) as test_client:
        yield test_client
    
    app.dependency_overrides.clear()


@pytest.fixture
def sample_image() -> BytesIO:
    """Create a sample image for testing"""
    img = PILImage.new('RGB', (100, 100), color='red')
    img_bytes = BytesIO()
    img.save(img_bytes, format='JPEG')
    img_bytes.seek(0)
    return img_bytes


@pytest.fixture
def large_image() -> BytesIO:
    """Create a large image (>15MB) for testing"""
    # Create a 4000x4000 image which should be > 15MB
    img = PILImage.new('RGB', (4000, 4000), color='blue')
    img_bytes = BytesIO()
    img.save(img_bytes, format='JPEG', quality=100)
    img_bytes.seek(0)
    return img_bytes


@pytest.fixture
def corrupted_image() -> BytesIO:
    """Create a corrupted image for testing"""
    corrupted_data = b"This is not a valid image file"
    return BytesIO(corrupted_data)


@pytest.fixture
def sample_dataset(db_session: Session) -> Dataset:
    """Create a sample dataset"""
    dataset = Dataset(
        name="Test Dataset",
        description="A test dataset",
        minio_bucket="test-bucket",
        status="active"
    )
    db_session.add(dataset)
    db_session.commit()
    db_session.refresh(dataset)
    return dataset


@pytest.fixture
def sample_image_record(db_session: Session, sample_dataset: Dataset) -> Image:
    """Create a sample image record"""
    image = Image(
        id=uuid.uuid4(),
        source="upload",
        mime="image/jpeg",
        minio_path="test-bucket/test.jpg",
        dataset_id=sample_dataset.id,
        is_labeled=False
    )
    db_session.add(image)
    db_session.commit()
    db_session.refresh(image)
    return image


@pytest.fixture
def labeled_image_record(db_session: Session, sample_dataset: Dataset) -> Image:
    """Create a labeled image record"""
    image = Image(
        id=uuid.uuid4(),
        source="upload",
        mime="image/jpeg",
        minio_path="test-bucket/labeled.jpg",
        dataset_id=sample_dataset.id,
        is_labeled=True
    )
    db_session.add(image)
    db_session.commit()
    
    # Add label
    label = Label(
        image_id=image.id,
        verdict="authentic",
        confidence=0.95,
        notes="Test label"
    )
    db_session.add(label)
    db_session.commit()
    db_session.refresh(image)
    return image


@pytest.fixture
def sample_prediction(db_session: Session, sample_image_record: Image) -> Prediction:
    """Create a sample prediction"""
    prediction = Prediction(
        id=uuid.uuid4(),
        image_id=sample_image_record.id,
        model_version="v0-test",
        verdict="authentic",
        score=85,
        topk=[{"id": "ref_1", "similarity": 0.95, "thumb_url": ""}],
        heatmaps=[],
        result_path="results/test/result.json"
    )
    db_session.add(prediction)
    db_session.commit()
    db_session.refresh(prediction)
    return prediction


@pytest.fixture
def sample_training_job(db_session: Session, sample_dataset: Dataset) -> TrainingJob:
    """Create a sample training job"""
    job = TrainingJob(
        dataset_id=sample_dataset.id,
        model_type="detector",
        config={"epochs": 10, "batch_size": 32},
        status="pending"
    )
    db_session.add(job)
    db_session.commit()
    db_session.refresh(job)
    return job


@pytest.fixture
def sample_model(db_session: Session, sample_training_job: TrainingJob) -> Model:
    """Create a sample model"""
    model = Model(
        version="detector-v20231109",
        model_type="detector",
        training_job_id=sample_training_job.id,
        minio_path="models/detector-v20231109/model.pth",
        config={"architecture": "resnet50"},
        metrics={"accuracy": 0.92, "loss": 0.15},
        is_deployed=False
    )
    db_session.add(model)
    db_session.commit()
    db_session.refresh(model)
    return model


@pytest.fixture
def sample_feedback(db_session: Session, sample_prediction: Prediction) -> Feedback:
    """Create sample feedback"""
    feedback = Feedback(
        prediction_id=sample_prediction.id,
        is_correct=False,
        correct_verdict="fake",
        notes="This is actually fake"
    )
    db_session.add(feedback)
    db_session.commit()
    db_session.refresh(feedback)
    return feedback


@pytest.fixture
def multiple_datasets(db_session: Session) -> list[Dataset]:
    """Create multiple datasets for testing"""
    datasets = []
    for i in range(5):
        dataset = Dataset(
            name=f"Dataset {i+1}",
            description=f"Test dataset {i+1}",
            minio_bucket=f"test-bucket-{i+1}",
            status="active"
        )
        db_session.add(dataset)
        datasets.append(dataset)
    db_session.commit()
    for dataset in datasets:
        db_session.refresh(dataset)
    return datasets


@pytest.fixture
def dataset_with_images(db_session: Session, sample_dataset: Dataset) -> tuple[Dataset, list[Image]]:
    """Create a dataset with multiple images"""
    images = []
    for i in range(10):
        image = Image(
            id=uuid.uuid4(),
            source="upload",
            mime="image/jpeg",
            minio_path=f"test-bucket/image_{i}.jpg",
            dataset_id=sample_dataset.id,
            is_labeled=i < 5  # First 5 are labeled
        )
        db_session.add(image)
        images.append(image)
        
        if i < 5:
            label = Label(
                image_id=image.id,
                verdict="authentic" if i % 2 == 0 else "fake",
                confidence=0.90
            )
            db_session.add(label)
    
    db_session.commit()
    for image in images:
        db_session.refresh(image)
    
    return sample_dataset, images

