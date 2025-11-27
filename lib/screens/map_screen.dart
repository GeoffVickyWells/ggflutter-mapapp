import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/map_mode_service.dart';

/// Main Map Screen - displays OpenStreetMap with online/offline mode
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMap(),

          // Mode switcher overlay (top center)
          _buildModeSwitcher(),

          // GPS status indicator (top left)
          _buildGpsIndicator(),

          // Center on location button (bottom right)
          _buildCenterButton(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer2<LocationService, MapModeService>(
      builder: (context, locationService, mapModeService, child) {
        final position = locationService.currentPosition;
        final center = position != null
            ? LatLng(position.latitude, position.longitude)
            : LatLng(37.7749, -122.4194); // Default: San Francisco

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15.0,
            minZoom: 3.0,
            maxZoom: 19.0,
          ),
          children: [
            // Tile layer (changes based on online/offline mode)
            TileLayer(
              urlTemplate: mapModeService.isOnline
                  ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                  : null, // Offline mode - will implement tile loading later
              userAgentPackageName: 'com.geezerguides.app',
              maxNativeZoom: 19,
            ),

            // User location marker
            if (position != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(position.latitude, position.longitude),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildModeSwitcher() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 0,
      right: 0,
      child: Center(
        child: Consumer<MapModeService>(
          builder: (context, mapModeService, child) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ONLINE button
                  _buildModeButton(
                    label: 'ONLINE',
                    isActive: mapModeService.isOnline,
                    color: Colors.green,
                    onTap: () => mapModeService.switchToOnline(),
                  ),

                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),

                  // OFFLINE button
                  _buildModeButton(
                    label: 'OFFLINE',
                    isActive: mapModeService.isOffline,
                    color: Colors.blue,
                    onTap: () {
                      if (!mapModeService.hasOfflineMapSelected) {
                        _showNoOfflineMapDialog();
                      } else {
                        mapModeService.switchToOffline();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? color : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 88,
      left: 16,
      child: Consumer<LocationService>(
        builder: (context, locationService, child) {
          final hasPosition = locationService.currentPosition != null;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasPosition ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: hasPosition ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  hasPosition ? 'GPS Active' : 'Acquiring GPS...',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenterButton() {
    return Positioned(
      bottom: 24,
      right: 16,
      child: Consumer<LocationService>(
        builder: (context, locationService, child) {
          final position = locationService.currentPosition;

          return FloatingActionButton.large(
            onPressed: position != null
                ? () {
                    _mapController.move(
                      LatLng(position.latitude, position.longitude),
                      15.0,
                    );
                  }
                : null,
            backgroundColor: Colors.blue.shade700,
            child: const Icon(Icons.my_location, size: 32),
          );
        },
      ),
    );
  }

  void _showNoOfflineMapDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Offline Map'),
        content: const Text(
          'You haven\'t downloaded any offline maps yet. '
          'Please download maps while online before using offline mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
