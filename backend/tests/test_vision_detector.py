"""Unit tests for GoogleVisionDetector mapping and deduplication logic."""

import pytest
from unittest.mock import patch

from app.ml.google_vision_detector import GoogleVisionDetector


@pytest.fixture
def detector():
    """Create a GoogleVisionDetector with Vision API disabled (no real API calls).
    We then manually enable mapping methods for testing."""
    with patch.dict('app.ml.google_vision_detector.__builtins__', {}):
        pass
    # Instantiate with VISION_AVAILABLE=False so __init__ returns early
    with patch('app.ml.google_vision_detector.VISION_AVAILABLE', False):
        det = GoogleVisionDetector()
    # Clear any learned mappings cache to avoid cross-test pollution
    GoogleVisionDetector._learned_mappings_cache = {}
    GoogleVisionDetector._cache_timestamp = None
    return det


class TestMapToIngredient:
    """Tests for _map_to_ingredient method."""

    def test_direct_mapping(self, detector, app):
        """Known labels map to correct ingredients."""
        with app.app_context():
            assert detector._map_to_ingredient('pineapple') == 'Pineapple'
            assert detector._map_to_ingredient('chicken') == 'Chicken'
            assert detector._map_to_ingredient('tomato') == 'Tomato'

    def test_case_insensitive(self, detector, app):
        """Mapping is case-insensitive (input lowercased)."""
        with app.app_context():
            assert detector._map_to_ingredient('TOMATO') == 'Tomato'
            assert detector._map_to_ingredient('Garlic') == 'Garlic'

    def test_whitespace_stripped(self, detector, app):
        """Leading/trailing whitespace is stripped."""
        with app.app_context():
            assert detector._map_to_ingredient('  garlic  ') == 'Garlic'
            assert detector._map_to_ingredient('\tonion\n') == 'Onion'

    def test_unmapped_returns_none(self, detector, app):
        """Unknown labels return None."""
        with app.app_context():
            assert detector._map_to_ingredient('laptop') is None
            assert detector._map_to_ingredient('skyscraper') is None

    def test_null_mapped_returns_none(self, detector, app):
        """Labels explicitly mapped to None in VISION_TO_INGREDIENT return None."""
        with app.app_context():
            # These are in the dict but mapped to None (generic terms)
            assert detector._map_to_ingredient('food') is None
            assert detector._map_to_ingredient('dish') is None
            assert detector._map_to_ingredient('cuisine') is None

    def test_partial_match(self, detector, app):
        """Partial matches work when valid (whole word or length ratio)."""
        with app.app_context():
            assert detector._map_to_ingredient('fresh carrot') == 'Carrot'

    def test_partial_match_short_rejected(self, detector, app):
        """Very short strings don't trigger partial matches."""
        with app.app_context():
            # "car" is < 4 chars, should NOT match "carrot"
            assert detector._map_to_ingredient('car') is None


class TestIsValidPartialMatch:
    """Tests for _is_valid_partial_match static method."""

    def test_short_strings_rejected(self):
        """Strings under 4 chars are rejected."""
        assert GoogleVisionDetector._is_valid_partial_match('ab', 'abc') is False
        assert GoogleVisionDetector._is_valid_partial_match('cat', 'cat food') is False

    def test_whole_word_match(self):
        """Shorter string appears as whole word in longer string."""
        assert GoogleVisionDetector._is_valid_partial_match('carrot', 'fresh carrot') is True
        assert GoogleVisionDetector._is_valid_partial_match('chicken', 'grilled chicken breast') is True

    def test_length_ratio_match(self):
        """Strings with >= 70% length ratio match even without word boundary."""
        # "carro" (5) / "carrot" (6) = 83% → should match
        assert GoogleVisionDetector._is_valid_partial_match('carro', 'carrot') is True

    def test_low_ratio_no_word_rejected(self):
        """Low ratio without word boundary is rejected."""
        # "pine" (4) / "pineapple juice" (15) = 27% and "pine" is a word boundary in "pineapple juice"
        # Actually "pine" IS a whole word boundary at start... let's use a better example
        # "appl" (4) / "pineapple" (9) = 44% and "appl" is NOT a word boundary
        assert GoogleVisionDetector._is_valid_partial_match('appl', 'pineapple') is False


class TestRemoveDuplicates:
    """Tests for _remove_duplicates method."""

    def test_keeps_highest_confidence(self, detector):
        """When same ingredient detected twice, keeps highest confidence."""
        detections = [
            {'name': 'Chicken', 'confidence': 0.8, 'bbox': [], 'source': 'label'},
            {'name': 'Chicken', 'confidence': 0.95, 'bbox': [], 'source': 'object'},
        ]
        result = detector._remove_duplicates(detections)
        chicken = [d for d in result if d['name'] == 'Chicken']
        assert len(chicken) == 1
        assert chicken[0]['confidence'] == 0.95

    def test_preserves_unmapped(self, detector):
        """Unmapped detections (name=None) are all preserved separately."""
        detections = [
            {'name': None, 'confidence': 0.9, 'bbox': [], 'google_label': 'fruit', 'source': 'label_raw'},
            {'name': None, 'confidence': 0.7, 'bbox': [], 'google_label': 'food', 'source': 'label_raw'},
            {'name': 'Chicken', 'confidence': 0.8, 'bbox': [], 'source': 'label'},
        ]
        result = detector._remove_duplicates(detections)
        unmapped = [d for d in result if d['name'] is None]
        assert len(unmapped) == 2

    def test_no_duplicates_unchanged(self, detector):
        """All different names → all kept."""
        detections = [
            {'name': 'Chicken', 'confidence': 0.9, 'bbox': [], 'source': 'label'},
            {'name': 'Tomato', 'confidence': 0.8, 'bbox': [], 'source': 'label'},
            {'name': 'Garlic', 'confidence': 0.7, 'bbox': [], 'source': 'object'},
        ]
        result = detector._remove_duplicates(detections)
        assert len(result) == 3
