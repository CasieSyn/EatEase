import os
from app import create_app, db

app = create_app(os.getenv('FLASK_ENV', 'development'))


@app.shell_context_processor
def make_shell_context():
    """Make database and models available in Flask shell"""
    from app.models import User, Recipe, Ingredient, RecipeIngredient, UserPreference, MealPlan, ShoppingList
    return {
        'db': db,
        'User': User,
        'Recipe': Recipe,
        'Ingredient': Ingredient,
        'RecipeIngredient': RecipeIngredient,
        'UserPreference': UserPreference,
        'MealPlan': MealPlan,
        'ShoppingList': ShoppingList
    }


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
