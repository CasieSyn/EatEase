"""
Seed script to populate database with Filipino ingredients and recipes
Run: python seed_data.py
"""
import os
import sys
from app import create_app, db
from app.models import Ingredient, Recipe, RecipeIngredient

# Filipino ingredients with nutritional data (per 100g)
INGREDIENTS = [
    # Proteins
    {"name": "Chicken Breast", "category": "protein", "calories": 165, "protein": 31, "carbohydrates": 0, "fat": 3.6, "fiber": 0, "common_unit": "g"},
    {"name": "Pork Belly", "category": "protein", "calories": 518, "protein": 9, "carbohydrates": 0, "fat": 53, "fiber": 0, "common_unit": "g"},
    {"name": "Beef", "category": "protein", "calories": 250, "protein": 26, "carbohydrates": 0, "fat": 15, "fiber": 0, "common_unit": "g"},
    {"name": "Tilapia", "category": "protein", "calories": 128, "protein": 26, "carbohydrates": 0, "fat": 2.7, "fiber": 0, "common_unit": "g"},
    {"name": "Shrimp", "category": "protein", "calories": 99, "protein": 24, "carbohydrates": 0.2, "fat": 0.3, "fiber": 0, "common_unit": "g"},
    {"name": "Eggs", "category": "protein", "calories": 155, "protein": 13, "carbohydrates": 1.1, "fat": 11, "fiber": 0, "common_unit": "piece"},

    # Vegetables
    {"name": "Tomato", "category": "vegetable", "calories": 18, "protein": 0.9, "carbohydrates": 3.9, "fat": 0.2, "fiber": 1.2, "common_unit": "piece"},
    {"name": "Onion", "category": "vegetable", "calories": 40, "protein": 1.1, "carbohydrates": 9.3, "fat": 0.1, "fiber": 1.7, "common_unit": "piece"},
    {"name": "Garlic", "category": "vegetable", "calories": 149, "protein": 6.4, "carbohydrates": 33, "fat": 0.5, "fiber": 2.1, "common_unit": "clove"},
    {"name": "Ginger", "category": "vegetable", "calories": 80, "protein": 1.8, "carbohydrates": 18, "fat": 0.8, "fiber": 2, "common_unit": "g"},
    {"name": "Bell Pepper", "category": "vegetable", "calories": 31, "protein": 1, "carbohydrates": 6, "fat": 0.3, "fiber": 2.1, "common_unit": "piece"},
    {"name": "Cabbage", "category": "vegetable", "calories": 25, "protein": 1.3, "carbohydrates": 5.8, "fat": 0.1, "fiber": 2.5, "common_unit": "g"},
    {"name": "Potato", "category": "vegetable", "calories": 77, "protein": 2, "carbohydrates": 17, "fat": 0.1, "fiber": 2.1, "common_unit": "piece"},
    {"name": "Carrot", "category": "vegetable", "calories": 41, "protein": 0.9, "carbohydrates": 10, "fat": 0.2, "fiber": 2.8, "common_unit": "piece"},
    {"name": "Green Beans", "category": "vegetable", "calories": 31, "protein": 1.8, "carbohydrates": 7, "fat": 0.2, "fiber": 2.7, "common_unit": "g"},
    {"name": "Eggplant", "category": "vegetable", "calories": 25, "protein": 1, "carbohydrates": 6, "fat": 0.2, "fiber": 3, "common_unit": "piece"},

    # Grains & Starches
    {"name": "Rice", "category": "grain", "calories": 130, "protein": 2.7, "carbohydrates": 28, "fat": 0.3, "fiber": 0.4, "common_unit": "cup"},
    {"name": "Noodles", "category": "grain", "calories": 138, "protein": 4.5, "carbohydrates": 25, "fat": 2.1, "fiber": 1.2, "common_unit": "g"},
    {"name": "Bread", "category": "grain", "calories": 265, "protein": 9, "carbohydrates": 49, "fat": 3.2, "fiber": 2.7, "common_unit": "slice"},

    # Condiments & Sauces
    {"name": "Soy Sauce", "category": "condiment", "calories": 53, "protein": 5, "carbohydrates": 4.9, "fat": 0.1, "fiber": 0.8, "common_unit": "tbsp"},
    {"name": "Fish Sauce", "category": "condiment", "calories": 35, "protein": 5.1, "carbohydrates": 3.8, "fat": 0, "fiber": 0, "common_unit": "tbsp"},
    {"name": "Vinegar", "category": "condiment", "calories": 18, "protein": 0, "carbohydrates": 0.04, "fat": 0, "fiber": 0, "common_unit": "tbsp"},
    {"name": "Coconut Milk", "category": "dairy", "calories": 230, "protein": 2.3, "carbohydrates": 6, "fat": 24, "fiber": 2.2, "common_unit": "ml"},
    {"name": "Oil", "category": "condiment", "calories": 884, "protein": 0, "carbohydrates": 0, "fat": 100, "fiber": 0, "common_unit": "tbsp"},
    {"name": "Salt", "category": "condiment", "calories": 0, "protein": 0, "carbohydrates": 0, "fat": 0, "fiber": 0, "common_unit": "tsp"},
    {"name": "Black Pepper", "category": "spice", "calories": 251, "protein": 10, "carbohydrates": 64, "fat": 3.3, "fiber": 25, "common_unit": "tsp"},
    {"name": "Bay Leaf", "category": "spice", "calories": 313, "protein": 7.6, "carbohydrates": 75, "fat": 8.4, "fiber": 26, "common_unit": "piece"},
]

