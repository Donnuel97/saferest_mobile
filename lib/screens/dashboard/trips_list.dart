import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:saferest_mobile/utils/routes.dart';
import '../../controller/trip_detail_controller.dart';
import '../../models/trip_model.dart';
import 'trip_map_screen.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({Key? key}) : super(key: key);

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> statusOptions = ['All', 'Pending', 'Ongoing', 'Completed', 'Cancelled'];
  final List<String> tripTypes = ['ROAD', 'RAIL', 'SEA'];

  // Add these class-level variables in _TripListPageState
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  Timer? _locationTimer;
  
  @override
  void initState() {
    super.initState();
    loadTrips();
    _enableLocationService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _positionStreamSubscription?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> loadTrips() async {
    setState(() => isLoading = true);
    try {
      final data = await TripController.fetchTrips();
      
      // Fix statusCode comparison by converting to int
      // if (data is Map<String, dynamic>) {
      //   final statusCode = data['statusCode'];
      //   final code = statusCode is String ? int.tryParse(statusCode) ?? 0 : statusCode;
      //
      //   if (code == 401) {
      //     if (mounted) {
      //       Navigator.pushNamedAndRemoveUntil(
      //         context,
      //         Routes.login,
      //         (route) => false,
      //       );
      //     }
      //     return;
      //   }
      // }

      final updatedTrips = await Future.wait(
        data.map(resolveTripLocations).toList()
      );
      
      if (mounted) {
        setState(() {
          trips = updatedTrips;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading trips: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load trips. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> resolveTripLocations(Map<String, dynamic> trip) async {
    if (trip['departure_station'] == null &&
        trip['departure_lat'] != null &&
        trip['departure_long'] != null) {
      trip['departure_station'] = await getLocationName(
        trip['departure_lat'],
        trip['departure_long'],
      );
    }

    if (trip['arrival_station'] == null &&
        trip['arrival_lat'] != null &&
        trip['arrival_long'] != null) {
      trip['arrival_station'] = await getLocationName(
        trip['arrival_lat'],
        trip['arrival_long'],
      );
    }

    return trip;
  }

  Future<String> getLocationName(dynamic lat, dynamic long) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        double.tryParse(lat.toString()) ?? 0.0,
        double.tryParse(long.toString()) ?? 0.0,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      debugPrint("❌ Failed to reverse geocode: $e");
    }
    return "Unknown Location";
  }

  String formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return 'Invalid date';
    }
  }

  String mapStatus(String? statusCode) {
    switch (statusCode) {
      case 'PENDING':
        return 'Pending';
      case 'ONGOING':
        return 'Ongoing';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getTripTypeIcon(String tripType) {
    switch (tripType.toUpperCase()) {
      case 'ROAD':
        return Icons.directions_car;
      case 'RAIL':
        return Icons.train;
      case 'SEA':
        return Icons.directions_boat;
      default:
        return Icons.trip_origin;
    }
  }

  List<Map<String, dynamic>> getFilteredTrips() {
    return trips.where((trip) {
      final status = mapStatus(trip['trip_status']);
      final title = trip['title']?.toString().toLowerCase() ?? '';
      final description = trip['ride_description']?.toString().toLowerCase() ?? '';
      final source = trip['departure_station']?.toString().toLowerCase() ?? '';
      final destination = trip['arrival_station']?.toString().toLowerCase() ?? '';
      
      bool matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          description.contains(_searchQuery.toLowerCase()) ||
          source.contains(_searchQuery.toLowerCase()) ||
          destination.contains(_searchQuery.toLowerCase());

      bool matchesFilter = _selectedFilter == 'All' || status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search trips...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusOptions.map((status) {
                bool isSelected = _selectedFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(status),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = selected ? status : 'All');
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.orange.withOpacity(0.2),
                    checkmarkColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.orange : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final title = trip['title'] ?? 'Untitled';
    final description = trip['ride_description'] ?? 'No description';
    final status = mapStatus(trip['trip_status']);
    final date = formatDate(trip['departure_date']);
    final source = trip['departure_station'] ?? 'Unknown';
    final destination = trip['arrival_station'] ?? 'Unknown';
    final tripType = trip['trip_type'] ?? 'ROAD';
    final logisticsCompany = trip['logistics_company'] ?? 'N/A';
    final plateNumber = trip['plate_number'] ?? 'N/A';

    final depLat = double.tryParse(trip['departure_lat']?.toString() ?? '');
    final depLong = double.tryParse(trip['departure_long']?.toString() ?? '');
    final arrLat = double.tryParse(trip['arrival_lat']?.toString() ?? '');
    final arrLong = double.tryParse(trip['arrival_long']?.toString() ?? '');

    // Add watchers variable
    final List<dynamic> watchers = trip['watchers'] ?? [];
    final String watchersText = watchers.isEmpty 
        ? 'No watchers' 
        : watchers.map((w) => '${w['first_name']} ${w['last_name']}').join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ExpansionTile(
        leading: Icon(
          getTripTypeIcon(tripType),
          color: Colors.orange,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '$source → $destination',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Date: $date',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: getStatusColor(status),
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.visibility, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        watchersText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    if (watchers.isNotEmpty) Text(
                      '(${watchers.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Logistics Company: $logisticsCompany'),
                Text('Plate Number: $plateNumber'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (status != 'Completed' && status != 'Cancelled')
                      Expanded(
                        child: DropdownButton<String>(
                          value: status,
                          isExpanded: true,
                          onChanged: (String? newValue) async {
                            if (newValue == null) return;

                            final tripId = trip['id'];
                            final lat = trip['departure_lat']?.toString() ?? '';
                            final long = trip['departure_long']?.toString() ?? '';
                            bool actionSuccess = true;

                            switch (newValue.toLowerCase()) {
                              case 'ongoing':
                                actionSuccess = await TripController.startTrip(
                                  tripId: tripId,
                                  lat: lat,     // Changed from departure_lat
                                  long: long,   // Changed from departure_long
                                  context: context,
                                );
                                break;
                              case 'completed':
                                actionSuccess = await TripController.endTrip(
                                  tripId: tripId,
                                  lat: lat,
                                  long: long,
                                );
                                break;
                              case 'cancelled':
                                actionSuccess = await TripController.cancelTrip(
                                  tripId: tripId,
                                  lat: lat,
                                  long: long,
                                );
                                break;
                            }

                            if (actionSuccess) {
                              loadTrips(); // Reload all trips to get updated status
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Trip marked as $newValue')),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update trip to $newValue'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          items: statusOptions
                              .where((s) => s != 'All')
                              .map((String statusItem) {
                            return DropdownMenuItem<String>(
                              value: statusItem,
                              child: Text(statusItem),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (status.toLowerCase() == 'ongoing') {
                          // Get current location for ongoing trips
                          final position = await _getCurrentLocation();
                          if (position != null && arrLat != null && arrLong != null) {
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TripMapScreen(
                                  departureLat: position.latitude,
                                  departureLong: position.longitude,
                                  arrivalLat: arrLat,
                                  arrivalLong: arrLong,
                                  isTracking: true, // Add this parameter to TripMapScreen
                                ),
                              ),
                            );
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unable to get current location'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          // Original behavior for non-ongoing trips
                          if (depLat != null && depLong != null && 
                              arrLat != null && arrLong != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TripMapScreen(
                                  departureLat: depLat,
                                  departureLong: depLong,
                                  arrivalLat: arrLat,
                                  arrivalLong: arrLong,
                                  isTracking: false,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Missing or invalid coordinates'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        status.toLowerCase() == 'ongoing' ? Icons.location_on : Icons.map,
                        color: Colors.white
                      ),
                      label: Text(
                        status.toLowerCase() == 'ongoing' ? 'Track Trip' : 'View Map',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to enable location services
  Future<void> _enableLocationService() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, request the user to enable it
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable location services'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check the location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, handle appropriately
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Permissions are granted, proceed to get the current location
    _positionStreamSubscription = Geolocator.getPositionStream().listen(
          (Position position) {
        setState(() {
          _currentPosition = position;
        });
      },
    );
  }

  // Add this new method to get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final request = await Geolocator.requestPermission();
        if (request == LocationPermission.denied) return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrips = getFilteredTrips();
    
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.6)),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Your Trips', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: loadTrips,
                color: Colors.white,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: loadTrips,
            child: Column(
              children: [
                _buildSearchAndFilter(),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredTrips.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.route,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No trips available'
                                        : 'No trips match your search',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredTrips.length,
                              itemBuilder: (context, index) =>
                                  _buildTripCard(filteredTrips[index]),
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
