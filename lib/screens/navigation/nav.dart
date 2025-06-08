import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:saferest_mobile/screens/dashboard/dashboard.dart';
import 'package:saferest_mobile/screens/dashboard/trips_list.dart';
import 'package:saferest_mobile/screens/dashboard/friends/friends_page.dart';
import 'package:saferest_mobile/screens/dashboard/watcher_trips_list.dart';

import '../dashboard/settings_page.dart';
import '../dashboard/tracked_trips_page.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ProfileTab(),          // Home
    TripListPage(),        // Trips
    TrackedTripsPage(),    // Watcher Trips
    FriendsPage(),         // Friends
    SettingsPage(),        // Settings
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Add this to show all items
        items: const [
          BottomNavigationBarItem(icon: Icon(LineIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LineIcons.car), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(LineIcons.eye), label: 'Watching'),
          BottomNavigationBarItem(icon: Icon(LineIcons.users), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(LineIcons.alternateSignOut), label: 'Settings'),
        ],
      ),
    );
  }
}
