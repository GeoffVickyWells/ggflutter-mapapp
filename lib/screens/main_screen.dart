import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'map_screen.dart';
import '../services/map_mode_service.dart';
import '../services/location_service.dart';

/// Minimalist main screen with fullscreen map and 3 controls:
/// - Top-left: Settings (gear icon)
/// - Top-right: Map Upload (upload icon)
/// - Top-center: Live/Offline toggle
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsSheet(),
    );
  }

  void _showMapLoadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMapLoadSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen map
          const MapScreen(),

          // Top controls overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildTopControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
      child: Row(
        children: [
          // Settings button (top-left)
          _buildControlButton(
            icon: Icons.settings,
            onPressed: _showSettingsSheet,
          ),

          const Spacer(),

          // Center controls: GPS toggle + Live/Offline toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // GPS toggle
              Consumer<LocationService>(
                builder: (context, locationService, child) {
                  return _buildControlButton(
                    icon: locationService.isTracking
                        ? Icons.gps_fixed
                        : Icons.gps_off,
                    onPressed: () => locationService.toggleTracking(),
                    isActive: locationService.isTracking,
                  );
                },
              ),
              const SizedBox(width: 12),
              // Live/Offline toggle
              _buildModeToggle(),
            ],
          ),

          const Spacer(),

          // Map Library button (top-right)
          _buildControlButton(
            icon: Icons.file_download_outlined,
            onPressed: _showMapLoadSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = true,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.85)
                : Colors.grey.shade300.withOpacity(0.65),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  size: 22,
                  color: isActive ? Colors.grey.shade800 : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Consumer<MapModeService>(
      builder: (context, mapModeService, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleOption(
                    label: 'Live',
                    isSelected: mapModeService.isOnline,
                    onTap: () => mapModeService.switchToOnline(),
                  ),
                  _buildToggleOption(
                    label: 'Offline',
                    isSelected: !mapModeService.isOnline,
                    onTap: () {
                      final success = mapModeService.switchToOffline();
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'No offline map available. Please download a map first.',
                            ),
                            action: SnackBarAction(
                              label: 'Download',
                              onPressed: _showMapLoadSheet,
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Settings content (placeholder for now)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'POI Filter Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Coming soon: POI filters, map type, Where am I, Direction Up, Save Home'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLoadSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Map Library',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Map load content (placeholder for now)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                Text('Coming soon: Search and download offline maps'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
