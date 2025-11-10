"""
Update recipe images with actual food images from Foodish API and other sources
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app, db
from app.models import Recipe

# High-quality food images from various free sources
# Using Lorem Picsum with food photos and FoodiesFeed URLs
FILIPINO_FOOD_IMAGES = {
    'adobo': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800&q=80',
    'sinigang': 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800&q=80',
    'lumpia': 'https://images.unsplash.com/photo-1550498653-f0e640e1a36e?w=800&q=80',
    'pancit': 'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=800&q=80',
    'tinola': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&q=80',
    'kare-kare': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=800&q=80',
    'caldereta': 'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=800&q=80',
    'bistek': 'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=800&q=80',
    'chicken': 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=800&q=80',
    'rice': 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=800&q=80',
    'pork': 'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=800&q=80',
    'beef': 'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=800&q=80',
    'fish': 'https://images.unsplash.com/photo-1559737558-2f6c7c87b1c3?w=800&q=80',
    'vegetable': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80',
    'soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&q=80',
    'egg': 'https://images.unsplash.com/photo-1506084868230-bb9d95c24759?w=800&q=80',
    'ginataang': 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800&q=80',
    'humba': 'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=800&q=80',
    'tocino': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=800&q=80',
    'tortang': 'https://images.unsplash.com/photo-1606787619091-d6f1d50b7665?w=800&q=80',
}

# Generic food categories as fallback
FOOD_CATEGORY_IMAGES = {
    'breakfast': 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=800&q=80',
    'lunch': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80',
    'dinner': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80',
    'snack': 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=800&q=80',
}

def find_best_image(recipe_name, meal_type):
    """Find the best matching food image for a recipe"""
    recipe_lower = recipe_name.lower()

    # Try to find specific food match
    for keyword, url in FILIPINO_FOOD_IMAGES.items():
        if keyword in recipe_lower:
            return url

    # Fallback to meal type
    if meal_type and meal_type.lower() in FOOD_CATEGORY_IMAGES:
        return FOOD_CATEGORY_IMAGES[meal_type.lower()]

    # Default generic food image
    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80'

def update_recipe_images():
    """Update all recipes with actual food images"""
    app = create_app('development')

    with app.app_context():
        recipes = Recipe.query.all()

        print(f"Found {len(recipes)} recipes to update...")

        for recipe in recipes:
            image_url = find_best_image(recipe.name, recipe.meal_type)
            recipe.image_url = image_url
            print(f"Updated '{recipe.name}' with image: {image_url}")

        db.session.commit()
        print(f"\nSuccessfully updated {len(recipes)} recipes with food images!")

if __name__ == '__main__':
    update_recipe_images()
