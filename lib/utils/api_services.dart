import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saferest_mobile/const/const_api.dart';
import 'package:saferest_mobile/utils/routes.dart';
import 'package:saferest_mobile/utils/navigator_key.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String baseUrl = ConstApi.baseUrl;

  static String _buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // 🔐 Save JWT tokens and user data to local storage
  static Future<void> saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access']);
    await prefs.setString('refresh_token', data['refresh']);
    await prefs.setString('user_id', data['user_id']);
    await prefs.setString('email', data['email']);
  }

  // 📤 POST request (e.g., login, register)
  static Future<Map<String, dynamic>> postRequest(
      String endpoint,
      Map<String, dynamic> formData, {
        Map<String, String>? extraHeaders,
      }) async {
    final url = _buildUrl(endpoint);
    debugPrint("📤 Making POST request to: $url");
    debugPrint("📤 Request body: ${jsonEncode(formData)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          ...ConstApi.headers,
          'Content-Type': 'application/json',
          if (extraHeaders != null) ...extraHeaders,
        },
        body: jsonEncode(formData),
      );

      debugPrint("📥 Response status code: ${response.statusCode}");
      debugPrint("📥 Response body: ${response.body}");

      final result = await _handleResponse(response);  // Add await here
      debugPrint("🔄 Processed response: $result");

      // Fix the containsKey check
      if (result is Map<String, dynamic> &&
          result.containsKey('access') && 
          result.containsKey('refresh')) {
        await saveAuthData(result);
      }

      return result;
    } catch (e) {
      debugPrint("❌ POST request error: $e");
      return {'status': 'error', 'message': 'POST request error: $e'};
    }
  }

  // 📥 GET request
  static Future<dynamic> getRequest(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final requestHeaders = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers, // Merge any additional headers
      };

      final response = await http.get(
        Uri.parse(ConstApi.baseUrl + endpoint),
        headers: requestHeaders,
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Error in GET request: $e');
      return {
        'status': 'error',
        'message': 'Request failed',
        'statusCode': 500
      };
    }
  }

  // ⚙️ Response handler
  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
      return {
        'status': 'error',
        'message': 'User unauthenticated. Redirecting to login.',
        'statusCode': 401,
      };
    }

    try {
      final decodedResponse = json.decode(response.body);
      return {
        ...decodedResponse,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      debugPrint('❌ Error decoding response: $e');
      return {
        'status': 'error',
        'message': 'Invalid response format',
        'statusCode': response.statusCode,
      };
    }
  }

  // 🔓 Optional: Clear tokens
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
