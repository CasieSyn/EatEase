from datetime import datetime
from app import db


class UserPreference(db.Model):
    __tablename__ = 'user_preferences'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)

    # Dietary preferences
    is_vegetarian = db.Column(db.Boolean, default=False)
    is_vegan = db.Column(db.Boolean, default=False)
    is_gluten_free = db.Column(db.Boolean, default=False)
    is_dairy_free = db.Column(db.Boolean, default=False)

    # Allergies (stored as JSON array)
    allergies = db.Column(db.JSON)  # ['peanuts', 'shellfish', etc.]

    # Disliked ingredients (stored as JSON array of ingredient IDs)
    disliked_ingredients = db.Column(db.JSON)

    # Preferred cuisines (stored as JSON array)
    preferred_cuisines = db.Column(db.JSON)  # ['Filipino', 'Italian', etc.]

    # Cooking preferences
    max_prep_time = db.Column(db.Integer)  # Maximum preparation time in minutes
    skill_level = db.Column(db.String(20))  # beginner, intermediate, advanced

    # Nutritional goals (daily targets)
    target_calories = db.Column(db.Integer)
    target_protein = db.Column(db.Float)
    target_carbs = db.Column(db.Float)
    target_fat = db.Column(db.Float)

    # Meal planning preferences
    meals_per_day = db.Column(db.Integer, default=3)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        """Convert user preferences to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'dietary': {
                'is_vegetarian': self.is_vegetarian,
                'is_vegan': self.is_vegan,
                'is_gluten_free': self.is_gluten_free,
                'is_dairy_free': self.is_dairy_free
            },
            'allergies': self.allergies or [],
            'disliked_ingredients': self.disliked_ingredients or [],
            'preferred_cuisines': self.preferred_cuisines or [],
            'cooking': {
                'max_prep_time': self.max_prep_time,
                'skill_level': self.skill_level
            },
            'nutritional_goals': {
                'target_calories': self.target_calories,
                'target_protein': self.target_protein,
                'target_carbs': self.target_carbs,
                'target_fat': self.target_fat
            },
            'meals_per_day': self.meals_per_day,
            'updated_at': self.updated_at.isoformat()
        }

    def __repr__(self):
        return f'<UserPreference for User {self.user_id}>'
