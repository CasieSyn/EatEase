import 'package:flutter/material.dart';
import '../main.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final IngredientService _ingredientService = IngredientService();
  final TextEditingController _searchController = TextEditingController();

  List<Ingredient> _ingredients = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadIngredients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _ingredientService.getCategories();
      setState(() {
        _categories = ['All', ...categories];
      });
    } catch (e) {
      // Use default categories if API fails
      setState(() {
        _categories = ['All', 'Protein', 'Vegetable', 'Grain', 'Condiment', 'Spice'];
      });
    }
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ingredients = await _ingredientService.getIngredients(
        category: _selectedCategory != null && _selectedCategory != 'All' ? _selectedCategory : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _ingredients = ingredients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _loadIngredients();
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadIngredients();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Section
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
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search ingredients...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: AppColors.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Category Filter
              if (_categories.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.category_rounded, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category ||
                                       (_selectedCategory == null && category == 'All');

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_capitalizeFirst(category)),
                          selected: isSelected,
                          onSelected: (selected) {
                            _onCategorySelected(category == 'All' ? null : category);
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
            ],
          ),
        ),

        // Ingredients List
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading ingredients...',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
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
                              child: Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
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
                              onPressed: _loadIngredients,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _ingredients.isEmpty
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
                                  child: Icon(Icons.egg_alt_rounded, size: 48, color: AppColors.onSurfaceVariant),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No ingredients found',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedCategory != null
                                      ? 'Try adjusting your filters'
                                      : 'Check back later',
                                  style: TextStyle(color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadIngredients,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 100),
                            itemCount: _ingredients.length,
                            itemBuilder: (context, index) {
                              final ingredient = _ingredients[index];
                              return IngredientCard(ingredient: ingredient);
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class IngredientCard extends StatelessWidget {
  final Ingredient ingredient;

  const IngredientCard({
    super.key,
    required this.ingredient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showIngredientDetails(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ingredient Icon/Image
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.15),
                        AppColors.secondary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            ingredient.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.eco_rounded, color: AppColors.secondary, size: 32);
                            },
                          ),
                        )
                      : Icon(Icons.eco_rounded, color: AppColors.secondary, size: 32),
                ),
                const SizedBox(width: 16),

                // Ingredient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        ingredient.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),

                      // Category
                      if (ingredient.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ingredient.category!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Nutrition Info
                      if (ingredient.calories != null)
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _buildNutritionInfo(
                              icon: Icons.local_fire_department_rounded,
                              label: '${ingredient.calories!.toStringAsFixed(0)} cal',
                              color: AppColors.primary,
                            ),
                            if (ingredient.protein != null)
                              _buildNutritionInfo(
                                icon: Icons.fitness_center_rounded,
                                label: '${ingredient.protein!.toStringAsFixed(1)}g',
                                color: AppColors.secondary,
                              ),
                            if (ingredient.carbohydrates != null)
                              _buildNutritionInfo(
                                icon: Icons.grain_rounded,
                                label: '${ingredient.carbohydrates!.toStringAsFixed(1)}g',
                                color: AppColors.accent,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionInfo({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showIngredientDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.eco_rounded, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(ingredient.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              if (ingredient.category != null) ...[
                _buildDetailSection('Category', ingredient.category!),
                const SizedBox(height: 16),
              ],

              // Common Unit
              if (ingredient.commonUnit != null) ...[
                _buildDetailSection('Common Unit', ingredient.commonUnit!),
                const SizedBox(height: 16),
              ],

              // Nutrition Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restaurant_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Nutrition (per 100g)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (ingredient.calories != null)
                      _buildDetailRow('Calories', '${ingredient.calories!.toStringAsFixed(1)} kcal', AppColors.primary),
                    if (ingredient.protein != null)
                      _buildDetailRow('Protein', '${ingredient.protein!.toStringAsFixed(1)}g', AppColors.secondary),
                    if (ingredient.carbohydrates != null)
                      _buildDetailRow('Carbohydrates', '${ingredient.carbohydrates!.toStringAsFixed(1)}g', AppColors.accent),
                    if (ingredient.fat != null)
                      _buildDetailRow('Fat', '${ingredient.fat!.toStringAsFixed(1)}g', AppColors.warning),
                    if (ingredient.fiber != null)
                      _buildDetailRow('Fiber', '${ingredient.fiber!.toStringAsFixed(1)}g', AppColors.success),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.onSurfaceVariant)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
