from flask import request, jsonify, url_for, send_file
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
import os
from app import db
from app.models import User, UserPreference, MealPlan, ShoppingList
from app.api import users_bp


@users_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    """Get user profile"""
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    return jsonify({'user': user.to_dict()}), 200


@users_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """Update user profile"""
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json()

    # Update allowed fields
    if 'first_name' in data:
        user.first_name = data['first_name']
    if 'last_name' in data:
        user.last_name = data['last_name']
    if 'phone' in data:
        user.phone = data['phone']

    db.session.commit()

    return jsonify({
        'message': 'Profile updated successfully',
        'user': user.to_dict()
    }), 200


@users_bp.route('/profile/photo', methods=['POST'])
@jwt_required()
def upload_profile_photo():
    """Upload profile photo"""
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Check if file is present
    if 'photo' not in request.files:
        return jsonify({'error': 'No photo file provided'}), 400

    file = request.files['photo']

    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400

    # Validate file type
    allowed_extensions = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
    if '.' not in file.filename or \
       file.filename.rsplit('.', 1)[1].lower() not in allowed_extensions:
        return jsonify({'error': 'Invalid file type. Allowed: png, jpg, jpeg, gif, webp'}), 400

    # Create uploads directory if it doesn't exist
    upload_folder = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'uploads', 'profile_photos')
    os.makedirs(upload_folder, exist_ok=True)

    # Generate secure filename with user ID
    ext = file.filename.rsplit('.', 1)[1].lower()
    filename = f"user_{user_id}.{ext}"
    filepath = os.path.join(upload_folder, filename)

    # Delete old photo if exists
    if user.profile_photo and os.path.exists(user.profile_photo):
        try:
            os.remove(user.profile_photo)
        except:
            pass

    # Save new photo
    file.save(filepath)

    # Update user profile
    user.profile_photo = filepath

    db.session.commit()

    return jsonify({
        'message': 'Profile photo uploaded successfully',
        'user': user.to_dict()
    }), 200


@users_bp.route('/profile/photo/<int:user_id>', methods=['GET'])
def get_profile_photo(user_id):
    """Get profile photo"""
    user = User.query.get(user_id)

    if not user or not user.profile_photo:
        # Return default avatar
        return jsonify({'error': 'No profile photo found'}), 404

    if not os.path.exists(user.profile_photo):
        return jsonify({'error': 'Photo file not found'}), 404

    return send_file(user.profile_photo, mimetype='image/jpeg')


@users_bp.route('/preferences', methods=['GET'])
@jwt_required()
def get_preferences():
    """Get user preferences"""
    user_id = int(get_jwt_identity())
    preference = UserPreference.query.filter_by(user_id=user_id).first()

    if not preference:
        return jsonify({'preferences': None}), 200

    return jsonify({'preferences': preference.to_dict()}), 200


@users_bp.route('/preferences', methods=['POST', 'PUT'])
@jwt_required()
def update_preferences():
    """Create or update user preferences"""
    user_id = int(get_jwt_identity())
    data = request.get_json()

    preference = UserPreference.query.filter_by(user_id=user_id).first()

    if not preference:
        preference = UserPreference(user_id=user_id)
        db.session.add(preference)

    # Update dietary preferences
    if 'dietary' in data:
        dietary = data['dietary']
        preference.is_vegetarian = dietary.get('is_vegetarian', False)
        preference.is_vegan = dietary.get('is_vegan', False)
        preference.is_gluten_free = dietary.get('is_gluten_free', False)
        preference.is_dairy_free = dietary.get('is_dairy_free', False)

    if 'allergies' in data:
        preference.allergies = data['allergies']

    if 'disliked_ingredients' in data:
        preference.disliked_ingredients = data['disliked_ingredients']

    if 'preferred_cuisines' in data:
        preference.preferred_cuisines = data['preferred_cuisines']

    # Update cooking preferences
    if 'cooking' in data:
        cooking = data['cooking']
        preference.max_prep_time = cooking.get('max_prep_time')
        preference.skill_level = cooking.get('skill_level')

    # Update nutritional goals
    if 'nutritional_goals' in data:
        goals = data['nutritional_goals']
        preference.target_calories = goals.get('target_calories')
        preference.target_protein = goals.get('target_protein')
        preference.target_carbs = goals.get('target_carbs')
        preference.target_fat = goals.get('target_fat')

    if 'meals_per_day' in data:
        preference.meals_per_day = data['meals_per_day']

    db.session.commit()

    return jsonify({
        'message': 'Preferences updated successfully',
        'preferences': preference.to_dict()
    }), 200


