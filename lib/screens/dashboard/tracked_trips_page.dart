import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../controller/tracked_trips_controller.dart';
import 'trip_map_screen.dart';

class TrackedTripsPage extends StatefulWidget {
  const TrackedTripsPage({Key? key}) : super(key: key);

  @override
  State<TrackedTripsPage> createState() => _TrackedTripsPageState();
}

class _TrackedTripsPageState extends State<TrackedTripsPage> {
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadTrips() async {
    setState(() => isLoading = true);
    final data = await TrackedTripsController.fetchTrackedTrips();
    final updatedTrips = await Future.wait(data.map(resolveTripLocations).toList());
    setState(() {
      trips = updatedTrips;
      isLoading = false;
    });
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
      final title = trip['title']?.toString().toLowerCase() ?? '';
      final description = trip['ride_description']?.toString().toLowerCase() ?? '';
      final source = trip['departure_station']?.toString().toLowerCase() ?? '';
      final destination = trip['arrival_station']?.toString().toLowerCase() ?? '';
      final travelerName = '${trip['traveler_first_name'] ?? ''} ${trip['traveler_last_name'] ?? ''}'.toLowerCase();
      
      return _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          description.contains(_searchQuery.toLowerCase()) ||
          source.contains(_searchQuery.toLowerCase()) ||
          destination.contains(_searchQuery.toLowerCase()) ||
          travelerName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search tracked trips...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
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
    final travelerName = '${trip['traveler_first_name'] ?? 'Unknown'} ${trip['traveler_last_name'] ?? ''}';

    final depLat = double.tryParse(trip['departure_lat']?.toString() ?? '');
    final depLong = double.tryParse(trip['departure_long']?.toString() ?? '');
    final arrLat = double.tryParse(trip['arrival_lat']?.toString() ?? '');
    final arrLong = double.tryParse(trip['arrival_long']?.toString() ?? '');

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
              'Traveler: $travelerName',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (depLat != null &&
                        depLong != null &&
                        arrLat != null &&
                        arrLong != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripMapScreen(
                            departureLat: depLat,
                            departureLong: depLong,
                            arrivalLat: arrLat,
                            arrivalLong: arrLong,
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
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text(
                    'Track on Map',
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
            title: const Text('Tracked Trips', style: TextStyle(color: Colors.white)),
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
                _buildSearchBar(),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredTrips.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.track_changes,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No tracked trips available'
                                        : 'No tracked trips match your search',
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