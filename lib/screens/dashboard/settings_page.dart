import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controller/UserController.dart';
import 'terms_conditions_page.dart';
import 'privacy_policy_page.dart';
import 'edit_profile_screen.dart';
import 'help_support_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String location = 'Loading...';

  // User profile state
  String userName = 'Loading...';
  String userEmail = '';
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadLocationFromPrefs();
    _loadUserProfile();
  }

  Future<void> _loadLocationFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedLocation = prefs.getString('userLocation');

    setState(() {
      location = savedLocation?.isNotEmpty == true ? savedLocation! : 'Location not available';
    });
  }

  Future<void> _loadUserProfile() async {
    final userData = await UserController.fetchUserDetails();
    if (userData != null && mounted) {
      setState(() {
        userName = '${userData['first_name']} ${userData['last_name']}';
        userEmail = userData['email'] ?? '';
        avatarUrl = userData['avatar_url'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    currentName: userName,
                    currentEmail: userEmail,
                    currentAvatar: avatarUrl,
                    currentLocation: location,
                  ),
                ),
              );

              if (updated ?? false) {
                // Reload user profile
                _loadUserProfile();
                _loadLocationFromPrefs();
              }
            },
            icon: const Icon(LineIcons.pen),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                              ? NetworkImage(avatarUrl!)
                              : const AssetImage('assets/male.png') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: const SizedBox(height: 10, width: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          userEmail,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    const Icon(LineIcons.locationArrow, size: 20),
                    const SizedBox(width: 10),
                    Text('Current Location: $location'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _settingTile(Icons.help, 'Help & Support', context),
                    const SizedBox(height: 15),
                    _settingTile(Icons.checklist, 'Terms & Conditions', context),
                    const SizedBox(height: 15),
                    _settingTile(Icons.privacy_tip, 'Privacy Policy', context),
                    const SizedBox(height: 15),
                    _settingTile(Icons.notifications, 'Notifications', context),
                    const SizedBox(height: 15),
                    _logoutTile(context),
                    const SizedBox(height: 30),
                    const Text(
                      'Version 2.3.0',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(LineIcons.alternateArrowCircleRightAlt),
        onTap: () {
          if (title == 'Terms & Conditions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TermsAndConditionsPage(),
              ),
            );
          } else if (title == 'Privacy Policy') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyPage(),
              ),
            );
          } else if (title == 'Help & Support') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpSupportPage(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title tapped')),
            );
          }
        },
      ),
    );
  }

  Widget _logoutTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        onTap: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  child: const Text('Logout'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          );

          if (shouldLogout ?? false) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();

            if (!context.mounted) return;

            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (Route<dynamic> route) => false,
            );
          }
        },
      ),
    );
  }
}
