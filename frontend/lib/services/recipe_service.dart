import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

class RecipeService {
  final AuthService _authService = AuthService();

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
        return recipesJson.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
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
        final List<dynamic> recipesJson = data['recommendations'] as List;
        return recipesJson.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
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
}
