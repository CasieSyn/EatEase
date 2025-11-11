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

  /// Detect ingredients from image (requires authentication)
  Future<List<Map<String, dynamic>>> detectIngredients(String imagePath) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.detectIngredients),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add image file
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['ingredients'] as List);
      } else {
        throw Exception('Failed to detect ingredients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error detecting ingredients: $e');
    }
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
}
