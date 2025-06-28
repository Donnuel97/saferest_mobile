import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class FriendController {
  static const String _baseUrl = "https://saferestapi-h6p5.onrender.com";
  static const Duration _timeout = Duration(seconds: 30);
  static final NotificationService _notificationService = NotificationService();

  // Cache token to avoid multiple SharedPreferences calls
  static String? _cachedToken;
  static DateTime? _tokenCacheTime;
  static const Duration _tokenCacheExpiry = Duration(minutes: 5);

  static Future<String?> _getToken() async {
    // Return cached token if still valid
    if (_cachedToken != null &&
        _tokenCacheTime != null &&
        DateTime.now().difference(_tokenCacheTime!) < _tokenCacheExpiry) {
      return _cachedToken;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");

    if (token == null || token.isEmpty) {
      debugPrint("⚠️ Access token not found");
      _cachedToken = null;
      _tokenCacheTime = null;
      return null;
    }

    // Cache the token
    _cachedToken = token;
    _tokenCacheTime = DateTime.now();
    return token;
  }

  static Map<String, String> _getHeaders(String token, {bool includeContentType = false}) {
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  static Future<http.Response> _makeRequest(
      String method,
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not available');
    }

    final uri = Uri.parse("$_baseUrl$endpoint");
    final headers = _getHeaders(token, includeContentType: body != null);

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers).timeout(_timeout);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(_timeout);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  static Future<List<Map<String, dynamic>>> _parseListResponse(http.Response response, String operation) async {
    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } catch (e) {
        debugPrint("❌ Failed to parse $operation response: $e");
        return [];
      }
    } else {
      debugPrint("❌ Failed to $operation: ${response.statusCode} - ${response.body}");
      return [];
    }
  }

  static Future<bool> _parseBoolResponse(http.Response response, String operation) async {
    final success = response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204;
    if (!success) {
      debugPrint("❌ Failed to $operation: ${response.statusCode} - ${response.body}");
    }
    return success;
  }

  /// Clear cached token (useful for logout scenarios)
  static void clearTokenCache() {
    _cachedToken = null;
    _tokenCacheTime = null;
  }

  /// Fetch current friends
  static Future<List<Map<String, dynamic>>> fetchFriends() async {
    try {
      final response = await _makeRequest('GET', '/users/friends/');
      return await _parseListResponse(response, 'fetch friends');
    } catch (e) {
      debugPrint("❌ Error fetching friends: $e");
      return [];
    }
  }

  /// Fetch incoming friend requests
  static Future<List<Map<String, dynamic>>> fetchFriendRequests() async {
    try {
      final response = await _makeRequest('GET', '/friend_requests/');
      final requests = await _parseListResponse(response, 'fetch friend requests');
      
      // Show notifications for new friend requests
      for (final request in requests) {
        if (request['is_new'] == true) {
          final name = "${request['first_name']} ${request['last_name']}";
          await _notificationService.showFriendRequestNotification(
            title: 'New Friend Request',
            body: '$name sent you a friend request',
            payload: jsonEncode({
              'type': 'friend_request',
              'id': request['id'],
              'name': name,
            }),
          );
        }
      }
      
      return requests;
    } catch (e) {
      debugPrint("❌ Error fetching friend requests: $e");
      return [];
    }
  }

  /// Accept a friend request
  static Future<bool> acceptFriendRequest(String id) async {
    if (id.isEmpty) {
      debugPrint("❌ Invalid friend request ID");
      return false;
    }

    try {
      final response = await _makeRequest('POST', '/friend_requests/$id/accept/');
      final success = await _parseBoolResponse(response, 'accept friend request');
      
      if (success) {
        // Show notification for accepted request
        await _notificationService.showFriendRequestNotification(
          title: 'Friend Request Accepted',
          body: 'You are now friends',
          payload: jsonEncode({
            'type': 'friend_request_accepted',
            'id': id,
          }),
        );
      }
      
      return success;
    } catch (e) {
      debugPrint("❌ Error accepting friend request: $e");
      return false;
    }
  }

  /// Decline a friend request
  static Future<bool> declineFriendRequest(String id) async {
    if (id.isEmpty) {
      debugPrint("❌ Invalid friend request ID");
      return false;
    }

    try {
      final response = await _makeRequest('POST', '/friend_requests/$id/decline/');
      return await _parseBoolResponse(response, 'decline friend request');
    } catch (e) {
      debugPrint("❌ Error declining friend request: $e");
      return false;
    }
  }

  /// Send a friend request
  static Future<bool> sendFriendRequest(String id) async {
    if (id.isEmpty) {
      debugPrint("❌ Invalid user ID");
      return false;
    }

    try {
      final response = await _makeRequest('POST', '/friend_requests/$id/send/');
      final success = await _parseBoolResponse(response, 'send friend request');
      
      if (success) {
        // Show notification for sent request
        await _notificationService.showFriendRequestNotification(
          title: 'Friend Request Sent',
          body: 'Your friend request has been sent',
          payload: jsonEncode({
            'type': 'friend_request_sent',
            'id': id,
          }),
        );
      }
      
      return success;
    } catch (e) {
      debugPrint("❌ Error sending friend request: $e");
      return false;
    }
  }

  /// Send a watcher request
  static Future<bool> sendWatcherRequest(String tripId, String userId) async {
    if (tripId.isEmpty || userId.isEmpty) {
      debugPrint("❌ Invalid trip or user ID");
      return false;
    }

    try {
      final response = await _makeRequest('POST', '/trips/$tripId/watchers/$userId/');
      final success = await _parseBoolResponse(response, 'send watcher request');
      
      if (success) {
        // Show notification for watcher request
        await _notificationService.showWatcherNotification(
          title: 'Watcher Request Sent',
          body: 'You have been invited to watch a trip',
          payload: jsonEncode({
            'type': 'watcher_request',
            'trip_id': tripId,
            'user_id': userId,
          }),
        );
      }
      
      return success;
    } catch (e) {
      debugPrint("❌ Error sending watcher request: $e");
      return false;
    }
  }

  /// Accept a watcher request
  static Future<bool> acceptWatcherRequest(String tripId) async {
    if (tripId.isEmpty) {
      debugPrint("❌ Invalid trip ID");
      return false;
    }

    try {
      final response = await _makeRequest('POST', '/trips/$tripId/watchers/accept/');
      final success = await _parseBoolResponse(response, 'accept watcher request');
      
      if (success) {
        // Show notification for accepted watcher request
        await _notificationService.showWatcherNotification(
          title: 'Watcher Request Accepted',
          body: 'You are now watching this trip',
          payload: jsonEncode({
            'type': 'watcher_request_accepted',
            'trip_id': tripId,
          }),
        );
      }
      
      return success;
    } catch (e) {
      debugPrint("❌ Error accepting watcher request: $e");
      return false;
    }
  }

  /// Decline a watcher request
  static Future<bool> declineWatcherRequest(String tripId) async {
    if (tripId.isEmpty) {
      debugPrint("❌ Invalid trip ID");
      return false;
    }

    try {
      final response = await _makeRequest('POST', '/trips/$tripId/watchers/decline/');
      return await _parseBoolResponse(response, 'decline watcher request');
    } catch (e) {
      debugPrint("❌ Error declining watcher request: $e");
      return false;
    }
  }

  /// Search users by name or email
  static Future<List<Map<String, dynamic>>> searchUsers(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      debugPrint("❌ Search term cannot be empty");
      return [];
    }

    try {
      final response = await _makeRequest(
        'POST',
        '/users/search/',
        body: {'search': searchTerm.trim()},
      );
      return await _parseListResponse(response, 'search users');
    } catch (e) {
      debugPrint("❌ Error searching users: $e");
      return [];
    }
  }

  /// Batch operations for better performance
  static Future<Map<String, List<Map<String, dynamic>>>> fetchFriendsAndRequests() async {
    try {
      final results = await Future.wait([
        fetchFriends(),
        fetchFriendRequests(),
      ]);

      return {
        'friends': results[0],
        'requests': results[1],
      };
    } catch (e) {
      debugPrint("❌ Error fetching friends and requests: $e");
      return {
        'friends': <Map<String, dynamic>>[],
        'requests': <Map<String, dynamic>>[],
      };
    }
  }
}