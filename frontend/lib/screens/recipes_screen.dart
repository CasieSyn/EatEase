import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final RecipeService _recipeService = RecipeService();
  List<Recipe> _recipes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCuisine;
  String? _selectedMealType;

  final List<String> _cuisineTypes = [
    'All',
    'Filipino',
    'Italian',
    'Chinese',
    'Japanese',
    'Mexican',
    'Thai',
    'Indian',
  ];

  final List<String> _mealTypes = [
    'All',
    'breakfast',
    'lunch',
    'dinner',
    'snack',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recipes = await _recipeService.getRecipes(
        cuisineType: _selectedCuisine != null && _selectedCuisine != 'All' ? _selectedCuisine : null,
        mealType: _selectedMealType != null && _selectedMealType != 'All' ? _selectedMealType : null,
      );

      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cuisine Type Filter
              const Text('Cuisine Type:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cuisineTypes.length,
                  itemBuilder: (context, index) {
                    final cuisine = _cuisineTypes[index];
                    final isSelected = _selectedCuisine == cuisine || (_selectedCuisine == null && cuisine == 'All');

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cuisine),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCuisine = cuisine == 'All' ? null : cuisine;
                          });
                          _loadRecipes();
                        },
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Meal Type Filter
              const Text('Meal Type:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mealTypes.length,
                  itemBuilder: (context, index) {
                    final mealType = _mealTypes[index];
                    final isSelected = _selectedMealType == mealType || (_selectedMealType == null && mealType == 'All');

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(mealType[0].toUpperCase() + mealType.substring(1)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedMealType = mealType == 'All' ? null : mealType;
                          });
                          _loadRecipes();
                        },
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Recipe List
        Expanded(
          child: _isLoading
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
                            onPressed: _loadRecipes,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _recipes.isEmpty
                      ? const Center(
                          child: Text('No recipes found'),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRecipes,
                          child: ListView.builder(
                            itemCount: _recipes.length,
                            itemBuilder: (context, index) {
                              final recipe = _recipes[index];
                              return RecipeCard(
                                recipe: recipe,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
              Image.network(
                recipe.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                  );
                },
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.restaurant, size: 64, color: Colors.grey),
              ),

            // Recipe Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    recipe.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (recipe.description != null && recipe.description!.isNotEmpty)
                    Text(
                      recipe.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  const SizedBox(height: 12),

                  // Tags and Info Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Cuisine Type
                      if (recipe.cuisineType != null)
                        Chip(
                          label: Text(recipe.cuisineType!),
                          backgroundColor: Colors.green[100],
                          labelStyle: const TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),

                      // Meal Type
                      if (recipe.mealType != null)
                        Chip(
                          label: Text(recipe.mealType!),
                          backgroundColor: Colors.blue[100],
                          labelStyle: const TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),

                      // Difficulty
                      if (recipe.difficultyLevel != null)
                        Chip(
                          label: Text(recipe.difficultyLevel!),
                          backgroundColor: Colors.orange[100],
                          labelStyle: const TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats Row
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Time
                      if (recipe.time?.totalTime != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.time!.totalTime} min',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),

                      // Rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.rating?.toStringAsFixed(1) ?? '0.0'} (${recipe.ratingCount ?? 0})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),

                      // Servings
                      if (recipe.servings != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.servings} servings',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Dietary Tags
                  if (recipe.dietary != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (recipe.dietary!.isVegetarian)
                          const Chip(
                            label: Text('Vegetarian', style: TextStyle(fontSize: 10)),
                            backgroundColor: Color(0xFF4CAF50),
                            labelStyle: TextStyle(color: Colors.white),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (recipe.dietary!.isVegan)
                          const Chip(
                            label: Text('Vegan', style: TextStyle(fontSize: 10)),
                            backgroundColor: Color(0xFF8BC34A),
                            labelStyle: TextStyle(color: Colors.white),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (recipe.dietary!.isGlutenFree)
                          const Chip(
                            label: Text('Gluten-Free', style: TextStyle(fontSize: 10)),
                            backgroundColor: Color(0xFFFF9800),
                            labelStyle: TextStyle(color: Colors.white),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (recipe.dietary!.isDairyFree)
                          const Chip(
                            label: Text('Dairy-Free', style: TextStyle(fontSize: 10)),
                            backgroundColor: Color(0xFF03A9F4),
                            labelStyle: TextStyle(color: Colors.white),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
