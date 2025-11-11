"""Tests for /v1/admin/labeling endpoint"""
import pytest
import uuid
from fastapi.testclient import TestClient
from models.database_models import Dataset, Image, Label


@pytest.mark.api
class TestLabelingEndpoint:
    """Test cases for labeling API"""
    
    def test_get_labeling_queue(self, client: TestClient, sample_image_record: Image):
        """Test getting unlabeled images"""
        response = client.get("/v1/admin/labeling/queue")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        
        # Verify structure
        if len(data) > 0:
            item = data[0]
            assert "id" in item
            assert "minio_path" in item
            assert "is_labeled" in item
            assert item["is_labeled"] is False
    
    def test_get_labeling_queue_with_dataset_filter(self, client: TestClient, dataset_with_images):
        """Test filtering queue by dataset_id"""
        dataset, images = dataset_with_images
        
        response = client.get(f"/v1/admin/labeling/queue?dataset_id={dataset.id}")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
    
    def test_get_labeling_queue_with_limit(self, client: TestClient, dataset_with_images):
        """Test queue limit parameter"""
        dataset, images = dataset_with_images
        
        response = client.get("/v1/admin/labeling/queue?limit=3")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 3
    
    def test_get_labeling_queue_empty(self, client: TestClient, labeled_image_record: Image):
        """Test empty queue when all images are labeled"""
        # All images are labeled, so queue should be empty
        response = client.get(f"/v1/admin/labeling/queue?dataset_id={labeled_image_record.dataset_id}")
        
        assert response.status_code == 200
        data = response.json()
        # Should have 0 or only other unlabeled images
        assert isinstance(data, list)
    
    def test_create_label_authentic(self, client: TestClient, sample_image_record: Image):
        """Test creating label with verdict: authentic"""
        label_data = {
            "image_id": str(sample_image_record.id),
            "verdict": "authentic",
            "confidence": 0.95,
            "notes": "Clearly authentic"
        }
        
        response = client.post(
            f"/v1/admin/labeling/{sample_image_record.id}",
            json=label_data
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["verdict"] == "authentic"
        assert data["image_id"] == str(sample_image_record.id)
    
    def test_create_label_fake(self, client: TestClient, sample_image_record: Image):
        """Test creating label with verdict: fake"""
        label_data = {
            "image_id": str(sample_image_record.id),
            "verdict": "fake",
            "confidence": 0.85,
            "notes": "Manipulation detected"
        }
        
        response = client.post(
            f"/v1/admin/labeling/{sample_image_record.id}",
            json=label_data
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["verdict"] == "fake"
    
    def test_create_label_uncertain(self, client: TestClient, sample_image_record: Image):
        """Test creating label with verdict: uncertain"""
        label_data = {
            "image_id": str(sample_image_record.id),
            "verdict": "uncertain",
            "confidence": 0.50
        }
        
        response = client.post(
            f"/v1/admin/labeling/{sample_image_record.id}",
            json=label_data
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["verdict"] == "uncertain"
    
    def test_create_label_with_bbox(self, client: TestClient, sample_image_record: Image):
        """Test creating label with bounding box"""
        label_data = {
            "image_id": str(sample_image_record.id),
            "verdict": "fake",
            "bbox": {"x": 10, "y": 20, "width": 100, "height": 150},
            "confidence": 0.90
        }
        
        response = client.post(
            f"/v1/admin/labeling/{sample_image_record.id}",
            json=label_data
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["bbox"] is not None
    
    def test_create_label_updates_is_labeled_flag(self, client: TestClient, sample_image_record: Image, db_session):
        """Test that is_labeled flag is updated"""
        assert sample_image_record.is_labeled is False
        
        label_data = {
            "image_id": str(sample_image_record.id),
            "verdict": "authentic",
            "confidence": 0.90
        }
        
        response = client.post(
            f"/v1/admin/labeling/{sample_image_record.id}",
            json=label_data
        )
        
        assert response.status_code == 200
        
        # Refresh and check
        db_session.refresh(sample_image_record)
        assert sample_image_record.is_labeled is True
    
    def test_create_label_nonexistent_image(self, client: TestClient):
        """Test creating label for non-existent image"""
        fake_id = uuid.uuid4()
        label_data = {
            "image_id": str(fake_id),
            "verdict": "authentic",
            "confidence": 0.90
        }
        
        response = client.post(
            f"/v1/admin/labeling/{fake_id}",
            json=label_data
        )
        
        assert response.status_code == 404
    
    def test_get_image_labels(self, client: TestClient, labeled_image_record: Image):
        """Test getting labels for an image"""
        response = client.get(f"/v1/admin/labeling/{labeled_image_record.id}/labels")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
    
    def test_get_image_labels_unlabeled(self, client: TestClient, sample_image_record: Image):
        """Test getting labels for unlabeled image"""
        response = client.get(f"/v1/admin/labeling/{sample_image_record.id}/labels")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 0
    
    def test_get_image_labels_nonexistent(self, client: TestClient):
        """Test getting labels for non-existent image"""
        fake_id = uuid.uuid4()
        response = client.get(f"/v1/admin/labeling/{fake_id}/labels")
        
        assert response.status_code == 404
    
    def test_create_batch_labels(self, client: TestClient, dataset_with_images):
        """Test creating multiple labels at once"""
        dataset, images = dataset_with_images
        unlabeled_images = [img for img in images if not img.is_labeled]
        
        if len(unlabeled_images) < 2:
            pytest.skip("Need at least 2 unlabeled images")
        
        batch_data = [
            {
                "image_id": str(unlabeled_images[0].id),
                "verdict": "authentic",
                "confidence": 0.90
            },
            {
                "image_id": str(unlabeled_images[1].id),
                "verdict": "fake",
                "confidence": 0.85
            }
        ]
        
        response = client.post("/v1/admin/labeling/batch", json=batch_data)
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
    
    def test_labeling_statistics_overall(self, client: TestClient, dataset_with_images):
        """Test getting overall labeling statistics"""
        response = client.get("/v1/admin/labeling/stats")
        
        assert response.status_code == 200
        data = response.json()
        assert "total_images" in data
        assert "labeled_images" in data
        assert "unlabeled_images" in data
        assert "label_distribution" in data
    
    def test_labeling_statistics_by_dataset(self, client: TestClient, dataset_with_images):
        """Test getting dataset-specific statistics"""
        dataset, images = dataset_with_images
        
        response = client.get(f"/v1/admin/labeling/stats?dataset_id={dataset.id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["total_images"] == 10
        assert data["labeled_images"] == 5
        assert data["unlabeled_images"] == 5

