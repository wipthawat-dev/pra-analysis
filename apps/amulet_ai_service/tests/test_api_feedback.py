"""Tests for /v1/feedback and /v1/admin/feedback endpoints"""
import pytest
import uuid
from fastapi.testclient import TestClient
from apps.amulet_ai_service.models.database_models import Feedback, Prediction


@pytest.mark.api
class TestFeedbackEndpoint:
    """Test cases for feedback API"""
    
    def test_create_feedback_correct(self, client: TestClient, sample_prediction: Prediction):
        """Test creating feedback with is_correct=true"""
        feedback_data = {
            "prediction_id": str(sample_prediction.id),
            "is_correct": True,
            "notes": "Good prediction"
        }
        
        response = client.post("/v1/feedback", json=feedback_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["is_correct"] is True
        assert data["prediction_id"] == str(sample_prediction.id)
    
    def test_create_feedback_incorrect_with_correct_verdict(self, client: TestClient, sample_prediction: Prediction):
        """Test creating feedback with is_correct=false and correct verdict"""
        feedback_data = {
            "prediction_id": str(sample_prediction.id),
            "is_correct": False,
            "correct_verdict": "fake",
            "notes": "This is actually fake"
        }
        
        response = client.post("/v1/feedback", json=feedback_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["is_correct"] is False
        assert data["correct_verdict"] == "fake"
    
    def test_create_feedback_with_notes(self, client: TestClient, sample_prediction: Prediction):
        """Test creating feedback with notes"""
        feedback_data = {
            "prediction_id": str(sample_prediction.id),
            "is_correct": True,
            "notes": "Detailed feedback notes here"
        }
        
        response = client.post("/v1/feedback", json=feedback_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["notes"] == "Detailed feedback notes here"
    
    def test_create_feedback_nonexistent_prediction(self, client: TestClient):
        """Test creating feedback for non-existent prediction"""
        fake_id = uuid.uuid4()
        feedback_data = {
            "prediction_id": str(fake_id),
            "is_correct": True
        }
        
        response = client.post("/v1/feedback", json=feedback_data)
        
        assert response.status_code == 404
    
    def test_list_feedback(self, client: TestClient, sample_feedback: Feedback):
        """Test listing all feedback"""
        response = client.get("/v1/admin/feedback")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
    
    def test_list_feedback_filter_reviewed(self, client: TestClient, sample_feedback: Feedback):
        """Test filtering feedback by reviewed status"""
        response = client.get("/v1/admin/feedback?reviewed=false")
        
        assert response.status_code == 200
        data = response.json()
        for item in data:
            assert item["reviewed_at"] is None
    
    def test_list_feedback_filter_unreviewed(self, client: TestClient, sample_feedback: Feedback):
        """Test filtering unreviewed feedback"""
        response = client.get("/v1/admin/feedback?reviewed=false")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
    
    def test_list_feedback_with_pagination(self, client: TestClient, sample_feedback: Feedback):
        """Test pagination for feedback list"""
        response = client.get("/v1/admin/feedback?skip=0&limit=5")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 5
    
    def test_approve_feedback(self, client: TestClient, sample_feedback: Feedback, db_session):
        """Test approving feedback"""
        response = client.post(f"/v1/admin/feedback/{sample_feedback.id}/approve")
        
        assert response.status_code == 200
        assert "approved" in response.json()["message"].lower()
        
        # Verify reviewed status
        db_session.refresh(sample_feedback)
        assert sample_feedback.reviewed_at is not None
    
    def test_approve_feedback_with_reviewer(self, client: TestClient, sample_feedback: Feedback, db_session):
        """Test approving feedback with reviewer ID"""
        reviewer_id = uuid.uuid4()
        response = client.post(
            f"/v1/admin/feedback/{sample_feedback.id}/approve?reviewer_id={reviewer_id}"
        )
        
        assert response.status_code == 200
        db_session.refresh(sample_feedback)
        assert sample_feedback.reviewed_by == reviewer_id
    
    def test_approve_feedback_with_auto_retrain_false(self, client: TestClient, sample_feedback: Feedback):
        """Test approving feedback without auto-retrain"""
        response = client.post(
            f"/v1/admin/feedback/{sample_feedback.id}/approve?auto_retrain=false"
        )
        
        assert response.status_code == 200
    
    def test_approve_nonexistent_feedback(self, client: TestClient):
        """Test approving non-existent feedback"""
        fake_id = uuid.uuid4()
        response = client.post(f"/v1/admin/feedback/{fake_id}/approve")
        
        assert response.status_code == 404
    
    def test_feedback_statistics(self, client: TestClient, sample_feedback: Feedback):
        """Test getting feedback statistics"""
        response = client.get("/v1/admin/feedback/stats")
        
        assert response.status_code == 200
        data = response.json()
        assert "total" in data
        assert "reviewed" in data
        assert "unreviewed" in data
        assert "incorrect" in data
        assert "correct" in data
        
        # Verify data types
        assert isinstance(data["total"], int)
        assert isinstance(data["reviewed"], int)
        assert isinstance(data["unreviewed"], int)
        assert isinstance(data["incorrect"], int)
        assert isinstance(data["correct"], int)

