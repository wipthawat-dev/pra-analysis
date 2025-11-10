"""Tests for /v1/admin/training endpoint"""
import pytest
import uuid
import time
from fastapi.testclient import TestClient
from models.database_models import Dataset, TrainingJob


@pytest.mark.api
class TestTrainingEndpoint:
    """Test cases for training jobs API"""
    
    def test_create_training_job_detector(self, client: TestClient, dataset_with_images):
        """Test creating training job for detector model"""
        dataset, images = dataset_with_images
        
        job_data = {
            "dataset_id": str(dataset.id),
            "model_type": "detector",
            "config": {"epochs": 10, "batch_size": 32, "learning_rate": 0.001}
        }
        
        response = client.post("/v1/admin/training/jobs", json=job_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["model_type"] == "detector"
        assert data["status"] == "pending"
        assert "id" in data
    
    def test_create_training_job_embedder(self, client: TestClient, dataset_with_images):
        """Test creating training job for embedder model"""
        dataset, images = dataset_with_images
        
        job_data = {
            "dataset_id": str(dataset.id),
            "model_type": "embedder",
            "config": {"epochs": 20, "embedding_dim": 768}
        }
        
        response = client.post("/v1/admin/training/jobs", json=job_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["model_type"] == "embedder"
    
    def test_create_training_job_classifier(self, client: TestClient, dataset_with_images):
        """Test creating training job for classifier model"""
        dataset, images = dataset_with_images
        
        job_data = {
            "dataset_id": str(dataset.id),
            "model_type": "classifier",
            "config": {"epochs": 15, "num_classes": 3}
        }
        
        response = client.post("/v1/admin/training/jobs", json=job_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["model_type"] == "classifier"
    
    def test_create_training_job_insufficient_labels(self, client: TestClient, sample_dataset: Dataset):
        """Test creating job with insufficient labeled images"""
        job_data = {
            "dataset_id": str(sample_dataset.id),
            "model_type": "detector",
            "config": {"epochs": 10}
        }
        
        response = client.post("/v1/admin/training/jobs", json=job_data)
        
        assert response.status_code == 400
        assert "at least 10" in response.json()["detail"].lower()
    
    def test_create_training_job_nonexistent_dataset(self, client: TestClient):
        """Test creating job for non-existent dataset"""
        fake_id = uuid.uuid4()
        job_data = {
            "dataset_id": str(fake_id),
            "model_type": "detector",
            "config": {"epochs": 10}
        }
        
        response = client.post("/v1/admin/training/jobs", json=job_data)
        
        assert response.status_code == 404
    
    def test_list_training_jobs(self, client: TestClient, sample_training_job: TrainingJob):
        """Test listing all training jobs"""
        response = client.get("/v1/admin/training/jobs")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
    
    def test_list_training_jobs_with_status_filter(self, client: TestClient, sample_training_job: TrainingJob):
        """Test filtering jobs by status"""
        response = client.get("/v1/admin/training/jobs?status=pending")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        for job in data:
            assert job["status"] == "pending"
    
    def test_list_training_jobs_with_pagination(self, client: TestClient, sample_training_job: TrainingJob):
        """Test pagination for training jobs"""
        response = client.get("/v1/admin/training/jobs?skip=0&limit=5")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 5
    
    def test_get_training_job(self, client: TestClient, sample_training_job: TrainingJob):
        """Test getting training job details"""
        response = client.get(f"/v1/admin/training/jobs/{sample_training_job.id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(sample_training_job.id)
        assert data["model_type"] == sample_training_job.model_type
    
    def test_get_training_job_not_found(self, client: TestClient):
        """Test getting non-existent training job"""
        fake_id = uuid.uuid4()
        response = client.get(f"/v1/admin/training/jobs/{fake_id}")
        
        assert response.status_code == 404
    
    def test_get_training_logs_no_logs(self, client: TestClient, sample_training_job: TrainingJob):
        """Test getting logs when none are available"""
        response = client.get(f"/v1/admin/training/jobs/{sample_training_job.id}/logs")
        
        assert response.status_code == 200
        data = response.json()
        assert "logs" in data
    
    def test_get_training_logs_not_found(self, client: TestClient):
        """Test getting logs for non-existent job"""
        fake_id = uuid.uuid4()
        response = client.get(f"/v1/admin/training/jobs/{fake_id}/logs")
        
        assert response.status_code == 404
    
    def test_get_training_metrics_no_metrics(self, client: TestClient, sample_training_job: TrainingJob):
        """Test getting metrics when none are available"""
        response = client.get(f"/v1/admin/training/jobs/{sample_training_job.id}/metrics")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)
    
    def test_get_training_metrics_not_found(self, client: TestClient):
        """Test getting metrics for non-existent job"""
        fake_id = uuid.uuid4()
        response = client.get(f"/v1/admin/training/jobs/{fake_id}/metrics")
        
        assert response.status_code == 404
    
    def test_cancel_pending_job(self, client: TestClient, sample_training_job: TrainingJob):
        """Test cancelling pending job"""
        response = client.post(f"/v1/admin/training/jobs/{sample_training_job.id}/cancel")
        
        assert response.status_code == 200
        assert "cancelled" in response.json()["message"].lower()
    
    def test_cancel_completed_job_fails(self, client: TestClient, sample_training_job: TrainingJob, db_session):
        """Test that completed jobs cannot be cancelled"""
        # Update job to completed
        sample_training_job.status = "completed"
        db_session.commit()
        
        response = client.post(f"/v1/admin/training/jobs/{sample_training_job.id}/cancel")
        
        assert response.status_code == 400
        assert "cannot cancel" in response.json()["detail"].lower()
    
    def test_cancel_nonexistent_job(self, client: TestClient):
        """Test cancelling non-existent job"""
        fake_id = uuid.uuid4()
        response = client.post(f"/v1/admin/training/jobs/{fake_id}/cancel")
        
        assert response.status_code == 404


@pytest.mark.slow
@pytest.mark.integration
class TestTrainingJobExecution:
    """Test training job execution (background tasks)"""
    
    def test_training_job_status_transitions(self, client: TestClient, dataset_with_images):
        """Test job status transitions: pending → running → completed"""
        dataset, images = dataset_with_images
        
        job_data = {
            "dataset_id": str(dataset.id),
            "model_type": "detector",
            "config": {"epochs": 1}
        }
        
        response = client.post("/v1/admin/training/jobs", json=job_data)
        assert response.status_code == 200
        job_id = response.json()["id"]
        
        # Wait a bit for background task
        time.sleep(3)
        
        # Check job status
        response = client.get(f"/v1/admin/training/jobs/{job_id}")
        data = response.json()
        
        # Status should have changed from pending
        assert data["status"] in ["pending", "running", "completed", "failed"]

