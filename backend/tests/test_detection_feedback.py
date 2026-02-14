"""Tests for detection feedback endpoint and learned mappings."""

import json
import pytest

from app.models import DetectionFeedback
from app.ml.google_vision_detector import GoogleVisionDetector


class TestFeedbackEndpoint:
    """Tests for POST /api/ingredients/detect/feedback."""

    def test_submit_feedback_success(self, client, auth_headers, sample_ingredients, db_session):
        """POST correction is stored in DB and returns success."""
        resp = client.post('/api/ingredients/detect/feedback',
                           headers=auth_headers,
                           data=json.dumps({
                               'corrections': [{
                                   'detected_label': 'jackfruit',
                                   'ai_mapped': 'Langka',
                                   'correct_ingredient': 'Pineapple'
                               }]
                           }),
                           content_type='application/json')

        assert resp.status_code == 200
        body = resp.get_json()
        assert body['results'][0]['success'] is True
        assert "Learned: 'jackfruit' -> 'Pineapple'" in body['results'][0]['message']

        # Verify stored in DB
        feedback = DetectionFeedback.query.filter_by(detected_label='jackfruit').first()
        assert feedback is not None
        assert feedback.correct_ingredient == 'Pineapple'
        assert feedback.correction_count == 1

    def test_submit_feedback_increments_count(self, client, auth_headers, sample_ingredients, db_session):
        """Same correction twice increments correction_count to 2."""
        correction = {
            'corrections': [{
                'detected_label': 'durian',
                'correct_ingredient': 'Pineapple'
            }]
        }

        # First submission
        client.post(
            '/api/ingredients/detect/feedback',
            headers=auth_headers,
            data=json.dumps(correction),
            content_type='application/json')

        # Second submission
        client.post(
            '/api/ingredients/detect/feedback',
            headers=auth_headers,
            data=json.dumps(correction),
            content_type='application/json')

        feedback = DetectionFeedback.query.filter_by(detected_label='durian').first()
        assert feedback.correction_count == 2

    def test_submit_feedback_missing_fields(self, client, auth_headers):
        """Missing required fields returns error in results."""
        resp = client.post('/api/ingredients/detect/feedback',
                           headers=auth_headers,
                           data=json.dumps({
                               'corrections': [{
                                   'detected_label': 'something'
                                   # missing correct_ingredient
                               }]
                           }),
                           content_type='application/json')

        assert resp.status_code == 200
        body = resp.get_json()
        assert 'error' in body['results'][0]

    def test_submit_feedback_clears_cache(self, client, auth_headers, sample_ingredients, db_session):
        """After feedback, cache_timestamp is set to None."""
        # Set a fake cache timestamp
        GoogleVisionDetector._cache_timestamp = 'some_old_time'

        client.post(
            '/api/ingredients/detect/feedback',
            headers=auth_headers,
            data=json.dumps({
                'corrections': [{
                    'detected_label': 'test_label',
                    'correct_ingredient': 'Tomato'
                }]
            }),
            content_type='application/json')

        assert GoogleVisionDetector._cache_timestamp is None


class TestLearnedMappingsEndpoint:
    """Tests for GET /api/ingredients/detect/learned-mappings."""

    def test_get_learned_mappings_endpoint(self, client, app, db_session):
        """GET returns all learned mappings."""
        # Insert feedback directly
        feedback = DetectionFeedback(
            detected_label='ananas',
            correct_ingredient='Pineapple',
            correction_count=3,
            learned_confidence=0.8
        )
        db_session.add(feedback)
        db_session.flush()

        resp = client.get('/api/ingredients/detect/learned-mappings')
        assert resp.status_code == 200
        body = resp.get_json()
        assert body['total_mappings'] >= 1

        mapping = next((m for m in body['mappings'] if m['detected_label'] == 'ananas'), None)
        assert mapping is not None
        assert mapping['correct_ingredient'] == 'Pineapple'
        assert mapping['correction_count'] == 3


class TestDetectionFeedbackModel:
    """Tests for DetectionFeedback model methods."""

    def test_learned_confidence_formula(self, app, db_session):
        """Confidence grows: 1st=0.5, 2nd=0.7, 3rd=0.8, capped at 0.99."""
        # 1st correction
        fb = DetectionFeedback.add_or_update_feedback(
            detected_label='test_fruit',
            correct_ingredient='Pineapple'
        )
        assert fb.correction_count == 1
        assert fb.learned_confidence == 0.5

        # 2nd correction
        fb = DetectionFeedback.add_or_update_feedback(
            detected_label='test_fruit',
            correct_ingredient='Pineapple'
        )
        assert fb.correction_count == 2
        assert fb.learned_confidence == pytest.approx(0.7)

        # 3rd correction
        fb = DetectionFeedback.add_or_update_feedback(
            detected_label='test_fruit',
            correct_ingredient='Pineapple'
        )
        assert fb.correction_count == 3
        assert fb.learned_confidence == pytest.approx(0.8)

    def test_model_add_new_feedback(self, app, db_session):
        """add_or_update_feedback creates a new row for new label."""
        fb = DetectionFeedback.add_or_update_feedback(
            detected_label='new_label',
            correct_ingredient='Chicken',
            ai_mapped='Unknown',
            user_id=None
        )
        assert fb.id is not None
        assert fb.detected_label == 'new_label'
        assert fb.correct_ingredient == 'Chicken'
        assert fb.ai_mapped_ingredient == 'Unknown'

    def test_model_update_existing_feedback(self, app, db_session):
        """add_or_update_feedback increments existing entry."""
        # Create first
        DetectionFeedback.add_or_update_feedback(
            detected_label='existing_label',
            correct_ingredient='Tomato'
        )

        # Update
        fb = DetectionFeedback.add_or_update_feedback(
            detected_label='existing_label',
            correct_ingredient='Tomato'
        )
        assert fb.correction_count == 2

        # Only one row should exist
        count = DetectionFeedback.query.filter_by(
            detected_label='existing_label',
            correct_ingredient='Tomato'
        ).count()
        assert count == 1
