import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/shopping_list.dart';
import '../services/shopping_list_service.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  final ShoppingListService _service = ShoppingListService();
  List<ShoppingList> _shoppingLists = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  Future<void> _loadShoppingLists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lists = await _service.getShoppingLists();
      if (mounted) {
        setState(() {
          _shoppingLists = lists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showGenerateDialog() async {
    final now = DateTime.now();
    DateTime startDate = now;
    DateTime endDate = now.add(const Duration(days: 7));
    final TextEditingController nameController = TextEditingController(
      text: 'Shopping List ${DateFormat('MMM dd').format(now)}',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generate Shopping List'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'List Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() {
                        startDate = date;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() {
                        endDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'startDate': DateFormat('yyyy-MM-dd').format(startDate),
                  'endDate': DateFormat('yyyy-MM-dd').format(endDate),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _generateShoppingList(
        result['startDate'],
        result['endDate'],
        result['name'],
      );
    }
  }

  Future<void> _generateShoppingList(
    String startDate,
    String endDate,
    String name,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _service.generateFromMealPlans(
        startDate: startDate,
        endDate: endDate,
        listName: name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Shopping list generated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadShoppingLists();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _toggleItemPurchased(ShoppingList list, int itemIndex) async {
    final updatedItems = List<ShoppingListItem>.from(list.items);
    updatedItems[itemIndex].isPurchased = !updatedItems[itemIndex].isPurchased;

    try {
      await _service.updateShoppingList(
        listId: list.id,
        items: updatedItems,
      );

      setState(() {
        _shoppingLists = _shoppingLists.map((sl) {
          if (sl.id == list.id) {
            return ShoppingList(
              id: sl.id,
              userId: sl.userId,
              name: sl.name,
              items: updatedItems,
              isActive: sl.isActive,
              generatedFromMealPlan: sl.generatedFromMealPlan,
              startDate: sl.startDate,
              endDate: sl.endDate,
              createdAt: sl.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return sl;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _deleteShoppingList(int listId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Delete Shopping List'),
          ],
        ),
        content: const Text('Are you sure you want to delete this shopping list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteShoppingList(listId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Shopping list deleted'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _loadShoppingLists();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting list: ${e.toString()}'),
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
      body: RefreshIndicator(
        onRefresh: _loadShoppingLists,
        color: AppColors.primary,
        child: _isLoading && _shoppingLists.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading shopping lists...',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            : _error != null
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
                          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadShoppingLists,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _shoppingLists.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.shopping_bag_rounded, size: 56, color: AppColors.primary),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No shopping lists yet',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Shopping lists are auto-generated from your meal plans',
                                style: TextStyle(color: AppColors.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // How it works section
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.secondary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline_rounded,
                                            color: AppColors.secondary, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'How it works',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildHowItWorksStep(
                                      number: '1',
                                      text: 'Plan your meals in the Plans tab',
                                      icon: Icons.calendar_month_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildHowItWorksStep(
                                      number: '2',
                                      text: 'Tap "Generate List" below',
                                      icon: Icons.add_shopping_cart_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildHowItWorksStep(
                                      number: '3',
                                      text: 'Select date range for your meal plans',
                                      icon: Icons.date_range_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildHowItWorksStep(
                                      number: '4',
                                      text: 'All ingredients are combined into one list!',
                                      icon: Icons.checklist_rounded,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              ElevatedButton.icon(
                                onPressed: _showGenerateDialog,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Generate Shopping List'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
                        itemCount: _shoppingLists.length,
                        itemBuilder: (context, index) {
                          final list = _shoppingLists[index];
                          return _buildShoppingListCard(list);
                        },
                      ),
      ),
      floatingActionButton: _shoppingLists.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'shopping_list_fab',
              onPressed: _showGenerateDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New List'),
            )
          : null,
    );
  }

  Widget _buildShoppingListCard(ShoppingList list) {
    final purchasedCount = list.items.where((item) => item.isPurchased).length;
    final totalCount = list.items.length;
    final progress = totalCount > 0 ? purchasedCount / totalCount : 0.0;
    final isComplete = progress == 1.0;

    // Group items by category
    final Map<String, List<ShoppingListItem>> itemsByCategory = {};
    for (var item in list.items) {
      final category = item.category ?? 'Other';
      if (!itemsByCategory.containsKey(category)) {
        itemsByCategory[category] = [];
      }
      itemsByCategory[category]!.add(item);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isComplete
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isComplete ? Icons.check_circle_rounded : Icons.shopping_bag_rounded,
              color: isComplete ? AppColors.success : AppColors.primary,
            ),
          ),
          title: Text(
            list.name ?? 'Shopping List ${list.id}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (list.generatedFromMealPlan && list.startDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('MMM dd').format(list.startDate!)} - ${DateFormat('MMM dd, yyyy').format(list.endDate!)}',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isComplete ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$purchasedCount/$totalCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isComplete ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () => _deleteShoppingList(list.id),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var category in itemsByCategory.keys) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.category_rounded, size: 14, color: AppColors.secondary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...itemsByCategory[category]!.asMap().entries.map((entry) {
                      final itemIndex = list.items.indexOf(entry.value);
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          value: item.isPurchased,
                          onChanged: (_) => _toggleItemPurchased(list, itemIndex),
                          activeColor: AppColors.success,
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          title: Text(
                            item.ingredientName,
                            style: TextStyle(
                              decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                              color: item.isPurchased ? AppColors.onSurfaceVariant : AppColors.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '${item.quantity} ${item.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksStep({
    required String number,
    required String text,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
