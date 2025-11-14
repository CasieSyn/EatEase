import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ingredient.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

/// Service for ingredient detection from images using YOLO
class IngredientDetectionService {
  final AuthService _authService = AuthService();

  /// Detect ingredients from image file
  Future<IngredientDetectionResult> detectIngredients(File imageFile) async {
    try {
      // Validate token and refresh if expired
      final isValid = await _authService.isLoggedIn();
      if (!isValid) {
        throw Exception('Authentication failed. Please login again.');
      }

      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/ingredients/detect'),
      );

      // Add auth header
      request.headers['Authorization'] = 'Bearer $token';

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IngredientDetectionResult.fromJson(data as Map<String, dynamic>);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to detect ingredients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error detecting ingredients: $e');
    }
  }
}

/// Result from ingredient detection
class IngredientDetectionResult {
  final String message;
  final List<Detection> detections;
  final List<String> ingredientNames;
  final List<String> highConfidenceIngredients;
  final List<Ingredient> detectedIngredients;
  final int totalDetected;

  IngredientDetectionResult({
    required this.message,
    required this.detections,
    required this.ingredientNames,
    required this.highConfidenceIngredients,
    required this.detectedIngredients,
    required this.totalDetected,
  });

  factory IngredientDetectionResult.fromJson(Map<String, dynamic> json) {
    return IngredientDetectionResult(
      message: json['message'],
      detections: (json['detections'] as List<dynamic>)
          .map((d) => Detection.fromJson(d as Map<String, dynamic>))
          .toList(),
      ingredientNames: List<String>.from(json['ingredient_names']),
      highConfidenceIngredients: List<String>.from(json['high_confidence_ingredients']),
      detectedIngredients: (json['detected_ingredients'] as List<dynamic>)
          .map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalDetected: json['total_detected'],
    );
  }
}

/// Individual detection with confidence and location
class Detection {
  final String name;
  final double confidence;
  final List<double> bbox;
  final String yoloClass;

  Detection({
    required this.name,
    required this.confidence,
    required this.bbox,
    required this.yoloClass,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      name: json['name'],
      confidence: (json['confidence'] as num).toDouble(),
      bbox: (json['bbox'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      yoloClass: json['yolo_class'],
    );
  }

  /// Get confidence as percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}
