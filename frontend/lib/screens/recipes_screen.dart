import 'package:flutter/material.dart';
import '../main.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final RecipeService _recipeService = RecipeService();
  List<Recipe> _recipes = [];
  List<Recipe> _recommendations = [];
  bool _isLoading = false;
  bool _isLoadingRecommendations = false;
  String? _errorMessage;
  String? _selectedMealType;
  final Set<int> _fetchingImages = {}; // Track which recipes are fetching images

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
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      final recommendations = await _recipeService.getRecommendations(limit: 5);
      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
      // Fetch images for recommendations without images
      _fetchMissingImages(recommendations, isRecommendation: true);
    } catch (e) {
      // Silently fail - recommendations are optional
      setState(() {
        _isLoadingRecommendations = false;
      });
    }
  }

  Future<void> _fetchMissingImages(List<Recipe> recipes, {bool isRecommendation = false}) async {
    for (final recipe in recipes) {
      if ((recipe.imageUrl == null || recipe.imageUrl!.isEmpty) && !_fetchingImages.contains(recipe.id)) {
        _fetchingImages.add(recipe.id);
        _fetchImageForRecipe(recipe.id, isRecommendation: isRecommendation);
      }
    }
  }

  Future<void> _fetchImageForRecipe(int recipeId, {bool isRecommendation = false}) async {
    try {
      final imageUrl = await _recipeService.fetchRecipeImage(recipeId);
      if (imageUrl != null && mounted) {
        setState(() {
          if (isRecommendation) {
            _recommendations = _recommendations.map((r) {
              if (r.id == recipeId) {
                return r.copyWith(imageUrl: imageUrl);
              }
              return r;
            }).toList();
          } else {
            _recipes = _recipes.map((r) {
              if (r.id == recipeId) {
                return r.copyWith(imageUrl: imageUrl);
              }
              return r;
            }).toList();
          }
        });
      }
    } catch (e) {
      // Silently fail
    } finally {
      _fetchingImages.remove(recipeId);
    }
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recipes = await _recipeService.getRecipes(
        mealType: _selectedMealType != null && _selectedMealType != 'All' ? _selectedMealType : null,
      );

      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
      // Fetch images for recipes without images
      _fetchMissingImages(recipes, isRecommendation: false);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createRecipe() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const RecipeFormScreen(),
      ),
    );

    if (result == true) {
      _loadRecipes();
    }
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended for You',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Based on your pantry ingredients',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: _isLoadingRecommendations
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final recipe = _recommendations[index];
                    return _buildRecommendationCard(recipe);
                  },
                ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 18, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'All Recipes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPlaceholderImage(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: height * 0.35,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            if (height > 100) ...[
              const SizedBox(height: 8),
              Text(
                'Filipino Cuisine',
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                      ? Image.network(
                          recipe.imageUrl!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(100);
                          },
                        )
                      : _buildPlaceholderImage(100),
                  // Match percentage badge
                  if (recipe.matchPercentage != null && recipe.matchPercentage! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: recipe.matchPercentage! >= 70
                              ? AppColors.success
                              : recipe.matchPercentage! >= 40
                                  ? AppColors.accent
                                  : AppColors.warning,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.matchPercentage!.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'AI Pick',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Match info
                  if (recipe.matchingIngredients != null && recipe.totalIngredients != null)
                    Text(
                      '${recipe.matchingIngredients}/${recipe.totalIngredients} ingredients',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (recipe.time?.totalTime != null)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${recipe.time!.totalTime}m',
                                  style: TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
                          const SizedBox(width: 2),
                          Text(
                            recipe.rating?.toStringAsFixed(1) ?? '0.0',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Type Filter
              Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text('Meal Type', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                ],
              ),
              const SizedBox(height: 12),
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
                        selectedColor: AppColors.secondary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        backgroundColor: AppColors.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide.none,
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text('Loading recipes...', style: TextStyle(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Oops! Something went wrong',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadRecipes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _recipes.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.restaurant_menu, size: 48, color: AppColors.onSurfaceVariant),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No recipes found',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters',
                                  style: TextStyle(color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _loadRecipes();
                            await _loadRecommendations();
                          },
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 100),
                            itemCount: _recipes.length + (_recommendations.isNotEmpty ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Show recommendations section first
                              if (_recommendations.isNotEmpty && index == 0) {
                                return _buildRecommendationsSection();
                              }

                              final recipeIndex = _recommendations.isNotEmpty ? index - 1 : index;
                              final recipe = _recipes[recipeIndex];
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
      ),
      // Create Recipe FAB
      Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton(
          heroTag: 'recipes_fab',
          onPressed: _createRecipe,
          backgroundColor: AppColors.secondary,
          child: const Icon(Icons.add_rounded),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image with gradient overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                        ? Image.network(
                            recipe.imageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildCardPlaceholder();
                            },
                          )
                        : _buildCardPlaceholder(),
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            recipe.rating?.toStringAsFixed(1) ?? '0.0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Time badge
                  if (recipe.time?.totalTime != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 14, color: AppColors.onSurface),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.time!.totalTime} min',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    if (recipe.description != null && recipe.description!.isNotEmpty)
                      Text(
                        recipe.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Tags Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Cuisine Type
                        if (recipe.cuisineType != null)
                          _buildTag(recipe.cuisineType!, AppColors.primary),

                        // Meal Type
                        if (recipe.mealType != null)
                          _buildTag(recipe.mealType!, AppColors.secondary),

                        // Difficulty
                        if (recipe.difficultyLevel != null)
                          _buildTag(recipe.difficultyLevel!, AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Stats Row
                    Row(
                      children: [
                        // Servings
                        if (recipe.servings != null) ...[
                          Icon(Icons.people_outline, size: 18, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.servings}',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        // Reviews count
                        Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.ratingCount ?? 0} reviews',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Arrow indicator
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCardPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Filipino Cuisine',
              style: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
