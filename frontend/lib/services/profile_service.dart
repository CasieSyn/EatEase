import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

class ProfileService {
  final AuthService _authService = AuthService();

  /// Get user profile
  Future<User> getProfile() async {
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

      final response = await http.get(
        Uri.parse(ApiConfig.userProfile),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
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

      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phone != null) body['phone'] = phone;

      final response = await http.put(
        Uri.parse(ApiConfig.userProfile),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  /// Upload profile photo
  Future<User> uploadProfilePhoto(File imageFile) async {
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
        Uri.parse('${ApiConfig.baseUrl}/api/users/profile/photo'),
      );

      // Add auth header
      request.headers['Authorization'] = 'Bearer $token';

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
        ),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to upload photo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading profile photo: $e');
    }
  }
}
