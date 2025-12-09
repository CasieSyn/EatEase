import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class RecipeService {
  final AuthService _authService = AuthService();
  final CacheService _cacheService = CacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

  Future<List<Recipe>> getRecipes({
    String? cuisineType,
    String? mealType,
    String? difficulty,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    int? maxTime,
    int page = 1,
    int perPage = 20,
  }) async {
    // Check connectivity - return cached if offline
    if (!_connectivityService.isOnline) {
      final cachedRecipes = await _cacheService.getCachedRecipes();
      if (cachedRecipes != null) {
        return cachedRecipes.map((json) => Recipe.fromJson(json)).toList();
      }
      throw Exception('No internet connection and no cached data available');
    }

    try {
      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (cuisineType != null) queryParams['cuisine_type'] = cuisineType;
      if (mealType != null) queryParams['meal_type'] = mealType;
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (isVegetarian == true) queryParams['is_vegetarian'] = 'true';
      if (isVegan == true) queryParams['is_vegan'] = 'true';
      if (isGlutenFree == true) queryParams['is_gluten_free'] = 'true';
      if (maxTime != null) queryParams['max_time'] = maxTime.toString();

      final uri = Uri.parse(ApiConfig.allRecipes).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> recipesJson = data['recipes'] as List;
        final recipes = recipesJson.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();

        // Cache recipes for offline access (only first page, no filters)
        if (page == 1 && cuisineType == null && mealType == null) {
          await _cacheService.cacheRecipes(recipesJson.cast<Map<String, dynamic>>());
        }

        return recipes;
      } else {
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
      // Try to return cached data on error
      final cachedRecipes = await _cacheService.getCachedRecipes();
      if (cachedRecipes != null) {
        return cachedRecipes.map((json) => Recipe.fromJson(json)).toList();
      }
      throw Exception('Error fetching recipes: $e');
    }
  }

  Future<Recipe> getRecipeById(int id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.recipeById(id)),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Recipe.fromJson(data['recipe'] as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw Exception('Recipe not found');
      } else {
        throw Exception('Failed to load recipe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching recipe: $e');
    }
  }

  Future<List<Recipe>> searchRecipes({
    required List<String> ingredients,
    Map<String, bool>? dietaryPreferences,
  }) async {
    try {
      final body = {
        'ingredients': ingredients,
        if (dietaryPreferences != null) 'dietary_preferences': dietaryPreferences,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.searchRecipes),
        headers: ApiConfig.headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> recipesJson = data['recipes'] as List;
        return recipesJson.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to search recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching recipes: $e');
    }
  }

  Future<List<Recipe>> getRecommendations({
    List<String>? ingredients,
    int limit = 10,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = {
        if (ingredients != null && ingredients.isNotEmpty) 'ingredients': ingredients,
        'limit': limit,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.recommendRecipes),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> recommendationsJson = data['recommendations'] as List;
        return recommendationsJson.map((item) {
          final recipeData = item['recipe'] as Map<String, dynamic>;
          // Merge match_info into recipe data for display
          if (item['match_info'] != null) {
            final matchInfo = item['match_info'] as Map<String, dynamic>;
            recipeData['match_percentage'] = matchInfo['match_percentage'];
            recipeData['matching_ingredients'] = matchInfo['matching_count'];
            recipeData['total_ingredients'] = matchInfo['total_count'];
          }
          return Recipe.fromJson(recipeData);
        }).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting recommendations: $e');
    }
  }

  Future<void> rateRecipe({
    required int recipeId,
    required int rating,
    String? notes,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      final body = {
        'rating': rating,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.rateRecipe(recipeId)),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          throw Exception('Unauthorized');
        } else if (response.statusCode == 404) {
          throw Exception('Recipe not found');
        } else {
          throw Exception('Failed to rate recipe: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error rating recipe: $e');
    }
  }

  Future<List<Recipe>> getQuickRecipes({
    int maxTime = 30,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'max_time': maxTime.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.recipes}/recommend/quick')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> recipesJson = data['recommendations'] as List;
        return recipesJson.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to get quick recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting quick recipes: $e');
    }
  }

  Future<List<Recipe>> getRecipesByCuisine({
    required String cuisineType,
    int limit = 10,
    Map<String, bool>? dietaryFilters,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'limit': limit.toString(),
      };

      if (dietaryFilters != null) {
        if (dietaryFilters['is_vegetarian'] == true) queryParams['is_vegetarian'] = 'true';
        if (dietaryFilters['is_vegan'] == true) queryParams['is_vegan'] = 'true';
        if (dietaryFilters['is_gluten_free'] == true) queryParams['is_gluten_free'] = 'true';
        if (dietaryFilters['is_dairy_free'] == true) queryParams['is_dairy_free'] = 'true';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.recipes}/recommend/cuisine/$cuisineType')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> recipesJson = data['recommendations'] as List;
        return recipesJson.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to get recipes by cuisine: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting recipes by cuisine: $e');
    }
  }

  Future<Recipe> createRecipe({
    required String name,
    String? description,
    String? cuisineType,
    String? mealType,
    String? difficultyLevel,
    int? prepTime,
    int? cookTime,
    int? totalTime,
    int? servings,
    List<String>? instructions,
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    double? fiber,
    bool isVegetarian = false,
    bool isVegan = false,
    bool isGlutenFree = false,
    bool isDairyFree = false,
    String? imageUrl,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = {
        'name': name,
        if (description != null) 'description': description,
        if (cuisineType != null) 'cuisine_type': cuisineType,
        if (mealType != null) 'meal_type': mealType,
        if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
        if (prepTime != null) 'prep_time': prepTime,
        if (cookTime != null) 'cook_time': cookTime,
        if (totalTime != null) 'total_time': totalTime,
        if (servings != null) 'servings': servings,
        if (instructions != null) 'instructions': instructions,
        if (calories != null) 'calories': calories,
        if (protein != null) 'protein': protein,
        if (carbohydrates != null) 'carbohydrates': carbohydrates,
        if (fat != null) 'fat': fat,
        if (fiber != null) 'fiber': fiber,
        'is_vegetarian': isVegetarian,
        'is_vegan': isVegan,
        'is_gluten_free': isGlutenFree,
        'is_dairy_free': isDairyFree,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.allRecipes),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Recipe.fromJson(data['recipe'] as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to create recipe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating recipe: $e');
    }
  }

  Future<Recipe> updateRecipe({
    required int recipeId,
    String? name,
    String? description,
    String? cuisineType,
    String? mealType,
    String? difficultyLevel,
    int? prepTime,
    int? cookTime,
    int? totalTime,
    int? servings,
    List<String>? instructions,
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    double? fiber,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    bool? isDairyFree,
    String? imageUrl,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (cuisineType != null) body['cuisine_type'] = cuisineType;
      if (mealType != null) body['meal_type'] = mealType;
      if (difficultyLevel != null) body['difficulty_level'] = difficultyLevel;
      if (prepTime != null) body['prep_time'] = prepTime;
      if (cookTime != null) body['cook_time'] = cookTime;
      if (totalTime != null) body['total_time'] = totalTime;
      if (servings != null) body['servings'] = servings;
      if (instructions != null) body['instructions'] = instructions;
      if (calories != null) body['calories'] = calories;
      if (protein != null) body['protein'] = protein;
      if (carbohydrates != null) body['carbohydrates'] = carbohydrates;
      if (fat != null) body['fat'] = fat;
      if (fiber != null) body['fiber'] = fiber;
      if (isVegetarian != null) body['is_vegetarian'] = isVegetarian;
      if (isVegan != null) body['is_vegan'] = isVegan;
      if (isGlutenFree != null) body['is_gluten_free'] = isGlutenFree;
      if (isDairyFree != null) body['is_dairy_free'] = isDairyFree;
      if (imageUrl != null) body['image_url'] = imageUrl;

      final response = await http.put(
        Uri.parse(ApiConfig.recipeById(recipeId)),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Recipe.fromJson(data['recipe'] as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 404) {
        throw Exception('Recipe not found');
      } else {
        throw Exception('Failed to update recipe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating recipe: $e');
    }
  }

  Future<void> deleteRecipe(int recipeId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse(ApiConfig.recipeById(recipeId)),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          throw Exception('Unauthorized');
        } else if (response.statusCode == 404) {
          throw Exception('Recipe not found');
        } else {
          throw Exception('Failed to delete recipe: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error deleting recipe: $e');
    }
  }

  /// Fetch image for a recipe using Google Custom Search
  Future<String?> fetchRecipeImage(int recipeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.recipeById(recipeId)}/image'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['image_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
