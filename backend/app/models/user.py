from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from app import db


class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)

    # Profile information
    first_name = db.Column(db.String(50))
    last_name = db.Column(db.String(50))
    phone = db.Column(db.String(20))
    profile_photo = db.Column(db.String(255))  # Path to profile photo

    # Subscription
    is_premium = db.Column(db.Boolean, default=False)
    subscription_expires = db.Column(db.DateTime)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = db.Column(db.DateTime)

    # Relationships
    preferences = db.relationship('UserPreference', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    meal_plans = db.relationship('MealPlan', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    shopping_lists = db.relationship('ShoppingList', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    pantry_items = db.relationship('UserPantry', backref='user', lazy='dynamic', cascade='all, delete-orphan')

    def set_password(self, password):
        """Hash and set password"""
        # Using scrypt method with optimized parameters for faster hashing
        # while maintaining security (salt_length=16 is default)
        self.password_hash = generate_password_hash(password, method='scrypt:32768:8:1')

    def check_password(self, password):
        """Verify password"""
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        """Convert user to dictionary"""
        # Combine first_name and last_name into full_name for Flutter app
        full_name = None
        if self.first_name and self.last_name:
            full_name = f"{self.first_name} {self.last_name}"
        elif self.first_name:
            full_name = self.first_name
        elif self.last_name:
            full_name = self.last_name

        return {
            'id': self.id,
            'email': self.email,
            'username': self.username,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'full_name': full_name,  # Added for Flutter app compatibility
            'phone': self.phone,
            'profile_photo': self.profile_photo,
            'is_premium': self.is_premium,
            'subscription_expires': self.subscription_expires.isoformat() if self.subscription_expires else None,
            'created_at': self.created_at.isoformat(),
            'last_login': self.last_login.isoformat() if self.last_login else None
        }

    def __repr__(self):
        return f'<User {self.username}>'
