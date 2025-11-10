class Ingredient {
  final int id;
  final String name;
  final String? category;
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? fiber;
  final String? commonUnit;
  final String? imageUrl;
  final String? createdAt;

  Ingredient({
    required this.id,
    required this.name,
    this.category,
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    this.fiber,
    this.commonUnit,
    this.imageUrl,
    this.createdAt,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String?,
      calories: json['calories'] != null ? (json['calories'] as num).toDouble() : null,
      protein: json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      carbohydrates: json['carbohydrates'] != null ? (json['carbohydrates'] as num).toDouble() : null,
      fat: json['fat'] != null ? (json['fat'] as num).toDouble() : null,
      fiber: json['fiber'] != null ? (json['fiber'] as num).toDouble() : null,
      commonUnit: json['common_unit'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'common_unit': commonUnit,
      'image_url': imageUrl,
      'created_at': createdAt,
    };
  }
}
