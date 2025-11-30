"""
Populate database with comprehensive Filipino ingredients and recipes
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app, db
from app.models import Ingredient, Recipe, RecipeIngredient

app = create_app()

# ============================================================================
# COMPREHENSIVE FILIPINO INGREDIENTS
# ============================================================================

FILIPINO_INGREDIENTS = [
    # === VEGETABLES ===
    {"name": "Tomato", "category": "vegetable", "common_unit": "piece"},
    {"name": "Onion", "category": "vegetable", "common_unit": "piece"},
    {"name": "Garlic", "category": "vegetable", "common_unit": "clove"},
    {"name": "Ginger", "category": "vegetable", "common_unit": "thumb"},
    {"name": "Potato", "category": "vegetable", "common_unit": "piece"},
    {"name": "Carrot", "category": "vegetable", "common_unit": "piece"},
    {"name": "Cabbage", "category": "vegetable", "common_unit": "head"},
    {"name": "Eggplant", "category": "vegetable", "common_unit": "piece"},
    {"name": "Bell Pepper", "category": "vegetable", "common_unit": "piece"},
    {"name": "Green Beans", "category": "vegetable", "common_unit": "cup"},
    {"name": "Kangkong", "category": "vegetable", "common_unit": "bunch"},
    {"name": "Pechay", "category": "vegetable", "common_unit": "bunch"},
    {"name": "Bok Choy", "category": "vegetable", "common_unit": "bunch"},
    {"name": "Sitaw", "category": "vegetable", "common_unit": "bundle"},
    {"name": "Kalabasa", "category": "vegetable", "common_unit": "slice"},
    {"name": "Sayote", "category": "vegetable", "common_unit": "piece"},
    {"name": "Ampalaya", "category": "vegetable", "common_unit": "piece"},
    {"name": "Malunggay", "category": "vegetable", "common_unit": "cup"},
    {"name": "Talong", "category": "vegetable", "common_unit": "piece"},
    {"name": "Okra", "category": "vegetable", "common_unit": "piece"},
    {"name": "Radish", "category": "vegetable", "common_unit": "piece"},
    {"name": "Corn", "category": "vegetable", "common_unit": "ear"},
    {"name": "Lettuce", "category": "vegetable", "common_unit": "head"},
    {"name": "Cucumber", "category": "vegetable", "common_unit": "piece"},
    {"name": "Spring Onion", "category": "vegetable", "common_unit": "stalk"},
    {"name": "Celery", "category": "vegetable", "common_unit": "stalk"},
    {"name": "Mushroom", "category": "vegetable", "common_unit": "cup"},
    {"name": "Bamboo Shoots", "category": "vegetable", "common_unit": "cup"},
    {"name": "Bean Sprouts", "category": "vegetable", "common_unit": "cup"},
    {"name": "Water Spinach", "category": "vegetable", "common_unit": "bunch"},
    {"name": "Spinach", "category": "vegetable", "common_unit": "bunch"},
    {"name": "Chili Pepper", "category": "vegetable", "common_unit": "piece"},
    {"name": "Siling Labuyo", "category": "vegetable", "common_unit": "piece"},
    {"name": "Siling Haba", "category": "vegetable", "common_unit": "piece"},

    # === PROTEINS - MEAT ===
    {"name": "Pork Belly", "category": "protein", "common_unit": "kg"},
    {"name": "Pork Shoulder", "category": "protein", "common_unit": "kg"},
    {"name": "Pork Loin", "category": "protein", "common_unit": "kg"},
    {"name": "Pork Ribs", "category": "protein", "common_unit": "kg"},
    {"name": "Pork Leg", "category": "protein", "common_unit": "kg"},
    {"name": "Pork Knuckle", "category": "protein", "common_unit": "piece"},
    {"name": "Ground Pork", "category": "protein", "common_unit": "kg"},
    {"name": "Pork Liver", "category": "protein", "common_unit": "kg"},
    {"name": "Pork Blood", "category": "protein", "common_unit": "cup"},
    {"name": "Chicken Breast", "category": "protein", "common_unit": "piece"},
    {"name": "Chicken Thigh", "category": "protein", "common_unit": "piece"},
    {"name": "Chicken Wings", "category": "protein", "common_unit": "piece"},
    {"name": "Chicken Drumstick", "category": "protein", "common_unit": "piece"},
    {"name": "Whole Chicken", "category": "protein", "common_unit": "piece"},
    {"name": "Chicken Liver", "category": "protein", "common_unit": "cup"},
    {"name": "Chicken Gizzard", "category": "protein", "common_unit": "cup"},
    {"name": "Ground Chicken", "category": "protein", "common_unit": "kg"},
    {"name": "Beef", "category": "protein", "common_unit": "kg"},
    {"name": "Beef Brisket", "category": "protein", "common_unit": "kg"},
    {"name": "Beef Shank", "category": "protein", "common_unit": "kg"},
    {"name": "Beef Tripe", "category": "protein", "common_unit": "kg"},
    {"name": "Beef Oxtail", "category": "protein", "common_unit": "kg"},
    {"name": "Ground Beef", "category": "protein", "common_unit": "kg"},
    {"name": "Corned Beef", "category": "protein", "common_unit": "can"},
    {"name": "Spam", "category": "protein", "common_unit": "can"},
    {"name": "Hotdog", "category": "protein", "common_unit": "piece"},
    {"name": "Tocino", "category": "protein", "common_unit": "pack"},
    {"name": "Longganisa", "category": "protein", "common_unit": "piece"},
    {"name": "Bacon", "category": "protein", "common_unit": "strip"},

    # === PROTEINS - SEAFOOD ===
    {"name": "Tilapia", "category": "protein", "common_unit": "piece"},
    {"name": "Bangus", "category": "protein", "common_unit": "piece"},
    {"name": "Galunggong", "category": "protein", "common_unit": "piece"},
    {"name": "Salmon", "category": "protein", "common_unit": "fillet"},
    {"name": "Tuna", "category": "protein", "common_unit": "steak"},
    {"name": "Canned Tuna", "category": "protein", "common_unit": "can"},
    {"name": "Sardines", "category": "protein", "common_unit": "can"},
    {"name": "Mackerel", "category": "protein", "common_unit": "piece"},
    {"name": "Shrimp", "category": "protein", "common_unit": "kg"},
    {"name": "Prawns", "category": "protein", "common_unit": "kg"},
    {"name": "Squid", "category": "protein", "common_unit": "kg"},
    {"name": "Crab", "category": "protein", "common_unit": "piece"},
    {"name": "Mussels", "category": "protein", "common_unit": "kg"},
    {"name": "Clams", "category": "protein", "common_unit": "kg"},
    {"name": "Tahong", "category": "protein", "common_unit": "kg"},
    {"name": "Halaan", "category": "protein", "common_unit": "kg"},
    {"name": "Dried Fish", "category": "protein", "common_unit": "piece"},
    {"name": "Tuyo", "category": "protein", "common_unit": "piece"},
    {"name": "Daing", "category": "protein", "common_unit": "piece"},
    {"name": "Tinapa", "category": "protein", "common_unit": "piece"},
    {"name": "Dilis", "category": "protein", "common_unit": "cup"},

    # === PROTEINS - EGGS & DAIRY ===
    {"name": "Eggs", "category": "protein", "common_unit": "piece"},
    {"name": "Salted Egg", "category": "protein", "common_unit": "piece"},
    {"name": "Century Egg", "category": "protein", "common_unit": "piece"},
    {"name": "Quail Eggs", "category": "protein", "common_unit": "piece"},
    {"name": "Cheese", "category": "dairy", "common_unit": "slice"},
    {"name": "Kesong Puti", "category": "dairy", "common_unit": "piece"},
    {"name": "Cheddar Cheese", "category": "dairy", "common_unit": "cup"},
    {"name": "Quickmelt Cheese", "category": "dairy", "common_unit": "pack"},
    {"name": "Milk", "category": "dairy", "common_unit": "cup"},
    {"name": "Evaporated Milk", "category": "dairy", "common_unit": "can"},
    {"name": "Condensed Milk", "category": "dairy", "common_unit": "can"},
    {"name": "Butter", "category": "dairy", "common_unit": "tbsp"},
    {"name": "Cream", "category": "dairy", "common_unit": "cup"},

    # === GRAINS & STARCHES ===
    {"name": "Rice", "category": "grain", "common_unit": "cup"},
    {"name": "Glutinous Rice", "category": "grain", "common_unit": "cup"},
    {"name": "Rice Noodles", "category": "grain", "common_unit": "pack"},
    {"name": "Bihon", "category": "grain", "common_unit": "pack"},
    {"name": "Sotanghon", "category": "grain", "common_unit": "pack"},
    {"name": "Canton Noodles", "category": "grain", "common_unit": "pack"},
    {"name": "Egg Noodles", "category": "grain", "common_unit": "pack"},
    {"name": "Instant Noodles", "category": "grain", "common_unit": "pack"},
    {"name": "Spaghetti", "category": "grain", "common_unit": "pack"},
    {"name": "Macaroni", "category": "grain", "common_unit": "pack"},
    {"name": "Bread", "category": "grain", "common_unit": "slice"},
    {"name": "Pandesal", "category": "grain", "common_unit": "piece"},
    {"name": "Flour", "category": "grain", "common_unit": "cup"},
    {"name": "Cornstarch", "category": "grain", "common_unit": "tbsp"},
    {"name": "Bread Crumbs", "category": "grain", "common_unit": "cup"},
    {"name": "Lumpia Wrapper", "category": "grain", "common_unit": "pack"},
    {"name": "Wonton Wrapper", "category": "grain", "common_unit": "pack"},

    # === LEGUMES & BEANS ===
    {"name": "Mung Beans", "category": "legume", "common_unit": "cup"},
    {"name": "Red Beans", "category": "legume", "common_unit": "cup"},
    {"name": "White Beans", "category": "legume", "common_unit": "cup"},
    {"name": "Chickpeas", "category": "legume", "common_unit": "cup"},
    {"name": "Tofu", "category": "legume", "common_unit": "block"},
    {"name": "Tokwa", "category": "legume", "common_unit": "block"},
    {"name": "Taho", "category": "legume", "common_unit": "cup"},
    {"name": "Peanuts", "category": "legume", "common_unit": "cup"},
    {"name": "Peanut Butter", "category": "legume", "common_unit": "tbsp"},

    # === CONDIMENTS & SAUCES ===
    {"name": "Soy Sauce", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Fish Sauce", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Vinegar", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Cane Vinegar", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Coconut Vinegar", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Oyster Sauce", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Worcestershire Sauce", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Banana Ketchup", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Tomato Sauce", "category": "condiment", "common_unit": "cup"},
    {"name": "Tomato Paste", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Calamansi", "category": "condiment", "common_unit": "piece"},
    {"name": "Lemon", "category": "condiment", "common_unit": "piece"},
    {"name": "Lime", "category": "condiment", "common_unit": "piece"},
    {"name": "Tamarind", "category": "condiment", "common_unit": "pack"},
    {"name": "Sampalok", "category": "condiment", "common_unit": "cup"},
    {"name": "Bagoong", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Bagoong Alamang", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Patis", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Achuete", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Annatto Seeds", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Coconut Milk", "category": "condiment", "common_unit": "cup"},
    {"name": "Coconut Cream", "category": "condiment", "common_unit": "cup"},
    {"name": "Cooking Oil", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Vegetable Oil", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Sesame Oil", "category": "condiment", "common_unit": "tbsp"},
    {"name": "Olive Oil", "category": "condiment", "common_unit": "tbsp"},

    # === SPICES & SEASONINGS ===
    {"name": "Salt", "category": "spice", "common_unit": "tsp"},
    {"name": "Black Pepper", "category": "spice", "common_unit": "tsp"},
    {"name": "White Pepper", "category": "spice", "common_unit": "tsp"},
    {"name": "Bay Leaf", "category": "spice", "common_unit": "piece"},
    {"name": "Peppercorn", "category": "spice", "common_unit": "tsp"},
    {"name": "Paprika", "category": "spice", "common_unit": "tsp"},
    {"name": "Cumin", "category": "spice", "common_unit": "tsp"},
    {"name": "Turmeric", "category": "spice", "common_unit": "tsp"},
    {"name": "Cinnamon", "category": "spice", "common_unit": "stick"},
    {"name": "Star Anise", "category": "spice", "common_unit": "piece"},
    {"name": "Cloves", "category": "spice", "common_unit": "piece"},
    {"name": "Oregano", "category": "spice", "common_unit": "tsp"},
    {"name": "Basil", "category": "spice", "common_unit": "cup"},
    {"name": "Parsley", "category": "spice", "common_unit": "cup"},
    {"name": "Cilantro", "category": "spice", "common_unit": "cup"},
    {"name": "Wansoy", "category": "spice", "common_unit": "cup"},
    {"name": "Lemongrass", "category": "spice", "common_unit": "stalk"},
    {"name": "Pandan", "category": "spice", "common_unit": "leaf"},
    {"name": "Sugar", "category": "spice", "common_unit": "tbsp"},
    {"name": "Brown Sugar", "category": "spice", "common_unit": "tbsp"},
    {"name": "Muscovado", "category": "spice", "common_unit": "tbsp"},
    {"name": "MSG", "category": "spice", "common_unit": "tsp"},
    {"name": "Chicken Bouillon", "category": "spice", "common_unit": "cube"},
    {"name": "Beef Bouillon", "category": "spice", "common_unit": "cube"},
    {"name": "Pork Bouillon", "category": "spice", "common_unit": "cube"},

    # === FRUITS (common in Filipino cooking) ===
    {"name": "Banana", "category": "fruit", "common_unit": "piece"},
    {"name": "Saba Banana", "category": "fruit", "common_unit": "piece"},
    {"name": "Mango", "category": "fruit", "common_unit": "piece"},
    {"name": "Green Mango", "category": "fruit", "common_unit": "piece"},
    {"name": "Papaya", "category": "fruit", "common_unit": "piece"},
    {"name": "Green Papaya", "category": "fruit", "common_unit": "piece"},
    {"name": "Pineapple", "category": "fruit", "common_unit": "slice"},
    {"name": "Coconut", "category": "fruit", "common_unit": "piece"},
    {"name": "Jackfruit", "category": "fruit", "common_unit": "cup"},
    {"name": "Langka", "category": "fruit", "common_unit": "cup"},
    {"name": "Guava", "category": "fruit", "common_unit": "piece"},
    {"name": "Atis", "category": "fruit", "common_unit": "piece"},
    {"name": "Rambutan", "category": "fruit", "common_unit": "piece"},
    {"name": "Lanzones", "category": "fruit", "common_unit": "piece"},
    {"name": "Durian", "category": "fruit", "common_unit": "piece"},
    {"name": "Buko", "category": "fruit", "common_unit": "piece"},
    {"name": "Santol", "category": "fruit", "common_unit": "piece"},
    {"name": "Tamarind Fruit", "category": "fruit", "common_unit": "piece"},
    {"name": "Avocado", "category": "fruit", "common_unit": "piece"},
    {"name": "Apple", "category": "fruit", "common_unit": "piece"},
    {"name": "Orange", "category": "fruit", "common_unit": "piece"},
    {"name": "Watermelon", "category": "fruit", "common_unit": "slice"},

    # === CANNED GOODS ===
    {"name": "Canned Tomatoes", "category": "canned", "common_unit": "can"},
    {"name": "Tomato Sauce Can", "category": "canned", "common_unit": "can"},
    {"name": "Liver Spread", "category": "canned", "common_unit": "can"},
    {"name": "Canned Mushrooms", "category": "canned", "common_unit": "can"},
    {"name": "Canned Corn", "category": "canned", "common_unit": "can"},
    {"name": "Canned Peas", "category": "canned", "common_unit": "can"},
    {"name": "Canned Beans", "category": "canned", "common_unit": "can"},

    # === OTHERS ===
    {"name": "Water", "category": "liquid", "common_unit": "cup"},
    {"name": "Beef Broth", "category": "liquid", "common_unit": "cup"},
    {"name": "Chicken Broth", "category": "liquid", "common_unit": "cup"},
    {"name": "Pork Broth", "category": "liquid", "common_unit": "cup"},
    {"name": "Ice", "category": "other", "common_unit": "cup"},
]

# ============================================================================
# COMPREHENSIVE FILIPINO RECIPES
# ============================================================================

FILIPINO_RECIPES = [
    # === ADOBO VARIATIONS ===
    {
        "name": "Chicken Adobo",
        "description": "Classic Filipino braised chicken in soy sauce and vinegar with garlic and bay leaves. A staple comfort food in every Filipino household.",
        "instructions": "1. Combine chicken, soy sauce, vinegar, garlic, bay leaves, and peppercorns in a pot.\n2. Marinate for 30 minutes.\n3. Bring to a boil, then simmer for 30-40 minutes until chicken is tender.\n4. Remove chicken and fry until golden (optional).\n5. Reduce sauce until thick.\n6. Return chicken to pot and coat with sauce.\n7. Serve hot with steamed rice.",
        "prep_time": 30,
        "cook_time": 45,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Chicken Thigh", 1, "kg"),
            ("Soy Sauce", 0.5, "cup"),
            ("Vinegar", 0.25, "cup"),
            ("Garlic", 8, "clove"),
            ("Bay Leaf", 3, "piece"),
            ("Peppercorn", 1, "tsp"),
            ("Cooking Oil", 2, "tbsp"),
            ("Water", 0.5, "cup"),
        ]
    },
    {
        "name": "Pork Adobo",
        "description": "Tender pork braised in a savory-tangy sauce of soy sauce and vinegar. Rich, flavorful, and perfect with rice.",
        "instructions": "1. Cut pork belly into cubes.\n2. Combine pork with soy sauce, vinegar, garlic, bay leaves, and peppercorns.\n3. Marinate for at least 1 hour.\n4. Simmer until pork is tender (about 45 minutes).\n5. Fry pork pieces until crispy.\n6. Reduce remaining sauce.\n7. Combine and serve with rice.",
        "prep_time": 60,
        "cook_time": 50,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Pork Belly", 1, "kg"),
            ("Soy Sauce", 0.5, "cup"),
            ("Vinegar", 0.33, "cup"),
            ("Garlic", 10, "clove"),
            ("Bay Leaf", 4, "piece"),
            ("Peppercorn", 1, "tsp"),
            ("Sugar", 1, "tbsp"),
        ]
    },
    {
        "name": "Adobong Pusit",
        "description": "Squid cooked adobo-style in a dark, flavorful sauce made with its own ink. A unique seafood twist on the classic adobo.",
        "instructions": "1. Clean squid and reserve the ink sacs.\n2. Saute garlic and onion.\n3. Add squid and cook briefly.\n4. Add soy sauce, vinegar, and squid ink.\n5. Simmer until squid is tender.\n6. Season to taste.\n7. Serve hot with rice.",
        "prep_time": 20,
        "cook_time": 25,
        "servings": 4,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Squid", 0.5, "kg"),
            ("Soy Sauce", 3, "tbsp"),
            ("Vinegar", 2, "tbsp"),
            ("Garlic", 5, "clove"),
            ("Onion", 1, "piece"),
            ("Cooking Oil", 2, "tbsp"),
        ]
    },

    # === SINIGANG VARIATIONS ===
    {
        "name": "Sinigang na Baboy",
        "description": "Sour pork soup with vegetables, flavored with tamarind. A comforting and refreshing soup perfect for rainy days.",
        "instructions": "1. Boil pork in water until tender, removing scum.\n2. Add onion and tomatoes.\n3. Add tamarind soup base or fresh tamarind.\n4. Add vegetables starting with those that take longer to cook.\n5. Add kangkong last.\n6. Season with fish sauce.\n7. Serve hot with rice.",
        "prep_time": 15,
        "cook_time": 60,
        "servings": 6,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Pork Ribs", 0.5, "kg"),
            ("Tamarind", 1, "pack"),
            ("Tomato", 2, "piece"),
            ("Onion", 1, "piece"),
            ("Kangkong", 1, "bunch"),
            ("Radish", 1, "piece"),
            ("Sitaw", 1, "bundle"),
            ("Eggplant", 2, "piece"),
            ("Fish Sauce", 3, "tbsp"),
            ("Water", 8, "cup"),
        ]
    },
    {
        "name": "Sinigang na Hipon",
        "description": "Sour shrimp soup with a medley of fresh vegetables. Light yet flavorful, showcasing the natural sweetness of shrimp.",
        "instructions": "1. Boil water with tomatoes and onion.\n2. Add tamarind soup base.\n3. Add vegetables.\n4. Add shrimp and cook until pink.\n5. Season with fish sauce.\n6. Add kangkong last.\n7. Serve immediately.",
        "prep_time": 15,
        "cook_time": 25,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Shrimp", 0.5, "kg"),
            ("Tamarind", 1, "pack"),
            ("Tomato", 2, "piece"),
            ("Onion", 1, "piece"),
            ("Kangkong", 1, "bunch"),
            ("Radish", 1, "piece"),
            ("Fish Sauce", 2, "tbsp"),
            ("Water", 6, "cup"),
        ]
    },
    {
        "name": "Sinigang na Bangus",
        "description": "Milkfish in sour tamarind broth with vegetables. A lighter, healthier version of the classic sinigang.",
        "instructions": "1. Boil water with tomatoes and onion.\n2. Add tamarind soup base.\n3. Add harder vegetables first.\n4. Add bangus belly pieces.\n5. Add leafy vegetables last.\n6. Season with fish sauce.\n7. Serve hot.",
        "prep_time": 15,
        "cook_time": 30,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Bangus", 1, "piece"),
            ("Tamarind", 1, "pack"),
            ("Tomato", 2, "piece"),
            ("Onion", 1, "piece"),
            ("Kangkong", 1, "bunch"),
            ("Radish", 1, "piece"),
            ("Fish Sauce", 2, "tbsp"),
            ("Siling Haba", 2, "piece"),
        ]
    },

    # === KARE-KARE ===
    {
        "name": "Kare-Kare",
        "description": "Rich peanut-based stew with oxtail, tripe, and vegetables. A festive dish traditionally served with bagoong.",
        "instructions": "1. Boil oxtail and tripe until very tender (2-3 hours).\n2. Toast and grind rice for thickening.\n3. Saute garlic and onion in annatto oil.\n4. Add meat and broth.\n5. Add peanut butter and ground rice.\n6. Add vegetables.\n7. Simmer until vegetables are cooked.\n8. Serve with bagoong.",
        "prep_time": 30,
        "cook_time": 180,
        "servings": 8,
        "difficulty": "hard",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Beef Oxtail", 1, "kg"),
            ("Beef Tripe", 0.5, "kg"),
            ("Peanut Butter", 0.5, "cup"),
            ("Achuete", 2, "tbsp"),
            ("Eggplant", 2, "piece"),
            ("Sitaw", 1, "bundle"),
            ("Pechay", 1, "bunch"),
            ("Banana", 2, "piece"),
            ("Garlic", 5, "clove"),
            ("Onion", 1, "piece"),
            ("Rice", 0.25, "cup"),
            ("Bagoong Alamang", 0.25, "cup"),
        ]
    },

    # === LECHON & ROASTS ===
    {
        "name": "Lechon Kawali",
        "description": "Crispy deep-fried pork belly. Sinfully delicious with crackling skin and tender meat inside.",
        "instructions": "1. Boil pork belly with salt, peppercorns, and bay leaves until tender.\n2. Let cool and dry completely.\n3. Deep fry in hot oil until skin is crispy and golden.\n4. Chop into serving pieces.\n5. Serve with liver sauce or vinegar dip.",
        "prep_time": 15,
        "cook_time": 90,
        "servings": 6,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Pork Belly", 1, "kg"),
            ("Salt", 2, "tbsp"),
            ("Peppercorn", 1, "tbsp"),
            ("Bay Leaf", 3, "piece"),
            ("Cooking Oil", 4, "cup"),
            ("Garlic", 5, "clove"),
        ]
    },
    {
        "name": "Crispy Pata",
        "description": "Deep-fried pork leg with ultra-crispy skin and tender meat. A celebratory dish perfect for special occasions.",
        "instructions": "1. Boil pork leg with aromatics until tender (about 2 hours).\n2. Drain and dry completely overnight in refrigerator.\n3. Deep fry until golden and crispy.\n4. Serve with soy-vinegar dipping sauce.",
        "prep_time": 20,
        "cook_time": 150,
        "servings": 8,
        "difficulty": "hard",
        "cuisine_type": "Filipino",
        "meal_type": "dinner",
        "ingredients": [
            ("Pork Leg", 1, "piece"),
            ("Salt", 2, "tbsp"),
            ("Peppercorn", 1, "tbsp"),
            ("Bay Leaf", 5, "piece"),
            ("Garlic", 1, "head"),
            ("Cooking Oil", 6, "cup"),
            ("Soy Sauce", 0.25, "cup"),
            ("Vinegar", 0.25, "cup"),
        ]
    },

    # === LUMPIA ===
    {
        "name": "Lumpiang Shanghai",
        "description": "Crispy Filipino spring rolls filled with seasoned ground pork. A party favorite and popular appetizer.",
        "instructions": "1. Mix ground pork with carrots, onion, garlic, and seasonings.\n2. Wrap mixture in lumpia wrapper, sealing edges.\n3. Deep fry until golden and crispy.\n4. Drain on paper towels.\n5. Serve with sweet chili sauce.",
        "prep_time": 45,
        "cook_time": 20,
        "servings": 30,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "appetizer,snack",
        "ingredients": [
            ("Ground Pork", 0.5, "kg"),
            ("Carrot", 1, "piece"),
            ("Onion", 1, "piece"),
            ("Garlic", 4, "clove"),
            ("Eggs", 1, "piece"),
            ("Lumpia Wrapper", 1, "pack"),
            ("Soy Sauce", 2, "tbsp"),
            ("Salt", 0.5, "tsp"),
            ("Black Pepper", 0.25, "tsp"),
            ("Cooking Oil", 3, "cup"),
        ]
    },
    {
        "name": "Lumpiang Sariwa",
        "description": "Fresh spring rolls with vegetables and a sweet peanut sauce. A healthier, non-fried version of lumpia.",
        "instructions": "1. Saute garlic, then add tofu and shrimp.\n2. Add vegetables and cook until tender-crisp.\n3. Season with soy sauce and pepper.\n4. Make peanut sauce by cooking garlic, peanut butter, soy sauce, and sugar.\n5. Wrap filling in fresh lumpia wrapper.\n6. Top with peanut sauce and crushed peanuts.",
        "prep_time": 30,
        "cook_time": 20,
        "servings": 10,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "appetizer,snack",
        "ingredients": [
            ("Cabbage", 0.5, "head"),
            ("Carrot", 2, "piece"),
            ("Green Beans", 1, "cup"),
            ("Tofu", 1, "block"),
            ("Shrimp", 0.25, "kg"),
            ("Garlic", 4, "clove"),
            ("Peanut Butter", 0.5, "cup"),
            ("Soy Sauce", 3, "tbsp"),
            ("Sugar", 2, "tbsp"),
            ("Lumpia Wrapper", 1, "pack"),
        ]
    },

    # === PANCIT VARIATIONS ===
    {
        "name": "Pancit Canton",
        "description": "Stir-fried egg noodles with meat and vegetables. A birthday staple symbolizing long life.",
        "instructions": "1. Cook noodles according to package directions.\n2. Saute garlic, onion, and meat.\n3. Add vegetables and cook until tender.\n4. Add noodles and soy sauce.\n5. Toss everything together.\n6. Serve with calamansi.",
        "prep_time": 20,
        "cook_time": 15,
        "servings": 6,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Canton Noodles", 2, "pack"),
            ("Chicken Breast", 0.25, "kg"),
            ("Shrimp", 0.25, "kg"),
            ("Cabbage", 0.25, "head"),
            ("Carrot", 1, "piece"),
            ("Celery", 2, "stalk"),
            ("Garlic", 4, "clove"),
            ("Onion", 1, "piece"),
            ("Soy Sauce", 3, "tbsp"),
            ("Oyster Sauce", 2, "tbsp"),
            ("Chicken Broth", 1, "cup"),
        ]
    },
    {
        "name": "Pancit Bihon",
        "description": "Stir-fried rice noodles with vegetables and meat. Light and satisfying, a Filipino celebration essential.",
        "instructions": "1. Soak bihon noodles in water until soft.\n2. Saute garlic and onion.\n3. Add meat and cook through.\n4. Add vegetables.\n5. Add noodles and broth.\n6. Season with soy sauce and fish sauce.\n7. Cook until noodles absorb the liquid.",
        "prep_time": 20,
        "cook_time": 20,
        "servings": 6,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Bihon", 1, "pack"),
            ("Chicken Breast", 0.25, "kg"),
            ("Pork Belly", 0.25, "kg"),
            ("Cabbage", 0.25, "head"),
            ("Carrot", 1, "piece"),
            ("Celery", 2, "stalk"),
            ("Green Beans", 0.5, "cup"),
            ("Garlic", 4, "clove"),
            ("Onion", 1, "piece"),
            ("Soy Sauce", 3, "tbsp"),
            ("Fish Sauce", 1, "tbsp"),
            ("Chicken Broth", 2, "cup"),
        ]
    },
    {
        "name": "Pancit Palabok",
        "description": "Rice noodles in savory shrimp sauce topped with various garnishes. A colorful and flavorful noodle dish.",
        "instructions": "1. Make shrimp sauce by sauteing garlic, adding shrimp broth, and thickening with annatto water and cornstarch.\n2. Cook rice noodles.\n3. Arrange noodles on a platter.\n4. Pour sauce over noodles.\n5. Top with flaked smoked fish, crushed chicharon, hard-boiled eggs, and spring onions.",
        "prep_time": 30,
        "cook_time": 30,
        "servings": 6,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Rice Noodles", 1, "pack"),
            ("Shrimp", 0.5, "kg"),
            ("Tinapa", 1, "piece"),
            ("Eggs", 3, "piece"),
            ("Garlic", 6, "clove"),
            ("Achuete", 2, "tbsp"),
            ("Cornstarch", 3, "tbsp"),
            ("Fish Sauce", 2, "tbsp"),
            ("Spring Onion", 3, "stalk"),
        ]
    },

    # === GRILLED DISHES ===
    {
        "name": "Inihaw na Liempo",
        "description": "Grilled pork belly marinated in a sweet and savory sauce. A barbecue favorite with charred, caramelized edges.",
        "instructions": "1. Slice pork belly into thin strips.\n2. Make marinade with soy sauce, calamansi, garlic, sugar, and pepper.\n3. Marinate pork for at least 4 hours or overnight.\n4. Grill over charcoal until cooked and slightly charred.\n5. Serve with vinegar dipping sauce.",
        "prep_time": 240,
        "cook_time": 20,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Pork Belly", 1, "kg"),
            ("Soy Sauce", 0.5, "cup"),
            ("Calamansi", 5, "piece"),
            ("Garlic", 6, "clove"),
            ("Sugar", 2, "tbsp"),
            ("Black Pepper", 1, "tsp"),
        ]
    },
    {
        "name": "Pork Barbecue",
        "description": "Sweet and savory grilled pork skewers. A street food favorite loved by all ages.",
        "instructions": "1. Cut pork into cubes.\n2. Make marinade with soy sauce, banana ketchup, 7-Up, garlic, and sugar.\n3. Marinate overnight.\n4. Thread onto bamboo skewers.\n5. Grill while basting with marinade.\n6. Serve with rice and atchara.",
        "prep_time": 480,
        "cook_time": 15,
        "servings": 6,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Pork Shoulder", 1, "kg"),
            ("Soy Sauce", 0.5, "cup"),
            ("Banana Ketchup", 0.5, "cup"),
            ("Garlic", 6, "clove"),
            ("Sugar", 3, "tbsp"),
            ("Black Pepper", 1, "tsp"),
        ]
    },
    {
        "name": "Chicken Inasal",
        "description": "Grilled chicken marinated in vinegar, calamansi, and annatto. Originating from Bacolod, known for its tangy flavor.",
        "instructions": "1. Butterfly or cut chicken into serving pieces.\n2. Make marinade with vinegar, calamansi, garlic, lemongrass, and annatto oil.\n3. Marinate for at least 4 hours.\n4. Grill over charcoal, basting with marinade and oil.\n5. Serve with garlic rice and chicken oil.",
        "prep_time": 240,
        "cook_time": 30,
        "servings": 4,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Whole Chicken", 1, "piece"),
            ("Vinegar", 0.5, "cup"),
            ("Calamansi", 8, "piece"),
            ("Garlic", 8, "clove"),
            ("Lemongrass", 3, "stalk"),
            ("Achuete", 3, "tbsp"),
            ("Cooking Oil", 0.5, "cup"),
            ("Salt", 1, "tbsp"),
            ("Black Pepper", 1, "tsp"),
        ]
    },

    # === BREAKFAST DISHES (SILOG) ===
    {
        "name": "Tapsilog",
        "description": "Filipino breakfast combo of beef tapa, sinangag (garlic fried rice), and itlog (egg). A hearty way to start the day.",
        "instructions": "1. Marinate beef slices in soy sauce, garlic, sugar, and pepper overnight.\n2. Fry marinated beef until slightly caramelized.\n3. Make garlic fried rice by frying garlic in oil, then adding day-old rice.\n4. Fry eggs sunny side up.\n5. Serve together with vinegar dipping sauce.",
        "prep_time": 480,
        "cook_time": 15,
        "servings": 2,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "breakfast",
        "ingredients": [
            ("Beef", 0.3, "kg"),
            ("Soy Sauce", 0.25, "cup"),
            ("Garlic", 8, "clove"),
            ("Sugar", 2, "tbsp"),
            ("Rice", 2, "cup"),
            ("Eggs", 2, "piece"),
            ("Cooking Oil", 3, "tbsp"),
            ("Black Pepper", 0.5, "tsp"),
        ]
    },
    {
        "name": "Tocilog",
        "description": "Sweet cured pork tocino with garlic rice and egg. A sweet and savory breakfast favorite.",
        "instructions": "1. Pan-fry tocino with a little water until water evaporates.\n2. Continue frying until caramelized.\n3. Prepare garlic fried rice.\n4. Fry eggs.\n5. Serve together.",
        "prep_time": 5,
        "cook_time": 15,
        "servings": 2,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "breakfast",
        "ingredients": [
            ("Tocino", 1, "pack"),
            ("Rice", 2, "cup"),
            ("Garlic", 6, "clove"),
            ("Eggs", 2, "piece"),
            ("Cooking Oil", 2, "tbsp"),
        ]
    },
    {
        "name": "Longsilog",
        "description": "Filipino sausage longganisa with garlic rice and egg. Regional varieties offer different flavors.",
        "instructions": "1. Pan-fry longganisa with a little water.\n2. Once water evaporates, continue frying until cooked through.\n3. Prepare garlic fried rice.\n4. Fry eggs.\n5. Serve with vinegar and garlic dip.",
        "prep_time": 5,
        "cook_time": 15,
        "servings": 2,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "breakfast",
        "ingredients": [
            ("Longganisa", 6, "piece"),
            ("Rice", 2, "cup"),
            ("Garlic", 6, "clove"),
            ("Eggs", 2, "piece"),
            ("Cooking Oil", 2, "tbsp"),
            ("Vinegar", 2, "tbsp"),
        ]
    },

    # === STEWS & BRAISED DISHES ===
    {
        "name": "Kaldereta",
        "description": "Rich tomato-based beef stew with liver spread and vegetables. A fiesta favorite with bold, complex flavors.",
        "instructions": "1. Brown beef cubes in oil.\n2. Saute garlic, onion, and tomatoes.\n3. Add tomato sauce and liver spread.\n4. Add beef broth and simmer until beef is tender.\n5. Add potatoes, carrots, and bell peppers.\n6. Season to taste.\n7. Add olives if desired.\n8. Serve hot with rice.",
        "prep_time": 20,
        "cook_time": 90,
        "servings": 6,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Beef", 1, "kg"),
            ("Tomato Sauce", 1, "cup"),
            ("Liver Spread", 1, "can"),
            ("Potato", 3, "piece"),
            ("Carrot", 2, "piece"),
            ("Bell Pepper", 2, "piece"),
            ("Garlic", 6, "clove"),
            ("Onion", 1, "piece"),
            ("Bay Leaf", 2, "piece"),
            ("Beef Broth", 2, "cup"),
            ("Cooking Oil", 3, "tbsp"),
        ]
    },
    {
        "name": "Mechado",
        "description": "Braised beef in tomato sauce with soy sauce and citrus. A hearty, comforting dish with Spanish influences.",
        "instructions": "1. Lard beef with pork fat (optional).\n2. Brown beef in oil.\n3. Saute garlic and onion.\n4. Add tomato sauce, soy sauce, and calamansi juice.\n5. Add water and simmer until tender.\n6. Add potatoes.\n7. Season to taste.",
        "prep_time": 15,
        "cook_time": 90,
        "servings": 6,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Beef Brisket", 1, "kg"),
            ("Tomato Sauce", 1, "cup"),
            ("Soy Sauce", 0.25, "cup"),
            ("Calamansi", 3, "piece"),
            ("Potato", 3, "piece"),
            ("Garlic", 5, "clove"),
            ("Onion", 1, "piece"),
            ("Bay Leaf", 2, "piece"),
            ("Water", 2, "cup"),
        ]
    },
    {
        "name": "Menudo",
        "description": "Pork and liver stew with potatoes and chickpeas in tomato sauce. A home-style comfort food.",
        "instructions": "1. Saute garlic, onion, and tomatoes.\n2. Add pork and cook until browned.\n3. Add pork liver and cook briefly.\n4. Add tomato sauce, soy sauce, and water.\n5. Simmer until pork is tender.\n6. Add potatoes and chickpeas.\n7. Add raisins if desired.\n8. Season to taste.",
        "prep_time": 20,
        "cook_time": 45,
        "servings": 6,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Pork Shoulder", 0.5, "kg"),
            ("Pork Liver", 0.25, "kg"),
            ("Potato", 2, "piece"),
            ("Chickpeas", 1, "cup"),
            ("Tomato Sauce", 1, "cup"),
            ("Soy Sauce", 2, "tbsp"),
            ("Garlic", 4, "clove"),
            ("Onion", 1, "piece"),
            ("Tomato", 1, "piece"),
        ]
    },
    {
        "name": "Afritada",
        "description": "Chicken or pork braised in tomato sauce with vegetables. A comforting, home-style dish.",
        "instructions": "1. Brown chicken pieces in oil.\n2. Saute garlic, onion, and tomatoes.\n3. Add tomato sauce and water.\n4. Simmer until chicken is tender.\n5. Add potatoes, carrots, and bell peppers.\n6. Add peas last.\n7. Season with salt and pepper.",
        "prep_time": 15,
        "cook_time": 40,
        "servings": 6,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Chicken Thigh", 1, "kg"),
            ("Tomato Sauce", 1, "cup"),
            ("Potato", 2, "piece"),
            ("Carrot", 2, "piece"),
            ("Bell Pepper", 1, "piece"),
            ("Garlic", 4, "clove"),
            ("Onion", 1, "piece"),
            ("Bay Leaf", 2, "piece"),
            ("Water", 1, "cup"),
        ]
    },

    # === VEGETABLE DISHES ===
    {
        "name": "Pinakbet",
        "description": "Mixed vegetables cooked in bagoong (fermented shrimp paste). A nutritious Ilocano dish packed with local vegetables.",
        "instructions": "1. Saute garlic, onion, and tomatoes.\n2. Add pork and cook until browned.\n3. Add bagoong and cook for a minute.\n4. Add vegetables starting with harder ones.\n5. Add a little water if needed.\n6. Cover and cook until vegetables are tender.\n7. Do not over-stir to maintain vegetable integrity.",
        "prep_time": 20,
        "cook_time": 25,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Pork Belly", 0.25, "kg"),
            ("Ampalaya", 1, "piece"),
            ("Eggplant", 2, "piece"),
            ("Kalabasa", 2, "slice"),
            ("Sitaw", 1, "bundle"),
            ("Okra", 6, "piece"),
            ("Tomato", 2, "piece"),
            ("Onion", 1, "piece"),
            ("Garlic", 4, "clove"),
            ("Bagoong Alamang", 2, "tbsp"),
        ]
    },
    {
        "name": "Ginisang Ampalaya",
        "description": "Sauteed bitter melon with eggs. A simple, healthy dish that balances bitterness with savory eggs.",
        "instructions": "1. Slice ampalaya thinly and salt to reduce bitterness.\n2. Rinse and squeeze out excess water.\n3. Saute garlic and onion.\n4. Add ampalaya and cook until slightly tender.\n5. Add beaten eggs and scramble with the vegetable.\n6. Season with salt and pepper.",
        "prep_time": 15,
        "cook_time": 10,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Ampalaya", 2, "piece"),
            ("Eggs", 3, "piece"),
            ("Garlic", 3, "clove"),
            ("Onion", 1, "piece"),
            ("Tomato", 1, "piece"),
            ("Salt", 1, "tsp"),
            ("Cooking Oil", 2, "tbsp"),
        ]
    },
    {
        "name": "Laing",
        "description": "Taro leaves cooked in coconut milk with chili. A Bicolano specialty known for its creamy, spicy flavor.",
        "instructions": "1. Dry taro leaves in the sun or use dried leaves.\n2. Saute garlic, onion, and ginger.\n3. Add pork and cook until browned.\n4. Add coconut milk and bring to a boil.\n5. Add taro leaves and chili.\n6. Simmer uncovered, stirring occasionally, until leaves are tender.\n7. Season with fish sauce.\n8. Add coconut cream at the end.",
        "prep_time": 20,
        "cook_time": 45,
        "servings": 6,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Malunggay", 4, "cup"),
            ("Coconut Milk", 2, "cup"),
            ("Coconut Cream", 1, "cup"),
            ("Pork Belly", 0.25, "kg"),
            ("Shrimp", 0.25, "kg"),
            ("Garlic", 4, "clove"),
            ("Onion", 1, "piece"),
            ("Ginger", 1, "thumb"),
            ("Siling Labuyo", 5, "piece"),
            ("Fish Sauce", 2, "tbsp"),
        ]
    },
    {
        "name": "Ginataang Kalabasa",
        "description": "Squash cooked in coconut milk with shrimp. A creamy, slightly sweet vegetable dish.",
        "instructions": "1. Saute garlic, onion, and ginger.\n2. Add pork and cook until browned.\n3. Add coconut milk and bring to a boil.\n4. Add kalabasa and simmer until tender.\n5. Add shrimp and sitaw.\n6. Season with fish sauce.\n7. Add chili if desired.",
        "prep_time": 15,
        "cook_time": 25,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Kalabasa", 0.5, "kg"),
            ("Coconut Milk", 2, "cup"),
            ("Shrimp", 0.25, "kg"),
            ("Pork Belly", 0.2, "kg"),
            ("Sitaw", 1, "bundle"),
            ("Garlic", 3, "clove"),
            ("Onion", 1, "piece"),
            ("Ginger", 1, "thumb"),
            ("Fish Sauce", 2, "tbsp"),
        ]
    },

    # === SOUP DISHES ===
    {
        "name": "Bulalo",
        "description": "Beef shank and bone marrow soup with vegetables. Rich, flavorful broth from long-simmered bones.",
        "instructions": "1. Boil beef shank and bone marrow in water, removing scum.\n2. Simmer for 2-3 hours until meat is very tender.\n3. Add onion and fish sauce.\n4. Add corn and potatoes.\n5. Add cabbage and pechay last.\n6. Season to taste.\n7. Serve hot with rice.",
        "prep_time": 15,
        "cook_time": 180,
        "servings": 6,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Beef Shank", 1.5, "kg"),
            ("Corn", 2, "ear"),
            ("Potato", 3, "piece"),
            ("Cabbage", 0.25, "head"),
            ("Pechay", 1, "bunch"),
            ("Onion", 1, "piece"),
            ("Fish Sauce", 3, "tbsp"),
            ("Peppercorn", 1, "tbsp"),
            ("Water", 10, "cup"),
        ]
    },
    {
        "name": "Tinola",
        "description": "Ginger-based chicken soup with green papaya and malunggay leaves. Light, nourishing, and perfect when feeling under the weather.",
        "instructions": "1. Saute garlic, onion, and ginger until fragrant.\n2. Add chicken and cook until slightly browned.\n3. Add water or broth and bring to a boil.\n4. Add green papaya and cook until tender.\n5. Add fish sauce to taste.\n6. Add malunggay or chili leaves.\n7. Serve hot.",
        "prep_time": 15,
        "cook_time": 35,
        "servings": 6,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Whole Chicken", 1, "piece"),
            ("Green Papaya", 1, "piece"),
            ("Malunggay", 2, "cup"),
            ("Ginger", 2, "thumb"),
            ("Garlic", 4, "clove"),
            ("Onion", 1, "piece"),
            ("Fish Sauce", 3, "tbsp"),
            ("Water", 8, "cup"),
        ]
    },
    {
        "name": "Nilaga",
        "description": "Boiled beef or pork with vegetables in clear broth. Simple, clean flavors showcasing quality ingredients.",
        "instructions": "1. Boil beef in water, removing scum.\n2. Add peppercorns and onion.\n3. Simmer until beef is tender.\n4. Add potatoes and corn.\n5. Add cabbage last.\n6. Season with fish sauce and pepper.",
        "prep_time": 10,
        "cook_time": 90,
        "servings": 6,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Beef Brisket", 1, "kg"),
            ("Potato", 3, "piece"),
            ("Cabbage", 0.25, "head"),
            ("Corn", 2, "ear"),
            ("Onion", 1, "piece"),
            ("Peppercorn", 1, "tbsp"),
            ("Fish Sauce", 3, "tbsp"),
            ("Water", 10, "cup"),
        ]
    },
    {
        "name": "Mami",
        "description": "Filipino-Chinese noodle soup with meat and vegetables. A comforting soup for any time of day.",
        "instructions": "1. Make broth by boiling bones or use instant broth.\n2. Cook egg noodles separately.\n3. Prepare toppings: sliced meat, hard-boiled eggs.\n4. Place noodles in a bowl.\n5. Add toppings.\n6. Pour hot broth over.\n7. Garnish with spring onions.",
        "prep_time": 15,
        "cook_time": 20,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "breakfast,lunch,dinner",
        "ingredients": [
            ("Egg Noodles", 2, "pack"),
            ("Chicken Breast", 0.25, "kg"),
            ("Eggs", 4, "piece"),
            ("Chicken Broth", 6, "cup"),
            ("Spring Onion", 2, "stalk"),
            ("Garlic", 3, "clove"),
            ("Soy Sauce", 2, "tbsp"),
        ]
    },

    # === FRIED DISHES ===
    {
        "name": "Chicken Nuggets",
        "description": "Breaded and fried chicken pieces. A family-friendly dish loved by kids and adults alike.",
        "instructions": "1. Cut chicken breast into bite-sized pieces.\n2. Season with salt and pepper.\n3. Dip in beaten egg, then coat with bread crumbs.\n4. Deep fry until golden and cooked through.\n5. Drain on paper towels.\n6. Serve with ketchup or gravy.",
        "prep_time": 20,
        "cook_time": 15,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "snack,dinner",
        "ingredients": [
            ("Chicken Breast", 0.5, "kg"),
            ("Bread Crumbs", 1, "cup"),
            ("Eggs", 2, "piece"),
            ("Flour", 0.5, "cup"),
            ("Salt", 1, "tsp"),
            ("Black Pepper", 0.5, "tsp"),
            ("Cooking Oil", 2, "cup"),
        ]
    },
    {
        "name": "Fried Chicken",
        "description": "Crispy fried chicken Filipino-style. Golden, juicy, and perfect with rice.",
        "instructions": "1. Marinate chicken in soy sauce, calamansi, and garlic.\n2. Coat in seasoned flour.\n3. Deep fry until golden and cooked through.\n4. Drain and serve hot.",
        "prep_time": 60,
        "cook_time": 25,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Whole Chicken", 1, "piece"),
            ("Soy Sauce", 0.5, "cup"),
            ("Calamansi", 4, "piece"),
            ("Garlic", 6, "clove"),
            ("Flour", 1, "cup"),
            ("Cooking Oil", 4, "cup"),
            ("Salt", 1, "tsp"),
            ("Black Pepper", 1, "tsp"),
        ]
    },
    {
        "name": "Pritong Tilapia",
        "description": "Crispy fried tilapia fish. A simple, everyday Filipino fish dish.",
        "instructions": "1. Clean and score tilapia.\n2. Rub with salt inside and out.\n3. Heat oil in a pan.\n4. Fry fish until golden and crispy on both sides.\n5. Serve with vinegar-garlic dip.",
        "prep_time": 10,
        "cook_time": 15,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Tilapia", 4, "piece"),
            ("Salt", 1, "tbsp"),
            ("Cooking Oil", 1, "cup"),
            ("Garlic", 4, "clove"),
            ("Vinegar", 0.25, "cup"),
        ]
    },

    # === DESSERTS & SWEETS ===
    {
        "name": "Leche Flan",
        "description": "Filipino caramel custard dessert. Rich, creamy, and with a perfect caramel top.",
        "instructions": "1. Caramelize sugar in llanera until golden.\n2. Beat egg yolks with condensed and evaporated milk.\n3. Add vanilla.\n4. Strain mixture into llanera.\n5. Cover with foil.\n6. Steam for 45-60 minutes.\n7. Let cool, then refrigerate.\n8. Invert onto a plate to serve.",
        "prep_time": 20,
        "cook_time": 60,
        "servings": 8,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "dessert",
        "ingredients": [
            ("Eggs", 10, "piece"),
            ("Condensed Milk", 1, "can"),
            ("Evaporated Milk", 1, "can"),
            ("Sugar", 0.75, "cup"),
        ]
    },
    {
        "name": "Halo-Halo",
        "description": "Filipino shaved ice dessert with mixed ingredients. A refreshing summer treat with layers of sweetness.",
        "instructions": "1. Place sweet beans, jellies, and fruits at the bottom of a tall glass.\n2. Add shaved ice on top.\n3. Pour evaporated milk over.\n4. Top with leche flan, ube ice cream, and rice crispies.\n5. Mix everything together before eating.",
        "prep_time": 15,
        "cook_time": 0,
        "servings": 1,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "dessert,snack",
        "ingredients": [
            ("Ice", 2, "cup"),
            ("Evaporated Milk", 0.5, "cup"),
            ("Mung Beans", 2, "tbsp"),
            ("Red Beans", 2, "tbsp"),
            ("Jackfruit", 2, "tbsp"),
            ("Banana", 0.5, "piece"),
            ("Condensed Milk", 2, "tbsp"),
        ]
    },
    {
        "name": "Turon",
        "description": "Fried banana spring rolls with jackfruit and brown sugar. A popular street food dessert.",
        "instructions": "1. Slice saba banana lengthwise.\n2. Roll in brown sugar.\n3. Place banana and jackfruit strips on lumpia wrapper.\n4. Roll and seal edges.\n5. Deep fry until golden and caramelized.\n6. Serve warm.",
        "prep_time": 15,
        "cook_time": 10,
        "servings": 10,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "dessert,snack",
        "ingredients": [
            ("Saba Banana", 10, "piece"),
            ("Jackfruit", 1, "cup"),
            ("Brown Sugar", 0.5, "cup"),
            ("Lumpia Wrapper", 10, "piece"),
            ("Cooking Oil", 2, "cup"),
        ]
    },
    {
        "name": "Bibingka",
        "description": "Traditional rice cake cooked in clay pot lined with banana leaves. A Christmas morning tradition.",
        "instructions": "1. Mix rice flour, sugar, coconut milk, and eggs.\n2. Line bilao with banana leaves.\n3. Pour batter into lined mold.\n4. Top with salted egg slices and cheese.\n5. Bake until golden.\n6. Brush with butter.\n7. Serve warm.",
        "prep_time": 15,
        "cook_time": 30,
        "servings": 8,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "dessert,breakfast,snack",
        "ingredients": [
            ("Rice", 2, "cup"),
            ("Coconut Milk", 1.5, "cup"),
            ("Sugar", 1, "cup"),
            ("Eggs", 3, "piece"),
            ("Butter", 3, "tbsp"),
            ("Salted Egg", 2, "piece"),
            ("Cheese", 0.5, "cup"),
        ]
    },
    {
        "name": "Puto",
        "description": "Steamed rice cakes. Soft, fluffy, and slightly sweet - perfect as snack or with savory dishes.",
        "instructions": "1. Mix rice flour, sugar, baking powder, and water.\n2. Pour into greased molds.\n3. Top with cheese if desired.\n4. Steam for 15-20 minutes.\n5. Let cool before removing from molds.",
        "prep_time": 10,
        "cook_time": 20,
        "servings": 12,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "dessert,snack",
        "ingredients": [
            ("Rice", 2, "cup"),
            ("Sugar", 0.75, "cup"),
            ("Water", 1.5, "cup"),
            ("Cheese", 0.5, "cup"),
        ]
    },

    # === MORE CLASSIC DISHES ===
    {
        "name": "Bicol Express",
        "description": "Spicy pork in coconut milk with lots of chili. A fiery Bicolano dish not for the faint of heart.",
        "instructions": "1. Saute garlic, onion, and ginger.\n2. Add pork and cook until browned.\n3. Add bagoong and cook for a minute.\n4. Add coconut milk and bring to a boil.\n5. Add chili peppers.\n6. Simmer until pork is tender and sauce is thick.\n7. Add coconut cream and cook until oil separates.",
        "prep_time": 15,
        "cook_time": 45,
        "servings": 4,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Pork Belly", 0.5, "kg"),
            ("Coconut Milk", 2, "cup"),
            ("Coconut Cream", 1, "cup"),
            ("Siling Labuyo", 10, "piece"),
            ("Siling Haba", 5, "piece"),
            ("Garlic", 5, "clove"),
            ("Onion", 1, "piece"),
            ("Ginger", 1, "thumb"),
            ("Bagoong Alamang", 2, "tbsp"),
        ]
    },
    {
        "name": "Sisig",
        "description": "Sizzling chopped pork face and ears. A beloved Filipino bar food that's crispy, savory, and tangy.",
        "instructions": "1. Boil pork parts until tender.\n2. Grill until slightly charred.\n3. Chop finely.\n4. Saute chopped meat with onion and chili.\n5. Season with soy sauce, calamansi, and mayonnaise.\n6. Serve on sizzling plate.\n7. Top with raw egg if desired.",
        "prep_time": 30,
        "cook_time": 90,
        "servings": 4,
        "difficulty": "hard",
        "cuisine_type": "Filipino",
        "meal_type": "appetizer,dinner",
        "ingredients": [
            ("Pork Belly", 0.5, "kg"),
            ("Pork Liver", 0.1, "kg"),
            ("Onion", 2, "piece"),
            ("Siling Labuyo", 5, "piece"),
            ("Calamansi", 5, "piece"),
            ("Soy Sauce", 2, "tbsp"),
            ("Eggs", 1, "piece"),
            ("Black Pepper", 1, "tsp"),
        ]
    },
    {
        "name": "Dinuguan",
        "description": "Savory pork blood stew. Rich, dark, and deeply flavorful - an acquired taste for some.",
        "instructions": "1. Saute garlic and onion.\n2. Add pork and cook until browned.\n3. Add vinegar (don't stir until it boils).\n4. Add water and simmer until pork is tender.\n5. Add pork blood, stirring constantly.\n6. Add chili peppers.\n7. Season with fish sauce.\n8. Serve with puto.",
        "prep_time": 15,
        "cook_time": 60,
        "servings": 6,
        "difficulty": "medium",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Pork Belly", 0.5, "kg"),
            ("Pork Blood", 2, "cup"),
            ("Vinegar", 0.25, "cup"),
            ("Garlic", 5, "clove"),
            ("Onion", 1, "piece"),
            ("Siling Haba", 3, "piece"),
            ("Fish Sauce", 2, "tbsp"),
            ("Bay Leaf", 2, "piece"),
        ]
    },
    {
        "name": "Paksiw na Isda",
        "description": "Fish stewed in vinegar with ginger. A simple, tangy fish dish that keeps well.",
        "instructions": "1. Arrange fish in a pot.\n2. Add garlic, ginger, onion, and eggplant.\n3. Pour vinegar and water over.\n4. Add peppercorns.\n5. Bring to a boil without stirring.\n6. Simmer until fish is cooked.\n7. Season with salt if needed.",
        "prep_time": 10,
        "cook_time": 20,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Bangus", 1, "piece"),
            ("Vinegar", 0.5, "cup"),
            ("Ginger", 2, "thumb"),
            ("Garlic", 5, "clove"),
            ("Onion", 1, "piece"),
            ("Eggplant", 1, "piece"),
            ("Peppercorn", 1, "tsp"),
            ("Water", 0.5, "cup"),
        ]
    },
    {
        "name": "Tortang Talong",
        "description": "Eggplant omelette. A simple, satisfying dish where charred eggplant meets fluffy eggs.",
        "instructions": "1. Grill eggplants until skin is charred and flesh is soft.\n2. Peel off skin.\n3. Flatten eggplant with a fork.\n4. Beat eggs with salt and pepper.\n5. Dip flattened eggplant in egg.\n6. Pan-fry until golden on both sides.\n7. Serve with rice and ketchup.",
        "prep_time": 10,
        "cook_time": 15,
        "servings": 4,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "breakfast,lunch,dinner",
        "ingredients": [
            ("Eggplant", 4, "piece"),
            ("Eggs", 4, "piece"),
            ("Salt", 0.5, "tsp"),
            ("Black Pepper", 0.25, "tsp"),
            ("Cooking Oil", 3, "tbsp"),
        ]
    },
    {
        "name": "Ginisang Monggo",
        "description": "Sauteed mung bean stew with pork and vegetables. A nutritious, budget-friendly Filipino Friday staple.",
        "instructions": "1. Boil mung beans until soft.\n2. Saute garlic, onion, and tomatoes.\n3. Add pork and cook until browned.\n4. Add boiled mung beans and water.\n5. Simmer until thick.\n6. Add ampalaya leaves or malunggay.\n7. Season with fish sauce.",
        "prep_time": 15,
        "cook_time": 45,
        "servings": 6,
        "difficulty": "easy",
        "cuisine_type": "Filipino",
        "meal_type": "lunch,dinner",
        "ingredients": [
            ("Mung Beans", 1, "cup"),
            ("Pork Belly", 0.25, "kg"),
            ("Tomato", 2, "piece"),
            ("Onion", 1, "piece"),
            ("Garlic", 4, "clove"),
            ("Malunggay", 1, "cup"),
            ("Fish Sauce", 2, "tbsp"),
            ("Water", 4, "cup"),
        ]
    },
]


def populate_ingredients():
    """Add all Filipino ingredients to database"""
    print("\n=== Adding Filipino Ingredients ===")
    added = 0
    skipped = 0

    for ing_data in FILIPINO_INGREDIENTS:
        existing = Ingredient.query.filter_by(name=ing_data["name"]).first()
        if existing:
            skipped += 1
            continue

        ingredient = Ingredient(
            name=ing_data["name"],
            category=ing_data["category"],
            common_unit=ing_data.get("common_unit")
        )
        db.session.add(ingredient)
        added += 1

    db.session.commit()
    print(f"Added {added} ingredients, skipped {skipped} existing")
    return added


def populate_recipes():
    """Add all Filipino recipes to database"""
    print("\n=== Adding Filipino Recipes ===")
    added = 0
    skipped = 0

    for recipe_data in FILIPINO_RECIPES:
        existing = Recipe.query.filter_by(name=recipe_data["name"]).first()
        if existing:
            skipped += 1
            continue

        # Create recipe - instructions should be a list
        instructions_list = recipe_data["instructions"].split("\n")
        instructions_list = [step.strip() for step in instructions_list if step.strip()]

        recipe = Recipe(
            name=recipe_data["name"],
            description=recipe_data["description"],
            instructions=instructions_list,
            prep_time=recipe_data["prep_time"],
            cook_time=recipe_data["cook_time"],
            total_time=recipe_data["prep_time"] + recipe_data["cook_time"],
            servings=recipe_data["servings"],
            difficulty_level=recipe_data["difficulty"],
            cuisine_type=recipe_data["cuisine_type"],
            meal_type=recipe_data["meal_type"],
        )
        db.session.add(recipe)
        db.session.flush()  # Get recipe ID

        # Add recipe ingredients
        for ing_name, quantity, unit in recipe_data["ingredients"]:
            ingredient = Ingredient.query.filter_by(name=ing_name).first()
            if ingredient:
                recipe_ingredient = RecipeIngredient(
                    recipe_id=recipe.id,
                    ingredient_id=ingredient.id,
                    quantity=quantity,
                    unit=unit
                )
                db.session.add(recipe_ingredient)
            else:
                print(f"  Warning: Ingredient '{ing_name}' not found for recipe '{recipe_data['name']}'")

        added += 1

    db.session.commit()
    print(f"Added {added} recipes, skipped {skipped} existing")
    return added


def main():
    """Main function to populate database"""
    with app.app_context():
        print("=" * 60)
        print("POPULATING FILIPINO INGREDIENTS AND RECIPES")
        print("=" * 60)

        # First add ingredients
        ingredients_added = populate_ingredients()

        # Then add recipes (which reference ingredients)
        recipes_added = populate_recipes()

        # Summary
        total_ingredients = Ingredient.query.count()
        total_recipes = Recipe.query.count()

        print("\n" + "=" * 60)
        print("SUMMARY")
        print("=" * 60)
        print(f"Total ingredients in database: {total_ingredients}")
        print(f"Total recipes in database: {total_recipes}")
        print("\nDatabase population complete!")


if __name__ == "__main__":
    main()
