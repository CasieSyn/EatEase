import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  Recipe? _recipe;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recipe = await _recipeService.getRecipeById(widget.recipeId);
      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _rateRecipe() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    try {
      await _recipeService.rateRecipe(
        recipeId: widget.recipeId,
        rating: _selectedRating,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe rated successfully!')),
        );
        // Reload recipe to show updated rating
        _loadRecipe();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rating recipe: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRecipe,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _recipe == null
                  ? const Center(child: Text('Recipe not found'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recipe Image
                          if (_recipe!.imageUrl != null && _recipe!.imageUrl!.isNotEmpty)
                            Image.network(
                              _recipe!.imageUrl!,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 300,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.restaurant, size: 100, color: Colors.grey),
                                );
                              },
                            )
                          else
                            Container(
                              height: 300,
                              color: Colors.grey[300],
                              child: const Icon(Icons.restaurant, size: 100, color: Colors.grey),
                            ),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Recipe Name
                                Text(
                                  _recipe!.name,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),

                                // Tags Row
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (_recipe!.cuisineType != null)
                                      Chip(
                                        label: Text(_recipe!.cuisineType!),
                                        backgroundColor: Colors.green[100],
                                      ),
                                    if (_recipe!.mealType != null)
                                      Chip(
                                        label: Text(_recipe!.mealType!),
                                        backgroundColor: Colors.blue[100],
                                      ),
                                    if (_recipe!.difficultyLevel != null)
                                      Chip(
                                        label: Text(_recipe!.difficultyLevel!),
                                        backgroundColor: Colors.orange[100],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Stats
                                Row(
                                  children: [
                                    if (_recipe!.time?.totalTime != null) ...[
                                      const Icon(Icons.access_time, size: 20),
                                      const SizedBox(width: 4),
                                      Text('${_recipe!.time!.totalTime} min'),
                                      const SizedBox(width: 16),
                                    ],
                                    const Icon(Icons.star, size: 20, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text('${_recipe!.rating?.toStringAsFixed(1) ?? '0.0'} (${_recipe!.ratingCount ?? 0})'),
                                    const SizedBox(width: 16),
                                    if (_recipe!.servings != null) ...[
                                      const Icon(Icons.people, size: 20),
                                      const SizedBox(width: 4),
                                      Text('${_recipe!.servings} servings'),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Description
                                if (_recipe!.description != null && _recipe!.description!.isNotEmpty) ...[
                                  Text(
                                    'Description',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_recipe!.description!),
                                  const SizedBox(height: 24),
                                ],

                                // Ingredients
                                if (_recipe!.ingredients != null && _recipe!.ingredients!.isNotEmpty) ...[
                                  Text(
                                    'Ingredients',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...(_recipe!.ingredients!.map((ingredient) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, size: 20, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${ingredient.quantity != null ? '${ingredient.quantity} ' : ''}${ingredient.unit ?? ''} ${ingredient.ingredientName ?? ''} ${ingredient.preparation ?? ''}'.trim(),
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                          if (ingredient.isOptional == true)
                                            Chip(
                                              label: const Text('Optional', style: TextStyle(fontSize: 10)),
                                              backgroundColor: Colors.grey[300],
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity.compact,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList()),
                                  const SizedBox(height: 24),
                                ],

                                // Instructions
                                if (_recipe!.instructions != null && _recipe!.instructions!.isNotEmpty) ...[
                                  Text(
                                    'Instructions',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...(_recipe!.instructions!.asMap().entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${entry.key + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              entry.value,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList()),
                                  const SizedBox(height: 24),
                                ],

                                // Nutrition
                                if (_recipe!.nutrition != null) ...[
                                  Text(
                                    'Nutrition (per serving)',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          if (_recipe!.nutrition!.calories != null)
                                            _buildNutritionRow('Calories', '${_recipe!.nutrition!.calories!.toStringAsFixed(0)} kcal'),
                                          if (_recipe!.nutrition!.protein != null)
                                            _buildNutritionRow('Protein', '${_recipe!.nutrition!.protein!.toStringAsFixed(1)}g'),
                                          if (_recipe!.nutrition!.carbohydrates != null)
                                            _buildNutritionRow('Carbs', '${_recipe!.nutrition!.carbohydrates!.toStringAsFixed(1)}g'),
                                          if (_recipe!.nutrition!.fat != null)
                                            _buildNutritionRow('Fat', '${_recipe!.nutrition!.fat!.toStringAsFixed(1)}g'),
                                          if (_recipe!.nutrition!.fiber != null)
                                            _buildNutritionRow('Fiber', '${_recipe!.nutrition!.fiber!.toStringAsFixed(1)}g'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Rating Section
                                Text(
                                  'Rate this Recipe',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (index) {
                                    return IconButton(
                                      icon: Icon(
                                        index < _selectedRating ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 32,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedRating = index + 1;
                                        });
                                      },
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _rateRecipe,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                  child: const Text('Submit Rating'),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
