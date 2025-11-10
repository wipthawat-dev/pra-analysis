"""Tests for /v1/analyze endpoint"""
import pytest
from io import BytesIO
from fastapi.testclient import TestClient


@pytest.mark.api
class TestAnalyzeEndpoint:
    """Test cases for image analysis API"""
    
    def test_analyze_valid_jpeg(self, client: TestClient, sample_image: BytesIO):
        """Test uploading a valid JPEG image"""
        sample_image.seek(0)
        response = client.post(
            "/v1/analyze",
            files={"file": ("test.jpg", sample_image, "image/jpeg")}
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify response structure
        assert "verdict" in data
        assert "score" in data
        assert "model_version" in data
        assert "topk" in data
        assert "heatmaps" in data
        assert "prediction_id" in data
        
        # Verify data types
        assert isinstance(data["verdict"], str)
        assert isinstance(data["score"], (int, float))
        assert isinstance(data["model_version"], str)
        assert isinstance(data["topk"], list)
        assert isinstance(data["heatmaps"], list)
        assert data["prediction_id"] is not None
    
    def test_analyze_valid_png(self, client: TestClient):
        """Test uploading a valid PNG image"""
        from PIL import Image as PILImage
        
        img = PILImage.new('RGB', (100, 100), color='green')
        img_bytes = BytesIO()
        img.save(img_bytes, format='PNG')
        img_bytes.seek(0)
        
        response = client.post(
            "/v1/analyze",
            files={"file": ("test.png", img_bytes, "image/png")}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["prediction_id"] is not None
    
    def test_analyze_without_content_type(self, client: TestClient, sample_image: BytesIO):
        """Test uploading without content type"""
        sample_image.seek(0)
        response = client.post(
            "/v1/analyze",
            files={"file": ("test.jpg", sample_image, None)}
        )
        
        assert response.status_code == 400
        assert "content type" in response.json()["detail"].lower()
    
    def test_analyze_unsupported_file_type(self, client: TestClient):
        """Test uploading unsupported file type (GIF)"""
        from PIL import Image as PILImage
        
        img = PILImage.new('RGB', (100, 100), color='blue')
        img_bytes = BytesIO()
        img.save(img_bytes, format='GIF')
        img_bytes.seek(0)
        
        response = client.post(
            "/v1/analyze",
            files={"file": ("test.gif", img_bytes, "image/gif")}
        )
        
        assert response.status_code == 400
        assert "unsupported" in response.json()["detail"].lower()
    
    def test_analyze_file_too_large(self, client: TestClient, large_image: BytesIO):
        """Test uploading file larger than 15MB"""
        large_image.seek(0)
        
        # Skip if image is not large enough
        size = len(large_image.getvalue())
        if size <= 15 * 1024 * 1024:
            pytest.skip("Large image not generated properly")
        
        response = client.post(
            "/v1/analyze",
            files={"file": ("large.jpg", large_image, "image/jpeg")}
        )
        
        assert response.status_code == 400
        assert "too large" in response.json()["detail"].lower()
    
    def test_analyze_corrupted_image(self, client: TestClient, corrupted_image: BytesIO):
        """Test uploading corrupted image"""
        corrupted_image.seek(0)
        response = client.post(
            "/v1/analyze",
            files={"file": ("corrupted.jpg", corrupted_image, "image/jpeg")}
        )
        
        assert response.status_code == 400
        assert "invalid image" in response.json()["detail"].lower()
    
    def test_analyze_empty_request(self, client: TestClient):
        """Test sending empty request"""
        response = client.post("/v1/analyze")
        
        assert response.status_code == 422
    
    def test_analyze_missing_file_parameter(self, client: TestClient):
        """Test missing file parameter"""
        response = client.post(
            "/v1/analyze",
            data={"not_file": "test"}
        )
        
        assert response.status_code == 422
    
    def test_analyze_small_image(self, client: TestClient):
        """Test uploading 1x1 pixel image"""
        from PIL import Image as PILImage
        
        img = PILImage.new('RGB', (1, 1), color='white')
        img_bytes = BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        
        response = client.post(
            "/v1/analyze",
            files={"file": ("tiny.jpg", img_bytes, "image/jpeg")}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["prediction_id"] is not None
    
    def test_analyze_image_with_exif(self, client: TestClient):
        """Test uploading image with EXIF data"""
        from PIL import Image as PILImage
        from PIL.ExifTags import TAGS
        
        img = PILImage.new('RGB', (200, 200), color='yellow')
        img_bytes = BytesIO()
        img.save(img_bytes, format='JPEG', exif=b'Exif\x00\x00')
        img_bytes.seek(0)
        
        response = client.post(
            "/v1/analyze",
            files={"file": ("exif.jpg", img_bytes, "image/jpeg")}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["prediction_id"] is not None

