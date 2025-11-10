"""
Update recipe images with Lorem Picsum (reliable placeholder images)
Lorem Picsum provides reliable, fast-loading placeholder images
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app, db
from app.models import Recipe

# Using Lorem Picsum with food-related seed IDs for consistency
FOOD_IMAGE_SEEDS = [
    1080, 1060, 1040, 292, 431, 625, 835, 659, 326, 312,
    162, 163, 164, 165, 180, 184, 225, 242, 257, 292
]

def update_recipe_images():
    """Update all recipes with Lorem Picsum images"""
    app = create_app('development')

    with app.app_context():
        recipes = Recipe.query.all()

        print(f"Found {len(recipes)} recipes to update...")

        for idx, recipe in enumerate(recipes):
            # Use different seed for each recipe
            seed = FOOD_IMAGE_SEEDS[idx % len(FOOD_IMAGE_SEEDS)]
            image_url = f"https://picsum.photos/seed/{seed}/800/600"

            recipe.image_url = image_url
            print(f"Updated '{recipe.name}' with image: {image_url}")

        db.session.commit()
        print(f"\nSuccessfully updated {len(recipes)} recipes with images!")

if __name__ == '__main__':
    update_recipe_images()
