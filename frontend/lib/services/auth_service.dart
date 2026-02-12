import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user.dart';
import '../utils/api_config.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
    String? phone,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'address': address,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Save tokens
        await _saveTokens(
          data['access_token'],
          data['refresh_token'],
        );

        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'message': data['message'],
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'error': data['error'] ?? 'Please check your input and try again',
        };
      } else {
        return {
          'success': false,
          'error': 'Something went wrong. Please try again later.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': _friendlyError(e),
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save tokens
        await _saveTokens(
          data['access_token'],
          data['refresh_token'],
        );

        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'message': data['message'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': data['error'] ?? 'Incorrect email or password',
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'error': data['error'] ?? 'Please fill in all required fields',
        };
      } else {
        return {
          'success': false,
          'error': 'Something went wrong. Please try again later.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': _friendlyError(e),
      };
    }
  }

  // Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No access token found',
        };
      }

      final response = await http.get(
        Uri.parse(ApiConfig.me),
        headers: ApiConfig.authHeaders(token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': User.fromJson(data['user']),
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': _friendlyError(e),
      };
    }
  }

  // Refresh access token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.refresh),
        headers: ApiConfig.authHeaders(refreshToken),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAccessToken(data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) return false;

    // Check if token is expired
    if (JwtDecoder.isExpired(token)) {
      // Try to refresh token
      return await refreshAccessToken();
    }

    return true;
  }

  // Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Private: Save tokens
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  // Private: Save access token only
  Future<void> _saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated. Please log in again.',
        };
      }

      final response = await http.post(
        Uri.parse(ApiConfig.changePassword),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': _friendlyError(e),
      };
    }
  }

  // Convert raw exceptions to user-friendly messages
  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('failed to fetch') ||
        msg.contains('connection refused') ||
        msg.contains('socketexception') ||
        msg.contains('handshakeexception') ||
        msg.contains('clientexception')) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }
    if (msg.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    if (msg.contains('formatexception')) {
      return 'Received an unexpected response from the server.';
    }
    return 'Something went wrong. Please try again later.';
  }
}
