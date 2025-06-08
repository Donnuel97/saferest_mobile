import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Protection and Privacy Policy',
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
              'Saferest Limited and Saferest Consortia Limited ("we," "our," or "us") are committed to protecting the privacy and security of our users\' data. This policy outlines how we collect, use, store, and protect personal information in compliance with UK General Data Protection Regulation (UK GDPR) and other applicable data protection laws.',
            ),
            _buildSection(
              '2. Definitions and Key Terms',
              '• Personal Data: Any information that can identify an individual.\n'
              '• Processing: Any operation performed on personal data.\n'
              '• Data Controller: The entity responsible for determining how and why personal data is processed.\n'
              '• Data Processor: A third party that processes data on behalf of the data controller.',
            ),
            // Add other sections similarly...
            _buildSection(
              '16. Contact Information',
              'For any data protection inquiries, users may contact:\n\n'
              'Saferest Consortia Limited\n'
              'Email: dataprotectionteam@saferests.com, saferestapp@gmail.com',
            ),
            _buildSection(
              '17. Policy Updates',
              'We may update this policy periodically. Users will be notified of significant changes.',
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