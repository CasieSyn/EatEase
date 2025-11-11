import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
          const SnackBar(
            content: Text('Shopping list generated successfully'),
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteShoppingList(int listId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shopping List'),
        content: const Text('Are you sure you want to delete this shopping list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
            const SnackBar(
              content: Text('Shopping list deleted'),
              backgroundColor: Colors.green,
            ),
          );
          _loadShoppingLists();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting list: ${e.toString()}'),
              backgroundColor: Colors.red,
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
        child: _isLoading && _shoppingLists.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadShoppingLists,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _shoppingLists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No shopping lists yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate a list from your meal plans',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showGenerateDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Generate List'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _shoppingLists.length,
                        itemBuilder: (context, index) {
                          final list = _shoppingLists[index];
                          return _buildShoppingListCard(list);
                        },
                      ),
      ),
      floatingActionButton: _shoppingLists.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showGenerateDialog,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildShoppingListCard(ShoppingList list) {
    final purchasedCount = list.items.where((item) => item.isPurchased).length;
    final totalCount = list.items.length;
    final progress = totalCount > 0 ? purchasedCount / totalCount : 0.0;

    // Group items by category
    final Map<String, List<ShoppingListItem>> itemsByCategory = {};
    for (var item in list.items) {
      final category = item.category ?? 'Other';
      if (!itemsByCategory.containsKey(category)) {
        itemsByCategory[category] = [];
      }
      itemsByCategory[category]!.add(item);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: progress == 1.0 ? Colors.green : Colors.orange,
          child: Icon(
            progress == 1.0 ? Icons.check : Icons.shopping_cart,
            color: Colors.white,
          ),
        ),
        title: Text(
          list.name ?? 'Shopping List ${list.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (list.generatedFromMealPlan && list.startDate != null)
              Text(
                '${DateFormat('MMM dd').format(list.startDate!)} - ${DateFormat('MMM dd, yyyy').format(list.endDate!)}',
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$purchasedCount/$totalCount',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteShoppingList(list.id),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var category in itemsByCategory.keys) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  ...itemsByCategory[category]!.asMap().entries.map((entry) {
                    final itemIndex = list.items.indexOf(entry.value);
                    final item = entry.value;
                    return CheckboxListTile(
                      dense: true,
                      value: item.isPurchased,
                      onChanged: (_) => _toggleItemPurchased(list, itemIndex),
                      title: Text(
                        item.ingredientName,
                        style: TextStyle(
                          decoration: item.isPurchased
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        '${item.quantity} ${item.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
