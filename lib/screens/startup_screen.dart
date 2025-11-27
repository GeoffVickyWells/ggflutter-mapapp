import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Startup Screen - shown until location permission is granted
/// CRITICAL: App will not function without location permission
class StartupScreen extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const StartupScreen({
    super.key,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Icon(
                Icons.map,
                size: 100,
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 24),

              // App Name
              const Text(
                'GeezerGuides',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Offline Travel Navigation',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 48),

              // Permission required message
              if (errorMessage == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Checking location permissions...',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Icon(
                  Icons.location_off,
                  size: 64,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(height: 24),

                // Error message
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Explanation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why we need location:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Show your position on offline maps\n'
                        '• Navigate to waypoints without internet\n'
                        '• Calculate distances and routes\n'
                        '• GPS works offline (no data charges)',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 28),
                    label: const Text(
                      'Grant Location Access',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Settings button (if permanently denied)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => Geolocator.openAppSettings(),
                    icon: const Icon(Icons.settings, size: 28),
                    label: const Text(
                      'Open Settings',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(
                        color: Colors.blue.shade700,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
