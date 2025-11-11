import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shopping_list.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

class ShoppingListService {
  final AuthService _authService = AuthService();

  /// Get all shopping lists
  Future<List<ShoppingList>> getShoppingLists({bool activeOnly = true}) async {
    try {
      // Validate token and refresh if expired
      final isValid = await _authService.isLoggedIn();
      if (!isValid) {
        throw Exception('Authentication failed. Please login again.');
      }

      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.shoppingLists}?active_only=$activeOnly'),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> listData = data['shopping_lists'];
        return listData.map((json) => ShoppingList.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load shopping lists: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shopping lists: $e');
    }
  }

  /// Generate shopping list from meal plans
  Future<ShoppingList> generateFromMealPlans({
    required String startDate,
    required String endDate,
    String? listName,
  }) async {
    try {
      // Validate token and refresh if expired
      final isValid = await _authService.isLoggedIn();
      if (!isValid) {
        throw Exception('Authentication failed. Please login again.');
      }

      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = {
        'start_date': startDate,
        'end_date': endDate,
        if (listName != null) 'name': listName,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/shopping-lists/generate'),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ShoppingList.fromJson(data['shopping_list'] as Map<String, dynamic>);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to generate shopping list');
      }
    } catch (e) {
      throw Exception('Error generating shopping list: $e');
    }
  }

  /// Update shopping list (mark items as purchased, update name, etc.)
  Future<ShoppingList> updateShoppingList({
    required int listId,
    List<ShoppingListItem>? items,
    bool? isActive,
    String? name,
  }) async {
    try {
      // Validate token and refresh if expired
      final isValid = await _authService.isLoggedIn();
      if (!isValid) {
        throw Exception('Authentication failed. Please login again.');
      }

      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = <String, dynamic>{};
      if (items != null) {
        body['items'] = items.map((item) => item.toJson()).toList();
      }
      if (isActive != null) body['is_active'] = isActive;
      if (name != null) body['name'] = name;

      final response = await http.put(
        Uri.parse(ApiConfig.shoppingListById(listId)),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ShoppingList.fromJson(data['shopping_list'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update shopping list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating shopping list: $e');
    }
  }

  /// Delete shopping list
  Future<void> deleteShoppingList(int listId) async {
    try {
      // Validate token and refresh if expired
      final isValid = await _authService.isLoggedIn();
      if (!isValid) {
        throw Exception('Authentication failed. Please login again.');
      }

      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse(ApiConfig.shoppingListById(listId)),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete shopping list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting shopping list: $e');
    }
  }
}
