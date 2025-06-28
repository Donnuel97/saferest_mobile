import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildContactTile(IconData icon, String title, String subtitle, 
      {VoidCallback? onTap, Color iconColor = Colors.orange}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSocialMediaRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialButton(LineIcons.facebook, Colors.blue[900]!, 
            'https://facebook.com/saferest'),
        _buildSocialButton(LineIcons.twitter, Colors.blue, 
            'https://twitter.com/saferest'),
        _buildSocialButton(LineIcons.instagram, Colors.purple, 
            'https://instagram.com/saferest'),
        _buildSocialButton(LineIcons.linkedin, Colors.blue[700]!, 
            'https://linkedin.com/company/saferest'),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support', 
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How can we help you?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildContactTile(
                Icons.email_outlined,
                'Email Us',
                'support@saferest.com',
                onTap: () => _launchUrl('mailto:support@saferest.com'),
              ),
              _buildContactTile(
                Icons.phone_outlined,
                'Call Us',
                '+1 (555) 123-4567',
                onTap: () => _launchUrl('tel:+15551234567'),
              ),
              _buildContactTile(
                Icons.language,
                'Website',
                'www.saferest.com',
                onTap: () => _launchUrl('https://www.saferest.com'),
              ),
              _buildContactTile(
                Icons.location_on_outlined,
                'Visit Us',
                '123 Safe Street, Rest City, ST 12345',
                onTap: () => _launchUrl(
                    'https://maps.google.com/?q=123+Safe+Street+Rest+City'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Follow us on social media',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildSocialMediaRow(),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.orange),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Hours',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Monday - Friday: 9:00 AM - 6:00 PM\nWeekends: Closed',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}