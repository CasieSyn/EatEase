from datetime import datetime
from app import db


class ShoppingList(db.Model):
    __tablename__ = 'shopping_lists'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)

    # List details
    name = db.Column(db.String(100))  # Optional name for the list
    items = db.Column(db.JSON, nullable=False)  # Array of {ingredient_id, quantity, unit, is_purchased}

    # Status
    is_active = db.Column(db.Boolean, default=True)

    # Metadata
    generated_from_meal_plan = db.Column(db.Boolean, default=False)
    start_date = db.Column(db.Date)  # If generated from meal plan
    end_date = db.Column(db.Date)    # If generated from meal plan

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        """Convert shopping list to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'items': self.items or [],
            'is_active': self.is_active,
            'generated_from_meal_plan': self.generated_from_meal_plan,
            'start_date': self.start_date.isoformat() if self.start_date else None,
            'end_date': self.end_date.isoformat() if self.end_date else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }

    def __repr__(self):
        return f'<ShoppingList {self.name or self.id}>'
