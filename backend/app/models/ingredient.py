from datetime import datetime
from app import db


class Ingredient(db.Model):
    __tablename__ = 'ingredients'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False, index=True)
    category = db.Column(db.String(50))  # vegetable, protein, dairy, grain, etc.

    # Nutritional information per 100g
    calories = db.Column(db.Float)
    protein = db.Column(db.Float)
    carbohydrates = db.Column(db.Float)
    fat = db.Column(db.Float)
    fiber = db.Column(db.Float)

    # Common measurements
    common_unit = db.Column(db.String(20))  # g, ml, piece, cup, etc.

    # Metadata
    image_url = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    recipe_ingredients = db.relationship(
        'RecipeIngredient',
        backref='ingredient',
        lazy='dynamic',
        cascade='all, delete-orphan'
    )

    def to_dict(self):
        """Convert ingredient to dictionary"""
        return {
            'id': self.id,
            'name': self.name,
            'category': self.category,
            'nutrition': {
                'calories': self.calories,
                'protein': self.protein,
                'carbohydrates': self.carbohydrates,
                'fat': self.fat,
                'fiber': self.fiber
            },
            'common_unit': self.common_unit,
            'image_url': self.image_url
        }

    def __repr__(self):
        return f'<Ingredient {self.name}>'


class RecipeIngredient(db.Model):
    __tablename__ = 'recipe_ingredients'

    id = db.Column(db.Integer, primary_key=True)
    recipe_id = db.Column(db.Integer, db.ForeignKey('recipes.id'), nullable=False)
    ingredient_id = db.Column(db.Integer, db.ForeignKey('ingredients.id'), nullable=False)

    # Quantity information
    quantity = db.Column(db.Float, nullable=False)
    unit = db.Column(db.String(20), nullable=False)  # g, ml, piece, cup, etc.

    # Optional specifications
    preparation = db.Column(db.String(100))  # chopped, diced, sliced, etc.
    is_optional = db.Column(db.Boolean, default=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        """Convert recipe ingredient to dictionary"""
        ingredient_dict = self.ingredient.to_dict() if self.ingredient else None
        return {
            'id': self.id,
            'ingredient_id': self.ingredient_id,
            'ingredient_name': self.ingredient.name if self.ingredient else None,
            'ingredient': ingredient_dict,
            'quantity': self.quantity,
            'unit': self.unit,
            'preparation': self.preparation,
            'is_optional': self.is_optional
        }

    def __repr__(self):
        ing_name = self.ingredient.name if self.ingredient else "Unknown"
        return f'<RecipeIngredient {self.quantity}{self.unit} of {ing_name}>'
