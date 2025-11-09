"""
ML Module for EatEase
Handles ingredient detection, image preprocessing, and recipe recommendations
"""

from .ingredient_detector import IngredientDetector
from .image_preprocessor import ImagePreprocessor
from .recipe_recommender import RecipeRecommender

__all__ = ['IngredientDetector', 'ImagePreprocessor', 'RecipeRecommender']
