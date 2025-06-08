import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/api_services.dart';

class RegisterController {
  static Future<String> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    String submissionMessage = '';

    try {
      final Map<String, dynamic> body = {
        "email": email,
        "password": password,
        "first_name": firstName,
        "last_name": lastName,
        if (phoneNumber != null && phoneNumber.isNotEmpty) "phone_number": phoneNumber,
      };

      debugPrint("📤 Submitting Registration Payload:");
      body.forEach((key, value) => debugPrint("   $key: $value"));

      final response = await ApiService.postRequest(
        '/users/',
        body,
      );

      debugPrint("🔹 Registration API Response: $response");

      if (response["status"] == true || response["success"] == true) {
        submissionMessage = response["message"] ?? "✅ Registration successful!";
      } else {
        if (response.containsKey('errors')) {
          final errors = response['errors'] as Map<String, dynamic>;
          final errorMessages = errors.entries
              .map((entry) => entry.value is List
              ? (entry.value as List).join(', ')
              : entry.value.toString())
              .join('\n');

          submissionMessage = errorMessages.isNotEmpty
              ? "⚠️ $errorMessages"
              : (response["message"] ?? "⚠️ Registration failed.");
        } else {
          submissionMessage = response["message"] ?? "⚠️ Registration failed.";
        }
      }
    } on SocketException catch (_) {
      submissionMessage = "🚫 Unable to connect. Please check your internet connection and try again.";
    } catch (e) {
      debugPrint("❌ Registration Error: $e");
      submissionMessage = "❌ Error submitting registration. Please try again.";
    }

    return submissionMessage;
  }

}
