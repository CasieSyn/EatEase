from datetime import datetime
from app import db


class Recipe(db.Model):
    __tablename__ = 'recipes'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False, index=True)
    description = db.Column(db.Text)

    # Recipe details
    cuisine_type = db.Column(db.String(50))  # Filipino, Italian, Chinese, etc.
    meal_type = db.Column(db.String(50))  # breakfast, lunch, dinner, snack
    difficulty_level = db.Column(db.String(20))  # easy, medium, hard

    # Time information (in minutes)
    prep_time = db.Column(db.Integer)
    cook_time = db.Column(db.Integer)
    total_time = db.Column(db.Integer)

    # Serving information
    servings = db.Column(db.Integer, default=1)

    # Instructions
    instructions = db.Column(db.JSON)  # Array of step-by-step instructions

    # Nutritional information (per serving)
    calories = db.Column(db.Float)
    protein = db.Column(db.Float)
    carbohydrates = db.Column(db.Float)
    fat = db.Column(db.Float)
    fiber = db.Column(db.Float)

    # Dietary information
    is_vegetarian = db.Column(db.Boolean, default=False)
    is_vegan = db.Column(db.Boolean, default=False)
    is_gluten_free = db.Column(db.Boolean, default=False)
    is_dairy_free = db.Column(db.Boolean, default=False)

    # Media
    image_url = db.Column(db.String(255))
    video_url = db.Column(db.String(255))

    # Rating and popularity
    rating = db.Column(db.Float, default=0.0)
    rating_count = db.Column(db.Integer, default=0)
    view_count = db.Column(db.Integer, default=0)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    ingredients = db.relationship('RecipeIngredient', backref='recipe', lazy='dynamic', cascade='all, delete-orphan')

    def to_dict(self, include_ingredients=True):
        """Convert recipe to dictionary"""
        data = {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'cuisine_type': self.cuisine_type,
            'meal_type': self.meal_type,
            'difficulty_level': self.difficulty_level,
            'time': {
                'prep_time': self.prep_time,
                'cook_time': self.cook_time,
                'total_time': self.total_time
            },
            'servings': self.servings,
            'instructions': self.instructions,
            'nutrition': {
                'calories': self.calories,
                'protein': self.protein,
                'carbohydrates': self.carbohydrates,
                'fat': self.fat,
                'fiber': self.fiber
            },
            'dietary': {
                'is_vegetarian': self.is_vegetarian,
                'is_vegan': self.is_vegan,
                'is_gluten_free': self.is_gluten_free,
                'is_dairy_free': self.is_dairy_free
            },
            'image_url': self.image_url,
            'video_url': self.video_url,
            'rating': self.rating,
            'rating_count': self.rating_count,
            'view_count': self.view_count,
            'created_at': self.created_at.isoformat()
        }

        if include_ingredients:
            data['ingredients'] = [ri.to_dict() for ri in self.ingredients.all()]

        return data

    def __repr__(self):
        return f'<Recipe {self.name}>'
