"""
Script to populate recipes with images from free sources
This uses placeholder images from various free food image services
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app, db
from app.models import Recipe

# Free food image sources
# Using Unsplash Source for random food images
def get_food_image_url(food_name, width=800, height=600):
    """
    Generate food image URLs from free sources
    Options:
    1. Unsplash Source (free, no attribution required)
    2. Foodish API (free food images)
    """
    # Using Unsplash Source - returns random food images
    food_keywords = food_name.lower().replace(' ', '-')
    return f"https://source.unsplash.com/featured/{width}x{height}/?{food_keywords},food,filipino"

# Alternative: Using specific Unsplash photo IDs for Filipino dishes
FILIPINO_FOOD_IMAGES = {
    'adobo': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800',
    'sinigang': 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800',
    'lechon': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800',
    'lumpia': 'https://images.unsplash.com/photo-1550498653-f0e640e1a36e?w=800',
    'pancit': 'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=800',
    'kare-kare': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=800',
    'chicken': 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=800',
    'pork': 'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=800',
    'beef': 'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=800',
    'fish': 'https://images.unsplash.com/photo-1559737558-2f6c7c87b1c3?w=800',
    'rice': 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=800',
    'soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800',
    'noodles': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800',
    'vegetables': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800',
}

def find_best_image_match(recipe_name):
    """Find the best matching image for a recipe"""
    recipe_lower = recipe_name.lower()

    # Check for exact matches first
    for keyword, url in FILIPINO_FOOD_IMAGES.items():
        if keyword in recipe_lower:
            return url

    # Default to search-based URL
    return get_food_image_url(recipe_name)

def update_recipe_images():
    """Update all recipes with image URLs"""
    app = create_app('development')

    with app.app_context():
        recipes = Recipe.query.all()

        print(f"Found {len(recipes)} recipes to update...")

        for recipe in recipes:
            if not recipe.image_url or recipe.image_url == '':
                # Find best matching image
                image_url = find_best_image_match(recipe.name)
                recipe.image_url = image_url
                print(f"Updated '{recipe.name}' with image: {image_url}")

        db.session.commit()
        print(f"\nSuccessfully updated {len(recipes)} recipes with images!")

if __name__ == '__main__':
    update_recipe_images()
