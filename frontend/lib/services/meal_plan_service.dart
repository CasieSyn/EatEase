import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal_plan.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

class MealPlanService {
  final AuthService _authService = AuthService();

  /// Get all meal plans for the authenticated user
  Future<List<MealPlan>> getMealPlans({
    String? startDate,
    String? endDate,
    bool? isCompleted,
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

      final queryParams = <String, String>{};

      if (startDate != null) {
        queryParams['start_date'] = startDate;
      }

      if (endDate != null) {
        queryParams['end_date'] = endDate;
      }

      if (isCompleted != null) {
        queryParams['is_completed'] = isCompleted.toString();
      }

      final uri = Uri.parse(ApiConfig.mealPlans).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> mealPlansJson = data['meal_plans'] as List;
        return mealPlansJson.map((json) => MealPlan.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load meal plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching meal plans: $e');
    }
  }

  /// Create a new meal plan
  Future<MealPlan> createMealPlan({
    required int recipeId,
    required String plannedDate,
    required String mealType,
    int? servings,
    String? notes,
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
        'recipe_id': recipeId,
        'planned_date': plannedDate,
        'meal_type': mealType,
        if (servings != null) 'servings': servings,
        if (notes != null) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.mealPlans),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return MealPlan.fromJson(data['meal_plan'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create meal plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating meal plan: $e');
    }
  }

  /// Update a meal plan
  Future<MealPlan> updateMealPlan({
    required int id,
    String? plannedDate,
    String? mealType,
    int? servings,
    String? notes,
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
      if (plannedDate != null) body['planned_date'] = plannedDate;
      if (mealType != null) body['meal_type'] = mealType;
      if (servings != null) body['servings'] = servings;
      if (notes != null) body['notes'] = notes;

      final response = await http.put(
        Uri.parse(ApiConfig.mealPlanById(id)),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MealPlan.fromJson(data['meal_plan'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update meal plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating meal plan: $e');
    }
  }

  /// Mark a meal plan as completed
  Future<MealPlan> completeMealPlan(int id) async {
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

      final response = await http.post(
        Uri.parse(ApiConfig.completeMealPlan(id)),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MealPlan.fromJson(data['meal_plan'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to complete meal plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error completing meal plan: $e');
    }
  }

  /// Delete a meal plan
  Future<void> deleteMealPlan(int id) async {
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
        Uri.parse(ApiConfig.mealPlanById(id)),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete meal plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting meal plan: $e');
    }
  }
}
