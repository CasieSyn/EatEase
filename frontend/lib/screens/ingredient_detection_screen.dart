import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/ingredient_detection_service.dart';
import '../services/recipe_service.dart';
import '../services/ingredient_service.dart';
import '../services/pantry_service.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import 'recipe_detail_screen.dart';
import 'live_camera_detection_screen.dart';

/// Screen for detecting ingredients from camera/gallery
class IngredientDetectionScreen extends StatefulWidget {
  const IngredientDetectionScreen({super.key});

  @override
  State<IngredientDetectionScreen> createState() => _IngredientDetectionScreenState();
}

class _IngredientDetectionScreenState extends State<IngredientDetectionScreen> {
  final IngredientDetectionService _detectionService = IngredientDetectionService();
  final RecipeService _recipeService = RecipeService();
  final IngredientService _ingredientService = IngredientService();
  final PantryService _pantryService = PantryService();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isDetecting = false;
  bool _isSearching = false;
  bool _isLoadingIngredients = false;
  bool _isAddingToPantry = false;
  IngredientDetectionResult? _detectionResult;
  List<Recipe>? _matchingRecipes;
  String? _errorMessage;

  // Manual ingredient selection
  List<Ingredient> _availableIngredients = [];
  final Set<int> _selectedIngredientIds = {};
  String _ingredientSearchQuery = '';

