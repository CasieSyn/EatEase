class ShoppingList {
  final int id;
  final int userId;
  final String? name;
  final List<ShoppingListItem> items;
  final bool isActive;
  final bool generatedFromMealPlan;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingList({
    required this.id,
    required this.userId,
    this.name,
    required this.items,
    required this.isActive,
    required this.generatedFromMealPlan,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      items: (json['items'] as List<dynamic>)
          .map((item) => ShoppingListItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      isActive: json['is_active'],
      generatedFromMealPlan: json['generated_from_meal_plan'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'is_active': isActive,
      'generated_from_meal_plan': generatedFromMealPlan,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ShoppingListItem {
  final int ingredientId;
  final String ingredientName;
  final double quantity;
  final String unit;
  final String? category;
  bool isPurchased;

  ShoppingListItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    this.category,
    this.isPurchased = false,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      ingredientId: json['ingredient_id'],
      ingredientName: json['ingredient_name'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      category: json['category'],
      isPurchased: json['is_purchased'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'ingredient_name': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'is_purchased': isPurchased,
    };
  }
}
