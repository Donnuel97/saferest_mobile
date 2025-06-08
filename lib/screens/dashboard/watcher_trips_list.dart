import 'package:flutter/material.dart';
import '../../controller/trip_detail_controller.dart';
import 'trip_map_screen.dart';

class WatcherTripsPage extends StatefulWidget {
  const WatcherTripsPage({Key? key}) : super(key: key);

  @override
  State<WatcherTripsPage> createState() => _WatcherTripsPageState();
}

class _WatcherTripsPageState extends State<WatcherTripsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> watcherTrips = [];

  @override
  void initState() {
    super.initState();
    loadWatcherTrips();
  }

  Future<void> loadWatcherTrips() async {
    setState(() => isLoading = true);
    try {
      final trips = await TripController.fetchWatcherTrips();
      setState(() {
        watcherTrips = trips;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trips: $e')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final title = trip['title'] ?? 'Untitled';
    final description = trip['ride_description'] ?? 'No description';
    final owner = trip['owner'] ?? {};
    final ownerName = '${owner['first_name'] ?? ''} ${owner['last_name'] ?? ''}'.trim();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: $ownerName'),
            Text(description),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.map),
          onPressed: () {
            // Navigate to map view
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips You\'re Watching'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : watcherTrips.isEmpty
              ? const Center(child: Text('No trips assigned to watch'))
              : ListView.builder(
                  itemCount: watcherTrips.length,
                  itemBuilder: (context, index) => _buildTripCard(watcherTrips[index]),
                ),
    );
  }
}