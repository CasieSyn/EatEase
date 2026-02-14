"""
ML Module for EatEase
Handles ingredient detection via Google Vision and recipe recommendations
"""

from .recipe_recommender import RecipeRecommender
from .google_vision_detector import GoogleVisionDetector

__all__ = ['GoogleVisionDetector', 'RecipeRecommender']
