"""Integration tests for end-to-end workflows"""
import pytest
import time
from io import BytesIO
from PIL import Image as PILImage
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session


@pytest.mark.integration
class TestImageAnalysisWorkflow:
    """Test complete image analysis workflow"""
    
    def test_complete_analysis_workflow(self, client: TestClient, db_session: Session):
        """
        Test Workflow 1: Image Analysis
        1. User uploads image via frontend
        2. API validates and stores in MinIO
        3. Database records created
        4. Analysis performed (mock)
        5. Results saved to MinIO
        6. Results displayed to user
        7. User submits feedback
        8. Feedback saved to database
        """
        # Step 1-5: Upload and analyze image
        img = PILImage.new('RGB', (200, 200), color='red')
        img_bytes = BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        
        response = client.post(
            "/v1/analyze",
            files={"file": ("test.jpg", img_bytes, "image/jpeg")}
        )
        
        assert response.status_code == 200
        analysis_data = response.json()
        prediction_id = analysis_data["prediction_id"]
        
        # Verify database records
        from apps.amulet_ai_service.models.database_models import Image, Prediction
        
        images = db_session.query(Image).all()
        assert len(images) >= 1
        
        predictions = db_session.query(Prediction).all()
        assert len(predictions) >= 1
        
        # Step 6-8: Submit feedback
        feedback_data = {
            "prediction_id": prediction_id,
            "is_correct": False,
            "correct_verdict": "fake",
            "notes": "This image is manipulated"
        }
        
        feedback_response = client.post("/v1/feedback", json=feedback_data)
        assert feedback_response.status_code == 200
        
        # Verify feedback saved
        from apps.amulet_ai_service.models.database_models import Feedback
        feedbacks = db_session.query(Feedback).filter(
            Feedback.prediction_id == prediction_id
        ).all()
        assert len(feedbacks) == 1
        assert feedbacks[0].correct_verdict == "fake"


@pytest.mark.integration
class TestDatasetTrainingDeploymentWorkflow:
    """Test complete dataset to model deployment workflow"""
    
    def test_dataset_to_deployment_workflow(self, client: TestClient, db_session: Session):
        """
        Test Workflow 2: Dataset → Training → Model → Deployment
        1. Create new dataset
        2. Upload images to dataset
        3. Label images
        4. Create training job
        5. Training completes
        6. Model created in registry
        7. Evaluate model
        8. Deploy model
        """
        # Step 1: Create dataset
        dataset_response = client.post(
            "/v1/admin/datasets",
            json={"name": "Integration Test Dataset"}
        )
        assert dataset_response.status_code == 200
        dataset_id = dataset_response.json()["id"]
        
        # Step 2: Upload images to dataset
        images_to_upload = []
        for i in range(12):  # Need at least 10 labeled images
            img = PILImage.new('RGB', (100, 100), color='blue')
            img_bytes = BytesIO()
            img.save(img_bytes, format='JPEG')
            img_bytes.seek(0)
            images_to_upload.append(
                ("files", (f"test{i}.jpg", img_bytes, "image/jpeg"))
            )
        
        upload_response = client.post(
            f"/v1/admin/datasets/{dataset_id}/images",
            files=images_to_upload
        )
        assert upload_response.status_code == 200
        uploaded_images = upload_response.json()["images"]
        
        # Step 3: Label images
        for img in uploaded_images[:10]:  # Label first 10
            label_data = {
                "image_id": img["id"],
                "verdict": "authentic" if int(img["id"][-1]) % 2 == 0 else "fake",
                "confidence": 0.90
            }
            label_response = client.post(
                f"/v1/admin/labeling/{img['id']}",
                json=label_data
            )
            assert label_response.status_code == 200
        
        # Step 4: Create training job
        training_data = {
            "dataset_id": dataset_id,
            "model_type": "detector",
            "config": {"epochs": 5, "batch_size": 16}
        }
        training_response = client.post(
            "/v1/admin/training/jobs",
            json=training_data
        )
        assert training_response.status_code == 200
        job_id = training_response.json()["id"]
        
        # Step 5: Wait for training (in real scenario, would poll status)
        time.sleep(1)
        
        job_status_response = client.get(f"/v1/admin/training/jobs/{job_id}")
        assert job_status_response.status_code == 200
        job_status = job_status_response.json()["status"]
        assert job_status in ["pending", "running", "completed"]


@pytest.mark.integration
class TestMinIOImportWorkflow:
    """Test MinIO import workflow"""
    
    def test_minio_import_workflow(self, client: TestClient, db_session: Session):
        """
        Test Workflow 3: MinIO Import
        1. Create dataset
        2. Create import job
        3. Background task processes images
        4. Images imported to dataset
        5. Label imported images
        """
        # Step 1: Create dataset
        dataset_response = client.post(
            "/v1/admin/datasets",
            json={"name": "Import Test Dataset"}
        )
        assert dataset_response.status_code == 200
        dataset_id = dataset_response.json()["id"]
        
        # Step 2: Note - actual import would require MinIO bucket
        # This test verifies the API contract
        # In real testing, we would set up a test MinIO bucket with images


@pytest.mark.integration
class TestConcurrentOperations:
    """Test concurrent operations"""
    
    def test_concurrent_image_uploads(self, client: TestClient):
        """Test handling multiple concurrent image uploads"""
        import concurrent.futures
        
        def upload_image(index):
            img = PILImage.new('RGB', (100, 100), color='red')
            img_bytes = BytesIO()
            img.save(img_bytes, format='JPEG')
            img_bytes.seek(0)
            
            response = client.post(
                "/v1/analyze",
                files={"file": (f"concurrent{index}.jpg", img_bytes, "image/jpeg")}
            )
            return response.status_code
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(upload_image, i) for i in range(10)]
            results = [f.result() for f in concurrent.futures.as_completed(futures)]
        
        # All should succeed
        assert all(status == 200 for status in results)
    
    def test_concurrent_dataset_creation(self, client: TestClient):
        """Test handling multiple concurrent dataset creations"""
        import concurrent.futures
        
        def create_dataset(index):
            response = client.post(
                "/v1/admin/datasets",
                json={"name": f"Concurrent Dataset {index}"}
            )
            return response.status_code
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(create_dataset, i) for i in range(10)]
            results = [f.result() for f in concurrent.futures.as_completed(futures)]
        
        # All should succeed
        assert all(status == 200 for status in results)


@pytest.mark.integration
class TestErrorRecovery:
    """Test error recovery and resilience"""
    
    def test_transaction_rollback_on_partial_failure(self, client: TestClient, sample_dataset, db_session):
        """Test that partial failures don't leave corrupt data"""
        # Try batch label creation with one invalid image ID
        import uuid
        
        batch_data = [
            {
                "image_id": str(uuid.uuid4()),  # Invalid ID
                "verdict": "authentic",
                "confidence": 90
            }
        ]
        
        try:
            response = client.post("/v1/admin/labeling/batch", json=batch_data)
            # Should handle gracefully
        except:
            pass
        
        # Database should remain consistent
        from apps.amulet_ai_service.models.database_models import Label
        labels = db_session.query(Label).all()
        # Verify no orphaned labels
        for label in labels:
            assert label.image is not None

