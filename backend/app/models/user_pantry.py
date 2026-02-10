from datetime import datetime
from app import db


class UserPantry(db.Model):
    """Model to track user's available ingredients (their pantry)"""
    __tablename__ = 'user_pantry'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    ingredient_id = db.Column(db.Integer, db.ForeignKey('ingredients.id'), nullable=False)

    # Quantity information (optional - user may just mark as "have" without quantity)
    quantity = db.Column(db.Float, nullable=True)
    unit = db.Column(db.String(20), nullable=True)

    # Expiry tracking (optional)
    expiry_date = db.Column(db.Date, nullable=True)

    # Timestamps
    added_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    ingredient = db.relationship('Ingredient', backref='pantry_entries')

    # Unique constraint: one entry per user-ingredient combination
    __table_args__ = (
        db.UniqueConstraint('user_id', 'ingredient_id', name='unique_user_ingredient'),
    )

    def to_dict(self):
        """Convert pantry item to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'ingredient_id': self.ingredient_id,
            'ingredient': self.ingredient.to_dict() if self.ingredient else None,
            'quantity': self.quantity,
            'unit': self.unit,
            'expiry_date': self.expiry_date.isoformat() if self.expiry_date else None,
            'added_at': self.added_at.isoformat() if self.added_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

    def __repr__(self):
        ing_name = self.ingredient.name if self.ingredient else "Unknown"
        return f'<UserPantry {ing_name} for user {self.user_id}>'
