from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import Recipe, RecipeIngredient, Ingredient
from app.api import recipes_bp
from app.ml import RecipeRecommender

# Initialize recommender
recommender = RecipeRecommender()


@recipes_bp.route('/', methods=['GET'])
def get_recipes():
    """Get all recipes with optional filters"""
    # Query parameters for filtering
    cuisine_type = request.args.get('cuisine_type')
    meal_type = request.args.get('meal_type')
    difficulty = request.args.get('difficulty')
    is_vegetarian = request.args.get('is_vegetarian')
    is_vegan = request.args.get('is_vegan')
    is_gluten_free = request.args.get('is_gluten_free')
    max_time = request.args.get('max_time', type=int)

    # Pagination
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)

    # Build query
    query = Recipe.query

    if cuisine_type:
        query = query.filter_by(cuisine_type=cuisine_type)
    if meal_type:
        query = query.filter_by(meal_type=meal_type)
    if difficulty:
        query = query.filter_by(difficulty_level=difficulty)
    if is_vegetarian:
        query = query.filter_by(is_vegetarian=True)
    if is_vegan:
        query = query.filter_by(is_vegan=True)
    if is_gluten_free:
        query = query.filter_by(is_gluten_free=True)
    if max_time:
        query = query.filter(Recipe.total_time <= max_time)

    # Execute query with pagination
    paginated = query.order_by(Recipe.rating.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )

    return jsonify({
        'recipes': [recipe.to_dict(include_ingredients=False) for recipe in paginated.items],
        'total': paginated.total,
        'page': page,
        'per_page': per_page,
        'pages': paginated.pages
    }), 200


@recipes_bp.route('/<int:recipe_id>', methods=['GET'])
def get_recipe(recipe_id):
    """Get a specific recipe by ID"""
    recipe = Recipe.query.get(recipe_id)

    if not recipe:
        return jsonify({'error': 'Recipe not found'}), 404

    # Increment view count
    recipe.view_count += 1
    db.session.commit()

    return jsonify({'recipe': recipe.to_dict()}), 200


@recipes_bp.route('/search', methods=['POST'])
def search_recipes():
    """Search recipes by available ingredients"""
    data = request.get_json()

    if not data or not data.get('ingredients'):
        return jsonify({'error': 'Ingredients list is required'}), 400

    ingredient_names = [ing.lower() for ing in data['ingredients']]

    # Find ingredient IDs
    ingredients = Ingredient.query.filter(
        db.func.lower(Ingredient.name).in_(ingredient_names)
    ).all()

    ingredient_ids = [ing.id for ing in ingredients]

    if not ingredient_ids:
        return jsonify({'recipes': []}), 200

    # Find recipes that use these ingredients
    recipes_query = db.session.query(Recipe).join(RecipeIngredient).filter(
        RecipeIngredient.ingredient_id.in_(ingredient_ids)
    ).distinct(Recipe.id)

    # Apply additional filters if provided
    if data.get('dietary_preferences'):
        prefs = data['dietary_preferences']
        if prefs.get('is_vegetarian'):
            recipes_query = recipes_query.filter_by(is_vegetarian=True)
        if prefs.get('is_vegan'):
            recipes_query = recipes_query.filter_by(is_vegan=True)
        if prefs.get('is_gluten_free'):
            recipes_query = recipes_query.filter_by(is_gluten_free=True)

    recipes = recipes_query.all()

    # Calculate match percentage for each recipe
    results = []
    for recipe in recipes:
        recipe_ingredient_ids = [ri.ingredient_id for ri in recipe.ingredients.all()]
        matching = len(set(ingredient_ids) & set(recipe_ingredient_ids))
        total = len(recipe_ingredient_ids)
        match_percentage = (matching / total * 100) if total > 0 else 0

        recipe_dict = recipe.to_dict()
        recipe_dict['match_percentage'] = round(match_percentage, 2)
        recipe_dict['matching_ingredients'] = matching
        recipe_dict['total_ingredients'] = total

        results.append(recipe_dict)

    # Sort by match percentage
    results.sort(key=lambda x: x['match_percentage'], reverse=True)

    return jsonify({'recipes': results}), 200


