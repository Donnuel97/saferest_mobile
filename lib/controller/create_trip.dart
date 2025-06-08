import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/api_services.dart';
import '../const/const_api.dart';

class LocationController {
  // Singleton pattern for better resource management
  static LocationController? _instance;
  static LocationController get instance => _instance ??= LocationController._();
  LocationController._();

  // Enhanced caching with LRU mechanism
  static final Map<String, Map<String, dynamic>> _locationCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final List<String> _cacheKeys = []; // For LRU tracking
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const int _maxCacheSize = 100;

  // Connection pool for HTTP requests
  static final http.Client _httpClient = http.Client();

  // Dispose method for cleanup
  static void dispose() {
    _httpClient.close();
  }

  static bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  static void _updateCache(String key, Map<String, dynamic> data) {
    // Implement LRU cache eviction
    if (_locationCache.length >= _maxCacheSize) {
      final oldestKey = _cacheKeys.removeAt(0);
      _locationCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }

    _locationCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    // Update LRU order
    _cacheKeys.remove(key);
    _cacheKeys.add(key);
  }

  static Map<String, dynamic>? _getFromCache(String key) {
    if (_locationCache.containsKey(key) && _isCacheValid(key)) {
      // Update LRU order
      _cacheKeys.remove(key);
      _cacheKeys.add(key);
      return _locationCache[key];
    }
    return null;
  }

