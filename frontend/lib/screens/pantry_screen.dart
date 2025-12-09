import 'package:flutter/material.dart';
import '../main.dart';
import '../models/ingredient.dart';
import '../models/pantry_item.dart';
import '../services/ingredient_service.dart';
import '../services/pantry_service.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> with SingleTickerProviderStateMixin {
  final PantryService _pantryService = PantryService();
  final IngredientService _ingredientService = IngredientService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  List<PantryItem> _pantryItems = [];
  List<Ingredient> _allIngredients = [];
  Set<int> _pantryIngredientIds = {};
  bool _isLoading = false;
  bool _isLoadingIngredients = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadPantry();
    _loadAllIngredients();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      setState(() {
        _categories = ['All', 'protein', 'vegetable', 'grain', 'condiment', 'spice', 'dairy'];
      });
    }
  }

  Future<void> _loadPantry() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _pantryService.getPantry();
      setState(() {
        _pantryItems = items;
        _pantryIngredientIds = items.map((item) => item.ingredientId).toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllIngredients() async {
    setState(() {
      _isLoadingIngredients = true;
    });

    try {
      final ingredients = await _ingredientService.getIngredients(
        perPage: 100, // Load more ingredients
        category: _selectedCategory != null && _selectedCategory != 'All' ? _selectedCategory : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _allIngredients = ingredients;
        _isLoadingIngredients = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingIngredients = false;
      });
    }
  }

  Future<void> _addToPantry(Ingredient ingredient) async {
    try {
      await _pantryService.addToPantry(ingredientId: ingredient.id);
      setState(() {
        _pantryIngredientIds.add(ingredient.id);
      });
      await _loadPantry();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ingredient.name} added to pantry'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeFromPantry(PantryItem item) async {
    try {
      await _pantryService.removeFromPantry(item.id);
      setState(() {
        _pantryIngredientIds.remove(item.ingredientId);
        _pantryItems.removeWhere((i) => i.id == item.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed from pantry'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearPantry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Pantry'),
        content: const Text('Are you sure you want to remove all ingredients from your pantry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _pantryService.clearPantry();
        setState(() {
          _pantryItems.clear();
          _pantryIngredientIds.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pantry cleared'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear pantry: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _loadAllIngredients();
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadAllIngredients();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pantry'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_pantryItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: AppColors.error),
              onPressed: _clearPantry,
              tooltip: 'Clear pantry',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          tabs: [
            Tab(
              icon: const Icon(Icons.kitchen_rounded),
              text: 'My Pantry (${_pantryItems.length})',
            ),
            const Tab(
              icon: Icon(Icons.add_shopping_cart_rounded),
              text: 'Add Ingredients',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPantryTab(),
          _buildAddIngredientsTab(),
        ],
      ),
    );
  }

  Widget _buildPantryTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Loading your pantry...', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading pantry', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_errorMessage!, style: TextStyle(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPantry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pantryItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.kitchen_rounded, size: 64, color: AppColors.secondary),
              ),
              const SizedBox(height: 24),
              Text('Your pantry is empty', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Add ingredients you have at home to get personalized recipe recommendations!',
                style: TextStyle(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Ingredients'),
              ),
            ],
          ),
        ),
      );
    }

    // Group by category
    final groupedItems = <String, List<PantryItem>>{};
    for (final item in _pantryItems) {
      final category = item.category ?? 'Other';
      groupedItems.putIfAbsent(category, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: _loadPantry,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_pantryItems.length} Ingredients',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ready for cooking!',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Grouped ingredients
          ...groupedItems.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _capitalizeFirst(entry.key),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${entry.value.length})',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.map((item) {
                    return Chip(
                      label: Text(item.name),
                      deleteIcon: Icon(Icons.close, size: 18, color: AppColors.error),
                      onDeleted: () => _removeFromPantry(item),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      labelStyle: TextStyle(color: AppColors.onSurface),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddIngredientsTab() {
    return Column(
      children: [
        // Search and Filter
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
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search ingredients to add...',
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
              const SizedBox(height: 12),
              if (_categories.isNotEmpty)
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
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
          child: _isLoadingIngredients
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _allIngredients.isEmpty
                  ? Center(
                      child: Text('No ingredients found', style: TextStyle(color: AppColors.onSurfaceVariant)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: _allIngredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _allIngredients[index];
                        final isInPantry = _pantryIngredientIds.contains(ingredient.id);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: isInPantry
                                ? Border.all(color: AppColors.success, width: 2)
                                : null,
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isInPantry
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isInPantry ? Icons.check_circle_rounded : Icons.eco_rounded,
                                color: isInPantry ? AppColors.success : AppColors.secondary,
                              ),
                            ),
                            title: Text(
                              ingredient.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isInPantry ? AppColors.success : AppColors.onSurface,
                              ),
                            ),
                            subtitle: ingredient.category != null
                                ? Text(
                                    _capitalizeFirst(ingredient.category!),
                                    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                                  )
                                : null,
                            trailing: isInPantry
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'In Pantry',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
                                    onPressed: () => _addToPantry(ingredient),
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
