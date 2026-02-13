import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../main.dart';
import '../services/ingredient_detection_service.dart';

/// Live camera detection screen with real-time ingredient detection
class LiveCameraDetectionScreen extends StatefulWidget {
  final Function(IngredientDetectionResult) onDetectionComplete;

  const LiveCameraDetectionScreen({
    super.key,
    required this.onDetectionComplete,
  });

  @override
  State<LiveCameraDetectionScreen> createState() => _LiveCameraDetectionScreenState();
}

class _LiveCameraDetectionScreenState extends State<LiveCameraDetectionScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isCameraAvailable = true;
  String? _errorMessage;

  // Detection state
  List<Detection> _currentDetections = [];
  Timer? _detectionTimer;
  final IngredientDetectionService _detectionService = IngredientDetectionService();

  // For tracking detected ingredients over time
  final Map<String, int> _detectionCounts = {};
  final Set<String> _confirmedIngredients = {};

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _isCameraAvailable = false;
          _errorMessage = 'No camera available on this device';
        });
        return;
      }

      // Use back camera if available, otherwise first camera
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Start periodic detection
        _startPeriodicDetection();
      }
    } catch (e) {
      setState(() {
        _isCameraAvailable = false;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  void _startPeriodicDetection() {
    // Detect every 4 seconds to avoid overloading the API
    _detectionTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isInitialized && !_isDetecting && mounted) {
        _captureAndDetect();
      }
    });
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isDetecting = true;
    });

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();

      // Send to detection API
      final result = await _detectionService.detectIngredients(imageFile);

      if (mounted) {
        setState(() {
          _currentDetections = result.detections;
          _isDetecting = false;

          // Track detection counts for confirmed ingredients
          final currentNames = <String>{};
          for (final detection in result.detections) {
            if (detection.name != null && detection.confidence >= 0.6) {
              currentNames.add(detection.name!);
              _detectionCounts[detection.name!] =
                  (_detectionCounts[detection.name!] ?? 0) + 1;

              // After 2 consecutive detections, consider it confirmed
              if (_detectionCounts[detection.name!]! >= 2) {
                _confirmedIngredients.add(detection.name!);
              }
            }
          }

          // Decay counts for ingredients NOT detected in this frame
          final keysToRemove = <String>[];
          for (final key in _detectionCounts.keys) {
            if (!currentNames.contains(key)) {
              _detectionCounts[key] = (_detectionCounts[key]! - 1).clamp(0, 999);
              if (_detectionCounts[key]! <= 0) {
                keysToRemove.add(key);
                _confirmedIngredients.remove(key);
              }
            }
          }
          for (final key in keysToRemove) {
            _detectionCounts.remove(key);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
      }
    }
  }

  Future<void> _captureAndFinish() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _detectionTimer?.cancel();

    setState(() {
      _isDetecting = true;
    });

    try {
      // Capture final image
      final XFile imageFile = await _cameraController!.takePicture();

      // Send to detection API for final result
      final result = await _detectionService.detectIngredients(imageFile);

      if (mounted) {
        Navigator.pop(context);
        widget.onDetectionComplete(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detection failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        // Restart periodic detection
        _startPeriodicDetection();
      }
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview or error message
          if (!_isCameraAvailable)
            _buildErrorState()
          else if (!_isInitialized)
            _buildLoadingState()
          else
            _buildCameraPreview(),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        kIsWeb ? 'Webcam Detection' : 'Live Detection',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isDetecting)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Scanning...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Detection overlays
          if (_isInitialized && _currentDetections.isNotEmpty)
            _buildDetectionOverlay(),

          // Confirmed ingredients panel
          if (_confirmedIngredients.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 120,
              child: _buildConfirmedIngredientsPanel(),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    _buildControlButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => Navigator.pop(context),
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: _isDetecting ? null : _captureAndFinish,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isDetecting
                                ? Colors.grey
                                : AppColors.primary,
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),

                    // Switch camera button
                    _buildControlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Flip',
                      onTap: _cameras.length > 1 ? _switchCamera : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final previewSize = _cameraController!.value.previewSize;
    // On web, previewSize may be null — use simple expanded preview
    if (previewSize == null) {
      return Center(child: CameraPreview(_cameraController!));
    }
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionOverlay() {
    final filteredDetections = _currentDetections.where((d) => d.name != null).toList();
    return Positioned.fill(
      child: Stack(
        children: filteredDetections.asMap().entries.map((entry) {
          final index = entry.key;
          final detection = entry.value;
          // Only show if we have bounding box
          if (detection.bbox.isEmpty || detection.bbox.length < 4) {
            return const SizedBox.shrink();
          }

          final confidence = (detection.confidence * 100).toInt();
          final isHighConfidence = detection.confidence >= 0.7;
          final color = isHighConfidence ? AppColors.success : AppColors.warning;

          return Positioned(
            top: 80 + (index * 60),
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHighConfidence ? Icons.check_circle : Icons.help_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detection.name!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$confidence%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConfirmedIngredientsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'Confirmed Ingredients',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _confirmedIngredients.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap != null
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            child: Icon(
              icon,
              color: onTap != null ? Colors.white : Colors.white38,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: onTap != null ? Colors.white : Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Camera not available',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Use Gallery Instead'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    final currentDirection = _cameraController?.description.lensDirection;
    final newCamera = _cameras.firstWhere(
      (c) => c.lensDirection != currentDirection,
      orElse: () => _cameras.first,
    );

    _detectionTimer?.cancel();
    await _cameraController?.dispose();

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {});
        _startPeriodicDetection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch camera: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        // Try to go back since camera is broken
        Navigator.pop(context);
      }
    }
  }
}
