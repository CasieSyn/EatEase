"""Integration tests for POST /api/ingredients/detect endpoint."""

from unittest.mock import patch

from tests.conftest import make_test_image, make_mock_detector


class TestDetectEndpointValidation:
    """Tests for request validation (auth, file, format)."""

    def test_detect_requires_auth(self, client):
        """Returns 401 without JWT token."""
        data = {'image': make_test_image()}
        resp = client.post('/api/ingredients/detect', data=data, content_type='multipart/form-data')
        assert resp.status_code == 401

    def test_detect_missing_image(self, client, auth_headers):
        """Returns 400 when no image file in request."""
        resp = client.post('/api/ingredients/detect', headers=auth_headers)
        assert resp.status_code == 400
        assert 'No image file provided' in resp.get_json()['error']

    def test_detect_empty_filename(self, client, auth_headers):
        """Returns 400 when filename is empty."""
        data = {'image': make_test_image(filename='')}
        resp = client.post('/api/ingredients/detect', data=data,
                           content_type='multipart/form-data', headers=auth_headers)
        assert resp.status_code == 400

    def test_detect_invalid_file_type(self, client, auth_headers):
        """Returns 400 for unsupported file extension."""
        data = {'image': make_test_image(filename='test.txt')}
        resp = client.post('/api/ingredients/detect', data=data,
                           content_type='multipart/form-data', headers=auth_headers)
        assert resp.status_code == 400
        assert 'Invalid file type' in resp.get_json()['error']

    @patch('app.api.ingredients.get_vision_detector')
    def test_detect_image_too_large(self, mock_get_det, client, auth_headers):
        """Returns 400 for image exceeding 10MB."""
        mock_get_det.return_value = make_mock_detector()
        # 10MB + 1 byte
        data = {'image': make_test_image(size=10 * 1024 * 1024 + 1)}
        resp = client.post('/api/ingredients/detect', data=data,
                           content_type='multipart/form-data', headers=auth_headers)
        assert resp.status_code == 400
        assert 'too large' in resp.get_json()['error']


class TestDetectEndpointSuccess:
    """Tests for successful detection responses."""

    @patch('app.api.ingredients.get_vision_detector')
    def test_detect_successful_with_detections(self, mock_get_det, client, auth_headers, sample_ingredients):
        """Returns 200 with correct response structure when detections found."""
        detections = [
            {'name': 'Chicken', 'confidence': 0.95, 'bbox': [], 'google_label': 'chicken', 'source': 'label'},
            {'name': 'Tomato', 'confidence': 0.8, 'bbox': [], 'google_label': 'tomato', 'source': 'label'},
        ]
        mock_get_det.return_value = make_mock_detector(detections=detections)

        data = {'image': make_test_image()}
        resp = client.post('/api/ingredients/detect', data=data,
                           content_type='multipart/form-data', headers=auth_headers)

        assert resp.status_code == 200
        body = resp.get_json()
        assert body['message'] == 'Ingredient detection successful'
        assert body['total_detected'] == 2
        assert 'Chicken' in body['ingredient_names']
        assert 'Tomato' in body['ingredient_names']

    @patch('app.api.ingredients.get_vision_detector')
    def test_detect_maps_to_db_ingredients(self, mock_get_det, client, auth_headers, sample_ingredients):
        """detected_ingredients populated from DB for matching names."""
        detections = [
            {'name': 'Pineapple', 'confidence': 0.9, 'bbox': [], 'google_label': 'pineapple', 'source': 'label'},
        ]
        mock_get_det.return_value = make_mock_detector(detections=detections)

        data = {'image': make_test_image()}
        resp = client.post('/api/ingredients/detect', data=data,
                           content_type='multipart/form-data', headers=auth_headers)

        body = resp.get_json()
        assert len(body['detected_ingredients']) == 1
        assert body['detected_ingredients'][0]['name'] == 'Pineapple'
        assert body['detected_ingredients'][0]['category'] == 'Fruits'

    @patch('app.api.ingredients.get_vision_detector')
    def test_detect_high_confidence_filter(self, mock_get_det, client, auth_headers, sample_ingredients):
        """Only detections >= 0.7 in high_confidence_ingredients."""
        detections = [
            {'name': 'Chicken', 'confidence': 0.95, 'bbox': [], 'google_label': 'chicken', 'source': 'label'},
            {'name': 'Garlic', 'confidence': 0.5, 'bbox': [], 'google_label': 'garlic', 'source': 'label'},
        ]
        mock_get_det.return_value = make_mock_detector(detections=detections)

        data = {'image': make_test_image()}
        resp = client.post('/api/ingredients/detect', data=data,
                           content_type='multipart/form-data', headers=auth_headers)

        body = resp.get_json()
        assert 'Chicken' in body['high_confidence_ingredients']
        assert 'Garlic' not in body['high_confidence_ingredients']

    @patch('app.api.ingredients.get_vision_detector')
    def test_detect_no_detections(self, mock_get_det, client, auth_headers):
        """Returns 200 with total_detected: 0 when Vision returns empty."""
        mock_get_det.return_value = make_mock_detector(detections=[])

        data = {'image': make_test_image()}
        resp = client.post('/api/ingredients/detect', data=data,
                           content_type='multipart/form-data', headers=auth_headers)

        assert resp.status_code == 200
        body = resp.get_json()
        assert body['total_detected'] == 0
        assert body['ingredient_names'] == []

    @patch('app.api.ingredients.get_vision_detector')
    def test_detect_vision_unavailable(self, mock_get_det, client, auth_headers):
        """Returns 200 with 0 detections when vision is unavailable."""
        mock_get_det.return_value = make_mock_detector(available=False)

        data = {'image': make_test_image()}
        resp = client.post('/api/ingredients/detect', data=data,
                           content_type='multipart/form-data', headers=auth_headers)

        assert resp.status_code == 200
        body = resp.get_json()
        assert body['total_detected'] == 0

    @patch('app.api.ingredients.get_vision_detector')
    def test_detect_returns_debug_info(self, mock_get_det, client, auth_headers):
        """Response includes debug_info with detection_source and vision_available."""
        detections = [
            {'name': 'Onion', 'confidence': 0.85, 'bbox': [], 'google_label': 'onion', 'source': 'label'},
        ]
        mock_get_det.return_value = make_mock_detector(detections=detections)

        data = {'image': make_test_image()}
        resp = client.post('/api/ingredients/detect', data=data,
                           content_type='multipart/form-data', headers=auth_headers)

        body = resp.get_json()
        assert 'debug_info' in body
        assert body['debug_info']['detection_source'] == 'google_vision'
        assert body['debug_info']['vision_available'] is True
