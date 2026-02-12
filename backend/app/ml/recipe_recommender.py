"""
Recipe Recommendation Module
Provides intelligent recipe recommendations based on user preferences and history
"""

from typing import List, Dict, Optional
from datetime import datetime, timedelta
from app.models import Recipe, UserPreference, MealPlan, RecipeIngredient, Ingredient, UserPantry
from app import db


class RecipeRecommender:
    """Handles intelligent recipe recommendations"""

    def __init__(self):
        """Initialize recipe recommender"""
        pass

    def recommend_for_user(
        self,
        user_id: int,
        available_ingredients: Optional[List[str]] = None,
        limit: int = 10,
        use_pantry: bool = True,
        min_match_percentage: float = 20.0
    ) -> List[Dict]:
        """
        Recommend recipes for a user based on preferences, history, and pantry

        Args:
            user_id: User ID
            available_ingredients: List of available ingredient names (overrides pantry if provided)
            limit: Maximum number of recommendations
            use_pantry: Whether to use user's pantry ingredients (default True)

        Returns:
            List of recommended recipes with scores and match info
        """
        # Get user preferences
        preferences = UserPreference.query.filter_by(user_id=user_id).first()

        # Get user's recent meal history (last 30 days)
        recent_meals = self._get_recent_meals(user_id, days=30)

        # Get user's highly rated recipes
        favorite_recipes = self._get_favorite_recipes(user_id)

        # Get available ingredients from pantry if not provided
        if available_ingredients is None and use_pantry:
            available_ingredients = self._get_pantry_ingredients(user_id)

        # Start with all recipes
        query = Recipe.query

        # Apply dietary filters if preferences exist
        if preferences:
            if preferences.is_vegetarian:
                query = query.filter(Recipe.is_vegetarian.is_(True))
            if preferences.is_vegan:
                query = query.filter(Recipe.is_vegan.is_(True))
            if preferences.is_gluten_free:
                query = query.filter(Recipe.is_gluten_free.is_(True))
            if preferences.is_dairy_free:
                query = query.filter(Recipe.is_dairy_free.is_(True))

        recipes = query.all()

        # Score each recipe
        scored_recipes = []
        for recipe in recipes:
            # Calculate ingredient match details
            match_info = self._calculate_ingredient_match_details(recipe, available_ingredients)

            score = self._calculate_recipe_score(
                recipe=recipe,
                user_id=user_id,
                available_ingredients=available_ingredients,
                recent_meals=recent_meals,
                favorite_recipes=favorite_recipes,
                preferences=preferences
            )

            recipe_dict = recipe.to_dict()
            # Add match info to recipe
            recipe_dict['match_percentage'] = match_info['match_percentage']
            recipe_dict['matching_ingredients'] = match_info['matching_count']
            recipe_dict['total_ingredients'] = match_info['total_count']
            recipe_dict['missing_ingredients'] = match_info['missing_ingredients']

            scored_recipes.append({
                'recipe': recipe_dict,
                'score': score,
                'match_info': match_info,
                'reasoning': self._get_recommendation_reasoning(
                    recipe, score, available_ingredients, recent_meals
                )
            })

        # Filter out recipes below minimum ingredient match threshold
        if available_ingredients and min_match_percentage > 0:
            scored_recipes = [
                sr for sr in scored_recipes
                if sr['match_info']['match_percentage'] >= min_match_percentage
            ]

        # Sort by score (highest first)
        scored_recipes.sort(key=lambda x: x['score'], reverse=True)

        # Return top N
        return scored_recipes[:limit]

    def _get_pantry_ingredients(self, user_id: int) -> List[str]:
        """
        Get ingredient names from user's pantry

        Args:
            user_id: User ID

        Returns:
            List of ingredient names
        """
        pantry_items = db.session.query(Ingredient.name).join(
            UserPantry
        ).filter(
            UserPantry.user_id == user_id
        ).all()

        return [item[0] for item in pantry_items]

    @staticmethod
    def _ingredient_matches(ingredient_name: str, available_set: set) -> bool:
        """Check if an ingredient matches any available ingredient using substring matching.
        Handles cases like 'Egg' matching 'Eggs', 'Chicken' matching 'Chicken breast'."""
        if ingredient_name in available_set:
            return True
        for available_ing in available_set:
            if ingredient_name in available_ing or available_ing in ingredient_name:
                return True
        return False

    def _calculate_ingredient_match_details(
        self,
        recipe: Recipe,
        available_ingredients: Optional[List[str]]
    ) -> Dict:
        """
        Calculate detailed ingredient match information

        Args:
            recipe: Recipe object
            available_ingredients: List of ingredient names

        Returns:
            Dict with match details
        """
        # Get recipe ingredients
        recipe_ingredients = db.session.query(
            Ingredient.id,
            Ingredient.name,
            RecipeIngredient.is_optional
        ).join(
            RecipeIngredient
        ).filter(
            RecipeIngredient.recipe_id == recipe.id
        ).all()

        if not available_ingredients:
            return {
                'match_percentage': 0,
                'matching_count': 0,
                'total_count': len(recipe_ingredients),
                'matching_ingredients': [],
                'missing_ingredients': [
                    {'id': ing[0], 'name': ing[1], 'is_optional': ing[2]}
                    for ing in recipe_ingredients
                ]
            }

        available_set = {ing.lower() for ing in available_ingredients}

        matching = []
        missing = []

        for ing_id, ing_name, is_optional in recipe_ingredients:
            if self._ingredient_matches(ing_name.lower(), available_set):
                matching.append({'id': ing_id, 'name': ing_name, 'is_optional': is_optional})
            else:
                missing.append({'id': ing_id, 'name': ing_name, 'is_optional': is_optional})

        total = len(recipe_ingredients)
        match_count = len(matching)
        match_percentage = (match_count / total * 100) if total > 0 else 0

        return {
            'match_percentage': round(match_percentage, 1),
            'matching_count': match_count,
            'total_count': total,
            'matching_ingredients': matching,
            'missing_ingredients': missing
        }

    def _calculate_recipe_score(
        self,
        recipe: Recipe,
        user_id: int,
        available_ingredients: Optional[List[str]],
        recent_meals: List[int],
        favorite_recipes: List[int],
        preferences: Optional[UserPreference]
    ) -> float:
        """
        Calculate recommendation score for a recipe

        Score components:
        - Ingredient match: 0-70 points
        - Recipe rating: 0-10 points
        - Novelty (not recently eaten): 0-8 points
        - Similar to favorites: 0-7 points
        - Cooking time: 0-5 points

        Args:
            recipe: Recipe object
            user_id: User ID
            available_ingredients: List of available ingredients
            recent_meals: List of recently eaten recipe IDs
            favorite_recipes: List of favorite recipe IDs
            preferences: User preferences

        Returns:
            Score between 0-100
        """
        score = 0.0

        # 1. Ingredient Match (0-70 points)
        if available_ingredients:
            match_score = self._calculate_ingredient_match(recipe, available_ingredients)
            score += match_score * 70

        # 2. Recipe Rating (0-10 points)
        if recipe.rating is not None and recipe.rating > 0:
            rating_score = (recipe.rating / 5.0) * 10
            score += rating_score

        # 3. Novelty - penalize recently eaten (0-8 points)
        if recipe.id not in recent_meals:
            score += 8
        else:
            score += 3

        # 4. Similar to favorites (0-7 points)
        if recipe.id in favorite_recipes:
            score += 7
        elif len(favorite_recipes) > 0:
            # Check if same cuisine type as favorites
            favorite_cuisines = db.session.query(Recipe.cuisine_type).filter(
                Recipe.id.in_(favorite_recipes)
            ).distinct().all()
            favorite_cuisines = [c[0] for c in favorite_cuisines]

            if recipe.cuisine_type in favorite_cuisines:
                score += 4

        # 5. Cooking Time (0-5 points) - prefer quick recipes
        if recipe.total_time <= 30:
            score += 5
        elif recipe.total_time <= 45:
            score += 3
        elif recipe.total_time <= 60:
            score += 2

        return score

    def _calculate_ingredient_match(
        self,
        recipe: Recipe,
        available_ingredients: List[str]
    ) -> float:
        """
        Calculate how well recipe matches available ingredients

        Args:
            recipe: Recipe object
            available_ingredients: List of ingredient names

        Returns:
            Match percentage (0.0 to 1.0)
        """
        # Get recipe ingredients
        recipe_ingredients = db.session.query(Ingredient.name).join(
            RecipeIngredient
        ).filter(
            RecipeIngredient.recipe_id == recipe.id
        ).all()

        recipe_ingredient_names = {ing[0].lower() for ing in recipe_ingredients}
        available_set = {ing.lower() for ing in available_ingredients}

        if len(recipe_ingredient_names) == 0:
            return 0.0

        # Calculate match percentage using partial/substring matching
        matching = sum(
            1 for recipe_ing in recipe_ingredient_names
            if self._ingredient_matches(recipe_ing, available_set)
        )
        total = len(recipe_ingredient_names)

        return matching / total

    def _get_recent_meals(self, user_id: int, days: int = 30) -> List[int]:
        """
        Get recipe IDs of meals eaten in the last N days

        Args:
            user_id: User ID
            days: Number of days to look back

        Returns:
            List of recipe IDs
        """
        cutoff_date = datetime.utcnow() - timedelta(days=days)

        recent_meals = db.session.query(MealPlan.recipe_id).filter(
            MealPlan.user_id == user_id,
            MealPlan.planned_date >= cutoff_date,
            MealPlan.is_completed.is_(True)
        ).distinct().all()

        return [meal[0] for meal in recent_meals]

    def _get_favorite_recipes(self, user_id: int, min_rating: int = 4) -> List[int]:
        """
        Get recipe IDs that user rated highly

        Args:
            user_id: User ID
            min_rating: Minimum rating to consider as favorite

        Returns:
            List of recipe IDs
        """
        favorites = db.session.query(MealPlan.recipe_id).filter(
            MealPlan.user_id == user_id,
            MealPlan.user_rating >= min_rating
        ).distinct().all()

        return [fav[0] for fav in favorites]

    def _get_recommendation_reasoning(
        self,
        recipe: Recipe,
        score: float,
        available_ingredients: Optional[List[str]],
        recent_meals: List[int]
    ) -> str:
        """
        Generate human-readable reasoning for recommendation

        Args:
            recipe: Recipe object
            score: Recommendation score
            available_ingredients: Available ingredients
            recent_meals: Recent meal IDs

        Returns:
            Reasoning string
        """
        reasons = []

        # Ingredient match
        if available_ingredients:
            match_pct = self._calculate_ingredient_match(recipe, available_ingredients)
            if match_pct >= 0.8:
                reasons.append(f"Great match with your ingredients ({int(match_pct * 100)}%)")
            elif match_pct >= 0.5:
                reasons.append(f"Good match with your ingredients ({int(match_pct * 100)}%)")

        # Rating
        if recipe.rating and recipe.rating >= 4.0:
            reasons.append(f"Highly rated ({recipe.rating:.1f}/5)")

        # Novelty
        if recipe.id not in recent_meals:
            reasons.append("Try something new")

        # Quick to make
        if recipe.total_time <= 30:
            reasons.append(f"Quick to make ({recipe.total_time} min)")

        # Difficulty
        if recipe.difficulty_level == 'easy':
            reasons.append("Easy to prepare")

        if len(reasons) == 0:
            return "Recommended for you"

        return " • ".join(reasons)

    def recommend_by_cuisine(
        self,
        cuisine_type: str,
        limit: int = 10,
        dietary_filters: Optional[Dict] = None
    ) -> List[Dict]:
        """
        Recommend recipes by cuisine type

        Args:
            cuisine_type: Cuisine type (e.g., 'Filipino', 'Chinese')
            limit: Maximum number of recommendations
            dietary_filters: Optional dietary filters

        Returns:
            List of recommended recipes
        """
        query = Recipe.query.filter(Recipe.cuisine_type == cuisine_type)

        # Apply dietary filters
        if dietary_filters:
            if dietary_filters.get('is_vegetarian'):
                query = query.filter(Recipe.is_vegetarian.is_(True))
            if dietary_filters.get('is_vegan'):
                query = query.filter(Recipe.is_vegan.is_(True))
            if dietary_filters.get('is_gluten_free'):
                query = query.filter(Recipe.is_gluten_free.is_(True))
            if dietary_filters.get('is_dairy_free'):
                query = query.filter(Recipe.is_dairy_free.is_(True))

        # Order by rating and view count
        query = query.order_by(Recipe.rating.desc(), Recipe.view_count.desc())

        recipes = query.limit(limit).all()

        return [{'recipe': recipe.to_dict(), 'score': 80.0} for recipe in recipes]

    def recommend_quick_recipes(
        self,
        max_time: int = 30,
        limit: int = 10
    ) -> List[Dict]:
        """
        Recommend quick recipes under a time limit

        Args:
            max_time: Maximum total time in minutes
            limit: Maximum number of recommendations

        Returns:
            List of recommended recipes
        """
        recipes = Recipe.query.filter(
            Recipe.total_time <= max_time
        ).order_by(
            Recipe.rating.desc()
        ).limit(limit).all()

        return [{'recipe': recipe.to_dict(), 'score': 75.0} for recipe in recipes]
