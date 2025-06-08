import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../const/const_api.dart';
import 'dart:convert';

class TripStatsController {
  static Future<Map<String, int>> getTripStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        debugPrint("⚠️ No access token found");
        return {'pending': 0, 'completed': 0, 'friends': 0};
      }

      final Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await ApiService.getRequest(
        '/trips/count/',
        headers: headers,
      );

      debugPrint("🔹 Trip Stats API Raw Response: $response");

      if (response is Map<String, dynamic> && response.containsKey('trip_counts')) {
        final Map<String, dynamic> tripCounts = Map<String, dynamic>.from(response['trip_counts']);
        final int friendsCount = (response['friends_count'] ?? 0) as int;

        debugPrint("📊 Parsed Trip Counts: $tripCounts");
        debugPrint("👥 Friends Count: $friendsCount");

        return {
          'pending': (tripCounts['PENDING'] ?? 0) as int,
          'completed': (tripCounts['COMPLETED'] ?? 0) as int,
          'friends': friendsCount,
        };
      } else {
        debugPrint("❌ Invalid response format: $response");
        return {'pending': 0, 'completed': 0, 'friends': 0};
      }
    } on SocketException {
      debugPrint("❌ Network error fetching trip stats.");
      return {'pending': 0, 'completed': 0, 'friends': 0};
    } catch (e) {
      debugPrint("❌ Error fetching trip stats: $e");
      return {'pending': 0, 'completed': 0, 'friends': 0};
    }
  }
}
