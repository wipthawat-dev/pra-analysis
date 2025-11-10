"""Tests for /v1/admin/datasets endpoint"""
import pytest
import uuid
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from models.database_models import Dataset, Image


@pytest.mark.api
class TestDatasetsEndpoint:
    """Test cases for dataset management API"""
    
    def test_create_dataset_with_name_only(self, client: TestClient):
        """Test creating dataset with name only"""
        response = client.post(
            "/v1/admin/datasets",
            json={"name": "Test Dataset"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Test Dataset"
        assert "id" in data
        assert "minio_bucket" in data
        assert data["status"] == "active"
    
    def test_create_dataset_with_description(self, client: TestClient):
        """Test creating dataset with name and description"""
        response = client.post(
            "/v1/admin/datasets",
            json={
                "name": "Test Dataset",
                "description": "A detailed description"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Test Dataset"
        assert data["description"] == "A detailed description"
    
    def test_create_dataset_with_custom_bucket(self, client: TestClient):
        """Test creating dataset with custom MinIO bucket"""
        response = client.post(
            "/v1/admin/datasets",
            json={
                "name": "Custom Bucket Dataset",
                "minio_bucket": "my-custom-bucket"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["minio_bucket"] == "my-custom-bucket"
    
    def test_create_dataset_auto_generate_bucket(self, client: TestClient):
        """Test bucket auto-generation when not provided"""
        response = client.post(
            "/v1/admin/datasets",
            json={"name": "Auto Bucket Dataset"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["minio_bucket"] is not None
        assert "dataset-" in data["minio_bucket"]
    
    def test_create_dataset_duplicate_names(self, client: TestClient):
        """Test creating datasets with duplicate names (should be allowed)"""
        dataset_data = {"name": "Duplicate Name"}
        
        response1 = client.post("/v1/admin/datasets", json=dataset_data)
        response2 = client.post("/v1/admin/datasets", json=dataset_data)
        
        assert response1.status_code == 200
        assert response2.status_code == 200
        assert response1.json()["id"] != response2.json()["id"]
    
    def test_create_dataset_invalid_payload(self, client: TestClient):
        """Test creating dataset with invalid payload"""
        response = client.post(
            "/v1/admin/datasets",
            json={}  # Missing required 'name' field
        )
        
        assert response.status_code == 422
    
    def test_list_datasets_empty(self, client: TestClient):
        """Test listing datasets when none exist"""
        response = client.get("/v1/admin/datasets")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
    
    def test_list_datasets(self, client: TestClient, multiple_datasets):
        """Test listing multiple datasets"""
        response = client.get("/v1/admin/datasets")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 5
    
    def test_list_datasets_with_pagination(self, client: TestClient, multiple_datasets):
        """Test dataset pagination"""
        response = client.get("/v1/admin/datasets?skip=0&limit=2")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 2
    
    def test_get_dataset_by_id(self, client: TestClient, sample_dataset: Dataset):
        """Test getting dataset by valid UUID"""
        response = client.get(f"/v1/admin/datasets/{sample_dataset.id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(sample_dataset.id)
        assert data["name"] == sample_dataset.name
    
    def test_get_dataset_not_found(self, client: TestClient):
        """Test getting non-existent dataset"""
        fake_id = uuid.uuid4()
        response = client.get(f"/v1/admin/datasets/{fake_id}")
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()
    
    def test_get_dataset_invalid_uuid(self, client: TestClient):
        """Test getting dataset with invalid UUID format"""
        response = client.get("/v1/admin/datasets/invalid-uuid")
        
        assert response.status_code == 422
    
    def test_delete_dataset_no_images(self, client: TestClient, sample_dataset: Dataset):
        """Test deleting dataset with no images"""
        response = client.delete(f"/v1/admin/datasets/{sample_dataset.id}")
        
        assert response.status_code == 200
        assert "deleted successfully" in response.json()["message"].lower()
        
        # Verify dataset is deleted
        get_response = client.get(f"/v1/admin/datasets/{sample_dataset.id}")
        assert get_response.status_code == 404
    
    def test_delete_dataset_with_images(self, client: TestClient, dataset_with_images):
        """Test deleting dataset with images (CASCADE)"""
        dataset, images = dataset_with_images
        
        response = client.delete(f"/v1/admin/datasets/{dataset.id}")
        
        assert response.status_code == 200
    
    def test_delete_dataset_not_found(self, client: TestClient):
        """Test deleting non-existent dataset"""
        fake_id = uuid.uuid4()
        response = client.delete(f"/v1/admin/datasets/{fake_id}")
        
        assert response.status_code == 404
    
    def test_upload_single_image_to_dataset(self, client: TestClient, sample_dataset: Dataset, sample_image):
        """Test uploading single image to dataset"""
        sample_image.seek(0)
        
        response = client.post(
            f"/v1/admin/datasets/{sample_dataset.id}/images",
            files={"files": ("test.jpg", sample_image, "image/jpeg")}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["uploaded"] == 1
        assert len(data["images"]) == 1
    
    def test_upload_multiple_images_to_dataset(self, client: TestClient, sample_dataset: Dataset):
        """Test uploading multiple images to dataset"""
        from PIL import Image as PILImage
        from io import BytesIO
        
        files = []
        for i in range(3):
            img = PILImage.new('RGB', (100, 100), color='red')
            img_bytes = BytesIO()
            img.save(img_bytes, format='JPEG')
            img_bytes.seek(0)
            files.append(("files", (f"test{i}.jpg", img_bytes, "image/jpeg")))
        
        response = client.post(
            f"/v1/admin/datasets/{sample_dataset.id}/images",
            files=files
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["uploaded"] == 3
    
    def test_upload_to_nonexistent_dataset(self, client: TestClient, sample_image):
        """Test uploading to non-existent dataset"""
        fake_id = uuid.uuid4()
        sample_image.seek(0)
        
        response = client.post(
            f"/v1/admin/datasets/{fake_id}/images",
            files={"files": ("test.jpg", sample_image, "image/jpeg")}
        )
        
        assert response.status_code == 404
    
    def test_list_dataset_images(self, client: TestClient, dataset_with_images):
        """Test listing images in a dataset"""
        dataset, images = dataset_with_images
        
        response = client.get(f"/v1/admin/datasets/{dataset.id}/images")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 10
        
        # Verify response structure
        for img in data:
            assert "id" in img
            assert "minio_path" in img
            assert "mime" in img
            assert "is_labeled" in img
    
    def test_list_dataset_images_with_pagination(self, client: TestClient, dataset_with_images):
        """Test pagination for dataset images"""
        dataset, images = dataset_with_images
        
        response = client.get(f"/v1/admin/datasets/{dataset.id}/images?skip=0&limit=5")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 5
    
    def test_list_images_empty_dataset(self, client: TestClient, sample_dataset: Dataset):
        """Test listing images from empty dataset"""
        response = client.get(f"/v1/admin/datasets/{sample_dataset.id}/images")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 0

