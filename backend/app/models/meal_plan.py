from datetime import datetime
from app import db


class MealPlan(db.Model):
    __tablename__ = 'meal_plans'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    recipe_id = db.Column(db.Integer, db.ForeignKey('recipes.id'), nullable=False)

    # Planning details
    planned_date = db.Column(db.Date, nullable=False, index=True)
    meal_type = db.Column(db.String(50))  # breakfast, lunch, dinner, snack

    # Status
    is_completed = db.Column(db.Boolean, default=False)
    completed_at = db.Column(db.DateTime)

    # User feedback
    user_rating = db.Column(db.Integer)  # 1-5 stars
    user_notes = db.Column(db.Text)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    recipe = db.relationship('Recipe', backref='meal_plans')

    def to_dict(self):
        """Convert meal plan to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'recipe': self.recipe.to_dict(include_ingredients=False) if self.recipe else None,
            'planned_date': self.planned_date.isoformat(),
            'meal_type': self.meal_type,
            'is_completed': self.is_completed,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'user_rating': self.user_rating,
            'user_notes': self.user_notes,
            'created_at': self.created_at.isoformat()
        }

    def __repr__(self):
        return f'<MealPlan {self.planned_date} - {self.meal_type}>'
