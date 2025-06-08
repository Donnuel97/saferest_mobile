import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saferest_mobile/utils/routes.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:saferest_mobile/controller/trip_stats_controller.dart';


class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String firstName = '';
  String lastName = '';
  String location = 'Loading location...';
  int pendingTrips = 0;
  int completedTrips = 0;
  int totalFriends = 0;


  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadTripStats();
  }

  Future<void> _loadTripStats() async {
    if (!mounted) return; // Add early return if widget is disposed
    
    try {
      final stats = await TripStatsController.getTripStats();
      
      if (!mounted) return; // Check again before setState
      
      setState(() {
        pendingTrips = (stats['pending'] ?? 0);
        completedTrips = (stats['completed'] ?? 0);
        totalFriends = (stats['friends'] ?? 0);
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading trip stats: $e');
    }
  }


  Future<void> _loadUserInfo() async {
    if (!mounted) return;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Load user data
      final userData = prefs.getString('userData');
      if (userData != null) {
        final Map<String, dynamic> user = json.decode(userData);
        
        if (!mounted) return;
        setState(() {
          firstName = user['first_name'] ?? '';
          lastName = user['last_name'] ?? '';
        });
      }

      // Load saved location first
      final savedLocation = prefs.getString('userLocation');

      if (savedLocation != null && savedLocation.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          location = savedLocation;
        });
      } else {
        // If not saved, fetch and save
        await _getCurrentLocation();
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading user info: $e');
    }
  }


  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // Location service is not enabled, redirect to login
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission still denied, redirect to login
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, Routes.login);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions permanently denied, redirect to login
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      final currentLocation = '${place.locality}, ${place.country}';

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userLocation', currentLocation);

      if (!mounted) return;
      setState(() {
        location = currentLocation;
      });
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              // Fixed header section
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Good morning $firstName 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LineIcons.mapMarker, color: Colors.white),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    location,
                                    style: const TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: _buildAdvertCard(context),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: _buildActivityCard(),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
              // Expandable services section
              Expanded(
                child: _buildServicesSection(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFFEAEEFF),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Let's start\nYour Journey",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Set a new trip destination to begin your travel.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.new_trip);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'New Trip ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          Icon(Icons.keyboard_double_arrow_right,
                              color: Colors.white,
                              size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/people.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Add this
      children: [
        const Text(
          'My Activities',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFFEAEEFF),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10), // Reduced padding
            child: Column(
              mainAxisSize: MainAxisSize.min, // Add this
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Text(
                        'Pending Trips',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, // Add this
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Completed Trips',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'No. of Friends',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 1), // Reduced height
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _activityIcon(pendingTrips, Colors.purple, LineIcons.clock)),
                    Expanded(child: _activityIcon(completedTrips, Colors.orange, LineIcons.road)),
                    Expanded(child: _activityIcon(totalFriends, Colors.indigo, LineIcons.userFriends)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _activityIcon(int count, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Add this
      children: [
        Icon(icon, size: 24, color: color), // Reduced size
        const SizedBox(height: 4), // Reduced spacing
        Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14, // Reduced font size
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, right: 30, left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Services',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 5),
                const Text(
                  'You can choose from the options below',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _serviceCard(
                    LineIcons.taxi,
                    'Road Transportation',
                    'Taxi or Bus',
                    Colors.orange,
                        () {
                      Navigator.pushNamed(context, Routes.new_trip);
                    },
                  ),
                  _serviceCard(
                    LineIcons.train,
                    'Rail Transportation',
                    'Train or Metro',
                    Colors.blue,
                        () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rail Transportation coming soon!')),
                      );
                    },
                  ),
                  _serviceCard(
                    LineIcons.ship,
                    'Sea Transportation',
                    'Boat or Ferry',
                    Colors.teal,
                        () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sea Transportation coming soon!')),
                      );
                    },
                  ),
                  // Add bottom padding to account for bottom navigation
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _serviceCard(
      IconData icon,
      String title,
      String subtitle,
      Color iconColor,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

}