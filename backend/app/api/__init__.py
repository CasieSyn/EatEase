from flask import Blueprint

# Create blueprints
auth_bp = Blueprint('auth', __name__)
recipes_bp = Blueprint('recipes', __name__)
ingredients_bp = Blueprint('ingredients', __name__)
users_bp = Blueprint('users', __name__)

# Import routes
from app.api import auth, recipes, ingredients, users

__all__ = ['auth_bp', 'recipes_bp', 'ingredients_bp', 'users_bp']
