import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _apiKey = 'AIzaSyB30ed-a_mKI1FAzfhDye4zGg45kthVUmc'; // Replace with your actual API key

  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
    bool alternatives = false,
    List<LatLng>? waypoints,
  }) async {
    try {
      String waypointsParam = '';
      if (waypoints != null && waypoints.isNotEmpty) {
        waypointsParam = '&waypoints=${waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|')}';
      }

      final String url = '$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=$travelMode&'
          'alternatives=$alternatives$waypointsParam&'
          'key=$_apiKey';

      print('Directions API URL: $url'); // Debug log

      final response = await http.get(Uri.parse(url));
      print('API Response Status: ${response.statusCode}'); // Debug log
      print('API Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return DirectionsResult.fromMap(data);
        } else {
          print('Directions API error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
          throw Exception('Directions API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  static List<LatLng> decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}

class DirectionsResult {
  final List<DirectionsRoute> routes;
  final String status;

  DirectionsResult({
    required this.routes,
    required this.status,
  });

  factory DirectionsResult.fromMap(Map<String, dynamic> map) {
    return DirectionsResult(
      routes: List<DirectionsRoute>.from(
          map['routes']?.map((x) => DirectionsRoute.fromMap(x)) ?? []
      ),
      status: map['status'] ?? '',
    );
  }
}

class DirectionsRoute {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final int distanceValue;
  final int durationValue;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<DirectionsStep> steps;

  DirectionsRoute({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
    required this.startLocation,
    required this.endLocation,
    required this.steps,
  });

  factory DirectionsRoute.fromMap(Map<String, dynamic> map) {
    final polylinePoints = DirectionsService.decodePolyline(
        map['overview_polyline']['points']
    );

    final leg = map['legs'][0];

    return DirectionsRoute(
      polylinePoints: polylinePoints,
      distance: leg['distance']['text'] ?? '',
      duration: leg['duration']['text'] ?? '',
      distanceValue: leg['distance']['value'] ?? 0,
      durationValue: leg['duration']['value'] ?? 0,
      startLocation: LatLng(
        leg['start_location']['lat'].toDouble(),
        leg['start_location']['lng'].toDouble(),
      ),
      endLocation: LatLng(
        leg['end_location']['lat'].toDouble(),
        leg['end_location']['lng'].toDouble(),
      ),
      steps: List<DirectionsStep>.from(
          leg['steps']?.map((x) => DirectionsStep.fromMap(x)) ?? []
      ),
    );
  }
}

class DirectionsStep {
  final String instructions;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver;

  DirectionsStep({
    required this.instructions,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
  });

  factory DirectionsStep.fromMap(Map<String, dynamic> map) {
    return DirectionsStep(
      instructions: map['html_instructions'] ?? '',
      distance: map['distance']?['text'] ?? '',
      duration: map['duration']?['text'] ?? '',
      startLocation: LatLng(
        map['start_location']['lat'].toDouble(),
        map['start_location']['lng'].toDouble(),
      ),
      endLocation: LatLng(
        map['end_location']['lat'].toDouble(),
        map['end_location']['lng'].toDouble(),
      ),
      maneuver: map['maneuver'] ?? '',
    );
  }
}