@recipes_bp.route('/', methods=['POST'])
@jwt_required()
def create_recipe():
    """Create a new recipe (admin/premium feature)"""
    data = request.get_json()

    if not data or not data.get('name'):
        return jsonify({'error': 'Recipe name is required'}), 400

    recipe = Recipe(
        name=data['name'],
        description=data.get('description'),
        cuisine_type=data.get('cuisine_type'),
        meal_type=data.get('meal_type'),
        difficulty_level=data.get('difficulty_level'),
        prep_time=data.get('prep_time'),
        cook_time=data.get('cook_time'),
        total_time=data.get('total_time'),
        servings=data.get('servings', 1),
        instructions=data.get('instructions'),
        calories=data.get('calories'),
        protein=data.get('protein'),
        carbohydrates=data.get('carbohydrates'),
        fat=data.get('fat'),
        fiber=data.get('fiber'),
        is_vegetarian=data.get('is_vegetarian', False),
        is_vegan=data.get('is_vegan', False),
        is_gluten_free=data.get('is_gluten_free', False),
        is_dairy_free=data.get('is_dairy_free', False),
        image_url=data.get('image_url')
    )

    db.session.add(recipe)
    db.session.commit()

    return jsonify({
        'message': 'Recipe created successfully',
        'recipe': recipe.to_dict()
    }), 201


@recipes_bp.route('/<int:recipe_id>', methods=['PUT'])
@jwt_required()
def update_recipe(recipe_id):
    """Update an existing recipe"""
    data = request.get_json()

    recipe = Recipe.query.get(recipe_id)
    if not recipe:
        return jsonify({'error': 'Recipe not found'}), 404

    # Update fields if provided
    if 'name' in data:
        recipe.name = data['name']
    if 'description' in data:
        recipe.description = data['description']
    if 'cuisine_type' in data:
        recipe.cuisine_type = data['cuisine_type']
    if 'meal_type' in data:
        recipe.meal_type = data['meal_type']
    if 'difficulty_level' in data:
        recipe.difficulty_level = data['difficulty_level']
    if 'prep_time' in data:
        recipe.prep_time = data['prep_time']
    if 'cook_time' in data:
        recipe.cook_time = data['cook_time']
    if 'total_time' in data:
        recipe.total_time = data['total_time']
    if 'servings' in data:
        recipe.servings = data['servings']
    if 'instructions' in data:
        recipe.instructions = data['instructions']
    if 'calories' in data:
        recipe.calories = data['calories']
    if 'protein' in data:
        recipe.protein = data['protein']
    if 'carbohydrates' in data:
        recipe.carbohydrates = data['carbohydrates']
    if 'fat' in data:
        recipe.fat = data['fat']
    if 'fiber' in data:
        recipe.fiber = data['fiber']
    if 'is_vegetarian' in data:
        recipe.is_vegetarian = data['is_vegetarian']
    if 'is_vegan' in data:
        recipe.is_vegan = data['is_vegan']
    if 'is_gluten_free' in data:
        recipe.is_gluten_free = data['is_gluten_free']
    if 'is_dairy_free' in data:
        recipe.is_dairy_free = data['is_dairy_free']
    if 'image_url' in data:
        recipe.image_url = data['image_url']

    db.session.commit()

    return jsonify({
        'message': 'Recipe updated successfully',
        'recipe': recipe.to_dict()
    }), 200


@recipes_bp.route('/<int:recipe_id>', methods=['DELETE'])
@jwt_required()
def delete_recipe(recipe_id):
    """Delete a recipe"""
    recipe = Recipe.query.get(recipe_id)
    if not recipe:
        return jsonify({'error': 'Recipe not found'}), 404

    # Delete associated recipe ingredients first
    RecipeIngredient.query.filter_by(recipe_id=recipe_id).delete()

    db.session.delete(recipe)
    db.session.commit()

    return jsonify({'message': 'Recipe deleted successfully'}), 200


@recipes_bp.route('/<int:recipe_id>/rate', methods=['POST'])
@jwt_required()
def rate_recipe(recipe_id):
    """Rate a recipe (1-5 stars)"""
    from app.models import MealPlan
    from datetime import datetime

    user_id = get_jwt_identity()
    data = request.get_json()

    if not data or 'rating' not in data:
        return jsonify({'error': 'Rating is required'}), 400

    rating = data['rating']
    if rating < 1 or rating > 5:
        return jsonify({'error': 'Rating must be between 1 and 5'}), 400

    recipe = Recipe.query.get(recipe_id)
    if not recipe:
        return jsonify({'error': 'Recipe not found'}), 404

    # Find user's meal plan with this recipe to store rating
    meal_plan = MealPlan.query.filter_by(
        user_id=user_id,
        recipe_id=recipe_id
    ).order_by(MealPlan.created_at.desc()).first()

    if meal_plan:
        meal_plan.user_rating = rating
        if 'notes' in data:
            meal_plan.user_notes = data['notes']
    else:
        # Create a meal plan entry for the rating
        meal_plan = MealPlan(
            user_id=user_id,
            recipe_id=recipe_id,
            planned_date=datetime.utcnow().date(),
            meal_type='lunch',
            is_completed=True,
            completed_at=datetime.utcnow(),
            user_rating=rating,
            user_notes=data.get('notes')
        )
        db.session.add(meal_plan)

    # Update recipe's average rating
    all_ratings = db.session.query(MealPlan.user_rating).filter(
        MealPlan.recipe_id == recipe_id,
        MealPlan.user_rating.isnot(None)
    ).all()

    if all_ratings:
        total_rating = sum([r[0] for r in all_ratings])
        recipe.rating = round(total_rating / len(all_ratings), 2)
        recipe.rating_count = len(all_ratings)

    db.session.commit()

    return jsonify({
        'message': 'Recipe rated successfully',
        'recipe': {
            'id': recipe.id,
            'name': recipe.name,
            'rating': recipe.rating,
            'rating_count': recipe.rating_count
        }
    }), 200


