class Recipe {
  final int id;
  final String name;
  final String? description;
  final String? cuisineType;
  final String? mealType;
  final String? difficultyLevel;
  final RecipeTime? time;
  final int? servings;
  final List<String>? instructions;
  final Nutrition? nutrition;
  final Dietary? dietary;
  final String? imageUrl;
  final String? videoUrl;
  final double? rating;
  final int? ratingCount;
  final int? viewCount;
  final String? createdAt;
  final List<RecipeIngredient>? ingredients;

  // For search results
  final double? matchPercentage;
  final int? matchingIngredients;
  final int? totalIngredients;

  Recipe({
    required this.id,
    required this.name,
    this.description,
    this.cuisineType,
    this.mealType,
    this.difficultyLevel,
    this.time,
    this.servings,
    this.instructions,
    this.nutrition,
    this.dietary,
    this.imageUrl,
    this.videoUrl,
    this.rating,
    this.ratingCount,
    this.viewCount,
    this.createdAt,
    this.ingredients,
    this.matchPercentage,
    this.matchingIngredients,
    this.totalIngredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      cuisineType: json['cuisine_type'] as String?,
      mealType: json['meal_type'] as String?,
      difficultyLevel: json['difficulty_level'] as String?,
      time: json['time'] != null ? RecipeTime.fromJson(json['time'] as Map<String, dynamic>) : null,
      servings: json['servings'] as int?,
      instructions: json['instructions'] != null ? List<String>.from(json['instructions'] as List) : null,
      nutrition: json['nutrition'] != null ? Nutrition.fromJson(json['nutrition'] as Map<String, dynamic>) : null,
      dietary: json['dietary'] != null ? Dietary.fromJson(json['dietary'] as Map<String, dynamic>) : null,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      ratingCount: json['rating_count'] as int?,
      viewCount: json['view_count'] as int?,
      createdAt: json['created_at'] as String?,
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List).map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      matchPercentage: json['match_percentage'] != null ? (json['match_percentage'] as num).toDouble() : null,
      matchingIngredients: json['matching_ingredients'] as int?,
      totalIngredients: json['total_ingredients'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cuisine_type': cuisineType,
      'meal_type': mealType,
      'difficulty_level': difficultyLevel,
      'time': time?.toJson(),
      'servings': servings,
      'instructions': instructions,
      'nutrition': nutrition?.toJson(),
      'dietary': dietary?.toJson(),
      'image_url': imageUrl,
      'video_url': videoUrl,
      'rating': rating,
      'rating_count': ratingCount,
      'view_count': viewCount,
      'created_at': createdAt,
      'ingredients': ingredients?.map((e) => e.toJson()).toList(),
    };
  }
}

class RecipeTime {
  final int? prepTime;
  final int? cookTime;
  final int? totalTime;

  RecipeTime({this.prepTime, this.cookTime, this.totalTime});

  factory RecipeTime.fromJson(Map<String, dynamic> json) {
    return RecipeTime(
      prepTime: json['prep_time'] as int?,
      cookTime: json['cook_time'] as int?,
      totalTime: json['total_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prep_time': prepTime,
      'cook_time': cookTime,
      'total_time': totalTime,
    };
  }
}

class Nutrition {
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? fiber;

  Nutrition({
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    this.fiber,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: json['calories'] != null ? (json['calories'] as num).toDouble() : null,
      protein: json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      carbohydrates: json['carbohydrates'] != null ? (json['carbohydrates'] as num).toDouble() : null,
      fat: json['fat'] != null ? (json['fat'] as num).toDouble() : null,
      fiber: json['fiber'] != null ? (json['fiber'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
    };
  }
}

class Dietary {
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isDairyFree;

  Dietary({
    required this.isVegetarian,
    required this.isVegan,
    required this.isGlutenFree,
    required this.isDairyFree,
  });

  factory Dietary.fromJson(Map<String, dynamic> json) {
    return Dietary(
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isVegan: json['is_vegan'] as bool? ?? false,
      isGlutenFree: json['is_gluten_free'] as bool? ?? false,
      isDairyFree: json['is_dairy_free'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_vegetarian': isVegetarian,
      'is_vegan': isVegan,
      'is_gluten_free': isGlutenFree,
      'is_dairy_free': isDairyFree,
    };
  }
}

class RecipeIngredient {
  final int? id;
  final int? recipeId;
  final int? ingredientId;
  final String? ingredientName;
  final double? quantity;
  final String? unit;
  final String? preparation;
  final bool? isOptional;

  RecipeIngredient({
    this.id,
    this.recipeId,
    this.ingredientId,
    this.ingredientName,
    this.quantity,
    this.unit,
    this.preparation,
    this.isOptional,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as int?,
      recipeId: json['recipe_id'] as int?,
      ingredientId: json['ingredient_id'] as int?,
      ingredientName: json['ingredient_name'] as String?,
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : null,
      unit: json['unit'] as String?,
      preparation: json['preparation'] as String?,
      isOptional: json['is_optional'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'ingredient_name': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'preparation': preparation,
      'is_optional': isOptional,
    };
  }
}
