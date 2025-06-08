import 'dart:convert';
import 'package:flutter/cupertino.dart';
import '../utils/api_services.dart';
import '../const/const_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class UserController {
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static Map<String, dynamic>? _userCache;
  static DateTime? _lastCacheTime;

  // Check if cached data is still valid
  static bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheExpiry;
  }

  /// Fetch user details from /users/me/ endpoint
  static Future<Map<String, dynamic>?> fetchUserDetails({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _isCacheValid() && _userCache != null) {
        return _userCache!;
      }

      final response = await ApiService.getRequest('/users/'); // Change endpoint to get current user
      debugPrint("📥 User Fetch Response: $response");

      Map<String, dynamic>? parsedData;

      if (response is Map<String, dynamic>) {
        parsedData = response;
      } else if (response is List) {
        // If response is a list, find the current user (you might need to get the current user's ID from preferences)
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getString('user_id');
        
        if (currentUserId != null) {
          parsedData = response.firstWhere(
            (user) => user['id'] == currentUserId,
            orElse: () => null,
          );
        }
      } else if (response is String) {
        try {
          final decoded = jsonDecode(response);
          if (decoded is List) {
            // Handle list response after JSON decode
            final prefs = await SharedPreferences.getInstance();
            final currentUserId = prefs.getString('user_id');
            
            if (currentUserId != null) {
              parsedData = decoded.firstWhere(
                (user) => user['id'] == currentUserId,
                orElse: () => null,
              );
            }
          } else if (decoded is Map<String, dynamic>) {
            parsedData = decoded;
          }
        } catch (e) {
          debugPrint("❌ Failed to decode user JSON: $e");
          return null;
        }
      }

      if (parsedData != null &&
          parsedData.containsKey('id') &&
          parsedData.containsKey('email')) {
        _userCache = parsedData;
        _lastCacheTime = DateTime.now();
        return parsedData;
      }

      debugPrint("❌ Could not find current user data");
      return null;
    } catch (e) {
      debugPrint("❌ Exception fetching user details: $e");
      return _userCache; // fallback to cache if available
    }
  }

  /// Manually clear cached user data
  static void clearCache() {
    _userCache = null;
    _lastCacheTime = null;
  }

  /// Update user profile information
  static Future<Map<String, dynamic>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? location,
    File? avatarFile,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'status': false,
          'message': 'Authentication token not found',
        };
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ConstApi.baseUrl}/users/profile/edit/'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add text fields if they are not null
      if (firstName != null) request.fields['first_name'] = firstName;
      if (lastName != null) request.fields['last_name'] = lastName;
      if (email != null) request.fields['email'] = email;
      if (phoneNumber != null) request.fields['phone_number'] = phoneNumber;
      if (location != null) request.fields['location'] = location;

      // Add avatar file if provided
      if (avatarFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar_url',
            avatarFile.path,
            contentType: MediaType('image', 'jpeg'), // Adjust content type as needed
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📤 Update Profile Response Status: ${response.statusCode}');
      debugPrint('📤 Update Profile Response Body: ${response.body}');

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update local cache if needed
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', response.body);

        return {
          'status': true,
          'message': decodedResponse['message'],
          'data': decodedResponse['data'],
        };
      }

      return {
        'status': false,
        'message': decodedResponse['message'] ?? 'Failed to update profile',
        'errors': decodedResponse['errors'],
      };

    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      return {
        'status': false,
        'message': 'An error occurred while updating profile',
        'error': e.toString(),
      };
    }
  }

  // Helper method to get auth token
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}