@recipes_bp.route('/recommend', methods=['POST'])
@jwt_required()
def get_recommendations():
    """Get personalized recipe recommendations for the user"""
    user_id = get_jwt_identity()
    data = request.get_json() or {}

    # Get optional parameters
    available_ingredients = data.get('ingredients', [])
    limit = data.get('limit', 10)

    # Get recommendations
    recommendations = recommender.recommend_for_user(
        user_id=user_id,
        available_ingredients=available_ingredients if available_ingredients else None,
        limit=limit
    )

    return jsonify({
        'recommendations': recommendations,
        'total': len(recommendations)
    }), 200


@recipes_bp.route('/recommend/quick', methods=['GET'])
def get_quick_recommendations():
    """Get quick recipe recommendations"""
    max_time = request.args.get('max_time', 30, type=int)
    limit = request.args.get('limit', 10, type=int)

    recommendations = recommender.recommend_quick_recipes(
        max_time=max_time,
        limit=limit
    )

    return jsonify({
        'recommendations': recommendations,
        'total': len(recommendations)
    }), 200


@recipes_bp.route('/recommend/cuisine/<cuisine_type>', methods=['GET'])
def get_cuisine_recommendations(cuisine_type):
    """Get recommendations by cuisine type"""
    limit = request.args.get('limit', 10, type=int)

    # Get optional dietary filters
    dietary_filters = {}
    if request.args.get('is_vegetarian'):
        dietary_filters['is_vegetarian'] = True
    if request.args.get('is_vegan'):
        dietary_filters['is_vegan'] = True
    if request.args.get('is_gluten_free'):
        dietary_filters['is_gluten_free'] = True
    if request.args.get('is_dairy_free'):
        dietary_filters['is_dairy_free'] = True

    recommendations = recommender.recommend_by_cuisine(
        cuisine_type=cuisine_type,
        limit=limit,
        dietary_filters=dietary_filters if dietary_filters else None
    )

    return jsonify({
        'recommendations': recommendations,
        'total': len(recommendations),
        'cuisine_type': cuisine_type
    }), 200


@recipes_bp.route('/<int:recipe_id>/image', methods=['GET'])
def get_recipe_image(recipe_id):
    """Fetch an image for a recipe using Google Custom Search"""
    from app.services.image_search_service import image_search_service

    recipe = Recipe.query.get(recipe_id)
    if not recipe:
        return jsonify({'error': 'Recipe not found'}), 404

    # If recipe already has an image, return it
    if recipe.image_url:
        return jsonify({'image_url': recipe.image_url}), 200

    # Search for an image
    image_url = image_search_service.search_food_image(
        recipe.name,
        cuisine_type=recipe.cuisine_type
    )

    if image_url:
        # Save the image URL to the recipe
        recipe.image_url = image_url
        db.session.commit()
        return jsonify({'image_url': image_url}), 200

    return jsonify({'error': 'No image found', 'image_url': None}), 200


@recipes_bp.route('/fetch-images', methods=['POST'])
@jwt_required()
def fetch_recipe_images():
    """Fetch images for multiple recipes that don't have images"""
    from app.services.image_search_service import image_search_service

    data = request.get_json() or {}
    limit = data.get('limit', 10)

    # Get recipes without images
    recipes_without_images = Recipe.query.filter(
        (Recipe.image_url.is_(None)) | (Recipe.image_url == '')
    ).limit(limit).all()

    updated_count = 0
    for recipe in recipes_without_images:
        image_url = image_search_service.search_food_image(
            recipe.name,
            cuisine_type=recipe.cuisine_type
        )
        if image_url:
            recipe.image_url = image_url
            updated_count += 1

    db.session.commit()

    return jsonify({
        'message': f'Updated {updated_count} recipes with images',
        'updated_count': updated_count,
        'total_processed': len(recipes_without_images)
    }), 200
