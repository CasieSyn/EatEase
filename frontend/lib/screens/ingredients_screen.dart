import 'package:flutter/material.dart';
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
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search ingredients...',
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),

        // Category Filter
        if (_categories.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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

        // Ingredients List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
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
                            onPressed: _loadIngredients,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _ingredients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No ingredients found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadIngredients,
                          child: ListView.builder(
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Show ingredient details dialog
          _showIngredientDetails(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ingredient Icon/Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ingredient.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.eco, color: Colors.green[300], size: 32);
                          },
                        ),
                      )
                    : Icon(Icons.eco, color: Colors.green[300], size: 32),
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
                    const SizedBox(height: 4),

                    // Category
                    if (ingredient.category != null)
                      Chip(
                        label: Text(ingredient.category!),
                        backgroundColor: Colors.green[100],
                        labelStyle: const TextStyle(fontSize: 12),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    const SizedBox(height: 8),

                    // Nutrition Info
                    if (ingredient.calories != null)
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _buildNutritionInfo(
                            icon: Icons.local_fire_department,
                            label: '${ingredient.calories!.toStringAsFixed(0)} cal',
                            color: Colors.orange,
                          ),
                          if (ingredient.protein != null)
                            _buildNutritionInfo(
                              icon: Icons.fitness_center,
                              label: '${ingredient.protein!.toStringAsFixed(1)}g protein',
                              color: Colors.blue,
                            ),
                          if (ingredient.carbohydrates != null)
                            _buildNutritionInfo(
                              icon: Icons.grain,
                              label: '${ingredient.carbohydrates!.toStringAsFixed(1)}g carbs',
                              color: Colors.brown,
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              // Arrow Icon
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
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
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showIngredientDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ingredient.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              if (ingredient.category != null) ...[
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(ingredient.category!),
                const SizedBox(height: 16),
              ],

              // Common Unit
              if (ingredient.commonUnit != null) ...[
                const Text(
                  'Common Unit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(ingredient.commonUnit!),
                const SizedBox(height: 16),
              ],

              // Nutrition Information
              const Text(
                'Nutrition (per 100g)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (ingredient.calories != null)
                _buildDetailRow('Calories', '${ingredient.calories!.toStringAsFixed(1)} kcal'),
              if (ingredient.protein != null)
                _buildDetailRow('Protein', '${ingredient.protein!.toStringAsFixed(1)}g'),
              if (ingredient.carbohydrates != null)
                _buildDetailRow('Carbohydrates', '${ingredient.carbohydrates!.toStringAsFixed(1)}g'),
              if (ingredient.fat != null)
                _buildDetailRow('Fat', '${ingredient.fat!.toStringAsFixed(1)}g'),
              if (ingredient.fiber != null)
                _buildDetailRow('Fiber', '${ingredient.fiber!.toStringAsFixed(1)}g'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
