import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng location, String address) onLocationSelected;

  const MapLocationPicker({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  Set<Marker> _markers = {};
  bool _isLoading = false;
  bool _isMapMoving = false;
  Timer? _debounceTimer;

  // Map configuration
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(0, 0),
    zoom: 15,
  );

  // Map style
  static const String _mapStyle = '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
  ''';

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _updateMarker(_selectedLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 5),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () async {
          // Fallback to last known position if getting current position times out
          return await Geolocator.getLastKnownPosition() ?? 
                 await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        },
      );

      final location = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _selectedLocation = location;
          _isLoading = false;
        });
        _updateMarker(location);
        _animateToLocation(location);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          Placemark place = placemarks.first;
          final address = [
            if (place.street?.isNotEmpty ?? false) place.street,
            if (place.subLocality?.isNotEmpty ?? false) place.subLocality,
            if (place.locality?.isNotEmpty ?? false) place.locality,
            if (place.country?.isNotEmpty ?? false) place.country,
          ].where((e) => e != null).join(', ');

          setState(() => _selectedAddress = address);
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
      }
    });
  }

  void _updateMarker(LatLng location) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() => _selectedLocation = newPosition);
            _getAddressFromLatLng(newPosition);
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      };
    });
    _getAddressFromLatLng(location);
  }

  Future<void> _animateToLocation(LatLng location, {double zoom = 15}) async {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: zoom),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    controller.setMapStyle(_mapStyle);
    
    if (_selectedLocation != null) {
      _animateToLocation(_selectedLocation!);
    }
  }

  void _onCameraMove(CameraPosition position) {
    if (!_isMapMoving) {
      setState(() => _isMapMoving = true);
    }
  }

  void _onCameraIdle() {
    setState(() => _isMapMoving = false);
    if (_mapController != null) {
      _mapController!.getVisibleRegion().then((bounds) {
        final center = LatLng(
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        );
        setState(() => _selectedLocation = center);
        _updateMarker(center);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 400,
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _selectedLocation != null
                      ? CameraPosition(target: _selectedLocation!, zoom: 15)
                      : _defaultPosition,
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  mapType: MapType.normal,
                ),
                if (_selectedAddress.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _selectedAddress,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'location',
                        onPressed: _getCurrentLocation,
                        backgroundColor: Colors.white,
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'zoom_in',
                        onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.add, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'zoom_out',
                        onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.remove, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedLocation == null
                      ? null
                      : () {
                          widget.onLocationSelected(
                            _selectedLocation!,
                            _selectedAddress,
                          );
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'Select',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 