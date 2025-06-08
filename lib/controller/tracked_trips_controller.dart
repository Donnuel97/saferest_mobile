import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../const/const_api.dart';

class TrackedTripsController {
  static const String baseUrl = ConstApi.baseUrl;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static Map<String, dynamic> _tripCache = {};
  static DateTime? _lastCacheTime;

  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  static Map<String, String> _getHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheExpiry;
  }

  static Future<List<Map<String, dynamic>>> fetchTrackedTrips({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _isCacheValid() && _tripCache.containsKey('tracked_trips')) {
        return List<Map<String, dynamic>>.from(_tripCache['tracked_trips']);
      }

      final token = await _getAuthToken();
      if (token == null) {
        debugPrint("⚠️ Access token not found");
        return [];
      }

      final response = await http.get(
        Uri.parse("$baseUrl/trips/watched-trips/"),
        headers: _getHeaders(token),
      );

      debugPrint("📥 Tracked Trips Fetch Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Extract the results array from the response object
        final List<dynamic> trips = responseData['results'] ?? [];

        // Optionally, you can also access the count
        final int tripCount = responseData['count'] ?? 0;
        debugPrint("📊 Total tracked trips count: $tripCount");

        _tripCache['tracked_trips'] = trips;
        _lastCacheTime = DateTime.now();
        return trips.cast<Map<String, dynamic>>();
      } else {
        debugPrint("❌ Failed to fetch tracked trips: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Exception fetching tracked trips: $e");
      if (_tripCache.containsKey('tracked_trips')) {
        return List<Map<String, dynamic>>.from(_tripCache['tracked_trips']);
      }
      return [];
    }
  }

  // Optional: Method to get both trips and count
  static Future<Map<String, dynamic>> fetchTrackedTripsWithCount({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _isCacheValid() && _tripCache.containsKey('tracked_trips_full')) {
        return Map<String, dynamic>.from(_tripCache['tracked_trips_full']);
      }

      final token = await _getAuthToken();
      if (token == null) {
        debugPrint("⚠️ Access token not found");
        return {'count': 0, 'results': []};
      }

      final response = await http.get(
        Uri.parse("$baseUrl/trips/watched-trips/"),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        _tripCache['tracked_trips_full'] = responseData;
        _tripCache['tracked_trips'] = responseData['results'] ?? [];
        _lastCacheTime = DateTime.now();

        return responseData;
      } else {
        debugPrint("❌ Failed to fetch tracked trips: ${response.statusCode}");
        return {'count': 0, 'results': []};
      }
    } catch (e) {
      debugPrint("❌ Exception fetching tracked trips: $e");
      if (_tripCache.containsKey('tracked_trips_full')) {
        return Map<String, dynamic>.from(_tripCache['tracked_trips_full']);
      }
      return {'count': 0, 'results': []};
    }
  }
}