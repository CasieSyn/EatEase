import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // ========================================
  // NETWORK CONFIGURATION - Easy switching
  // ========================================

  // Uncomment the network you're currently using:

  // HOME INTERNET
  static const String _homeIp = '192.168.0.101:5000';  // Updated for new WiFi

  // WORK INTERNET (old)
  // ignore: unused_field
  static const String _workIp = '192.168.1.218:5000';

  // ANDROID EMULATOR (use this for Android emulator)
  // ignore: unused_field
  static const String _emulatorIp = '10.0.2.2:5000';

  // Current network - CHANGE THIS LINE WHEN SWITCHING NETWORKS
  static const String _currentNetwork = _homeIp;  // Using new WiFi IP

  // ========================================

  // Base URL for the backend API
  static String get baseUrl {
    if (kIsWeb) {
      // Web platform (Chrome, Firefox, etc.)
      return 'http://localhost:5000';
    } else if (Platform.isAndroid) {
      // For physical Android device, use the configured network IP
      return 'http://$_currentNetwork';
    } else {
      // iOS simulator and other platforms can use localhost
      return 'http://localhost:5000';
    }
  }

  // API endpoints
  static const String auth = '/api/auth';
  static const String recipes = '/api/recipes';
  static const String ingredients = '/api/ingredients';
  static const String users = '/api/users';

  // Auth endpoints
  static String get register => '$baseUrl$auth/register';
  static String get login => '$baseUrl$auth/login';
  static String get me => '$baseUrl$auth/me';
  static String get refresh => '$baseUrl$auth/refresh';

  // Recipe endpoints
  static String get allRecipes => '$baseUrl$recipes/';
  static String recipeById(int id) => '$baseUrl$recipes/$id';
  static String get searchRecipes => '$baseUrl$recipes/search';
  static String get recommendRecipes => '$baseUrl$recipes/recommend';
  static String rateRecipe(int id) => '$baseUrl$recipes/$id/rate';

  // Ingredient endpoints
  static String get allIngredients => '$baseUrl$ingredients/';
  static String ingredientById(int id) => '$baseUrl$ingredients/$id';
  static String get detectIngredients => '$baseUrl$ingredients/detect';

  // User endpoints
  static String get userProfile => '$baseUrl$users/profile';
  static String get userPreferences => '$baseUrl$users/preferences';
  static String get mealPlans => '$baseUrl$users/meal-plans';
  static String mealPlanById(int id) => '$baseUrl$users/meal-plans/$id';
  static String completeMealPlan(int id) => '$baseUrl$users/meal-plans/$id/complete';
  static String get shoppingLists => '$baseUrl$users/shopping-lists';
  static String shoppingListById(int id) => '$baseUrl$users/shopping-lists/$id';
  static String get generateShoppingList => '$baseUrl$users/shopping-lists/generate';

  // Pantry endpoints
  static String get pantry => '$baseUrl$users/pantry';
  static String pantryItemById(int id) => '$baseUrl$users/pantry/$id';
  static String pantryByIngredientId(int ingredientId) => '$baseUrl$users/pantry/ingredient/$ingredientId';
  static String get clearPantry => '$baseUrl$users/pantry/clear';
  static String get bulkRemovePantry => '$baseUrl$users/pantry/bulk';

  // Request headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
