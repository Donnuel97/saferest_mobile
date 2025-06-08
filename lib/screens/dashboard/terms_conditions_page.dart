import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms and Conditions for Saferest App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective Date: 16th May 2025\nLast Updated: 16th May 2025',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'Welcome to the Saferest App, developed and owned by Saferest Limited and Saferest Consortia Limited ("we," "our," or "us"). These Terms and Conditions govern your use of our software application and ensure compliance with international guidelines for data protection and privacy.',
            ),
            _buildSection(
              '2. Definitions',
              '• App: The Saferest software application.\n'
              '• User: Any individual or entity accessing or using the app.\n'
              '• Personal Data: Any information that can identify an individual.\n'
              '• Data Controller: The entity responsible for determining how and why personal data is processed.\n'
              '• Data Processor: A third party that processes data on behalf of the data controller.',
            ),
            // Add more sections...
            _buildSection(
              '11. Contact Information',
              'For any inquiries regarding data protection or these Terms and Conditions, users may contact:\n\n'
              'Saferest Consortia Limited\n'
              'Email: dataprotectionteam@saferests.com, saferestapp@gmail.com',
            ),
            _buildSection(
              '12. Amendments and Updates',
              'We may update these Terms and Conditions periodically. Users will be notified of significant changes.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}