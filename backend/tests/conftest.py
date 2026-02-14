"""Shared test fixtures for ingredient detection tests."""

import io
import pytest
from unittest.mock import MagicMock

from app import create_app, db as _db
from app.models import User, Ingredient
from flask_jwt_extended import create_access_token


@pytest.fixture
def app():
    """Create Flask application for testing."""
    app = create_app('testing')
    yield app


@pytest.fixture(autouse=True)
def db_session(app):
    """Fresh DB per test — drops and recreates all tables."""
    with app.app_context():
        _db.create_all()
        yield _db.session
        _db.session.remove()
        _db.drop_all()


@pytest.fixture
def client(app):
    """Flask test client."""
    return app.test_client()


@pytest.fixture
def test_user(app, db_session):
    """Create a test user."""
    user = User(
        email='test@eatease.com',
        username='testuser',
    )
    user.set_password('testpassword123')
    db_session.add(user)
    db_session.flush()
    return user


@pytest.fixture
def auth_token(app, test_user):
    """JWT auth token for the test user."""
    with app.app_context():
        token = create_access_token(identity=str(test_user.id))
        return token


@pytest.fixture
def auth_headers(auth_token):
    """Headers dict with Authorization Bearer token."""
    return {'Authorization': f'Bearer {auth_token}'}


@pytest.fixture
def sample_ingredients(db_session):
    """Seed ingredients that match VISION_TO_INGREDIENT mappings."""
    ingredients = [
        Ingredient(name='Pineapple', category='Fruits', calories=50, common_unit='pieces'),
        Ingredient(name='Chicken', category='Protein', calories=239, common_unit='grams'),
        Ingredient(name='Tomato', category='Vegetables', calories=18, common_unit='pieces'),
        Ingredient(name='Onion', category='Vegetables', calories=40, common_unit='pieces'),
        Ingredient(name='Garlic', category='Vegetables', calories=149, common_unit='cloves'),
    ]
    for ing in ingredients:
        db_session.add(ing)
    db_session.flush()
    return ingredients


def make_test_image(filename='test.jpg', content=b'fake-image-bytes', size=None):
    """Helper to create a fake image file for multipart upload."""
    if size:
        content = b'x' * size
    return (io.BytesIO(content), filename)


def make_mock_detector(available=True, detections=None):
    """Create a mock GoogleVisionDetector."""
    mock = MagicMock()
    mock.available = available
    mock.detect_from_bytes.return_value = detections or []
    return mock
