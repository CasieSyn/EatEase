from flask import request, jsonify, current_app
from flask_jwt_extended import jwt_required
from app import db
from app.models import Ingredient
from app.api import ingredients_bp
from app.ml import IngredientDetector
import os
from werkzeug.utils import secure_filename

# Initialize ingredient detector (will load model if available)
detector = None

def get_detector():
    """Lazy load detector instance"""
    global detector
    if detector is None:
        model_path = current_app.config.get('YOLO_MODEL_PATH', 'models/yolov8n.pt')
        confidence = current_app.config.get('YOLO_CONFIDENCE_THRESHOLD', 0.5)
        detector = IngredientDetector(model_path=model_path, confidence_threshold=confidence)

        # Download model if not exists
        if not os.path.exists(model_path):
            detector.download_model()

    return detector


@ingredients_bp.route('/', methods=['GET'])
def get_ingredients():
    """Get all ingredients with optional filters"""
    category = request.args.get('category')
    search = request.args.get('search')

    # Pagination
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 50, type=int)

    # Build query
    query = Ingredient.query

    if category:
        query = query.filter_by(category=category)

    if search:
        query = query.filter(Ingredient.name.ilike(f'%{search}%'))

    # Execute query with pagination
    paginated = query.order_by(Ingredient.name).paginate(
        page=page, per_page=per_page, error_out=False
    )

    return jsonify({
        'ingredients': [ingredient.to_dict() for ingredient in paginated.items],
        'total': paginated.total,
        'page': page,
        'per_page': per_page,
        'pages': paginated.pages
    }), 200


@ingredients_bp.route('/<int:ingredient_id>', methods=['GET'])
def get_ingredient(ingredient_id):
    """Get a specific ingredient by ID"""
    ingredient = Ingredient.query.get(ingredient_id)

    if not ingredient:
        return jsonify({'error': 'Ingredient not found'}), 404

    return jsonify({'ingredient': ingredient.to_dict()}), 200


@ingredients_bp.route('/detect', methods=['POST'])
@jwt_required()
def detect_ingredients():
    """Detect ingredients from uploaded image using YOLO"""
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']

    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    # Validate file extension
    allowed_extensions = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}
    if '.' not in file.filename or file.filename.rsplit('.', 1)[1].lower() not in allowed_extensions:
        return jsonify({'error': 'Invalid file type. Allowed: png, jpg, jpeg, gif, bmp'}), 400

    try:
        # Get detector instance
        det = get_detector()

        # Read image bytes
        image_bytes = file.read()

        # Detect ingredients
        detections = det.detect_from_bytes(image_bytes)

        # Get ingredient names
        ingredient_names = det.get_ingredient_names(detections)

        # Get high-confidence ingredients
        high_confidence = det.get_high_confidence_ingredients(detections, min_confidence=0.7)

        # Query database for detected ingredients
        detected_ingredients = []
        if ingredient_names:
            ingredients = Ingredient.query.filter(
                Ingredient.name.in_(ingredient_names)
            ).all()
            detected_ingredients = [ing.to_dict() for ing in ingredients]

        return jsonify({
            'message': 'Ingredient detection successful',
            'detections': detections,
            'ingredient_names': ingredient_names,
            'high_confidence_ingredients': high_confidence,
            'detected_ingredients': detected_ingredients,
            'total_detected': len(detections)
        }), 200

    except Exception as e:
        return jsonify({
            'error': 'Ingredient detection failed',
            'details': str(e)
        }), 500


@ingredients_bp.route('/', methods=['POST'])
@jwt_required()
def create_ingredient():
    """Create a new ingredient (admin feature)"""
    data = request.get_json()

    if not data or not data.get('name'):
        return jsonify({'error': 'Ingredient name is required'}), 400

    # Check if ingredient already exists
    existing = Ingredient.query.filter_by(name=data['name']).first()
    if existing:
        return jsonify({'error': 'Ingredient already exists'}), 400

    ingredient = Ingredient(
        name=data['name'],
        category=data.get('category'),
        calories=data.get('calories'),
        protein=data.get('protein'),
        carbohydrates=data.get('carbohydrates'),
        fat=data.get('fat'),
        fiber=data.get('fiber'),
        common_unit=data.get('common_unit'),
        image_url=data.get('image_url')
    )

    db.session.add(ingredient)
    db.session.commit()

    return jsonify({
        'message': 'Ingredient created successfully',
        'ingredient': ingredient.to_dict()
    }), 201
