import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pantry_item.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

class PantryService {
  final AuthService _authService = AuthService();

  /// Get user's pantry (all available ingredients)
  Future<List<PantryItem>> getPantry() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.pantry),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> pantryJson = data['pantry'] as List;
        return pantryJson.map((json) => PantryItem.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load pantry: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching pantry: $e');
    }
  }

  /// Add ingredient to pantry
  Future<Map<String, dynamic>> addToPantry({
    required int ingredientId,
    double? quantity,
    String? unit,
    String? expiryDate,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = {
        'ingredient_id': ingredientId,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (expiryDate != null) 'expiry_date': expiryDate,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.pantry),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to add to pantry');
      }
    } catch (e) {
      throw Exception('Error adding to pantry: $e');
    }
  }

  /// Add multiple ingredients to pantry
  Future<Map<String, dynamic>> addMultipleToPantry(List<Map<String, dynamic>> ingredients) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = {'ingredients': ingredients};

      final response = await http.post(
        Uri.parse(ApiConfig.pantry),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to add to pantry');
      }
    } catch (e) {
      throw Exception('Error adding to pantry: $e');
    }
  }

  /// Update pantry item
  Future<PantryItem> updatePantryItem({
    required int pantryId,
    double? quantity,
    String? unit,
    String? expiryDate,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = {
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (expiryDate != null) 'expiry_date': expiryDate,
      };

      final response = await http.put(
        Uri.parse(ApiConfig.pantryItemById(pantryId)),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PantryItem.fromJson(data['pantry_item'] as Map<String, dynamic>);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to update pantry item');
      }
    } catch (e) {
      throw Exception('Error updating pantry item: $e');
    }
  }

  /// Remove ingredient from pantry by pantry ID
  Future<void> removeFromPantry(int pantryId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse(ApiConfig.pantryItemById(pantryId)),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to remove from pantry');
      }
    } catch (e) {
      throw Exception('Error removing from pantry: $e');
    }
  }

  /// Remove ingredient from pantry by ingredient ID
  Future<void> removeIngredientFromPantry(int ingredientId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse(ApiConfig.pantryByIngredientId(ingredientId)),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to remove from pantry');
      }
    } catch (e) {
      throw Exception('Error removing from pantry: $e');
    }
  }

  /// Clear all items from pantry
  Future<void> clearPantry() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse(ApiConfig.clearPantry),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to clear pantry');
      }
    } catch (e) {
      throw Exception('Error clearing pantry: $e');
    }
  }

  /// Remove multiple ingredients from pantry
  Future<void> bulkRemoveFromPantry(List<int> ingredientIds) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse(ApiConfig.bulkRemovePantry),
        headers: ApiConfig.authHeaders(token),
        body: json.encode({'ingredient_ids': ingredientIds}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to remove from pantry');
      }
    } catch (e) {
      throw Exception('Error removing from pantry: $e');
    }
  }

  /// Check if an ingredient is in the pantry
  Future<bool> isInPantry(int ingredientId) async {
    try {
      final pantry = await getPantry();
      return pantry.any((item) => item.ingredientId == ingredientId);
    } catch (e) {
      return false;
    }
  }

  /// Get pantry ingredient IDs (for quick lookup)
  Future<Set<int>> getPantryIngredientIds() async {
    try {
      final pantry = await getPantry();
      return pantry.map((item) => item.ingredientId).toSet();
    } catch (e) {
      return {};
    }
  }
}