# Filipino recipes
RECIPES = [
    {
        "name": "Chicken Adobo",
        "description": "Classic Filipino dish with chicken braised in soy sauce, vinegar, and spices",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 40,
        "total_time": 50,
        "servings": 4,
        "instructions": [
            "Combine chicken, soy sauce, vinegar, garlic, bay leaves, and peppercorns in a pot",
            "Marinate for at least 30 minutes",
            "Bring to a boil, then reduce heat and simmer for 30 minutes",
            "Remove chicken and reduce sauce until thickened",
            "Serve hot with rice"
        ],
        "is_gluten_free": False,
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Chicken Breast", "quantity": 500, "unit": "g"},
            {"name": "Soy Sauce", "quantity": 60, "unit": "ml"},
            {"name": "Vinegar", "quantity": 60, "unit": "ml"},
            {"name": "Garlic", "quantity": 6, "unit": "clove", "preparation": "crushed"},
            {"name": "Bay Leaf", "quantity": 3, "unit": "piece"},
            {"name": "Black Pepper", "quantity": 1, "unit": "tsp"},
            {"name": "Oil", "quantity": 2, "unit": "tbsp"}
        ]
    },
    {
        "name": "Sinigang na Baboy",
        "description": "Filipino sour soup with pork and vegetables",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "medium",
        "prep_time": 15,
        "cook_time": 60,
        "total_time": 75,
        "servings": 6,
        "instructions": [
            "Boil pork in water until tender (about 45 minutes)",
            "Add tomatoes and onions, simmer for 5 minutes",
            "Add vegetables (eggplant, green beans)",
            "Add tamarind paste or mix for sour flavor",
            "Season with fish sauce",
            "Serve hot with rice"
        ],
        "is_gluten_free": True,
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Pork Belly", "quantity": 500, "unit": "g", "preparation": "cubed"},
            {"name": "Tomato", "quantity": 2, "unit": "piece", "preparation": "quartered"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Eggplant", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Green Beans", "quantity": 100, "unit": "g"},
            {"name": "Fish Sauce", "quantity": 30, "unit": "ml"}
        ]
    },
    {
        "name": "Vegetable Lumpia",
        "description": "Filipino spring rolls filled with vegetables",
        "cuisine_type": "Filipino",
        "meal_type": "snack",
        "difficulty_level": "medium",
        "prep_time": 30,
        "cook_time": 20,
        "total_time": 50,
        "servings": 6,
        "instructions": [
            "Sauté garlic and onion until fragrant",
            "Add shredded cabbage, carrots, and green beans",
            "Season with soy sauce and pepper",
            "Cool the filling completely",
            "Wrap filling in spring roll wrappers",
            "Deep fry until golden brown",
            "Serve with sweet chili sauce"
        ],
        "is_vegetarian": True,
        "is_vegan": True,
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Cabbage", "quantity": 200, "unit": "g", "preparation": "shredded"},
            {"name": "Carrot", "quantity": 2, "unit": "piece", "preparation": "julienned"},
            {"name": "Green Beans", "quantity": 100, "unit": "g", "preparation": "chopped"},
            {"name": "Garlic", "quantity": 4, "unit": "clove", "preparation": "minced"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "chopped"},
            {"name": "Soy Sauce", "quantity": 30, "unit": "ml"},
            {"name": "Oil", "quantity": 500, "unit": "ml", "preparation": "for frying"}
        ]
    },
    {
        "name": "Tinola",
        "description": "Filipino chicken soup with ginger and vegetables",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 35,
        "total_time": 45,
        "servings": 4,
        "instructions": [
            "Sauté garlic, onion, and ginger in oil",
            "Add chicken pieces and cook until lightly browned",
            "Pour in water and bring to a boil",
            "Add fish sauce and simmer for 20 minutes",
            "Add green beans and cook for 5 minutes",
            "Serve hot with rice"
        ],
        "is_gluten_free": True,
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Chicken Breast", "quantity": 500, "unit": "g", "preparation": "cut into pieces"},
            {"name": "Ginger", "quantity": 50, "unit": "g", "preparation": "sliced"},
            {"name": "Garlic", "quantity": 4, "unit": "clove", "preparation": "crushed"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Green Beans", "quantity": 150, "unit": "g"},
            {"name": "Fish Sauce", "quantity": 30, "unit": "ml"},
            {"name": "Oil", "quantity": 2, "unit": "tbsp"}
        ]
    },
    {
        "name": "Ginataang Gulay",
        "description": "Vegetables cooked in coconut milk",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 20,
        "total_time": 30,
        "servings": 4,
        "instructions": [
            "Sauté garlic, onion, and ginger",
            "Add coconut milk and bring to a boil",
            "Add vegetables (green beans, eggplant)",
            "Simmer until vegetables are tender",
            "Season with fish sauce or salt",
            "Serve with rice"
        ],
        "is_vegetarian": True,
        "is_gluten_free": True,
        "ingredients": [
            {"name": "Coconut Milk", "quantity": 400, "unit": "ml"},
            {"name": "Green Beans", "quantity": 150, "unit": "g"},
            {"name": "Eggplant", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Garlic", "quantity": 3, "unit": "clove", "preparation": "minced"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Ginger", "quantity": 20, "unit": "g", "preparation": "sliced"},
            {"name": "Fish Sauce", "quantity": 15, "unit": "ml"}
        ]
    },
    {
        "name": "Beef Caldereta",
        "description": "Filipino beef stew in tomato sauce with vegetables",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "medium",
        "prep_time": 20,
        "cook_time": 90,
        "total_time": 110,
        "servings": 6,
        "instructions": [
            "Brown beef in oil, set aside",
            "Sauté garlic, onion, and tomatoes",
            "Add beef back, pour in tomato sauce",
            "Add water and simmer until beef is tender (about 1.5 hours)",
            "Add potatoes, carrots, and bell peppers",
            "Cook until vegetables are tender",
            "Serve with rice"
        ],
        "is_gluten_free": True,
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Beef", "quantity": 500, "unit": "g", "preparation": "cubed"},
            {"name": "Tomato", "quantity": 3, "unit": "piece", "preparation": "chopped"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "diced"},
            {"name": "Garlic", "quantity": 5, "unit": "clove", "preparation": "minced"},
            {"name": "Potato", "quantity": 2, "unit": "piece", "preparation": "cubed"},
            {"name": "Carrot", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Bell Pepper", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Oil", "quantity": 3, "unit": "tbsp"}
        ]
    },
    {
        "name": "Pancit Canton",
        "description": "Filipino stir-fried noodles with vegetables and protein",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 15,
        "cook_time": 20,
        "total_time": 35,
        "servings": 4,
        "instructions": [
            "Soak noodles in warm water for 10 minutes",
            "Sauté garlic and onion",
            "Add chicken and cook through",
            "Add vegetables and stir-fry",
            "Add noodles and soy sauce",
            "Toss everything together",
            "Serve hot with calamansi"
        ],
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Noodles", "quantity": 400, "unit": "g"},
            {"name": "Chicken Breast", "quantity": 200, "unit": "g", "preparation": "sliced"},
            {"name": "Cabbage", "quantity": 100, "unit": "g", "preparation": "shredded"},
            {"name": "Carrot", "quantity": 1, "unit": "piece", "preparation": "julienned"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Garlic", "quantity": 4, "unit": "clove", "preparation": "minced"},
            {"name": "Soy Sauce", "quantity": 45, "unit": "ml"},
            {"name": "Oil", "quantity": 2, "unit": "tbsp"}
        ]
    },
    {
        "name": "Fish Sinigang",
        "description": "Sour tamarind soup with fish and vegetables",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 25,
        "total_time": 35,
        "servings": 4,
        "instructions": [
            "Boil water with tomatoes and onions",
            "Add fish sauce and tamarind",
            "Add fish and simmer for 10 minutes",
            "Add vegetables (eggplant, green beans)",
            "Cook until vegetables are tender",
            "Serve hot with rice"
        ],
        "is_gluten_free": True,
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Tilapia", "quantity": 500, "unit": "g"},
            {"name": "Tomato", "quantity": 2, "unit": "piece", "preparation": "quartered"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Eggplant", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Green Beans", "quantity": 100, "unit": "g"},
            {"name": "Fish Sauce", "quantity": 30, "unit": "ml"}
        ]
    },
    {
        "name": "Tortang Talong",
        "description": "Filipino eggplant omelette",
        "cuisine_type": "Filipino",
        "meal_type": "breakfast",
        "difficulty_level": "easy",
        "prep_time": 5,
        "cook_time": 15,
        "total_time": 20,
        "servings": 2,
        "instructions": [
            "Grill eggplant until soft",
            "Peel skin and flatten with fork",
            "Beat eggs with salt and pepper",
            "Dip eggplant in egg mixture",
            "Fry until golden on both sides",
            "Serve with rice and ketchup"
        ],
        "is_vegetarian": True,
        "is_gluten_free": True,
        "ingredients": [
            {"name": "Eggplant", "quantity": 2, "unit": "piece"},
            {"name": "Eggs", "quantity": 3, "unit": "piece"},
            {"name": "Garlic", "quantity": 2, "unit": "clove", "preparation": "minced"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "chopped", "is_optional": True},
            {"name": "Salt", "quantity": 1, "unit": "tsp"},
            {"name": "Black Pepper", "quantity": 0.5, "unit": "tsp"},
            {"name": "Oil", "quantity": 3, "unit": "tbsp"}
        ]
    },
    {
        "name": "Ginisang Ampalaya",
        "description": "Sautéed bitter gourd with eggs and tomatoes",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 15,
        "total_time": 25,
        "servings": 3,
        "instructions": [
            "Sauté garlic, onion, and tomatoes",
            "Add bitter gourd slices",
            "Season with fish sauce",
            "Add beaten eggs",
            "Scramble everything together",
            "Serve with rice"
        ],
        "is_vegetarian": True,
        "is_gluten_free": True,
        "ingredients": [
            {"name": "Eggs", "quantity": 3, "unit": "piece"},
            {"name": "Tomato", "quantity": 2, "unit": "piece", "preparation": "diced"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Garlic", "quantity": 3, "unit": "clove", "preparation": "minced"},
            {"name": "Fish Sauce", "quantity": 15, "unit": "ml"},
            {"name": "Oil", "quantity": 2, "unit": "tbsp"}
        ]
    },
    {
        "name": "Pork Bistek",
        "description": "Filipino-style pork steak with onions",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 25,
        "total_time": 35,
        "servings": 4,
        "instructions": [
            "Marinate pork in soy sauce and calamansi juice",
            "Sauté onion rings until soft, set aside",
            "Pan-fry pork slices until browned",
            "Add marinade and simmer",
            "Top with sautéed onions",
            "Serve with rice"
        ],
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Pork Belly", "quantity": 500, "unit": "g", "preparation": "thinly sliced"},
            {"name": "Soy Sauce", "quantity": 60, "unit": "ml"},
            {"name": "Onion", "quantity": 2, "unit": "piece", "preparation": "sliced into rings"},
            {"name": "Garlic", "quantity": 4, "unit": "clove", "preparation": "minced"},
            {"name": "Black Pepper", "quantity": 1, "unit": "tsp"},
            {"name": "Oil", "quantity": 2, "unit": "tbsp"}
        ]
    },
    {
        "name": "Chicken Tinola with Malunggay",
        "description": "Chicken ginger soup with moringa leaves",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 30,
        "total_time": 40,
        "servings": 4,
        "instructions": [
            "Sauté ginger, garlic, and onion",
            "Add chicken and lightly brown",
            "Pour water and bring to boil",
            "Simmer until chicken is cooked",
            "Add green beans",
            "Season with fish sauce",
            "Serve hot"
        ],
        "is_gluten_free": True,
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Chicken Breast", "quantity": 500, "unit": "g", "preparation": "cut into pieces"},
            {"name": "Ginger", "quantity": 50, "unit": "g", "preparation": "sliced"},
            {"name": "Garlic", "quantity": 4, "unit": "clove", "preparation": "crushed"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Green Beans", "quantity": 100, "unit": "g"},
            {"name": "Fish Sauce", "quantity": 30, "unit": "ml"},
            {"name": "Oil", "quantity": 2, "unit": "tbsp"}
        ]
    },
    {
        "name": "Garlic Fried Rice",
        "description": "Filipino breakfast fried rice with garlic",
        "cuisine_type": "Filipino",
        "meal_type": "breakfast",
        "difficulty_level": "easy",
        "prep_time": 5,
        "cook_time": 10,
        "total_time": 15,
        "servings": 3,
        "instructions": [
            "Heat oil in wok",
            "Fry minced garlic until golden and crispy",
            "Add day-old rice",
            "Season with salt",
            "Toss until heated through",
            "Serve with fried egg"
        ],
        "is_vegetarian": True,
        "is_gluten_free": True,
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Rice", "quantity": 3, "unit": "cup", "preparation": "day-old"},
            {"name": "Garlic", "quantity": 8, "unit": "clove", "preparation": "minced"},
            {"name": "Salt", "quantity": 1, "unit": "tsp"},
            {"name": "Oil", "quantity": 3, "unit": "tbsp"}
        ]
    },
    {
        "name": "Shrimp Sinigang",
        "description": "Sour tamarind soup with shrimp",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 20,
        "total_time": 30,
        "servings": 4,
        "instructions": [
            "Boil water with tomatoes and onions",
            "Add tamarind for sourness",
            "Add vegetables (eggplant, green beans)",
            "Add shrimp and cook until pink",
            "Season with fish sauce",
            "Serve hot"
        ],
        "is_gluten_free": True,
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Shrimp", "quantity": 400, "unit": "g"},
            {"name": "Tomato", "quantity": 2, "unit": "piece", "preparation": "quartered"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Eggplant", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Green Beans", "quantity": 100, "unit": "g"},
            {"name": "Fish Sauce", "quantity": 30, "unit": "ml"}
        ]
    },
    {
        "name": "Pork Humba",
        "description": "Filipino braised pork in sweet soy sauce",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "medium",
        "prep_time": 15,
        "cook_time": 60,
        "total_time": 75,
        "servings": 6,
        "instructions": [
            "Brown pork belly in oil",
            "Add garlic and onions",
            "Pour soy sauce and vinegar",
            "Add bay leaves and peppercorns",
            "Simmer for 45 minutes until tender",
            "Reduce sauce until thick",
            "Serve with rice"
        ],
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Pork Belly", "quantity": 600, "unit": "g", "preparation": "cut into chunks"},
            {"name": "Soy Sauce", "quantity": 75, "unit": "ml"},
            {"name": "Vinegar", "quantity": 60, "unit": "ml"},
            {"name": "Garlic", "quantity": 6, "unit": "clove", "preparation": "crushed"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Bay Leaf", "quantity": 3, "unit": "piece"},
            {"name": "Black Pepper", "quantity": 1, "unit": "tsp"},
            {"name": "Oil", "quantity": 2, "unit": "tbsp"}
        ]
    },
    {
        "name": "Simple Scrambled Eggs",
        "description": "Basic Filipino-style scrambled eggs",
        "cuisine_type": "Filipino",
        "meal_type": "breakfast",
        "difficulty_level": "easy",
        "prep_time": 2,
        "cook_time": 5,
        "total_time": 7,
        "servings": 2,
        "instructions": [
            "Beat eggs with salt and pepper",
            "Heat oil in pan",
            "Pour eggs and scramble",
            "Cook until just set",
            "Serve with rice"
        ],
        "is_vegetarian": True,
        "is_gluten_free": True,
        "ingredients": [
            {"name": "Eggs", "quantity": 4, "unit": "piece"},
            {"name": "Salt", "quantity": 0.5, "unit": "tsp"},
            {"name": "Black Pepper", "quantity": 0.25, "unit": "tsp"},
            {"name": "Oil", "quantity": 1, "unit": "tbsp"}
        ]
    },
    {
        "name": "Ginataang Manok",
        "description": "Chicken cooked in coconut milk",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 35,
        "total_time": 45,
        "servings": 4,
        "instructions": [
            "Sauté garlic, onion, and ginger",
            "Add chicken and brown lightly",
            "Pour coconut milk",
            "Simmer until chicken is cooked",
            "Add green beans",
            "Season with fish sauce",
            "Serve with rice"
        ],
        "is_gluten_free": True,
        "ingredients": [
            {"name": "Chicken Breast", "quantity": 500, "unit": "g", "preparation": "cut into pieces"},
            {"name": "Coconut Milk", "quantity": 400, "unit": "ml"},
            {"name": "Ginger", "quantity": 30, "unit": "g", "preparation": "sliced"},
            {"name": "Garlic", "quantity": 4, "unit": "clove", "preparation": "minced"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Green Beans", "quantity": 100, "unit": "g"},
            {"name": "Fish Sauce", "quantity": 20, "unit": "ml"}
        ]
    },
    {
        "name": "Beef with Vegetables",
        "description": "Simple sautéed beef with mixed vegetables",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 20,
        "total_time": 30,
        "servings": 4,
        "instructions": [
            "Stir-fry beef until browned",
            "Add garlic and onions",
            "Add vegetables (cabbage, carrots, green beans)",
            "Season with soy sauce",
            "Cook until vegetables are tender-crisp",
            "Serve with rice"
        ],
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Beef", "quantity": 400, "unit": "g", "preparation": "sliced"},
            {"name": "Cabbage", "quantity": 150, "unit": "g", "preparation": "chopped"},
            {"name": "Carrot", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Green Beans", "quantity": 100, "unit": "g"},
            {"name": "Garlic", "quantity": 4, "unit": "clove", "preparation": "minced"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Soy Sauce", "quantity": 30, "unit": "ml"},
            {"name": "Oil", "quantity": 2, "unit": "tbsp"}
        ]
    },
    {
        "name": "Vegetable Stir-Fry",
        "description": "Quick and healthy sautéed mixed vegetables",
        "cuisine_type": "Filipino",
        "meal_type": "lunch",
        "difficulty_level": "easy",
        "prep_time": 10,
        "cook_time": 10,
        "total_time": 20,
        "servings": 3,
        "instructions": [
            "Heat oil in wok",
            "Sauté garlic and onion",
            "Add all vegetables",
            "Stir-fry on high heat",
            "Season with soy sauce or salt",
            "Serve immediately"
        ],
        "is_vegetarian": True,
        "is_vegan": True,
        "is_gluten_free": True,
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Cabbage", "quantity": 200, "unit": "g", "preparation": "chopped"},
            {"name": "Carrot", "quantity": 1, "unit": "piece", "preparation": "julienned"},
            {"name": "Green Beans", "quantity": 150, "unit": "g"},
            {"name": "Bell Pepper", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Garlic", "quantity": 3, "unit": "clove", "preparation": "minced"},
            {"name": "Onion", "quantity": 1, "unit": "piece", "preparation": "sliced"},
            {"name": "Soy Sauce", "quantity": 20, "unit": "ml"},
            {"name": "Oil", "quantity": 2, "unit": "tbsp"}
        ]
    },
    {
        "name": "Chicken Tocino",
        "description": "Sweet Filipino chicken",
        "cuisine_type": "Filipino",
        "meal_type": "breakfast",
        "difficulty_level": "easy",
        "prep_time": 5,
        "cook_time": 20,
        "total_time": 25,
        "servings": 4,
        "instructions": [
            "Pan-fry chicken until caramelized",
            "Add a bit of water and cover",
            "Cook until tender",
            "Let water evaporate",
            "Caramelize in its own fat",
            "Serve with rice and eggs"
        ],
        "is_dairy_free": True,
        "ingredients": [
            {"name": "Chicken Breast", "quantity": 500, "unit": "g", "preparation": "sliced"},
            {"name": "Garlic", "quantity": 4, "unit": "clove", "preparation": "minced"},
            {"name": "Salt", "quantity": 1, "unit": "tsp"},
            {"name": "Black Pepper", "quantity": 0.5, "unit": "tsp"},
            {"name": "Oil", "quantity": 1, "unit": "tbsp"}
        ]
    }
]


def seed_ingredients():
    """Add ingredients to database"""
    print("Seeding ingredients...")
    count = 0

    for ing_data in INGREDIENTS:
        # Check if ingredient already exists
        existing = Ingredient.query.filter_by(name=ing_data["name"]).first()
        if not existing:
            ingredient = Ingredient(**ing_data)
            db.session.add(ingredient)
            count += 1

    db.session.commit()
    print(f"Added {count} ingredients")


def seed_recipes():
    """Add recipes with ingredients to database"""
    print("Seeding recipes...")
    count = 0

    for recipe_data in RECIPES:
        # Check if recipe already exists
        existing = Recipe.query.filter_by(name=recipe_data["name"]).first()
        if existing:
            continue

        # Extract ingredients list
        ingredients_list = recipe_data.pop("ingredients")

        # Calculate total nutritional values
        total_cal = total_prot = total_carbs = total_fat = total_fiber = 0

        # Create recipe
        recipe = Recipe(**recipe_data)
        db.session.add(recipe)
        db.session.flush()  # Get recipe ID

        # Add recipe ingredients
        for ing_data in ingredients_list:
            ingredient = Ingredient.query.filter_by(name=ing_data["name"]).first()
            if ingredient:
                recipe_ingredient = RecipeIngredient(
                    recipe_id=recipe.id,
                    ingredient_id=ingredient.id,
                    quantity=ing_data["quantity"],
                    unit=ing_data["unit"],
                    preparation=ing_data.get("preparation"),
                    is_optional=ing_data.get("is_optional", False)
                )
                db.session.add(recipe_ingredient)

                # Calculate nutrition (simplified - per 100g conversion)
                if ingredient.calories:
                    portion = ing_data["quantity"] / 100 if ing_data["unit"] == "g" else ing_data["quantity"] / 100
                    total_cal += (ingredient.calories or 0) * portion
                    total_prot += (ingredient.protein or 0) * portion
                    total_carbs += (ingredient.carbohydrates or 0) * portion
                    total_fat += (ingredient.fat or 0) * portion
                    total_fiber += (ingredient.fiber or 0) * portion

        # Update recipe nutrition (per serving)
        servings = recipe.servings or 1
        recipe.calories = round(total_cal / servings, 2)
        recipe.protein = round(total_prot / servings, 2)
        recipe.carbohydrates = round(total_carbs / servings, 2)
        recipe.fat = round(total_fat / servings, 2)
        recipe.fiber = round(total_fiber / servings, 2)

        count += 1

    db.session.commit()
    print(f"Added {count} recipes")


def main():
    """Run all seed functions"""
    app = create_app()

    with app.app_context():
        print("\nStarting database seeding...\n")

        seed_ingredients()
        seed_recipes()

        # Print summary
        total_ingredients = Ingredient.query.count()
        total_recipes = Recipe.query.count()

        print(f"\nSeeding complete!")
        print(f"   Total Ingredients: {total_ingredients}")
        print(f"   Total Recipes: {total_recipes}\n")


if __name__ == "__main__":
    main()
