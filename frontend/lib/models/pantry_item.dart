import 'ingredient.dart';

class PantryItem {
  final int id;
  final int userId;
  final int ingredientId;
  final Ingredient? ingredient;
  final double? quantity;
  final String? unit;
  final String? expiryDate;
  final String? addedAt;
  final String? updatedAt;

  PantryItem({
    required this.id,
    required this.userId,
    required this.ingredientId,
    this.ingredient,
    this.quantity,
    this.unit,
    this.expiryDate,
    this.addedAt,
    this.updatedAt,
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      ingredientId: json['ingredient_id'] as int,
      ingredient: json['ingredient'] != null
          ? Ingredient.fromJson(json['ingredient'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : null,
      unit: json['unit'] as String?,
      expiryDate: json['expiry_date'] as String?,
      addedAt: json['added_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ingredient_id': ingredientId,
      'ingredient': ingredient?.toJson(),
      'quantity': quantity,
      'unit': unit,
      'expiry_date': expiryDate,
      'added_at': addedAt,
      'updated_at': updatedAt,
    };
  }

  // Helper to get ingredient name
  String get name => ingredient?.name ?? 'Unknown';

  // Helper to get ingredient category
  String? get category => ingredient?.category;
}
