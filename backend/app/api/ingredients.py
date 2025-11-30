from flask import request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import Ingredient, DetectionFeedback
from app.api import ingredients_bp
from app.ml import IngredientDetector
from app.ml.google_vision_detector import GoogleVisionDetector
import os

# Initialize detectors (will load when needed)
yolo_detector = None
vision_detector = None


def get_yolo_detector():
    """Lazy load YOLO detector instance"""
    global yolo_detector
    if yolo_detector is None:
        model_path = current_app.config.get('YOLO_MODEL_PATH', 'models/yolov8n.pt')
        confidence = current_app.config.get('YOLO_CONFIDENCE_THRESHOLD', 0.5)
        yolo_detector = IngredientDetector(model_path=model_path, confidence_threshold=confidence)

        # Download model if not exists
        if not os.path.exists(model_path):
            yolo_detector.download_model()

    return yolo_detector


def get_vision_detector():
    """Lazy load Google Vision detector instance"""
    global vision_detector
    if vision_detector is None:
        credentials_path = current_app.config.get('GOOGLE_VISION_CREDENTIALS')
        # Make path absolute relative to the backend directory
        if credentials_path and not os.path.isabs(credentials_path):
            # Get the backend directory (parent of app directory)
            backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            credentials_path = os.path.join(backend_dir, credentials_path)
        print(f"DEBUG: Loading Google Vision credentials from: {credentials_path}")
        vision_detector = GoogleVisionDetector(credentials_path=credentials_path)
        print(f"DEBUG: Google Vision available: {vision_detector.available}")
    return vision_detector


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
    """Detect ingredients from uploaded image using Google Vision (primary) + YOLO (fallback)"""
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
        # Read image bytes
        image_bytes = file.read()

        all_detections = []
        detection_source = 'none'

        # Try Google Vision first (much better for food detection)
        vision_det = get_vision_detector()
        if vision_det.available:
            vision_detections = vision_det.detect_from_bytes(image_bytes)
            if vision_detections:
                all_detections.extend(vision_detections)
                detection_source = 'google_vision'

        # Fallback to YOLO if Google Vision didn't find anything
        if not all_detections:
            yolo_det = get_yolo_detector()
            yolo_detections = yolo_det.detect_from_bytes(image_bytes)
            # Filter to only mapped detections
            all_detections = [d for d in yolo_detections if d.get('name') is not None]
            detection_source = 'yolo' if all_detections else 'none'

        # Extract ingredient names (filter None values)
        ingredient_names = list(set([d['name'] for d in all_detections if d.get('name')]))

        # Get high-confidence ingredients
        high_confidence = [
            d['name'] for d in all_detections
            if d.get('name') and d.get('confidence', 0) >= 0.7
        ]
        high_confidence = list(set(high_confidence))

        # Query database for detected ingredients
        detected_ingredients = []
        if ingredient_names:
            ingredients = Ingredient.query.filter(
                Ingredient.name.in_(ingredient_names)
            ).all()
            detected_ingredients = [ing.to_dict() for ing in ingredients]

        return jsonify({
            'message': 'Ingredient detection successful',
            'detections': all_detections,
            'ingredient_names': ingredient_names,
            'high_confidence_ingredients': high_confidence,
            'detected_ingredients': detected_ingredients,
            'total_detected': len(all_detections),
            'debug_info': {
                'detection_source': detection_source,
                'vision_available': vision_det.available if vision_det else False
            }
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


@ingredients_bp.route('/detect/feedback', methods=['POST'])
@jwt_required()
def submit_detection_feedback():
    """
    Submit feedback to correct AI detection results.
    This helps the system learn and improve future detections.

    Expected JSON body:
    {
        "corrections": [
            {
                "detected_label": "jackfruit",  # What Google Vision detected
                "ai_mapped": "Langka",          # What AI mapped it to (optional)
                "correct_ingredient": "Pineapple"  # What user says it actually is
            }
        ]
    }
    """
    data = request.get_json()

    if not data or not data.get('corrections'):
        return jsonify({'error': 'Corrections array is required'}), 400

    corrections = data.get('corrections', [])
    user_id = get_jwt_identity()

    results = []
    for correction in corrections:
        detected_label = correction.get('detected_label')
        correct_ingredient = correction.get('correct_ingredient')

        if not detected_label or not correct_ingredient:
            results.append({
                'error': 'Both detected_label and correct_ingredient are required',
                'correction': correction
            })
            continue

        # Look up ingredient ID if it exists in database
        ingredient = Ingredient.query.filter_by(name=correct_ingredient).first()
        ingredient_id = ingredient.id if ingredient else None

        # Add or update feedback
        feedback = DetectionFeedback.add_or_update_feedback(
            detected_label=detected_label,
            correct_ingredient=correct_ingredient,
            ai_mapped=correction.get('ai_mapped'),
            ingredient_id=ingredient_id,
            user_id=user_id
        )

        results.append({
            'success': True,
            'feedback': feedback.to_dict(),
            'message': f"Learned: '{detected_label}' -> '{correct_ingredient}'"
        })

    # Clear the learned mappings cache to pick up new corrections immediately
    GoogleVisionDetector._cache_timestamp = None

    return jsonify({
        'message': f'Processed {len(results)} corrections',
        'results': results,
        'tip': 'The AI will now use these corrections for future detections'
    }), 200


@ingredients_bp.route('/detect/learned-mappings', methods=['GET'])
def get_learned_mappings():
    """Get all learned mappings from user corrections"""
    mappings = DetectionFeedback.get_all_learned_mappings(min_corrections=1)

    return jsonify({
        'total_mappings': len(mappings),
        'mappings': [
            {
                'detected_label': label,
                'correct_ingredient': data['ingredient'],
                'correction_count': data['count'],
                'confidence': data['confidence']
            }
            for label, data in mappings.items()
        ]
    }), 200
