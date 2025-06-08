import 'dart:convert';
import 'package:flutter/cupertino.dart';
import '../utils/api_services.dart';
import '../const/const_api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/routes.dart';

class TripController {
  static const String baseUrl = ConstApi.baseUrl;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static Map<String, dynamic> _tripCache = {};
  static DateTime? _lastCacheTime;

  // Check if cache is valid
  static bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheExpiry;
  }

  static Future<List<Map<String, dynamic>>> fetchTrips({bool forceRefresh = false}) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh && _isCacheValid() && _tripCache.containsKey('trips')) {
        final cachedTrips = _tripCache['trips'] as List;
        return List<Map<String, dynamic>>.from(cachedTrips);
      }

      final response = await ApiService.getRequest('/trips/');
      
      if (response is List) {
        final trips = List<Map<String, dynamic>>.from(response);
        _tripCache['trips'] = trips;
        _lastCacheTime = DateTime.now();
        return trips;
      } 

      debugPrint("❌ Unexpected response format");
      return [];

    } catch (e) {
      debugPrint("❌ Exception fetching trips: $e");
      // Return cached data if available during error
      if (_tripCache.containsKey('trips')) {
        final cachedTrips = _tripCache['trips'] as List;
        return List<Map<String, dynamic>>.from(cachedTrips);
      }
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchWatcherTrips() async {
    try {
      final response = await ApiService.getRequest('/trips/watched-trips/');
      debugPrint("📥 Watcher Trips Response: $response");

      // Handle different response types
      Map<String, dynamic> responseData;

      if (response is String) {
        try {
          responseData = jsonDecode(response);
        } catch (e) {
          debugPrint("❌ Failed to parse watcher trips response as JSON: $e");
          return [];
        }
      } else if (response is Map<String, dynamic>) {
        responseData = response;
      } else if (response is List) {
        // Handle case where API might return direct list (fallback)
        return List<Map<String, dynamic>>.from(response);
      } else {
        debugPrint("❌ Unexpected watcher trips response type: ${response.runtimeType}");
        return [];
      }

      // Check for error status
      if (responseData['status'] == 'error') {
        debugPrint("❌ Error fetching watcher trips: ${responseData['message']}");
        return [];
      }

      // Extract trips from the 'results' field
      if (responseData.containsKey('results') && responseData['results'] is List) {
        final List<dynamic> trips = responseData['results'];

        return List<Map<String, dynamic>>.from(trips.map((trip) => {
          'id': trip['id'],
          'title': trip['title'],
          'owner': trip['owner'], // This is now an object with id, name, email
          'ride_description': trip['ride_description'],
          'logistics_company': trip['logistics_company'],
          'plate_number': trip['plate_number'],
          'trip_type': trip['trip_type'],
          'trip_status': trip['trip_status'],
          'departure_station': trip['departure_station'],
          'arrival_station': trip['arrival_station'],
          'departure_date': trip['departure_date'],
          'arrival_date': trip['arrival_date'],
          'departure_lat': trip['departure_lat'],
          'departure_long': trip['departure_long'],
          'arrival_lat': trip['arrival_lat'],
          'arrival_long': trip['arrival_long'],
          'watcher_count': trip['watcher_count'],
        }));
      }

      // Handle case where 'data' field is used instead of 'results' (fallback)
      if (responseData.containsKey('data') && responseData['data'] is List) {
        final List<dynamic> trips = responseData['data'];
        return List<Map<String, dynamic>>.from(trips.map((trip) => {
          'id': trip['id'],
          'title': trip['title'],
          'owner': trip['owner'],
          'ride_description': trip['ride_description'],
          'logistics_company': trip['logistics_company'],
          'plate_number': trip['plate_number'],
          'trip_type': trip['trip_type'],
          'trip_status': trip['trip_status'],
          'departure_station': trip['departure_station'],
          'arrival_station': trip['arrival_station'],
          'departure_date': trip['departure_date'],
          'arrival_date': trip['arrival_date'],
          'departure_lat': trip['departure_lat'],
          'departure_long': trip['departure_long'],
          'arrival_lat': trip['arrival_lat'],
          'arrival_long': trip['arrival_long'],
          'watcher_count': trip['watcher_count'],
        }));
      }

      debugPrint("❌ No valid trips data found in response");
      debugPrint("Response keys: ${responseData.keys.toList()}");
      return [];

    } catch (e) {
      debugPrint("❌ Exception in fetchWatcherTrips: $e");
      return [];
    }
  }

  /// Generic POST for trip actions with retry logic
  static Future<bool> postTripAction({
    required String tripId,
    required String action,
    required String lat,
    required String long,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final response = await ApiService.postRequest(
          '/trips/$tripId/$action/',
          {
            "lat": lat,
            "long": long,
          },
        );

        debugPrint("📤 POST $action Response (Attempt ${retryCount + 1}): $response");

        if (response['status'] != 'error') {
          // Invalidate cache on successful action
          _tripCache.clear();
          _lastCacheTime = null;
          return true;
        } else if (response['message']?.contains('503') ?? false) {
          if (retryCount < maxRetries - 1) {
            retryCount++;
            await Future.delayed(retryDelay);
            continue;
          }
        }
        return false;
      } catch (e) {
        debugPrint("❌ Error during $action trip (Attempt ${retryCount + 1}): $e");
        if (retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(retryDelay);
          continue;
        }
        return false;
      }
    }
    return false;
  }

  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<bool> _handleUnauthorized(BuildContext? context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    
    if (context != null && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context, 
        Routes.login,
        (route) => false,
      );
    }
    return false;
  }

  // Simplified action methods using the generic postTripAction
  static Future<bool> startTrip({
    required String tripId,
    required String lat,
    required String long,
    BuildContext? context,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;

      final response = await ApiService.postRequest(
        '/trips/$tripId/start/',
        {
          'lat': lat,
          'long': long,
        },
        extraHeaders: {'Authorization': 'Bearer $token'}
      );

      debugPrint('📤 Start Trip Response: $response');

      if (response['statusCode'] == 401) {
        await _handleUnauthorized(context);
        return false;
      }

      // Change this condition to check for successful statusCode
      return response['statusCode'] == 200;
    } catch (e) {
      debugPrint('❌ Error starting trip: $e');
      return false;
    }
  }

  static Future<bool> endTrip({
    required String tripId,
    required String lat,
    required String long,
  }) => postTripAction(tripId: tripId, action: 'end', lat: lat, long: long);

  static Future<bool> cancelTrip({
    required String tripId,
    required String lat,
    required String long,
  }) => postTripAction(tripId: tripId, action: 'cancel', lat: lat, long: long);

  // Clear cache manually if needed
  static void clearCache() {
    _tripCache.clear();
    _lastCacheTime = null;
  }
}
