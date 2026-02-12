import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ingredient.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

class IngredientService {
  final AuthService _authService = AuthService();

  /// Get all ingredients with optional filters
  Future<List<Ingredient>> getIngredients({
    String? category,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category.toLowerCase();
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(ApiConfig.allIngredients).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ingredientsJson = data['ingredients'] as List;
        return ingredientsJson.map((json) => Ingredient.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load ingredients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching ingredients: $e');
    }
  }

  /// Get ingredient by ID
  Future<Ingredient> getIngredientById(int id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.ingredientById(id)),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Ingredient.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load ingredient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching ingredient: $e');
    }
  }

  /// Search ingredients by name
  Future<List<Ingredient>> searchIngredients(String query) async {
    return getIngredients(search: query);
  }

  /// Get ingredients by category
  Future<List<Ingredient>> getIngredientsByCategory(String category) async {
    return getIngredients(category: category);
  }

  /// Get available ingredient categories
  Future<List<String>> getCategories() async {
    // These are the actual categories from the backend database (lowercase)
    // Display names are capitalized in the UI
    return [
      'protein',
      'vegetable',
      'grain',
      'condiment',
      'spice',
      'dairy',
    ];
  }

  /// Create a new custom ingredient (requires authentication)
  Future<Ingredient> createIngredient({
    required String name,
    String? category,
    String? commonUnit,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = {
        'name': name,
        if (category != null) 'category': category,
        if (commonUnit != null) 'common_unit': commonUnit,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.allIngredients),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Ingredient.fromJson(data['ingredient'] as Map<String, dynamic>);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to create ingredient');
      }
    } catch (e) {
      if (e.toString().contains('Exception: ')) {
        rethrow;
      }
      throw Exception('Error creating ingredient: $e');
    }
  }
}