@users_bp.route('/meal-plans', methods=['GET'])
def get_meal_plans():
    """Get user's meal plans"""
    # Debug: Print request headers
    print(f"DEBUG: Request headers: {dict(request.headers)}")
    print(f"DEBUG: Authorization header: {request.headers.get('Authorization', 'NOT FOUND')}")

    # Now apply JWT requirement
    from flask_jwt_extended import verify_jwt_in_request
    try:
        verify_jwt_in_request()
        user_id = int(get_jwt_identity())  # Convert string to int
        print(f"DEBUG: Successfully got user_id: {user_id}")
    except Exception as e:
        print(f"DEBUG: JWT Error in get_meal_plans: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'JWT Error: {str(e)}'}), 422

    # Query parameters
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')

    query = MealPlan.query.filter_by(user_id=user_id)

    if start_date:
        query = query.filter(MealPlan.planned_date >= start_date)
    if end_date:
        query = query.filter(MealPlan.planned_date <= end_date)

    meal_plans = query.order_by(MealPlan.planned_date).all()

    return jsonify({
        'meal_plans': [mp.to_dict() for mp in meal_plans]
    }), 200


@users_bp.route('/meal-plans', methods=['POST'])
@jwt_required()
def create_meal_plan():
    """Create a new meal plan"""
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data or not data.get('recipe_id') or not data.get('planned_date'):
        return jsonify({'error': 'Recipe ID and planned date are required'}), 400

    # Verify recipe exists
    from app.models import Recipe
    recipe = Recipe.query.get(data['recipe_id'])
    if not recipe:
        return jsonify({'error': 'Recipe not found'}), 404

    meal_plan = MealPlan(
        user_id=user_id,
        recipe_id=data['recipe_id'],
        planned_date=data['planned_date'],
        meal_type=data.get('meal_type', 'lunch')
    )

    db.session.add(meal_plan)
    db.session.commit()

    return jsonify({
        'message': 'Meal plan created successfully',
        'meal_plan': meal_plan.to_dict()
    }), 201


@users_bp.route('/meal-plans/<int:meal_plan_id>', methods=['PUT'])
@jwt_required()
def update_meal_plan(meal_plan_id):
    """Update a meal plan"""
    user_id = int(get_jwt_identity())
    meal_plan = MealPlan.query.filter_by(id=meal_plan_id, user_id=user_id).first()

    if not meal_plan:
        return jsonify({'error': 'Meal plan not found'}), 404

    data = request.get_json()

    if 'recipe_id' in data:
        meal_plan.recipe_id = data['recipe_id']
    if 'planned_date' in data:
        meal_plan.planned_date = data['planned_date']
    if 'meal_type' in data:
        meal_plan.meal_type = data['meal_type']
    if 'is_completed' in data:
        meal_plan.is_completed = data['is_completed']
        if data['is_completed']:
            from datetime import datetime
            meal_plan.completed_at = datetime.utcnow()
    if 'user_rating' in data:
        meal_plan.user_rating = data['user_rating']
    if 'user_notes' in data:
        meal_plan.user_notes = data['user_notes']

    db.session.commit()

    return jsonify({
        'message': 'Meal plan updated successfully',
        'meal_plan': meal_plan.to_dict()
    }), 200


@users_bp.route('/meal-plans/<int:meal_plan_id>', methods=['DELETE'])
@jwt_required()
def delete_meal_plan(meal_plan_id):
    """Delete a meal plan"""
    user_id = int(get_jwt_identity())
    meal_plan = MealPlan.query.filter_by(id=meal_plan_id, user_id=user_id).first()

    if not meal_plan:
        return jsonify({'error': 'Meal plan not found'}), 404

    db.session.delete(meal_plan)
    db.session.commit()

    return jsonify({'message': 'Meal plan deleted successfully'}), 200


@users_bp.route('/shopping-lists', methods=['GET'])
@jwt_required()
def get_shopping_lists():
    """Get user's shopping lists"""
    user_id = int(get_jwt_identity())

    active_only = request.args.get('active_only', 'true').lower() == 'true'

    query = ShoppingList.query.filter_by(user_id=user_id)

    if active_only:
        query = query.filter_by(is_active=True)

    shopping_lists = query.order_by(ShoppingList.created_at.desc()).all()

    return jsonify({
        'shopping_lists': [sl.to_dict() for sl in shopping_lists]
    }), 200


@users_bp.route('/shopping-lists/generate', methods=['POST'])
@jwt_required()
def generate_shopping_list():
    """Generate shopping list from meal plans"""
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data or not data.get('start_date') or not data.get('end_date'):
        return jsonify({'error': 'Start date and end date are required'}), 400

    # Get meal plans for the date range
    meal_plans = MealPlan.query.filter_by(user_id=user_id).filter(
        MealPlan.planned_date >= data['start_date'],
        MealPlan.planned_date <= data['end_date']
    ).all()

    if not meal_plans:
        return jsonify({'error': 'No meal plans found for the specified dates'}), 404

    # Aggregate ingredients from all recipes
    ingredient_map = {}

    for meal_plan in meal_plans:
        recipe = meal_plan.recipe
        for recipe_ing in recipe.ingredients.all():
            ing_id = recipe_ing.ingredient_id
            ing_name = recipe_ing.ingredient.name

            if ing_id in ingredient_map:
                # Same ingredient, add quantity (simple addition for now)
                ingredient_map[ing_id]['quantity'] += recipe_ing.quantity
            else:
                ingredient_map[ing_id] = {
                    'ingredient_id': ing_id,
                    'ingredient_name': ing_name,
                    'quantity': recipe_ing.quantity,
                    'unit': recipe_ing.unit,
                    'is_purchased': False
                }

    # Create shopping list items
    items = list(ingredient_map.values())

    shopping_list = ShoppingList(
        user_id=user_id,
        name=f"Shopping List ({data['start_date']} to {data['end_date']})",
        items=items,
        generated_from_meal_plan=True,
        start_date=data['start_date'],
        end_date=data['end_date'],
        is_active=True
    )

    db.session.add(shopping_list)
    db.session.commit()

    return jsonify({
        'message': 'Shopping list generated successfully',
        'shopping_list': shopping_list.to_dict()
    }), 201


@users_bp.route('/shopping-lists/<int:list_id>', methods=['PUT'])
@jwt_required()
def update_shopping_list(list_id):
    """Update shopping list"""
    user_id = int(get_jwt_identity())
    shopping_list = ShoppingList.query.filter_by(id=list_id, user_id=user_id).first()

    if not shopping_list:
        return jsonify({'error': 'Shopping list not found'}), 404

    data = request.get_json()

    if 'items' in data:
        shopping_list.items = data['items']
    if 'is_active' in data:
        shopping_list.is_active = data['is_active']
    if 'name' in data:
        shopping_list.name = data['name']

    db.session.commit()

    return jsonify({
        'message': 'Shopping list updated successfully',
        'shopping_list': shopping_list.to_dict()
    }), 200


@users_bp.route('/shopping-lists/<int:list_id>', methods=['DELETE'])
@jwt_required()
def delete_shopping_list(list_id):
    """Delete shopping list"""
    user_id = int(get_jwt_identity())
    shopping_list = ShoppingList.query.filter_by(id=list_id, user_id=user_id).first()

    if not shopping_list:
        return jsonify({'error': 'Shopping list not found'}), 404

    db.session.delete(shopping_list)
    db.session.commit()

    return jsonify({'message': 'Shopping list deleted successfully'}), 200
