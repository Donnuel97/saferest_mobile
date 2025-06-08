import 'dart:math' show cos, sin, sqrt, asin, pi;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapUtils {
  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double lat1 = start.latitude * (pi / 180);
    double lon1 = start.longitude * (pi / 180);
    double lat2 = end.latitude * (pi / 180);
    double lon2 = end.longitude * (pi / 180);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  /// Get appropriate zoom level based on distance between points
  static double getZoomLevel(LatLng start, LatLng end) {
    double distance = calculateDistance(start, end);
    double zoom = 14.0; // Default zoom level
    
    if (distance > 100) {
      zoom = 9.0;
    } else if (distance > 50) {
      zoom = 10.0;
    } else if (distance > 20) {
      zoom = 11.0;
    } else if (distance > 10) {
      zoom = 12.0;
    } else if (distance > 5) {
      zoom = 13.0;
    } else if (distance <= 1) {
      zoom = 15.0;
    }
    
    return zoom;
  }

  /// Get bounds that include both points with padding
  static LatLngBounds getBounds(LatLng start, LatLng end) {
    double minLat = start.latitude < end.latitude ? start.latitude : end.latitude;
    double maxLat = start.latitude > end.latitude ? start.latitude : end.latitude;
    double minLng = start.longitude < end.longitude ? start.longitude : end.longitude;
    double maxLng = start.longitude > end.longitude ? start.longitude : end.longitude;

    // Add padding
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    return LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  /// Check if location services are enabled and permissions are granted
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get optimized location settings based on activity type
  static LocationSettings getLocationSettings({bool isBackground = false}) {
    return LocationSettings(
      accuracy: isBackground ? LocationAccuracy.reduced : LocationAccuracy.high,
      distanceFilter: isBackground ? 50 : 10, // Meters
      timeLimit: const Duration(seconds: 5),
    );
  }

  /// Generate custom marker icon colors based on marker type
  static BitmapDescriptor getMarkerIcon(MarkerType type) {
    switch (type) {
      case MarkerType.departure:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case MarkerType.arrival:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case MarkerType.current:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }
}

enum MarkerType {
  departure,
  arrival,
  current,
  waypoint
} 