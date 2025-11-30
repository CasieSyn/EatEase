import 'package:flutter/material.dart';
import '../main.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormScreen({super.key, this.recipe});

  bool get isEditing => recipe != null;

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final RecipeService _recipeService = RecipeService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _servingsController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;

  String? _selectedCuisineType;
  String? _selectedMealType;
  String? _selectedDifficulty;

  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _isGlutenFree = false;
  bool _isDairyFree = false;

  List<String> _instructions = [];
  final TextEditingController _instructionController = TextEditingController();

  bool _isLoading = false;

  final List<String> _cuisineTypes = [
    'Filipino',
    'Asian',
    'Western',
    'Mediterranean',
    'Indian',
    'Mexican',
    'Italian',
    'Japanese',
    'Chinese',
    'Korean',
    'Thai',
    'Other',
  ];

  final List<String> _mealTypes = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'dessert',
  ];

  final List<String> _difficultyLevels = [
    'easy',
    'medium',
    'hard',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final recipe = widget.recipe;

    _nameController = TextEditingController(text: recipe?.name ?? '');
    _descriptionController = TextEditingController(text: recipe?.description ?? '');
    _imageUrlController = TextEditingController(text: recipe?.imageUrl ?? '');
    _servingsController = TextEditingController(text: recipe?.servings?.toString() ?? '4');
    _prepTimeController = TextEditingController(text: recipe?.time?.prepTime?.toString() ?? '');
    _cookTimeController = TextEditingController(text: recipe?.time?.cookTime?.toString() ?? '');
    _caloriesController = TextEditingController(text: recipe?.nutrition?.calories?.toString() ?? '');
    _proteinController = TextEditingController(text: recipe?.nutrition?.protein?.toString() ?? '');
    _carbsController = TextEditingController(text: recipe?.nutrition?.carbohydrates?.toString() ?? '');
    _fatController = TextEditingController(text: recipe?.nutrition?.fat?.toString() ?? '');
    _fiberController = TextEditingController(text: recipe?.nutrition?.fiber?.toString() ?? '');

    _selectedCuisineType = recipe?.cuisineType;
    _selectedMealType = recipe?.mealType;
    _selectedDifficulty = recipe?.difficultyLevel;

    _isVegetarian = recipe?.dietary?.isVegetarian ?? false;
    _isVegan = recipe?.dietary?.isVegan ?? false;
    _isGlutenFree = recipe?.dietary?.isGlutenFree ?? false;
    _isDairyFree = recipe?.dietary?.isDairyFree ?? false;

    _instructions = List<String>.from(recipe?.instructions ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prepTime = int.tryParse(_prepTimeController.text);
      final cookTime = int.tryParse(_cookTimeController.text);
      final totalTime = (prepTime ?? 0) + (cookTime ?? 0);

      if (widget.isEditing) {
        await _recipeService.updateRecipe(
          recipeId: widget.recipe!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          cuisineType: _selectedCuisineType,
          mealType: _selectedMealType,
          difficultyLevel: _selectedDifficulty,
          prepTime: prepTime,
          cookTime: cookTime,
          totalTime: totalTime > 0 ? totalTime : null,
          servings: int.tryParse(_servingsController.text),
          instructions: _instructions.isNotEmpty ? _instructions : null,
          calories: double.tryParse(_caloriesController.text),
          protein: double.tryParse(_proteinController.text),
          carbohydrates: double.tryParse(_carbsController.text),
          fat: double.tryParse(_fatController.text),
          fiber: double.tryParse(_fiberController.text),
          isVegetarian: _isVegetarian,
          isVegan: _isVegan,
          isGlutenFree: _isGlutenFree,
          isDairyFree: _isDairyFree,
          imageUrl: _imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null,
        );
      } else {
        await _recipeService.createRecipe(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          cuisineType: _selectedCuisineType,
          mealType: _selectedMealType,
          difficultyLevel: _selectedDifficulty,
          prepTime: prepTime,
          cookTime: cookTime,
          totalTime: totalTime > 0 ? totalTime : null,
          servings: int.tryParse(_servingsController.text),
          instructions: _instructions.isNotEmpty ? _instructions : null,
          calories: double.tryParse(_caloriesController.text),
          protein: double.tryParse(_proteinController.text),
          carbohydrates: double.tryParse(_carbsController.text),
          fat: double.tryParse(_fatController.text),
          fiber: double.tryParse(_fiberController.text),
          isVegetarian: _isVegetarian,
          isVegan: _isVegan,
          isGlutenFree: _isGlutenFree,
          isDairyFree: _isDairyFree,
          imageUrl: _imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Recipe updated successfully' : 'Recipe created successfully'),
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
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addInstruction() {
    final instruction = _instructionController.text.trim();
    if (instruction.isNotEmpty) {
      setState(() {
        _instructions.add(instruction);
        _instructionController.clear();
      });
    }
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
    });
  }

  void _reorderInstructions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _instructions.removeAt(oldIndex);
      _instructions.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(widget.isEditing ? 'Edit Recipe' : 'Create Recipe'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _saveRecipe,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save'),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information', Icons.info_outline_rounded),
              const SizedBox(height: 16),
              _buildCard([
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Recipe Name *',
                    hintText: 'Enter recipe name',
                    prefixIcon: Icon(Icons.restaurant_menu_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Recipe name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of the recipe',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // Classification Section
              _buildSectionHeader('Classification', Icons.category_outlined),
              const SizedBox(height: 16),
              _buildCard([
                DropdownButtonFormField<String>(
                  initialValue: _selectedCuisineType,
                  decoration: const InputDecoration(
                    labelText: 'Cuisine Type',
                    prefixIcon: Icon(Icons.public_outlined),
                  ),
                  items: _cuisineTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedCuisineType = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                  items: _mealTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type[0].toUpperCase() + type.substring(1)),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedMealType = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty Level',
                    prefixIcon: Icon(Icons.bar_chart_outlined),
                  ),
                  items: _difficultyLevels.map((level) => DropdownMenuItem(
                    value: level,
                    child: Text(level[0].toUpperCase() + level.substring(1)),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedDifficulty = value),
                ),
              ]),

              const SizedBox(height: 24),

              // Time & Servings Section
              _buildSectionHeader('Time & Servings', Icons.timer_outlined),
              const SizedBox(height: 16),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prepTimeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prep Time (min)',
                          prefixIcon: Icon(Icons.hourglass_empty_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cookTimeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cook Time (min)',
                          prefixIcon: Icon(Icons.whatshot_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _servingsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Servings',
                    prefixIcon: Icon(Icons.people_outline_rounded),
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // Dietary Information Section
              _buildSectionHeader('Dietary Information', Icons.eco_outlined),
              const SizedBox(height: 16),
              _buildCard([
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildDietaryChip('Vegetarian', _isVegetarian, (val) => setState(() => _isVegetarian = val)),
                    _buildDietaryChip('Vegan', _isVegan, (val) => setState(() => _isVegan = val)),
                    _buildDietaryChip('Gluten-Free', _isGlutenFree, (val) => setState(() => _isGlutenFree = val)),
                    _buildDietaryChip('Dairy-Free', _isDairyFree, (val) => setState(() => _isDairyFree = val)),
                  ],
                ),
              ]),

              const SizedBox(height: 24),

              // Nutrition Section
              _buildSectionHeader('Nutrition (per serving)', Icons.local_fire_department_outlined),
              const SizedBox(height: 16),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calories',
                          suffixText: 'kcal',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _proteinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Protein',
                          suffixText: 'g',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _carbsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Carbs',
                          suffixText: 'g',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _fatController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fat',
                          suffixText: 'g',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fiberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fiber',
                    suffixText: 'g',
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // Instructions Section
              _buildSectionHeader('Instructions', Icons.format_list_numbered_rounded),
              const SizedBox(height: 16),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _instructionController,
                        decoration: const InputDecoration(
                          hintText: 'Add a step...',
                          prefixIcon: Icon(Icons.add_rounded),
                        ),
                        onSubmitted: (_) => _addInstruction(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _addInstruction,
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (_instructions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _instructions.length,
                    onReorder: _reorderInstructions,
                    itemBuilder: (context, index) {
                      return Container(
                        key: ValueKey('instruction_$index'),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            _instructions[index],
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.drag_handle_rounded, color: AppColors.onSurfaceVariant),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                onPressed: () => _removeInstruction(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ]),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'recipe_form_fab',
        onPressed: _isLoading ? null : _saveRecipe,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(widget.isEditing ? 'Update Recipe' : 'Create Recipe'),
      ),
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

  Widget _buildCard(List<Widget> children) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDietaryChip(String label, bool selected, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      selectedColor: AppColors.secondary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    );
  }
}
