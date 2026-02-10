"""
ML Module for EatEase
Handles ingredient detection, image preprocessing, and recipe recommendations
"""

from .recipe_recommender import RecipeRecommender

try:
    from .ingredient_detector import IngredientDetector
    from .image_preprocessor import ImagePreprocessor
    ML_AVAILABLE = True
except (ImportError, AttributeError):
    IngredientDetector = None
    ImagePreprocessor = None
    ML_AVAILABLE = False

__all__ = ['IngredientDetector', 'ImagePreprocessor', 'RecipeRecommender', 'ML_AVAILABLE']
