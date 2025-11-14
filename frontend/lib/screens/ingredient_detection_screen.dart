import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/ingredient_detection_service.dart';
import '../services/recipe_service.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

/// Screen for detecting ingredients from camera/gallery
class IngredientDetectionScreen extends StatefulWidget {
  const IngredientDetectionScreen({super.key});

  @override
  State<IngredientDetectionScreen> createState() => _IngredientDetectionScreenState();
}

class _IngredientDetectionScreenState extends State<IngredientDetectionScreen> {
  final IngredientDetectionService _detectionService = IngredientDetectionService();
  final RecipeService _recipeService = RecipeService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isDetecting = false;
  bool _isSearching = false;
  IngredientDetectionResult? _detectionResult;
  List<Recipe>? _matchingRecipes;
  String? _errorMessage;

  /// Pick image from camera
  Future<void> _pickFromCamera() async {
    if (kIsWeb) {
      _showError('Camera is not supported on web. Please use gallery.');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _detectionResult = null;
          _matchingRecipes = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showError('Error accessing camera: $e');
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _detectionResult = null;
          _matchingRecipes = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  /// Detect ingredients from selected image
  Future<void> _detectIngredients() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    setState(() {
      _isDetecting = true;
      _errorMessage = null;
    });

    try {
      final result = await _detectionService.detectIngredients(_selectedImage!);

      setState(() {
        _detectionResult = result;
        _isDetecting = false;
      });

      if (result.totalDetected == 0) {
        _showError('No ingredients detected. Try a clearer image.');
      }
    } catch (e) {
      setState(() {
        _isDetecting = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Search recipes with detected ingredients
  Future<void> _searchRecipes() async {
    if (_detectionResult == null || _detectionResult!.ingredientNames.isEmpty) {
      _showError('No ingredients detected');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final recipes = await _recipeService.searchRecipes(
        ingredients: _detectionResult!.ingredientNames,
      );

      setState(() {
        _matchingRecipes = recipes;
        _isSearching = false;
      });

      if (recipes.isEmpty) {
        _showError('No recipes found with these ingredients');
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Show error message
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Reset detection
  void _reset() {
    setState(() {
      _selectedImage = null;
      _detectionResult = null;
      _matchingRecipes = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredient Detection'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection area
            if (_selectedImage == null) ...[
              _buildImageSelectionCard(),
            ] else ...[
              _buildSelectedImage(),
              const SizedBox(height: 16),
              if (_detectionResult == null)
                _buildDetectButton()
              else
                _buildDetectionResults(),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],

            // Matching recipes
            if (_matchingRecipes != null) ...[
              const SizedBox(height: 24),
              _buildRecipesList(),
            ],
          ],
        ),
      ),
    );
  }

  /// Build image selection card
  Widget _buildImageSelectionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.add_a_photo,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Detect Ingredients',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo or select from gallery',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!kIsWeb) ...[
                  ElevatedButton.icon(
                    onPressed: _pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build selected image display
  Widget _buildSelectedImage() {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image.file(
            _selectedImage!,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Change'),
                ),
                if (!kIsWeb)
                  TextButton.icon(
                    onPressed: _pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Retake'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build detect button
  Widget _buildDetectButton() {
    return ElevatedButton.icon(
      onPressed: _isDetecting ? null : _detectIngredients,
      icon: _isDetecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.search),
      label: Text(_isDetecting ? 'Detecting...' : 'Detect Ingredients'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  /// Build detection results
  Widget _buildDetectionResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Detected ${_detectionResult!.totalDetected} ingredients',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // All detections
                Text(
                  'All Detections:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _detectionResult!.detections.map((detection) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: detection.confidence >= 0.7
                            ? Colors.green
                            : Colors.orange,
                        child: Text(
                          '${(detection.confidence * 100).toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      label: Text(detection.name),
                    );
                  }).toList(),
                ),
                // High confidence ingredients
                if (_detectionResult!.highConfidenceIngredients.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'High Confidence (>70%):',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _detectionResult!.highConfidenceIngredients
                        .map((name) => Chip(
                              label: Text(name),
                              backgroundColor: Colors.green[50],
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isSearching ? null : _searchRecipes,
          icon: _isSearching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.restaurant_menu),
          label: Text(_isSearching ? 'Searching...' : 'Find Recipes'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Build error card
  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build recipes list
  Widget _buildRecipesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matching Recipes (${_matchingRecipes!.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _matchingRecipes!.length,
          itemBuilder: (context, index) {
            final recipe = _matchingRecipes![index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe image
                    if (recipe.imageUrl != null)
                      Image.network(
                        recipe.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Icon(Icons.restaurant, size: 60),
                          );
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 4),
                              Text('${recipe.time?.totalTime ?? 0} min'),
                              const SizedBox(width: 16),
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(recipe.rating?.toStringAsFixed(1) ?? "N/A"),
                              const SizedBox(width: 16),
                              const Icon(Icons.restaurant_menu, size: 16),
                              const SizedBox(width: 4),
                              Text('${recipe.servings} servings'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
