import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/meal_plan_service.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  final MealPlanService _mealPlanService = MealPlanService();
  final CacheService _cacheService = CacheService();
  final NotificationService _notificationService = NotificationService();
  Recipe? _recipe;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedRating = 0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await _cacheService.isFavoriteRecipe(widget.recipeId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _cacheService.removeFavoriteRecipe(widget.recipeId);
    } else {
      await _cacheService.addFavoriteRecipe(widget.recipeId);
    }

    if (mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _shareRecipe() async {
    if (_recipe == null) return;

    final StringBuffer shareText = StringBuffer();
    shareText.writeln('Check out this recipe: ${_recipe!.name}');
    shareText.writeln('');

    if (_recipe!.description != null) {
      shareText.writeln(_recipe!.description);
      shareText.writeln('');
    }

    if (_recipe!.time?.totalTime != null) {
      shareText.writeln('Time: ${_recipe!.time!.totalTime} min');
    }
    if (_recipe!.servings != null) {
      shareText.writeln('Servings: ${_recipe!.servings}');
    }
    shareText.writeln('');

    if (_recipe!.ingredients != null && _recipe!.ingredients!.isNotEmpty) {
      shareText.writeln('Ingredients:');
      for (final ing in _recipe!.ingredients!) {
        shareText.writeln('- ${ing.quantity ?? ''} ${ing.unit ?? ''} ${ing.ingredientName ?? ''}'.trim());
      }
      shareText.writeln('');
    }

    if (_recipe!.instructions != null && _recipe!.instructions!.isNotEmpty) {
      shareText.writeln('Instructions:');
      for (int i = 0; i < _recipe!.instructions!.length; i++) {
        shareText.writeln('${i + 1}. ${_recipe!.instructions![i]}');
      }
    }

    shareText.writeln('');
    shareText.writeln('Shared from EatEase - AI-Powered Filipino Meal Planning');

    await Share.share(shareText.toString(), subject: 'Recipe: ${_recipe!.name}');
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

      // If recipe has no image, try to fetch one
      if (recipe.imageUrl == null || recipe.imageUrl!.isEmpty) {
        _fetchRecipeImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRecipeImage() async {
    try {
      final imageUrl = await _recipeService.fetchRecipeImage(widget.recipeId);
      if (imageUrl != null && mounted) {
        setState(() {
          _recipe = _recipe!.copyWith(imageUrl: imageUrl);
        });
      }
    } catch (e) {
      // Silently fail - image fetching is optional
    }
  }

  Future<void> _rateRecipe() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final submittedRating = _selectedRating;

    try {
      await _recipeService.rateRecipe(
        recipeId: widget.recipeId,
        rating: _selectedRating,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('You rated this recipe $submittedRating stars!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Reload recipe to get updated rating stats
        await _loadRecipe();

        // Keep the user's submitted rating visible
        setState(() {
          _selectedRating = submittedRating;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rating recipe: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _showAddToMealPlanDialog() async {
    DateTime selectedDate = DateTime.now();
    String selectedMealType = 'lunch';
    int servings = _recipe?.servings ?? 4;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Add to Meal Plan')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recipe?.name ?? 'Recipe',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Date Picker
                Text(
                  'Date',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setDialogState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Meal Type
                Text(
                  'Meal Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['breakfast', 'lunch', 'dinner', 'snack'].map((type) {
                    final isSelected = selectedMealType == type;
                    return FilterChip(
                      label: Text(type[0].toUpperCase() + type.substring(1)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          selectedMealType = type;
                        });
                      },
                      selectedColor: AppColors.secondary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      backgroundColor: AppColors.surfaceVariant,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Servings
                Text(
                  'Servings',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (servings > 1) {
                            setDialogState(() {
                              servings--;
                            });
                          }
                        },
                        icon: const Icon(Icons.remove_rounded),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$servings',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            servings++;
                          });
                        },
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final mealPlan = await _mealPlanService.createMealPlan(
                    recipeId: widget.recipeId,
                    plannedDate: DateFormat('yyyy-MM-dd').format(selectedDate),
                    mealType: selectedMealType,
                    servings: servings,
                  );

                  // Schedule notification for this meal plan
                  await _notificationService.scheduleMealPlanNotifications([
                    {
                      'id': mealPlan.id,
                      'planned_date': mealPlan.plannedDate,
                      'meal_type': mealPlan.mealType,
                      'recipe_name': _recipe?.name ?? 'Your meal',
                    }
                  ]);

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add to Plan'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recipe added to meal plan!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _editRecipe() async {
    if (_recipe == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeFormScreen(recipe: _recipe),
      ),
    );

    if (result == true) {
      _loadRecipe();
    }
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Delete Recipe'),
          ],
        ),
        content: Text('Are you sure you want to delete "${_recipe?.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _recipeService.deleteRecipe(widget.recipeId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Recipe deleted successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting recipe: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                          child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
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
                          style: const TextStyle(color: AppColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadRecipe,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _recipe == null
                  ? const Center(child: Text('Recipe not found'))
                  : CustomScrollView(
                      slivers: [
                        // App Bar with Image
                        SliverAppBar(
                          expandedHeight: 300,
                          pinned: true,
                          stretch: true,
                          backgroundColor: AppColors.surface,
                          leading: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          actions: [
                            // Favorite button
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: _isFavorite ? AppColors.error : Colors.white,
                                ),
                                onPressed: _toggleFavorite,
                              ),
                            ),
                            // Share button
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.share_rounded, color: Colors.white),
                                onPressed: _shareRecipe,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editRecipe();
                                      break;
                                    case 'delete':
                                      _deleteRecipe();
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_rounded, color: AppColors.primary),
                                        SizedBox(width: 12),
                                        Text('Edit Recipe'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                        SizedBox(width: 12),
                                        Text('Delete Recipe', style: TextStyle(color: AppColors.error)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            background: _recipe!.imageUrl != null && _recipe!.imageUrl!.isNotEmpty
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        _recipe!.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: AppColors.surfaceVariant,
                                            child: const Icon(Icons.restaurant_rounded, size: 100, color: AppColors.onSurfaceVariant),
                                          );
                                        },
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.7),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(Icons.restaurant_rounded, size: 100, color: AppColors.onSurfaceVariant),
                                  ),
                          ),
                        ),

                        // Content
                        SliverToBoxAdapter(
                          child: Padding(
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
                                      _buildTag(_recipe!.cuisineType!, AppColors.secondary),
                                    if (_recipe!.mealType != null)
                                      _buildTag(_recipe!.mealType!, AppColors.primary),
                                    if (_recipe!.difficultyLevel != null)
                                      _buildTag(_recipe!.difficultyLevel!, AppColors.accent),
                                    if (_recipe!.dietary?.isVegetarian == true)
                                      _buildTag('Vegetarian', AppColors.success),
                                    if (_recipe!.dietary?.isVegan == true)
                                      _buildTag('Vegan', AppColors.success),
                                    if (_recipe!.dietary?.isGlutenFree == true)
                                      _buildTag('Gluten-Free', AppColors.warning),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Stats Row
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      if (_recipe!.time?.totalTime != null)
                                        _buildStatItem(Icons.timer_outlined, '${_recipe!.time!.totalTime} min', 'Time'),
                                      _buildStatItem(
                                        Icons.star_rounded,
                                        _recipe!.rating?.toStringAsFixed(1) ?? '0.0',
                                        '${_recipe!.ratingCount ?? 0} ratings',
                                        iconColor: AppColors.accent,
                                      ),
                                      if (_recipe!.servings != null)
                                        _buildStatItem(Icons.people_outline_rounded, '${_recipe!.servings}', 'Servings'),
                                      if (_recipe!.nutrition?.calories != null)
                                        _buildStatItem(Icons.local_fire_department_outlined, _recipe!.nutrition!.calories!.toStringAsFixed(0), 'Calories'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Add to Meal Plan Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showAddToMealPlanDialog,
                                    icon: const Icon(Icons.calendar_today_rounded),
                                    label: const Text('Add to Meal Plan'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Description
                                if (_recipe!.description != null && _recipe!.description!.isNotEmpty) ...[
                                  _buildSectionHeader('Description', Icons.description_outlined),
                                  const SizedBox(height: 12),
                                  Text(
                                    _recipe!.description!,
                                    style: const TextStyle(fontSize: 16, height: 1.6),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Ingredients
                                if (_recipe!.ingredients != null && _recipe!.ingredients!.isNotEmpty) ...[
                                  _buildSectionHeader('Ingredients', Icons.egg_outlined),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: _recipe!.ingredients!.asMap().entries.map((entry) {
                                        final ingredient = entry.value;
                                        final isLast = entry.key == _recipe!.ingredients!.length - 1;
                                        return Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.secondary.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(Icons.check_rounded, size: 16, color: AppColors.secondary),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      '${ingredient.quantity != null ? '${ingredient.quantity} ' : ''}${ingredient.unit ?? ''} ${ingredient.ingredientName ?? ''} ${ingredient.preparation ?? ''}'.trim(),
                                                      style: const TextStyle(fontSize: 15),
                                                    ),
                                                  ),
                                                  if (ingredient.isOptional == true)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.surfaceVariant,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text(
                                                        'Optional',
                                                        style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if (!isLast) const Divider(height: 1),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Instructions
                                if (_recipe!.instructions != null && _recipe!.instructions!.isNotEmpty) ...[
                                  _buildSectionHeader('Instructions', Icons.format_list_numbered_rounded),
                                  const SizedBox(height: 12),
                                  ...(_recipe!.instructions!.asMap().entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(10),
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
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              entry.value,
                                              style: const TextStyle(fontSize: 15, height: 1.5),
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
                                  _buildSectionHeader('Nutrition (per serving)', Icons.local_fire_department_outlined),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        if (_recipe!.nutrition!.calories != null)
                                          _buildNutritionRow('Calories', '${_recipe!.nutrition!.calories!.toStringAsFixed(0)} kcal', AppColors.primary),
                                        if (_recipe!.nutrition!.protein != null)
                                          _buildNutritionRow('Protein', '${_recipe!.nutrition!.protein!.toStringAsFixed(1)}g', AppColors.secondary),
                                        if (_recipe!.nutrition!.carbohydrates != null)
                                          _buildNutritionRow('Carbs', '${_recipe!.nutrition!.carbohydrates!.toStringAsFixed(1)}g', AppColors.accent),
                                        if (_recipe!.nutrition!.fat != null)
                                          _buildNutritionRow('Fat', '${_recipe!.nutrition!.fat!.toStringAsFixed(1)}g', AppColors.warning),
                                        if (_recipe!.nutrition!.fiber != null)
                                          _buildNutritionRow('Fiber', '${_recipe!.nutrition!.fiber!.toStringAsFixed(1)}g', AppColors.success),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Rating Section
                                _buildSectionHeader('Rate this Recipe', Icons.star_outline_rounded),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(5, (index) {
                                          return IconButton(
                                            icon: Icon(
                                              index < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                              color: AppColors.accent,
                                              size: 40,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _selectedRating = index + 1;
                                              });
                                            },
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _rateRecipe,
                                          child: const Text('Submit Rating'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, {Color? iconColor}) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
