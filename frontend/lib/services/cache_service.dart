import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _recipesKey = 'cached_recipes';
  static const String _ingredientsKey = 'cached_ingredients';
  static const String _mealPlansKey = 'cached_meal_plans';
  static const String _shoppingListsKey = 'cached_shopping_lists';

  // Cache duration - 24 hours
  static const Duration cacheDuration = Duration(hours: 24);

  // Generic cache methods
  Future<void> cacheData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(data);
    await prefs.setString(key, jsonString);
    await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<dynamic> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    // Check if cache is expired
    final timestamp = prefs.getInt('${key}_timestamp');
    if (timestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > cacheDuration) {
        // Cache expired
        return null;
      }
    }

    return json.decode(jsonString);
  }

  Future<bool> isCacheValid(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('${key}_timestamp');
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) <= cacheDuration;
  }

  Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await prefs.remove('${key}_timestamp');
  }

  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recipesKey);
    await prefs.remove(_ingredientsKey);
    await prefs.remove(_mealPlansKey);
    await prefs.remove(_shoppingListsKey);
    await prefs.remove('${_recipesKey}_timestamp');
    await prefs.remove('${_ingredientsKey}_timestamp');
    await prefs.remove('${_mealPlansKey}_timestamp');
    await prefs.remove('${_shoppingListsKey}_timestamp');
  }

  // Recipes caching
  Future<void> cacheRecipes(List<Map<String, dynamic>> recipes) async {
    await cacheData(_recipesKey, recipes);
  }

  Future<List<Map<String, dynamic>>?> getCachedRecipes() async {
    final data = await getCachedData(_recipesKey);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<void> cacheRecipeById(int id, Map<String, dynamic> recipe) async {
    await cacheData('recipe_$id', recipe);
  }

  Future<Map<String, dynamic>?> getCachedRecipeById(int id) async {
    final data = await getCachedData('recipe_$id');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // Ingredients caching
  Future<void> cacheIngredients(List<Map<String, dynamic>> ingredients) async {
    await cacheData(_ingredientsKey, ingredients);
  }

  Future<List<Map<String, dynamic>>?> getCachedIngredients() async {
    final data = await getCachedData(_ingredientsKey);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  // Meal plans caching
  Future<void> cacheMealPlans(List<Map<String, dynamic>> mealPlans) async {
    await cacheData(_mealPlansKey, mealPlans);
  }

  Future<List<Map<String, dynamic>>?> getCachedMealPlans() async {
    final data = await getCachedData(_mealPlansKey);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  // Shopping lists caching
  Future<void> cacheShoppingLists(List<Map<String, dynamic>> lists) async {
    await cacheData(_shoppingListsKey, lists);
  }

  Future<List<Map<String, dynamic>>?> getCachedShoppingLists() async {
    final data = await getCachedData(_shoppingListsKey);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  // Favorite recipes
  static const String _favoriteRecipesKey = 'favorite_recipes';

  Future<void> addFavoriteRecipe(int recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoriteRecipesKey) ?? [];
    if (!favorites.contains(recipeId.toString())) {
      favorites.add(recipeId.toString());
      await prefs.setStringList(_favoriteRecipesKey, favorites);
    }
  }

  Future<void> removeFavoriteRecipe(int recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoriteRecipesKey) ?? [];
    favorites.remove(recipeId.toString());
    await prefs.setStringList(_favoriteRecipesKey, favorites);
  }

  Future<List<int>> getFavoriteRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoriteRecipesKey) ?? [];
    return favorites.map((e) => int.parse(e)).toList();
  }

  Future<bool> isFavoriteRecipe(int recipeId) async {
    final favorites = await getFavoriteRecipes();
    return favorites.contains(recipeId);
  }

  // Cache info
  Future<Map<String, dynamic>> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();

    DateTime? getTimestamp(String key) {
      final ts = prefs.getInt('${key}_timestamp');
      return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
    }

    return {
      'recipes_cached': prefs.containsKey(_recipesKey),
      'recipes_timestamp': getTimestamp(_recipesKey),
      'ingredients_cached': prefs.containsKey(_ingredientsKey),
      'ingredients_timestamp': getTimestamp(_ingredientsKey),
      'meal_plans_cached': prefs.containsKey(_mealPlansKey),
      'meal_plans_timestamp': getTimestamp(_mealPlansKey),
      'shopping_lists_cached': prefs.containsKey(_shoppingListsKey),
      'shopping_lists_timestamp': getTimestamp(_shoppingListsKey),
    };
  }
}
