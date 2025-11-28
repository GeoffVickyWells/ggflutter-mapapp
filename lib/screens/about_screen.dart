import 'package:flutter/material.dart';

/// About screen - app info, QR scanner, help
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About GeezerGuides'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GeezerGuides',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Offline travel navigation designed for senior travelers. '
              'No internet required once maps are downloaded.',
              style: TextStyle(fontSize: 18, height: 1.5),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement QR scanner
                debugPrint('🔵 Open QR scanner');
              },
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: const Text(
                'Scan Guide QR Code',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
