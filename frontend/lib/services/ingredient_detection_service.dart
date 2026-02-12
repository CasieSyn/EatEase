import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/ingredient.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

/// Service for ingredient detection from images using YOLO
class IngredientDetectionService {
  final AuthService _authService = AuthService();

  /// Submit feedback to correct AI detection (helps the system learn)
  Future<bool> submitDetectionFeedback(List<DetectionCorrection> corrections) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ingredients/detect/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'corrections': corrections.map((c) => c.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to submit feedback');
      }
    } catch (e) {
      throw Exception('Error submitting feedback: $e');
    }
  }

  /// Detect ingredients from image file
  Future<IngredientDetectionResult> detectIngredients(XFile imageFile) async {
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
      if (kIsWeb) {
        // For web, use bytes
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );
      } else {
        // For mobile, use path
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );
      }

      // Send request with timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Detection request timed out. Please try again.'),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IngredientDetectionResult.fromJson(data as Map<String, dynamic>);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to detect ingredients: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Detection timed out. Please check your connection and try again.');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw Exception(msg);
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
  final String? name;
  final double confidence;
  final List<double> bbox;
  final String? sourceClass;  // yolo_class or google_label
  final String source;  // 'yolo', 'label', or 'object'

  Detection({
    this.name,
    required this.confidence,
    required this.bbox,
    this.sourceClass,
    required this.source,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      name: json['name'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      bbox: json['bbox'] != null
          ? (json['bbox'] as List<dynamic>).map((e) => (e as num).toDouble()).toList()
          : [],
      sourceClass: json['yolo_class'] as String? ?? json['google_label'] as String?,
      source: json['source'] as String? ?? 'yolo',
    );
  }

  /// Get confidence as percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}

/// Represents a correction to send to the backend for learning
class DetectionCorrection {
  final String detectedLabel;  // What Google Vision detected
  final String? aiMapped;      // What AI mapped it to
  final String correctIngredient;  // What user says it actually is

  DetectionCorrection({
    required this.detectedLabel,
    this.aiMapped,
    required this.correctIngredient,
  });

  Map<String, dynamic> toJson() => {
    'detected_label': detectedLabel,
    'ai_mapped': aiMapped,
    'correct_ingredient': correctIngredient,
  };
}
