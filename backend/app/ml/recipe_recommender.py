"""
Recipe Recommendation Module
Provides intelligent recipe recommendations based on user preferences and history
"""

from typing import List, Dict, Optional
from datetime import datetime, timedelta
from app.models import Recipe, UserPreference, MealPlan, RecipeIngredient, Ingredient
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
        limit: int = 10
    ) -> List[Dict]:
        """
        Recommend recipes for a user based on preferences and history

        Args:
            user_id: User ID
            available_ingredients: List of available ingredient names
            limit: Maximum number of recommendations

        Returns:
            List of recommended recipes with scores
        """
        # Get user preferences
        preferences = UserPreference.query.filter_by(user_id=user_id).first()

        # Get user's recent meal history (last 30 days)
        recent_meals = self._get_recent_meals(user_id, days=30)

        # Get user's highly rated recipes
        favorite_recipes = self._get_favorite_recipes(user_id)

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
            score = self._calculate_recipe_score(
                recipe=recipe,
                user_id=user_id,
                available_ingredients=available_ingredients,
                recent_meals=recent_meals,
                favorite_recipes=favorite_recipes,
                preferences=preferences
            )

            scored_recipes.append({
                'recipe': recipe.to_dict(),
                'score': score,
                'reasoning': self._get_recommendation_reasoning(
                    recipe, score, available_ingredients, recent_meals
                )
            })

        # Sort by score (highest first)
        scored_recipes.sort(key=lambda x: x['score'], reverse=True)

        # Return top N
        return scored_recipes[:limit]

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
        - Ingredient match: 0-40 points
        - Recipe rating: 0-20 points
        - Novelty (not recently eaten): 0-15 points
        - Similar to favorites: 0-15 points
        - Cooking time: 0-10 points

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

        # 1. Ingredient Match (0-40 points)
        if available_ingredients:
            match_score = self._calculate_ingredient_match(recipe, available_ingredients)
            score += match_score * 40

        # 2. Recipe Rating (0-20 points)
        if recipe.rating is not None and recipe.rating > 0:
            rating_score = (recipe.rating / 5.0) * 20
            score += rating_score

        # 3. Novelty - penalize recently eaten (0-15 points)
        if recipe.id not in recent_meals:
            score += 15
        else:
            # Reduce score based on how recently it was eaten
            score += 5  # Still give some points for being a good option

        # 4. Similar to favorites (0-15 points)
        if recipe.id in favorite_recipes:
            score += 15
        elif len(favorite_recipes) > 0:
            # Check if same cuisine type as favorites
            favorite_cuisines = db.session.query(Recipe.cuisine_type).filter(
                Recipe.id.in_(favorite_recipes)
            ).distinct().all()
            favorite_cuisines = [c[0] for c in favorite_cuisines]

            if recipe.cuisine_type in favorite_cuisines:
                score += 8

        # 5. Cooking Time (0-10 points) - prefer quick recipes
        if recipe.total_time <= 30:
            score += 10
        elif recipe.total_time <= 45:
            score += 7
        elif recipe.total_time <= 60:
            score += 4

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

        # Calculate match percentage
        matching = len(recipe_ingredient_names.intersection(available_set))
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
                reasons.append(f"Great match with your ingredients ({int(match_pct*100)}%)")
            elif match_pct >= 0.5:
                reasons.append(f"Good match with your ingredients ({int(match_pct*100)}%)")

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
