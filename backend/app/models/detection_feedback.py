"""
Detection Feedback Model
Stores user corrections to improve ingredient detection accuracy over time
"""

from datetime import datetime
from app import db


class DetectionFeedback(db.Model):
    """
    Stores feedback when users correct AI detection results.
    Used to learn and improve future detections.
    """
    __tablename__ = 'detection_feedback'

    id = db.Column(db.Integer, primary_key=True)

    # What Google Vision detected (the raw label)
    detected_label = db.Column(db.String(100), nullable=False, index=True)

    # What the AI mapped it to (could be None if unmapped)
    ai_mapped_ingredient = db.Column(db.String(100), nullable=True)

    # What the user said it actually is (the correct ingredient name)
    correct_ingredient = db.Column(db.String(100), nullable=False, index=True)

    # Reference to the ingredient in the database (if exists)
    correct_ingredient_id = db.Column(db.Integer, db.ForeignKey('ingredients.id'), nullable=True)

    # Number of times this correction has been made (for confidence)
    correction_count = db.Column(db.Integer, default=1)

    # Confidence boost - increases with more corrections
    learned_confidence = db.Column(db.Float, default=0.5)

    # User who made the correction (for tracking)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    ingredient = db.relationship('Ingredient', backref='detection_feedbacks')
    user = db.relationship('User', backref='detection_feedbacks')

    def __repr__(self):
        return f'<DetectionFeedback {self.detected_label} -> {self.correct_ingredient}>'

    def to_dict(self):
        return {
            'id': self.id,
            'detected_label': self.detected_label,
            'ai_mapped_ingredient': self.ai_mapped_ingredient,
            'correct_ingredient': self.correct_ingredient,
            'correct_ingredient_id': self.correct_ingredient_id,
            'correction_count': self.correction_count,
            'learned_confidence': self.learned_confidence,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

    @classmethod
    def get_learned_mapping(cls, detected_label):
        """
        Get the learned correct ingredient for a detected label.
        Returns the mapping with highest correction count.
        """
        feedback = cls.query.filter_by(detected_label=detected_label.lower()) \
            .order_by(cls.correction_count.desc()) \
            .first()
        return feedback

    @classmethod
    def add_or_update_feedback(cls, detected_label, correct_ingredient,
                                ai_mapped=None, ingredient_id=None, user_id=None):
        """
        Add new feedback or increment existing correction count.
        """
        detected_label = detected_label.lower().strip()

        # Check if this correction already exists
        existing = cls.query.filter_by(
            detected_label=detected_label,
            correct_ingredient=correct_ingredient
        ).first()

        if existing:
            # Increment correction count and boost confidence
            existing.correction_count += 1
            # Confidence increases with more corrections (max 0.99)
            existing.learned_confidence = min(0.99, 0.5 + (existing.correction_count * 0.1))
            existing.updated_at = datetime.utcnow()
            db.session.commit()
            return existing
        else:
            # Create new feedback entry
            feedback = cls(
                detected_label=detected_label,
                ai_mapped_ingredient=ai_mapped,
                correct_ingredient=correct_ingredient,
                correct_ingredient_id=ingredient_id,
                user_id=user_id,
                correction_count=1,
                learned_confidence=0.5
            )
            db.session.add(feedback)
            db.session.commit()
            return feedback

    @classmethod
    def get_all_learned_mappings(cls, min_corrections=1):
        """
        Get all learned mappings with at least min_corrections.
        Returns a dictionary of detected_label -> correct_ingredient.
        """
        feedbacks = cls.query.filter(cls.correction_count >= min_corrections).all()
        mappings = {}
        for feedback in feedbacks:
            # Only use the mapping with highest correction count for each label
            if feedback.detected_label not in mappings or \
               feedback.correction_count > mappings[feedback.detected_label]['count']:
                mappings[feedback.detected_label] = {
                    'ingredient': feedback.correct_ingredient,
                    'count': feedback.correction_count,
                    'confidence': feedback.learned_confidence
                }
        return mappings
