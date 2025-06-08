import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../utils/api_services.dart';

class LoginController {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// 🔐 Login Method
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    String message = '';
    bool success = false;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final Map<String, dynamic> body = {
          "email": email,
          "password": password,
        };

        debugPrint("📤 Submitting Login Payload (Attempt ${retryCount + 1}/$maxRetries):");
        body.forEach((key, value) => debugPrint("   $key: $value"));

        final response = await ApiService.postRequest('/users/login/', body);

        debugPrint("🔹 Login API Response: $response");

        // Handle 503 Service Unavailable
        if (response['status'] == 'error' && response['statusCode'] == 503) {
          if (retryCount < maxRetries - 1) {
            retryCount++;
            debugPrint("⚠️ Server unavailable (503). Retrying in ${retryDelay.inSeconds} seconds...");
            await Future.delayed(retryDelay);
            continue;
          } else {
            message = "Server is temporarily unavailable. Please try again in a few moments.";
            return {"success": false, "message": message, "isServerDown": true};
          }
        }

        // Handle other errors
        if (response['status'] == 'error') {
          message = response['message'] ?? 'Login failed';
          if (response['statusCode'] == 401) {
            message = 'Invalid email or password';
          }
          return {"success": false, "message": message};
        }

        if (response.containsKey('access') && response.containsKey('refresh')) {
          message = "Login successful";
          success = true;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', response['access']);
          await prefs.setString('refresh_token', response['refresh']);
          await prefs.setBool('isLoggedIn', true);

          final user = {
            "user_id": response["user_id"],
            "email": response["email"],
            "first_name": response["first_name"],
            "last_name": response["last_name"],
            "role": response["role"],
          };
          await prefs.setString('userData', json.encode(user));
          break; // Exit the retry loop on success
        } else {
          message = "Invalid server response";
          debugPrint("❌ Invalid server response structure: $response");
        }
      } on SocketException catch (_) {
        message = "No internet connection";
        debugPrint("❌ Network error during login");
        break; // Don't retry on network errors
      } catch (e) {
        debugPrint("❌ Login Error: $e");
        message = "Login failed. Please try again.";
        if (retryCount < maxRetries - 1) {
          retryCount++;
          debugPrint("⚠️ Unexpected error. Retrying in ${retryDelay.inSeconds} seconds...");
          await Future.delayed(retryDelay);
          continue;
        }
        break;
      }
    }

    return {"success": success, "message": message};
  }

  /// 📧 Send Reset Password Email
  static Future<Map<String, dynamic>> sendResetEmail(String email) async {
    String message = '';
    bool success = false;

    try {
      final Map<String, dynamic> body = {"email": email};

      debugPrint("📤 Sending reset email to $email");
      final response = await ApiService.postRequest('/users/forgot-password/', body);

      debugPrint("🔹 Forgot Password API Response: $response");

      if (response['status'] == 'error') {
        return {
          "success": false,
          "message": response['message'] ?? 'Failed to send reset link'
        };
      }

      if (response.containsKey('message')) {
        message = response['message'];
        success = true;
      } else {
        message = "Failed to send reset link.";
      }
    } on SocketException catch (_) {
      message = "No internet connection";
    } catch (e) {
      debugPrint("❌ Forgot Password Error: $e");
      message = "An error occurred. Try again.";
    }

    return {"success": success, "message": message};
  }

  /// 🔄 Reset Password
  static Future<Map<String, dynamic>> resetPassword(String uid, String token, String newPassword) async {
    String message = '';
    bool success = false;

    try {
      final Map<String, dynamic> body = {
        "uid": uid,
        "token": token,
        "new_password": newPassword,
      };

      debugPrint("📤 Resetting password with UID: $uid & Token: $token");
      final response = await ApiService.postRequest('/users/reset-password/', body);

      debugPrint("🔹 Reset Password API Response: $response");

      if (response['status'] == 'error') {
        return {
          "success": false,
          "message": response['message'] ?? 'Password reset failed'
        };
      }

      if (response.containsKey('message')) {
        message = response['message'];
        success = true;
      } else {
        message = "Password reset failed.";
      }
    } on SocketException catch (_) {
      message = "No internet connection";
    } catch (e) {
      debugPrint("❌ Reset Password Error: $e");
      message = "An error occurred. Try again.";
    }

    return {"success": success, "message": message};
  }
}
