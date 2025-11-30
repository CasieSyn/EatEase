import 'recipe.dart';

class MealPlan {
  final int id;
  final int userId;
  final int recipeId;
  final String plannedDate;
  final String mealType;
  final bool isCompleted;
  final String? completedAt;
  final int? userRating;
  final String? userNotes;
  final String? createdAt;
  final String? updatedAt;
  final Recipe? recipe; // Included when fetched with recipe details

  MealPlan({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.plannedDate,
    required this.mealType,
    required this.isCompleted,
    this.completedAt,
    this.userRating,
    this.userNotes,
    this.createdAt,
    this.updatedAt,
    this.recipe,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      recipeId: json['recipe_id'] as int? ?? 0,
      plannedDate: json['planned_date'] as String? ?? '',
      mealType: json['meal_type'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] as String?,
      userRating: json['user_rating'] as int?,
      userNotes: json['user_notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      recipe: json['recipe'] != null ? Recipe.fromJson(json['recipe'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recipe_id': recipeId,
      'planned_date': plannedDate,
      'meal_type': mealType,
      'is_completed': isCompleted,
      'completed_at': completedAt,
      'user_rating': userRating,
      'user_notes': userNotes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      if (recipe != null) 'recipe': recipe!.toJson(),
    };
  }
}
