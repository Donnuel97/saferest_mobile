import 'dart:async';
import 'dart:math' show atan2, cos, pi, sin;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/map_utils.dart';
import '../../utils/directions.dart';
// Import your DirectionsService here
// import 'directions_service.dart';

class TripMapScreen extends StatefulWidget {
  final double departureLat;
  final double departureLong;
  final double arrivalLat;
  final double arrivalLong;
  final bool isTracking;

  const TripMapScreen({
    Key? key,
    required this.departureLat,
    required this.departureLong,
    required this.arrivalLat,
    required this.arrivalLong,
    this.isTracking = false,
  }) : super(key: key);

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  bool _isDisposed = false;
  bool _isBackground = false;
  Timer? _locationUpdateTimer;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];
  final List<LatLng> _plannedRoutePoints = []; // For the planned route from Google Directions
  LatLng? _currentLocation;
  DateTime? _lastLocationUpdate;

  // Route information
  String? _routeDistance;
  String? _routeDuration;
  bool _isLoadingRoute = false;

  // Add this property to the _TripMapScreenState class
  bool _isTrackingMode = false;

  static const Duration _backgroundInterval = Duration(minutes: 5);
  static const Duration _foregroundInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMap();
    if (widget.isTracking) {
      _startTracking();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isBackground = true;
      _updateLocationSettings();
    } else if (state == AppLifecycleState.resumed) {
      _isBackground = false;
      _updateLocationSettings();
    }
  }

  Future<void> _initializeMap() async {
    // Check location permissions
    if (!await MapUtils.checkLocationPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are required for tracking')),
        );
      }
      return;
    }

    _initMarkers();
    _getDirectionsRoute();
    _startLocationTracking();
  }

  void _initMarkers() {
    final departure = LatLng(widget.departureLat, widget.departureLong);
    final arrival = LatLng(widget.arrivalLat, widget.arrivalLong);

    _markers.addAll({
      Marker(
        markerId: const MarkerId('departure'),
        position: departure,
        infoWindow: const InfoWindow(title: 'Departure Point'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('arrival'),
        position: arrival,
        infoWindow: const InfoWindow(title: 'Arrival Point'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    });
  }

  Future<void> _getDirectionsRoute() async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final origin = LatLng(widget.departureLat, widget.departureLong);
      final destination = LatLng(widget.arrivalLat, widget.arrivalLong);

      // Use your DirectionsService
      final directionsResult = await DirectionsService.getDirections(
        origin: origin,
        destination: destination,
        travelMode: 'driving',
      );

      if (directionsResult != null && directionsResult.routes.isNotEmpty) {
        final route = directionsResult.routes.first;

        setState(() {
          _routeDistance = route.distance;
          _routeDuration = route.duration;

          // Clear previous route points
          _plannedRoutePoints.clear();
          _plannedRoutePoints.addAll(route.polylinePoints);

          // Create the planned route polyline
          _polylines.removeWhere((p) => p.polylineId == const PolylineId('planned_route'));
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('planned_route'),
              points: _plannedRoutePoints,
              color: Colors.blue,
              width: 4,
              patterns: [], // Solid blue line for planned route
            ),
          );
        });

        print('Route loaded successfully with ${_plannedRoutePoints.length} points');
      } else {
        print('No route found, using fallback');
        _createStraightLineRoute();
      }
    } catch (e) {
      print('Error fetching directions: $e');
      _createStraightLineRoute();
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _createStraightLineRoute() {
    final departure = LatLng(widget.departureLat, widget.departureLong);
    final arrival = LatLng(widget.arrivalLat, widget.arrivalLong);

    setState(() {
      _plannedRoutePoints.clear();
      _plannedRoutePoints.addAll([departure, arrival]);

      _polylines.removeWhere((p) => p.polylineId == const PolylineId('planned_route'));
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('planned_route'),
          points: [departure, arrival],
          color: Colors.blue,
          width: 4,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)], // Dashed line for fallback
        ),
      );

      // Calculate straight line distance
      final distance = Geolocator.distanceBetween(
        departure.latitude,
        departure.longitude,
        arrival.latitude,
        arrival.longitude,
      );
      _routeDistance = '${(distance / 1000).toStringAsFixed(2)} km (straight line)';
    });
  }

  void _updateLocationSettings() {
    _positionSubscription?.cancel();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (Position position) {
        if (_isDisposed || !mounted) return;

        final now = DateTime.now();
        if (_lastLocationUpdate != null) {
          final interval = _isBackground ? _backgroundInterval : _foregroundInterval;
          if (now.difference(_lastLocationUpdate!) < interval) {
            return;
          }
        }
        _lastLocationUpdate = now;

        final currentLatLng = LatLng(position.latitude, position.longitude);
        _updateCurrentLocation(currentLatLng);
      },
      onError: (error) {
        debugPrint('Location tracking error: $error');
      },
    );
  }

  void _startTracking() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final position = await Geolocator.getCurrentPosition();
      // Convert Position to LatLng
      final latLng = LatLng(position.latitude, position.longitude);
      _updateCurrentLocation(latLng);
    });
  }

  void _updateCurrentLocation(LatLng location) {
    setState(() {
      _currentLocation = location;

      // Update current location marker
      _markers.removeWhere((m) => m.markerId == const MarkerId('current'));
      _markers.add(Marker(
        markerId: const MarkerId('current'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Current Location'),
      ));

      // Add to traveled route
      if (_routePoints.isEmpty ||
          _calculateDistance(_routePoints.last, location) > 0.05) {
        _routePoints.add(location);
        _updateTraveledRoutePolyline();
      }

      // Auto-follow in tracking mode
      if (_isTrackingMode && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: location,
              zoom: 17.0,
              tilt: 45.0,
              bearing: _calculateBearing(location),
            ),
          ),
        );
      }

      // Check if near destination
      final destination = LatLng(widget.arrivalLat, widget.arrivalLong);
      if (_calculateDistance(location, destination) < 0.1) {
        _showArrivalAlert();
      }
    });
  }

  // Add this method to calculate bearing
  double _calculateBearing(LatLng location) {
    if (_routePoints.length < 2) return 0;

    final lastPoint = _routePoints[_routePoints.length - 2];
    final y = sin(location.longitude - lastPoint.longitude) * cos(location.latitude);
    final x = cos(lastPoint.latitude) * sin(location.latitude) -
        sin(lastPoint.latitude) * cos(location.latitude) * cos(location.longitude - lastPoint.longitude);
    final bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  void _updateTraveledRoutePolyline() {
    if (_routePoints.length < 2) return;

    _polylines.removeWhere((p) => p.polylineId == const PolylineId('traveled_route'));
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('traveled_route'),
        points: _routePoints,
        color: Colors.orange,
        width: 6, // Slightly thicker for visibility
        patterns: [], // Solid line for traveled route
      ),
    );
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // Convert to kilometers
  }

  void _showArrivalAlert() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 You have arrived at your destination!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _fitMapToRoute() {
    if (_mapController == null) return;

    // Use planned route points if available, otherwise use departure/arrival points
    List<LatLng> pointsToFit = _plannedRoutePoints.isNotEmpty
        ? _plannedRoutePoints
        : [
      LatLng(widget.departureLat, widget.departureLong),
      LatLng(widget.arrivalLat, widget.arrivalLong),
    ];

    if (_currentLocation != null) {
      pointsToFit.add(_currentLocation!);
    }

    if (pointsToFit.length < 2) return;

    double minLat = pointsToFit.first.latitude;
    double maxLat = pointsToFit.first.latitude;
    double minLng = pointsToFit.first.longitude;
    double maxLng = pointsToFit.first.longitude;

    for (LatLng point in pointsToFit) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _positionSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Route'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _fitMapToRoute,
            tooltip: 'Fit to Route',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getDirectionsRoute,
            tooltip: 'Refresh Route',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'toggleTracking',
            onPressed: () {
              setState(() {
                _isTrackingMode = !_isTrackingMode;
                if (_isTrackingMode && _currentLocation != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _currentLocation!,
                        zoom: 17.0,
                        tilt: 45.0,
                        bearing: _calculateBearing(_currentLocation!),
                      ),
                    ),
                  );
                }
              });
            },
            backgroundColor: _isTrackingMode ? Colors.blue : Colors.grey,
            child: Icon(
              _isTrackingMode ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // ... other floating action buttons if any
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.departureLat, widget.departureLong),
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 500), () {
                _fitMapToRoute();
              });
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: true,
            trafficEnabled: true,
          ),

          // Loading indicator for route
          if (_isLoadingRoute)
            const Positioned(
              top: 16,
              left: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading route...'),
                    ],
                  ),
                ),
              ),
            ),

          // Route information
          if (!_isLoadingRoute && _routeDistance != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Route Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_routeDistance != null)
                        Row(
                          children: [
                            const Icon(Icons.straighten, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Distance: $_routeDistance'),
                          ],
                        ),
                      if (_routeDuration != null)
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Duration: $_routeDuration'),
                          ],
                        ),
                      if (_currentLocation != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'To destination: ${_calculateDistance(
                                _currentLocation!,
                                LatLng(widget.arrivalLat, widget.arrivalLong),
                              ).toStringAsFixed(2)} km',
                            ),
                          ],
                        ),
                      Text(
                        'Route points: ${_plannedRoutePoints.length}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Legend
          Positioned(
            bottom: 16,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 3,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        const Text('Planned Route', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 3,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text('Traveled Route', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Add tracking mode indicator
          if (_isTrackingMode)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.navigation, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Tracking Mode',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}