  /// Pick image from camera (works on mobile + web via webcam)
  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _detectionResult = null;
          _matchingRecipes = null;
          _errorMessage = null;
          _selectedIngredientIds.clear();
        });
        _loadAvailableIngredients();
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
          _selectedImage = image;
          _detectionResult = null;
          _matchingRecipes = null;
          _errorMessage = null;
          _selectedIngredientIds.clear();
        });
        _loadAvailableIngredients();
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  /// Load available ingredients from database
  Future<void> _loadAvailableIngredients() async {
    if (_isLoadingIngredients) return;
    setState(() {
      _isLoadingIngredients = true;
      _errorMessage = null;
    });

    try {
      final ingredients = await _ingredientService.getIngredients(perPage: 500);
      if (!mounted) return;
      setState(() {
        _availableIngredients = ingredients;
        _isLoadingIngredients = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingIngredients = false;
        _errorMessage = 'Failed to load ingredients: $e';
      });
    }
  }

  /// Toggle ingredient selection
  void _toggleIngredientSelection(int ingredientId) {
    setState(() {
      if (_selectedIngredientIds.contains(ingredientId)) {
        _selectedIngredientIds.remove(ingredientId);
      } else {
        _selectedIngredientIds.add(ingredientId);
      }
    });
  }

  /// Auto-select ingredients that match the detected ones
  void _autoSelectDetectedIngredients(List<String> detectedNames) {
    final normalizedDetected = detectedNames.map((n) => n.toLowerCase().trim()).toSet();

    setState(() {
      for (final ingredient in _availableIngredients) {
        final normalizedName = ingredient.name.toLowerCase().trim();
        // Check for exact match or if detected name contains the ingredient name
        if (normalizedDetected.contains(normalizedName) ||
            normalizedDetected.any((d) => d.contains(normalizedName) || normalizedName.contains(d))) {
          _selectedIngredientIds.add(ingredient.id);
        }
      }
    });

    if (_selectedIngredientIds.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedIngredientIds.length} ingredients auto-selected from detection'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
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

      if (!mounted) return;
      setState(() {
        _detectionResult = result;
        _isDetecting = false;
      });

      // Auto-select detected ingredients if they match available ingredients
      if (result.highConfidenceIngredients.isNotEmpty) {
        _autoSelectDetectedIngredients(result.highConfidenceIngredients);
      }

      if (result.totalDetected == 0) {
        _showError('No ingredients detected. Try a clearer image.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Search recipes with detected or manually selected ingredients
  Future<void> _searchRecipes() async {
    // Get ingredient names from manual selection or detection
    List<String> ingredientNames = [];

    if (_selectedIngredientIds.isNotEmpty) {
      // Use manually selected ingredients
      ingredientNames = _availableIngredients
          .where((ing) => _selectedIngredientIds.contains(ing.id))
          .map((ing) => ing.name)
          .toList();
    } else if (_detectionResult != null && _detectionResult!.ingredientNames.isNotEmpty) {
      // Fall back to detected ingredients
      ingredientNames = _detectionResult!.ingredientNames;
    }

    if (ingredientNames.isEmpty) {
      _showError('Please select ingredients or use detection');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final recipes = await _recipeService.searchRecipes(
        ingredients: ingredientNames,
      );

      if (!mounted) return;
      setState(() {
        _matchingRecipes = recipes;
        _isSearching = false;
      });

      if (recipes.isEmpty) {
        _showError('No recipes found with these ingredients');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Add selected/detected ingredients to user's pantry
  Future<void> _addSelectedToPantry() async {
    List<int> ingredientIdsToAdd = [];

    if (_selectedIngredientIds.isNotEmpty) {
      ingredientIdsToAdd = _selectedIngredientIds.toList();
    } else if (_detectionResult != null &&
        _detectionResult!.detectedIngredients.isNotEmpty) {
      ingredientIdsToAdd =
          _detectionResult!.detectedIngredients.map((ing) => ing.id).toList();
    }

    if (ingredientIdsToAdd.isEmpty) {
      _showError('Please select ingredients or use detection first');
      return;
    }

    setState(() {
      _isAddingToPantry = true;
    });

    try {
      final ingredientMaps = ingredientIdsToAdd.map((id) {
        Ingredient? ingredient;
        try {
          ingredient = _availableIngredients.firstWhere((ing) => ing.id == id);
        } catch (_) {
          try {
            ingredient =
                _detectionResult?.detectedIngredients.firstWhere((ing) => ing.id == id);
          } catch (_) {
            ingredient = null;
          }
        }
        return <String, dynamic>{
          'ingredient_id': id,
          if (ingredient?.commonUnit != null) 'unit': ingredient!.commonUnit,
        };
      }).toList();

      final result = await _pantryService.addMultipleToPantry(ingredientMaps);

      if (!mounted) return;

      final addedCount = (result['added'] as List?)?.length ?? 0;
      final updatedCount = (result['updated'] as List?)?.length ?? 0;

      String message;
      if (addedCount > 0 && updatedCount > 0) {
        message = 'Added $addedCount new, $updatedCount already in pantry';
      } else if (addedCount > 0) {
        message =
            'Added $addedCount ingredient${addedCount > 1 ? 's' : ''} to pantry';
      } else if (updatedCount > 0) {
        message =
            'All $updatedCount ingredient${updatedCount > 1 ? 's' : ''} already in pantry';
      } else {
        message = 'Ingredients added to pantry';
      }

      setState(() {
        _isAddingToPantry = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAddingToPantry = false;
      });
      _showError(
          'Failed to add to pantry: ${e.toString().replaceFirst("Exception: ", "")}');
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
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      _selectedIngredientIds.clear();
      _availableIngredients.clear();
      _isAddingToPantry = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Scan Ingredients'),
          ],
        ),
        actions: [
          if (_selectedImage != null || _detectionResult != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _reset,
                tooltip: 'Start Over',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection area
            if (_selectedImage == null && _detectionResult == null) ...[
              _buildImageSelectionCard(),
            ] else ...[
              if (_selectedImage != null)
                _buildSelectedImage(),
              const SizedBox(height: 16),

              // AI Detection (show first — primary action)
              if (_detectionResult == null && _selectedImage != null)
                _buildDetectButton()
              else if (_detectionResult != null)
                _buildDetectionResults(),

              const SizedBox(height: 16),

              // Manual ingredient selector (fallback / supplement)
              if (_isLoadingIngredients)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading ingredients...',
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_availableIngredients.isNotEmpty)
                _buildManualIngredientSelector(),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scan Your Ingredients',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo of your ingredients and we\'ll help you find delicious recipes',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Live Camera Detection - primary option (works on all platforms via camera_web)
            _buildLiveCameraButton(),
            const SizedBox(height: 16),
            // Camera snap + Gallery options
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!kIsWeb)
                  _buildOptionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: _pickFromCamera,
                    isPrimary: false,
                  ),
                if (!kIsWeb)
                  const SizedBox(width: 16),
                _buildOptionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: _pickFromGallery,
                  isPrimary: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build the prominent live camera detection button
  Widget _buildLiveCameraButton() {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      child: InkWell(
        onTap: _openLiveDetection,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Detection',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Point camera at ingredients',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Open live camera detection screen
  void _openLiveDetection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveCameraDetectionScreen(
          onDetectionComplete: (result) {
            // Apply the detection result
            _handleLiveDetectionResult(result);
          },
        ),
      ),
    );
  }

  /// Handle detection result from live camera
  void _handleLiveDetectionResult(IngredientDetectionResult result) {
    setState(() {
      _detectionResult = result;
      _matchingRecipes = null;
      _errorMessage = null;
    });

    // Load available ingredients and auto-select detected ones
    _loadAvailableIngredients().then((_) {
      if (!mounted) return;
      if (result.ingredientNames.isNotEmpty) {
        _autoSelectDetectedIngredients(result.ingredientNames);
      }
    });
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: isPrimary ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isPrimary ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build selected image display
  Widget _buildSelectedImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Stack(
              children: [
                kIsWeb
                    ? Image.network(
                        _selectedImage!.path,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(_selectedImage!.path),
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Image uploaded badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Image Ready',
                          style: TextStyle(
                            color: Colors.white,
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
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSmallButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Change',
                    onTap: _pickFromGallery,
                  ),
                  const SizedBox(width: 16),
                  _buildSmallButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Retake',
                    onTap: _pickFromCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  /// Build detect button
  Widget _buildDetectButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isDetecting ? null : _detectIngredients,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isDetecting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  _isDetecting ? 'Detecting Ingredients...' : 'Detect Ingredients with AI',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build "Add to Pantry" button
  Widget _buildAddToPantryButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isAddingToPantry ? null : _addSelectedToPantry,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isAddingToPantry
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(Icons.kitchen_rounded,
                        color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Text(
                  _isAddingToPantry ? 'Adding to Pantry...' : 'Add to Pantry',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build detection results
  Widget _buildDetectionResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.auto_awesome, color: AppColors.success, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Detection Complete',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '${_detectionResult!.totalDetected} ingredients found',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // All detections
                Row(
                  children: [
                    Icon(Icons.visibility_rounded, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'All Detections',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Show recognized ingredients
                if (_detectionResult!.detections.any((d) => d.name != null))
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _detectionResult!.detections
                        .where((d) => d.name != null)
                        .map((detection) {
                      final isHighConfidence = detection.confidence >= 0.7;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isHighConfidence
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isHighConfidence
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isHighConfidence ? AppColors.success : AppColors.warning,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(detection.confidence * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              detection.name!,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isHighConfidence ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                // Show unrecognized items (detected but not in database)
                if (_detectionResult!.detections.any((d) => d.name == null && d.sourceClass != null)) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.help_outline_rounded, size: 18, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Not in Filipino ingredients database:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _detectionResult!.detections
                        .where((d) => d.name == null && d.sourceClass != null)
                        .map((detection) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(detection.confidence * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              detection.sourceClass!,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // High confidence ingredients
                if (_detectionResult!.highConfidenceIngredients.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'High Confidence (>70%)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _detectionResult!.highConfidenceIngredients
                        .map((name) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                // Wrong detection? Help us learn button
                const SizedBox(height: 16),
                InkWell(
                  onTap: _showCorrectionDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology_rounded, size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          'Wrong detection? Help AI learn',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.warning),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildAddToPantryButton(),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.secondary, AppColors.secondaryLight],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSearching ? null : _searchRecipes,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isSearching
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      _isSearching ? 'Searching Recipes...' : 'Find Matching Recipes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build error card
  Widget _buildErrorCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppColors.error.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build recipes list
  Widget _buildRecipesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Matching Recipes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_matchingRecipes!.length} recipes found',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _matchingRecipes!.length,
          itemBuilder: (context, index) {
            final recipe = _matchingRecipes![index];
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe image with gradient overlay
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: recipe.imageUrl != null
                                ? Image.network(
                                    recipe.imageUrl!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 180,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppColors.primary.withValues(alpha: 0.3),
                                              AppColors.secondary.withValues(alpha: 0.3),
                                            ],
                                          ),
                                        ),
                                        child: Icon(Icons.restaurant, size: 56, color: AppColors.onSurfaceVariant),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primary.withValues(alpha: 0.3),
                                          AppColors.secondary.withValues(alpha: 0.3),
                                        ],
                                      ),
                                    ),
                                    child: Icon(Icons.restaurant, size: 56, color: AppColors.onSurfaceVariant),
                                  ),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
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
                                // Cuisine type tag
                                if (recipe.cuisineType != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      recipe.cuisineType!,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
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
          },
        ),
      ],
    );
  }

  /// Build manual ingredient selector
  Widget _buildManualIngredientSelector() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.egg_alt_rounded, color: AppColors.secondary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Ingredients',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Tap what you see in the image',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_selectedIngredientIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedIngredientIds.length} selected',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search ingredients...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
                prefixIcon: Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
              ),
              onChanged: (value) {
                setState(() {
                  _ingredientSearchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _availableIngredients
                  .where((ingredient) =>
                      _ingredientSearchQuery.isEmpty ||
                      ingredient.name.toLowerCase().contains(_ingredientSearchQuery.toLowerCase()))
                  .map((ingredient) {
                final isSelected = _selectedIngredientIds.contains(ingredient.id);
                return GestureDetector(
                  onTap: () => _toggleIngredientSelection(ingredient.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check_circle_rounded, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          ingredient.name,
                          style: TextStyle(
                            color: isSelected ? AppColors.secondary : AppColors.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            // Only show this button if NO detection results (to avoid duplicate buttons)
            if (_selectedIngredientIds.isNotEmpty && _detectionResult == null) ...[
              const SizedBox(height: 24),
              _buildAddToPantryButton(),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.secondaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSearching ? null : _searchRecipes,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isSearching
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            _isSearching ? 'Searching...' : 'Find Recipes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show dialog to correct AI detection mistakes
  void _showCorrectionDialog() {
    if (_detectionResult == null) return;

    // Get unique detected ingredients (what user sees on screen)
    final detectionsWithNames = _detectionResult!.detections
        .where((d) => d.name != null)
        .toList();

    // Remove duplicates by name
    final uniqueDetections = <String, Detection>{};
    for (final d in detectionsWithNames) {
      if (d.name != null && !uniqueDetections.containsKey(d.name)) {
        uniqueDetections[d.name!] = d;
      }
    }

    // Map from displayed ingredient name to correction
    final corrections = <String, String?>{};
    // Map to track search text for each detection
    final searchQueries = <String, String>{};

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Correct Wrong Detections',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'If AI detected the wrong ingredient, select what it should be. This helps improve future detections!',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...uniqueDetections.entries.map((entry) {
                        final displayedName = entry.key;
                        final detection = entry.value;
                        final confidence = (detection.confidence * 100).toInt();
                        final searchQuery = searchQueries[displayedName] ?? '';

                        // Filter ingredients based on search
                        final filteredIngredients = _availableIngredients
                            .where((ing) =>
                                ing.name != displayedName &&
                                (searchQuery.isEmpty ||
                                    ing.name.toLowerCase().contains(searchQuery.toLowerCase())))
                            .toList();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: corrections[displayedName] != null
                                  ? AppColors.success
                                  : AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                              width: corrections[displayedName] != null ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          displayedName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.warning.withValues(alpha: 0.9),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$confidence%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.warning.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (corrections[displayedName] != null) ...[
                                    const SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.success),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        corrections[displayedName]!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Is this wrong? Search and select the correct ingredient:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Search field
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Type to search ingredients...',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
                                  prefixIcon: Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
                                ),
                                onChanged: (value) {
                                  setDialogState(() {
                                    searchQueries[displayedName] = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              // Filtered ingredient list
                              Container(
                                constraints: const BoxConstraints(maxHeight: 150),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.onSurfaceVariant.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: filteredIngredients.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          'No matching ingredients found',
                                          style: TextStyle(
                                            color: AppColors.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: filteredIngredients.length > 20 ? 20 : filteredIngredients.length,
                                        itemBuilder: (context, index) {
                                          final ingredient = filteredIngredients[index];
                                          final isSelected = corrections[displayedName] == ingredient.name;
                                          return InkWell(
                                            onTap: () {
                                              setDialogState(() {
                                                if (isSelected) {
                                                  corrections.remove(displayedName);
                                                } else {
                                                  corrections[displayedName] = ingredient.name;
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: isSelected ? AppColors.success.withValues(alpha: 0.1) : null,
                                                border: index < filteredIngredients.length - 1 && index < 19
                                                    ? Border(bottom: BorderSide(color: AppColors.onSurfaceVariant.withValues(alpha: 0.1)))
                                                    : null,
                                              ),
                                              child: Row(
                                                children: [
                                                  if (isSelected)
                                                    Icon(Icons.check_circle, size: 18, color: AppColors.success)
                                                  else
                                                    Icon(Icons.circle_outlined, size: 18, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      ingredient.name,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                        color: isSelected ? AppColors.success : AppColors.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              if (filteredIngredients.length > 20)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Showing 20 of ${filteredIngredients.length} results. Type to filter.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              // Clear correction button
                              if (corrections[displayedName] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        corrections.remove(displayedName);
                                      });
                                    },
                                    icon: Icon(Icons.undo, size: 16, color: AppColors.onSurfaceVariant),
                                    label: Text(
                                      'This is correct (no change needed)',
                                      style: TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
                ),
                ElevatedButton(
                  onPressed: corrections.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          await _submitCorrections(corrections);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Submit ${corrections.length} corrections'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Submit corrections to the backend
  /// corrections: Map of displayed ingredient name (e.g., "Langka") -> correct ingredient name (e.g., "Pineapple")
  Future<void> _submitCorrections(Map<String, String?> corrections) async {
    try {
      // Build correction list
      // Key is displayed name (e.g., "Langka"), value is what it should be (e.g., "Pineapple")
      final correctionList = <DetectionCorrection>[];

      for (final entry in corrections.entries) {
        if (entry.value == null) continue;

        final displayedName = entry.key;     // What user saw (e.g., "Langka")
        final correctName = entry.value!;     // What it should be (e.g., "Pineapple")

        // Find the detection that maps to this displayed name to get raw label
        final detection = _detectionResult?.detections
            .firstWhere(
              (d) => d.name == displayedName,
              orElse: () => Detection(confidence: 0, bbox: [], source: 'unknown'),
            );

        // Use the raw sourceClass (Google label) if available, otherwise use displayed name
        final rawLabel = detection?.sourceClass ?? displayedName;

        correctionList.add(DetectionCorrection(
          detectedLabel: rawLabel.toLowerCase(),  // Raw label (e.g., "jackfruit", "fruit")
          aiMapped: displayedName,                // What AI mapped it to (e.g., "Langka")
          correctIngredient: correctName,         // User's correction (e.g., "Pineapple")
        ));
      }

      if (correctionList.isEmpty) return;

      await _detectionService.submitDetectionFeedback(correctionList);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Thanks! AI will learn from ${correctionList.length} correction(s)',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit corrections: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