  // Optimized with better error handling and performance
  static Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      // Check if location services are enabled first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'message': 'Location services are disabled. Please enable them in settings.',
        };
      }

      // Streamlined permission handling
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return {
          'success': false,
          'message': permission == LocationPermission.deniedForever
              ? 'Location permissions permanently denied. Please enable in settings.'
              : 'Location permission denied',
        };
      }

      // Get position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Batch reverse geocoding with error handling
      String locationName = 'Unknown location';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 10));

        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          locationName = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.country
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      } catch (e) {
        debugPrint("⚠️ Geocoding failed: $e");
        // Continue with coordinates even if geocoding fails
      }

      return {
        'success': true,
        'locationData': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'name': locationName,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp?.toIso8601String(),
        },
      };
    } on LocationServiceDisabledException {
      return {
        'success': false,
        'message': 'Location services are disabled. Please enable them in settings.',
      };
    } on PermissionDeniedException {
      return {
        'success': false,
        'message': 'Location permissions denied. Please grant permission in settings.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Location request timed out. Please try again.',
      };
    } catch (e) {
      debugPrint("❌ Location Error: $e");
      return {
        'success': false,
        'message': 'Failed to get current location: ${e.toString()}',
      };
    }
  }

  // Optimized with better caching and error handling
  static Future<Map<String, dynamic>> getLocationCoordinates(String location) async {
    if (location.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Location cannot be empty',
        'locationData': {},
      };
    }

    final cacheKey = location.toLowerCase().trim();

    // Check cache first
    final cachedData = _getFromCache(cacheKey);
    if (cachedData != null) {
      debugPrint("📋 Using cached data for: $location");
      return cachedData;
    }

    try {
      final String url = '/trips/location-coordinates/?location=${Uri.encodeComponent(location)}';
      debugPrint("📤 Fetching Location Coordinates for: $location");

      final response = await ApiService.getRequest(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out after 15 seconds'),
      );

      debugPrint("🔹 Location Coordinates API Response: $response");

      if (response.containsKey('latitude') && response.containsKey('longitude')) {
        final locationData = {
          "latitude": (response['latitude'] as num).toDouble(),
          "longitude": (response['longitude'] as num).toDouble(),
          "name": response['name']?.toString() ?? location,
        };

        final result = {
          "success": true,
          "message": "Location coordinates fetched successfully",
          "locationData": locationData
        };

        // Cache the successful result
        _updateCache(cacheKey, result);

        // Background storage in SharedPreferences
        _storeLocationOffline(location, locationData).catchError((e) {
          debugPrint("⚠️ Failed to cache location offline: $e");
        });

        return result;
      } else {
        return {
          "success": false,
          "message": response['message'] ?? "Location not found or invalid.",
          "locationData": {}
        };
      }
    } on TimeoutException {
      return await _handleOfflineLocation(location, "Request timed out. Please try again.");
    } on SocketException {
      return await _handleOfflineLocation(location, "No internet connection");
    } catch (e) {
      debugPrint("❌ Location Fetch Error: $e");
      return await _handleOfflineLocation(location, "Failed to fetch location coordinates. Please try again.");
    }
  }

  // Helper method for offline location handling
  static Future<Map<String, dynamic>> _handleOfflineLocation(String location, String errorMessage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('${location}_lat');
      final long = prefs.getDouble('${location}_long');
      final timestamp = prefs.getString('${location}_timestamp');

      if (lat != null && long != null && timestamp != null) {
        final savedTime = DateTime.parse(timestamp);
        if (DateTime.now().difference(savedTime) < const Duration(days: 7)) {
          return {
            "success": true,
            "message": "Using saved location data (offline)",
            "locationData": {
              "latitude": lat,
              "longitude": long,
              "name": location,
            }
          };
        }
      }
    } catch (e) {
      debugPrint("❌ Error retrieving cached location: $e");
    }

    return {
      "success": false,
      "message": errorMessage,
      "locationData": {}
    };
  }

  // Helper method for background storage
  static Future<void> _storeLocationOffline(String location, Map<String, dynamic> locationData) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble('${location}_lat', locationData['latitude']),
      prefs.setDouble('${location}_long', locationData['longitude']),
      prefs.setString('${location}_timestamp', DateTime.now().toIso8601String()),
    ]);
  }

  // Optimized createTrip with better error handling
  static Future<String> createTrip({
    required String title,
    required String tripType,
    required String rideDescription,
    List<Map<String, dynamic>>? watchers,
    String? logisticsCompany,
    String? plateNumber,
    double? departureLat,
    double? departureLong,
    double? arrivalLat,
    double? arrivalLong,
    String? departureStation,
    String? arrivalStation,
    String? departureDate,
    String? arrivalDate, 
  }) async {
    // Input validation
    if (title.trim().isEmpty || rideDescription.trim().isEmpty) {
      return "Title and description are required";
    }

    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("access_token");

        if (token == null || token.isEmpty) {
          return "Access token not found. Please login again.";
        }

        final body = _buildTripRequestBody(
          title: title,
          tripType: tripType,
          rideDescription: rideDescription,
          watchers: watchers,
          logisticsCompany: logisticsCompany,
          plateNumber: plateNumber,
          departureLat: departureLat,
          departureLong: departureLong,
          arrivalLat: arrivalLat,
          arrivalLong: arrivalLong,
          departureStation: departureStation,
          arrivalStation: arrivalStation,
          departureDate: departureDate,
          arrivalDate: arrivalDate,
        );

        debugPrint("📦 Trip Payload (Attempt ${attempt + 1}): ${jsonEncode(body)}");

        final response = await _httpClient.post(
          Uri.parse("${ConstApi.baseUrl}/trips/"),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));

        debugPrint("🔹 Trip Creation Response: ${response.body}");
        debugPrint("🔹 Response Status Code: ${response.statusCode}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          return responseData["message"] ?? "Trip created successfully";
        } else if (response.statusCode == 503 && attempt < maxRetries - 1) {
          debugPrint("⚠️ Server unavailable (503). Retrying in ${retryDelay.inSeconds} seconds...");
          await Future.delayed(retryDelay);
          continue;
        } else {
          return _handleTripCreationError(response);
        }
      } on TimeoutException {
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
          continue;
        }
        return "Request timed out. Please try again.";
      } on SocketException {
        return "No internet connection. Please check your network and try again.";
      } catch (e) {
        debugPrint("❌ Trip Creation Error: $e");
        if (attempt < maxRetries - 1) {
          debugPrint("⚠️ Retrying in ${retryDelay.inSeconds} seconds...");
          await Future.delayed(retryDelay);
          continue;
        }
        return "Something went wrong while creating the trip. Please try again.";
      }
    }
    return "Failed to create trip after $maxRetries attempts. Please try again later.";
  }

  // Helper method to build trip request body
  static Map<String, dynamic> _buildTripRequestBody({
    required String title,
    required String tripType,
    required String rideDescription,
    List<Map<String, dynamic>>? watchers,
    String? logisticsCompany,
    String? plateNumber,
    double? departureLat,
    double? departureLong,
    double? arrivalLat,
    double? arrivalLong,
    String? departureStation,
    String? arrivalStation,
    String? departureDate,
    String? arrivalDate,
  }) {
    // Format watchers correctly
    final formattedWatchers = watchers?.map((watcher) => {
      "id": watcher['user'],  // Change 'user' to 'id' as expected by the API
    }).toList() ?? [];

    debugPrint("Formatted watchers: $formattedWatchers"); // Debug print

    return {
      "title": title.trim(),
      "trip_type": tripType,
      "ride_description": rideDescription.trim(),
      "logistics_company": logisticsCompany?.trim() ?? "",
      "plate_number": plateNumber?.trim() ?? "",
      "arrival_lat": arrivalLat?.toStringAsFixed(6) ?? "",
      "arrival_long": arrivalLong?.toStringAsFixed(6) ?? "",
      "departure_lat": departureLat?.toStringAsFixed(6) ?? "",
      "departure_long": departureLong?.toStringAsFixed(6) ?? "",
      "departure_station": departureStation?.trim() ?? "",
      "arrival_station": arrivalStation?.trim() ?? "",
      "departure_date": departureDate ?? "",
      "arrival_date": arrivalDate ?? "",
      "watchers": formattedWatchers,
    };
  }

  // Helper method to handle trip creation errors
  static String _handleTripCreationError(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);

      if (errorData.containsKey('non_field_errors')) {
        return errorData['non_field_errors'][0] ?? "Validation error occurred";
      } else if (errorData.containsKey('message')) {
        return errorData['message'];
      } else {
        final errors = <String>[];
        errorData.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errors.add("$key: ${value[0]}");
          } else if (value is String) {
            errors.add("$key: $value");
          }
        });
        return errors.isNotEmpty ? "Validation failed: ${errors.join('; ')}" : "Unknown error occurred";
      }
    } catch (e) {
      return "Error: ${response.statusCode} - Failed to create trip. Please try again.";
    }
  }

  // Optimized friends fetching with unified method
  static Future<Map<String, dynamic>> getFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Access token not found. Please login again.',
          'data': []
        };
      }

      final response = await _httpClient.get(
        Uri.parse("${ConstApi.baseUrl}/users/friends/"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint("🔹 Friends Fetch Response: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Friends fetched successfully',
          'data': responseData is List ? responseData : []
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch friends',
          'data': []
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'data': []
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
        'data': []
      };
    } catch (e) {
      debugPrint("❌ Error fetching friends: $e");
      return {
        'success': false,
        'message': 'An error occurred while fetching friends',
        'data': []
      };
    }
  }

  // Deprecated method - kept for backward compatibility
  @deprecated
  static Future<Map<String, dynamic>> getFriendRequests() async {
    return getFriends();
  }
}