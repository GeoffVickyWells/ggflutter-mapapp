import 'package:flutter/material.dart';

/// Get Maps screen - download offline maps for cities
class GetMapsScreen extends StatelessWidget {
  const GetMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Maps'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Download Offline Maps',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Download maps for offline use. You must be connected to WiFi or have internet to download.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Search box
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for a city...',
                hintStyle: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: const Icon(Icons.search, size: 28),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              style: const TextStyle(fontSize: 18),
              onChanged: (value) {
                // TODO: Implement search
                debugPrint('🔵 Search: $value');
              },
            ),

            const SizedBox(height: 32),

            // Popular cities
            const Text(
              'Popular Cities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: [
                  _buildCityCard(
                    city: 'Barcelona',
                    country: 'Spain',
                    size: '125 MB',
                    isDownloaded: false,
                  ),
                  _buildCityCard(
                    city: 'Paris',
                    country: 'France',
                    size: '156 MB',
                    isDownloaded: false,
                  ),
                  _buildCityCard(
                    city: 'Rome',
                    country: 'Italy',
                    size: '98 MB',
                    isDownloaded: false,
                  ),
                  _buildCityCard(
                    city: 'London',
                    country: 'United Kingdom',
                    size: '187 MB',
                    isDownloaded: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityCard({
    required String city,
    required String country,
    required String size,
    required bool isDownloaded,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isDownloaded ? Colors.green.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isDownloaded ? Icons.check_circle : Icons.download,
            size: 32,
            color: isDownloaded ? Colors.green.shade700 : Colors.blue.shade700,
          ),
        ),
        title: Text(
          city,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              country,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              size,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // TODO: Implement download
            debugPrint('🔵 Download: $city');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDownloaded ? Colors.grey.shade300 : Colors.blue.shade700,
            foregroundColor: isDownloaded ? Colors.grey.shade700 : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isDownloaded ? 'Downloaded' : 'Download',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
