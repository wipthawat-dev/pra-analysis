"""Tests for /v1/admin/models endpoint"""
import pytest
import uuid
from fastapi.testclient import TestClient
from models.database_models import Model, Dataset


@pytest.mark.api
class TestModelsEndpoint:
    """Test cases for models API"""
    
    def test_list_models(self, client: TestClient, sample_model: Model):
        """Test listing all models"""
        response = client.get("/v1/admin/models")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
    
    def test_list_models_empty(self, client: TestClient):
        """Test listing models when registry is empty"""
        response = client.get("/v1/admin/models")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
    
    def test_list_models_filter_by_type(self, client: TestClient, sample_model: Model):
        """Test filtering models by type"""
        response = client.get("/v1/admin/models?model_type=detector")
        
        assert response.status_code == 200
        data = response.json()
        for model in data:
            assert model["model_type"] == "detector"
    
    def test_list_models_filter_by_deployment(self, client: TestClient, sample_model: Model):
        """Test filtering models by deployment status"""
        response = client.get("/v1/admin/models?is_deployed=false")
        
        assert response.status_code == 200
        data = response.json()
        for model in data:
            assert model["is_deployed"] is False
    
    def test_list_models_with_pagination(self, client: TestClient, sample_model: Model):
        """Test pagination for models"""
        response = client.get("/v1/admin/models?skip=0&limit=5")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 5
    
    def test_get_model_by_version(self, client: TestClient, sample_model: Model):
        """Test getting model by version"""
        response = client.get(f"/v1/admin/models/{sample_model.version}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["version"] == sample_model.version
        assert data["model_type"] == sample_model.model_type
    
    def test_get_model_not_found(self, client: TestClient):
        """Test getting non-existent model"""
        response = client.get("/v1/admin/models/nonexistent-version")
        
        assert response.status_code == 404
    
    def test_evaluate_model(self, client: TestClient, sample_model: Model, sample_dataset: Dataset):
        """Test evaluating a model"""
        eval_data = {
            "test_dataset_id": str(sample_dataset.id)
        }
        
        response = client.post(
            f"/v1/admin/models/{sample_model.version}/evaluate",
            json=eval_data
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "accuracy" in data
        assert "precision" in data
        assert "recall" in data
        assert "f1_score" in data
    
    def test_evaluate_nonexistent_model(self, client: TestClient, sample_dataset: Dataset):
        """Test evaluating non-existent model"""
        eval_data = {"test_dataset_id": str(sample_dataset.id)}
        
        response = client.post(
            "/v1/admin/models/nonexistent-version/evaluate",
            json=eval_data
        )
        
        assert response.status_code == 404
    
    def test_deploy_model(self, client: TestClient, sample_model: Model, db_session):
        """Test deploying a model"""
        response = client.post(f"/v1/admin/models/{sample_model.version}/deploy")
        
        assert response.status_code == 200
        assert "deployed successfully" in response.json()["message"].lower()
        
        # Verify deployment status
        db_session.refresh(sample_model)
        assert sample_model.is_deployed is True
        assert sample_model.deployed_at is not None
    
    def test_deploy_model_undeploys_previous(self, client: TestClient, sample_training_job, db_session):
        """Test that deploying a model undeploys previous model of same type"""
        # Create first model and deploy it
        model1 = Model(
            version="detector-v1",
            model_type="detector",
            training_job_id=sample_training_job.id,
            minio_path="models/detector-v1/model.pth",
            is_deployed=True
        )
        db_session.add(model1)
        db_session.commit()
        
        # Create second model
        model2 = Model(
            version="detector-v2",
            model_type="detector",
            training_job_id=sample_training_job.id,
            minio_path="models/detector-v2/model.pth",
            is_deployed=False
        )
        db_session.add(model2)
        db_session.commit()
        
        # Deploy second model
        response = client.post(f"/v1/admin/models/{model2.version}/deploy")
        assert response.status_code == 200
        
        # Verify first model is undeployed
        db_session.refresh(model1)
        db_session.refresh(model2)
        assert model1.is_deployed is False
        assert model2.is_deployed is True
    
    def test_deploy_nonexistent_model(self, client: TestClient):
        """Test deploying non-existent model"""
        response = client.post("/v1/admin/models/nonexistent-version/deploy")
        
        assert response.status_code == 404
    
    def test_get_model_metrics(self, client: TestClient, sample_model: Model):
        """Test getting model metrics"""
        response = client.get(f"/v1/admin/models/{sample_model.version}/metrics")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)
        if sample_model.metrics:
            assert "accuracy" in data
    
    def test_get_model_metrics_no_metrics(self, client: TestClient, sample_training_job, db_session):
        """Test getting metrics for model without metrics"""
        model = Model(
            version="no-metrics-v1",
            model_type="detector",
            training_job_id=sample_training_job.id,
            minio_path="models/no-metrics/model.pth",
            metrics=None
        )
        db_session.add(model)
        db_session.commit()
        
        response = client.get(f"/v1/admin/models/{model.version}/metrics")
        
        assert response.status_code == 200
        data = response.json()
        assert data == {}
    
    def test_get_metrics_nonexistent_model(self, client: TestClient):
        """Test getting metrics for non-existent model"""
        response = client.get("/v1/admin/models/nonexistent-version/metrics")
        
        assert response.status_code == 404

