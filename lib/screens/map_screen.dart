import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/map_mode_service.dart';
import '../services/guide_book_service.dart';
import '../models/waypoint.dart' as models;

/// Enhanced Map Screen with MapLibre GL for offline support
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapLibreMapController? _mapController;
  bool _lockCenter = false;
  bool _headingUp = false;
  LatLng? _homeLocation;

  // Layer visibility toggles
  bool _showTransport = true;
  bool _showMedical = true;
  bool _showFood = true;
  bool _showAttractions = true;
  bool _showWaypoints = true;

  // Track added symbols for updates
  final Map<String, Symbol> _waypointSymbols = {};
  Symbol? _userSymbol;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMap(),

          // Menu button (top left)
          _buildMenuButton(),

          // Mode switcher (top center)
          _buildModeSwitcher(),

          // GPS indicator (top right)
          _buildGpsIndicator(),

          // Map controls (right side)
          _buildMapControls(),

          // HOME location button (bottom left)
          if (_homeLocation != null) _buildHomeButton(),

          // Center on location button (bottom right)
          _buildCenterButton(),

          // Test import button (temporary)
          _buildTestImportButton(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer3<LocationService, MapModeService, GuideBookService>(
      builder: (context, locationService, mapModeService, guideBookService,
          child) {
        final position = locationService.currentPosition;
        final center = position != null
            ? LatLng(position.latitude, position.longitude)
            : LatLng(41.3851, 2.1734); // Default: Barcelona

        // Update user location marker when position changes
        if (position != null && _mapController != null) {
          _updateUserMarker(position.latitude, position.longitude);

          // Auto-center if lock is enabled
          if (_lockCenter) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(center));
          }
        }

        return MapLibreMap(
          styleString: mapModeService.isOnline
              ? 'https://demotiles.maplibre.org/style.json'
              : _getOfflineStyleUrl(),
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: 15.0,
          ),
          minMaxZoomPreference: MinMaxZoomPreference(3.0, 19.0),
          myLocationEnabled: true,
          onMapCreated: (controller) async {
            _mapController = controller;
            debugPrint('✅ MapLibre map created');

            // Load waypoints after map is ready
            await Future.delayed(const Duration(milliseconds: 500));
            _updateWaypoints(guideBookService.activeGuideBook?.waypoints ?? []);
          },
          onMapClick: (point, coordinates) {
            debugPrint('🔵 Map clicked at: $coordinates');
          },
          onCameraIdle: () {
            // User manually moved map - disable lock
            if (_lockCenter) {
              setState(() => _lockCenter = false);
            }
          },
        );
      },
    );
  }

  String _getOfflineStyleUrl() {
    // TODO: Implement actual offline style loading
    // For now, use online fallback
    return 'https://demotiles.maplibre.org/style.json';
  }

  Future<void> _updateUserMarker(double lat, double lng) async {
    if (_mapController == null) return;

    try {
      // Remove old marker if exists
      if (_userSymbol != null) {
        await _mapController!.removeSymbol(_userSymbol!);
      }

      // Add new marker
      _userSymbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(lat, lng),
          iconImage: 'marker-15', // Built-in marker
          iconSize: 1.5,
          iconColor: '#0000FF',
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error updating user marker: $e');
    }
  }

  Future<void> _updateWaypoints(List<models.Waypoint> waypoints) async {
    if (_mapController == null) return;

    try {
      // Clear existing waypoint symbols
      for (final symbol in _waypointSymbols.values) {
        await _mapController!.removeSymbol(symbol);
      }
      _waypointSymbols.clear();

      // Filter waypoints by layer visibility
      final filteredWaypoints = waypoints.where((wp) {
        if (!_showWaypoints) return false;
        switch (wp.category.toLowerCase()) {
          case 'transport':
            return _showTransport;
          case 'medical':
            return _showMedical;
          case 'restaurant':
          case 'food':
            return _showFood;
          case 'attraction':
          case 'museum':
          case 'park':
          case 'shopping':
            return _showAttractions;
          default:
            return true;
        }
      }).toList();

      // Add new waypoint symbols
      for (final waypoint in filteredWaypoints) {
        final symbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(waypoint.latitude, waypoint.longitude),
            iconImage: 'marker-15',
            iconSize: 1.2,
            iconColor: _getWaypointColorHex(waypoint.category),
            textField: waypoint.name,
            textSize: 12.0,
            textOffset: Offset(0, 2),
            textColor: '#000000',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 2.0,
          ),
        );
        _waypointSymbols[waypoint.id] = symbol;
      }

      debugPrint('✅ Updated ${filteredWaypoints.length} waypoint markers');
    } catch (e) {
      debugPrint('⚠️ Error updating waypoints: $e');
    }
  }

  Widget _buildMenuButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 12,
      child: Tooltip(
        message: 'Layers',
        child: Material(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
          elevation: 2,
          child: InkWell(
            onTap: _showLayerMenu,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.layers, size: 26, color: Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 70,
      right: 70,
      child: Consumer<MapModeService>(
        builder: (context, mapModeService, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: _buildModeButton(
                    label: 'ONLINE',
                    isActive: mapModeService.isOnline,
                    color: Colors.green,
                    onTap: () => mapModeService.switchToOnline(),
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey.shade300),
                Expanded(
                  child: _buildModeButton(
                    label: 'OFFLINE',
                    isActive: mapModeService.isOffline,
                    color: Colors.blue,
                    onTap: () => mapModeService.switchToOffline(),
                  ),
                ),
              ],
            ),
          );
        },
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? color : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
      top: MediaQuery.of(context).padding.top + 12,
      right: 12,
      child: Consumer<LocationService>(
        builder: (context, locationService, child) {
          final hasPosition = locationService.currentPosition != null;
          return Tooltip(
            message: hasPosition ? 'GPS Active' : 'Acquiring GPS',
            child: Material(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(10),
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  hasPosition ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: hasPosition ? Colors.green.shade700 : Colors.orange.shade700,
                  size: 26,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 90,
      right: 12,
      child: Column(
        children: [
          // Heading Up toggle
          _buildControlButton(
            icon: _headingUp ? Icons.explore : Icons.explore_outlined,
            label: 'Heading Up',
            isActive: _headingUp,
            onTap: () {
              setState(() => _headingUp = !_headingUp);
              debugPrint('🔵 Heading Up: $_headingUp');
              // TODO: Implement compass heading rotation
            },
          ),
          const SizedBox(height: 6),

          // Lock Center toggle
          _buildControlButton(
            icon: _lockCenter ? Icons.gps_fixed : Icons.gps_not_fixed,
            label: 'Lock Center',
            isActive: _lockCenter,
            onTap: () {
              setState(() => _lockCenter = !_lockCenter);
              if (_lockCenter) {
                _centerOnUser();
              }
            },
          ),
          const SizedBox(height: 6),

          // Set HOME location
          _buildControlButton(
            icon: Icons.home_outlined,
            label: 'HOME',
            isActive: _homeLocation != null,
            onTap: _showHomeMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: isActive ? Colors.blue.shade700 : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 26,
              color: isActive ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton() {
    return Positioned(
      bottom: 24,
      left: 16,
      child: FloatingActionButton.extended(
        onPressed: () {
          if (_homeLocation != null && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_homeLocation!, 16.0),
            );
          }
        },
        backgroundColor: Colors.purple.shade700,
        icon: const Icon(Icons.home, size: 28),
        label: const Text(
          'Take Me Home',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
            onPressed: position != null ? _centerOnUser : null,
            backgroundColor: Colors.blue.shade700,
            child: const Icon(Icons.my_location, size: 32),
          );
        },
      ),
    );
  }

  Widget _buildTestImportButton() {
    return Positioned(
      bottom: 100,
      left: 16,
      child: Tooltip(
        message: 'Load Barcelona guide with 5 waypoints',
        child: FloatingActionButton.extended(
          onPressed: _testImportBarcelona,
          backgroundColor: Colors.orange.shade700,
          elevation: 2,
          icon: const Icon(Icons.map, size: 22),
          label: const Text(
            'Test Guide',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _centerOnUser() {
    final position = context.read<LocationService>().currentPosition;
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );
    }
  }

  Future<void> _testImportBarcelona() async {
    final guideBookService = context.read<GuideBookService>();

    final testJson = '''
{
  "id": "barcelona-2024",
  "version": "1.0",
  "guidebook_id": "geezer-guides-barcelona",
  "title": "GeezerGuides Barcelona",
  "city": "Barcelona",
  "country": "Spain",
  "author": "Geoff & Vicky Wells",
  "last_updated": "2024-01-15T10:00:00Z",
  "waypoints": [
    {
      "id": "wp-001",
      "name": "Sagrada Família",
      "category": "attraction",
      "description": "Antoni Gaudí's iconic unfinished masterpiece.",
      "address": "Carrer de Mallorca, 401, 08013 Barcelona",
      "book_id": "barcelona-2024",
      "latitude": 41.4036,
      "longitude": 2.1744,
      "is_visited": false,
      "is_wishlist": true
    },
    {
      "id": "wp-002",
      "name": "Park Güell",
      "category": "park",
      "description": "Colorful park with mosaic-covered structures by Gaudí.",
      "address": "08024 Barcelona, Spain",
      "book_id": "barcelona-2024",
      "latitude": 41.4145,
      "longitude": 2.1527,
      "is_visited": false,
      "is_wishlist": true
    },
    {
      "id": "wp-003",
      "name": "La Boqueria Market",
      "category": "food",
      "description": "Famous food market on Las Ramblas.",
      "address": "La Rambla, 91, 08001 Barcelona",
      "book_id": "barcelona-2024",
      "latitude": 41.3818,
      "longitude": 2.1717,
      "is_visited": false,
      "is_wishlist": false
    },
    {
      "id": "wp-004",
      "name": "Gothic Quarter",
      "category": "attraction",
      "description": "Medieval neighborhood with narrow streets.",
      "address": "Barri Gòtic, Barcelona",
      "book_id": "barcelona-2024",
      "latitude": 41.3828,
      "longitude": 2.1761,
      "is_visited": false,
      "is_wishlist": false
    },
    {
      "id": "wp-005",
      "name": "Casa Batlló",
      "category": "museum",
      "description": "Modernist building by Gaudí.",
      "address": "Passeig de Gràcia, 43, 08007 Barcelona",
      "book_id": "barcelona-2024",
      "latitude": 41.3916,
      "longitude": 2.1649,
      "is_visited": false,
      "is_wishlist": true
    }
  ]
}
''';

    final success = await guideBookService.importFromJson(testJson);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Barcelona guide imported! (5 waypoints)'
              : '❌ Failed to import guide'),
          backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );

      // Update markers and zoom to Barcelona
      if (success && _mapController != null) {
        final waypoints = guideBookService.activeGuideBook?.waypoints ?? [];
        await _updateWaypoints(waypoints);

        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(41.3851, 2.1734), 13.0),
        );
      }
    }
  }

  void _showLayerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map Layers',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildLayerToggle('Waypoints', Icons.place, _showWaypoints, (val) {
              setState(() => _showWaypoints = val);
              final waypoints = context.read<GuideBookService>().activeGuideBook?.waypoints ?? [];
              _updateWaypoints(waypoints);
              Navigator.pop(context);
            }),
            _buildLayerToggle('Attractions', Icons.star, _showAttractions, (val) {
              setState(() => _showAttractions = val);
              final waypoints = context.read<GuideBookService>().activeGuideBook?.waypoints ?? [];
              _updateWaypoints(waypoints);
              Navigator.pop(context);
            }),
            _buildLayerToggle('Food & Restaurants', Icons.restaurant, _showFood, (val) {
              setState(() => _showFood = val);
              final waypoints = context.read<GuideBookService>().activeGuideBook?.waypoints ?? [];
              _updateWaypoints(waypoints);
              Navigator.pop(context);
            }),
            _buildLayerToggle('Transport', Icons.directions_transit, _showTransport, (val) {
              setState(() => _showTransport = val);
              final waypoints = context.read<GuideBookService>().activeGuideBook?.waypoints ?? [];
              _updateWaypoints(waypoints);
              Navigator.pop(context);
            }),
            _buildLayerToggle('Medical', Icons.local_hospital, _showMedical, (val) {
              setState(() => _showMedical = val);
              final waypoints = context.read<GuideBookService>().activeGuideBook?.waypoints ?? [];
              _updateWaypoints(waypoints);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerToggle(
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.grey.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 18)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue.shade700,
          ),
        ],
      ),
    );
  }

  void _showHomeMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'HOME Location',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your hotel or accommodation as HOME',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.add_location, size: 32, color: Colors.blue.shade700),
              title: const Text('Set Current Location as HOME',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              onTap: () {
                final position = context.read<LocationService>().currentPosition;
                if (position != null) {
                  setState(() {
                    _homeLocation = LatLng(position.latitude, position.longitude);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ HOME location set!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            if (_homeLocation != null)
              ListTile(
                leading: Icon(Icons.clear, size: 32, color: Colors.red.shade700),
                title: Text('Clear HOME Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red.shade700)),
                onTap: () {
                  setState(() => _homeLocation = null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  String _getWaypointColorHex(String category) {
    switch (category.toLowerCase()) {
      case 'attraction':
        return '#D32F2F';
      case 'restaurant':
      case 'food':
        return '#F57C00';
      case 'hotel':
      case 'accommodation':
        return '#7B1FA2';
      case 'museum':
        return '#5D4037';
      case 'park':
        return '#388E3C';
      case 'shopping':
        return '#C2185B';
      case 'transport':
        return '#1976D2';
      case 'medical':
        return '#B71C1C';
      default:
        return '#616161';
    }
  }
}
