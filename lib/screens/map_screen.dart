import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/map_mode_service.dart';
import '../services/guide_book_service.dart';
import '../models/waypoint.dart';
import 'dart:io';

/// Enhanced Map Screen with full UI controls
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _lockCenter = false;
  bool _headingUp = false;
  LatLng? _homeLocation;

  // Layer visibility toggles
  bool _showTransport = true;
  bool _showMedical = true;
  bool _showFood = true;
  bool _showAttractions = true;
  bool _showWaypoints = true;

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

        // Get waypoints and filter by layer visibility
        final allWaypoints = guideBookService.activeGuideBook?.waypoints ?? [];
        final filteredWaypoints = allWaypoints.where((wp) {
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

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15.0,
            minZoom: 3.0,
            maxZoom: 19.0,
            onPositionChanged: (position, hasGesture) {
              // Disable lock center if user manually moves map
              if (hasGesture && _lockCenter) {
                setState(() => _lockCenter = false);
              }
            },
          ),
          children: [
            // Tile layer - CRITICAL FOR OFFLINE QUALITY
            TileLayer(
              urlTemplate: mapModeService.isOnline
                  ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                  : _getOfflineTilePath(),
              userAgentPackageName: 'com.geezerguides.app',
              maxNativeZoom: 19, // Critical for street-level detail
              minNativeZoom: 1,
              tileSize: 256,
              // Offline tile loading
              tileProvider: mapModeService.isOffline
                  ? FileTileProvider()
                  : NetworkTileProvider(),
            ),

            // Waypoint markers
            if (filteredWaypoints.isNotEmpty)
              MarkerLayer(
                markers: filteredWaypoints.map((waypoint) {
                  return Marker(
                    point: LatLng(waypoint.latitude, waypoint.longitude),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showWaypointDetails(waypoint),
                      child: _buildWaypointMarker(waypoint),
                    ),
                  );
                }).toList(),
              ),

            // HOME location marker
            if (_homeLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _homeLocation!,
                    width: 60,
                    height: 60,
                    child: _buildHomeMarker(),
                  ),
                ],
              ),

            // User location marker (always on top)
            if (position != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(position.latitude, position.longitude),
                    width: 40,
                    height: 40,
                    child: _buildUserMarker(),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  String _getOfflineTilePath() {
    // TODO: Implement actual offline tile storage
    // For now, return placeholder for UI testing
    return 'file:///path/to/offline/tiles/{z}/{x}/{y}.png';
  }

  Widget _buildUserMarker() {
    return Container(
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
    );
  }

  Widget _buildHomeMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.purple.shade700, width: 3),
      ),
      child: Icon(
        Icons.home,
        color: Colors.purple.shade700,
        size: 32,
      ),
    );
  }

  Widget _buildWaypointMarker(Waypoint waypoint) {
    final iconData = _getWaypointIcon(waypoint.category);
    final color = _getWaypointColor(waypoint.category);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            iconData,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
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
          if (_homeLocation != null) {
            _mapController.move(_homeLocation!, 16.0);
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
    if (position != null) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    }
  }

  void _testImportBarcelona() async {
    final guideBookService = context.read<GuideBookService>();

    // Use importFromJson instead of file path (works on simulator)
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
      "description": "Antoni Gaudí's iconic unfinished masterpiece. A stunning basilica with intricate facades and breathtaking interior.",
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
      "description": "Colorful park with mosaic-covered structures designed by Gaudí. Offers panoramic views of Barcelona.",
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
      "description": "Famous food market on Las Ramblas. Fresh produce, seafood, jamón, and tapas bars.",
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
      "description": "Medieval neighborhood with narrow streets, hidden squares, and historic buildings.",
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
      "description": "Modernist building by Gaudí with unique organic shapes and colorful tiles.",
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

      // Zoom to Barcelona center after import
      if (success) {
        _mapController.move(LatLng(41.3851, 2.1734), 13.0);
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
              Navigator.pop(context);
            }),
            _buildLayerToggle('Attractions', Icons.star, _showAttractions,
                (val) {
              setState(() => _showAttractions = val);
              Navigator.pop(context);
            }),
            _buildLayerToggle('Food & Restaurants', Icons.restaurant, _showFood,
                (val) {
              setState(() => _showFood = val);
              Navigator.pop(context);
            }),
            _buildLayerToggle(
                'Transport', Icons.directions_transit, _showTransport, (val) {
              setState(() => _showTransport = val);
              Navigator.pop(context);
            }),
            _buildLayerToggle('Medical', Icons.local_hospital, _showMedical,
                (val) {
              setState(() => _showMedical = val);
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
            child: Text(
              label,
              style: const TextStyle(fontSize: 18),
            ),
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

  void _showWaypointDetails(Waypoint waypoint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWaypointDetailSheet(waypoint),
    );
  }

  Widget _buildWaypointDetailSheet(Waypoint waypoint) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        final distance = locationService.distanceTo(
          waypoint.latitude,
          waypoint.longitude,
        );
        final distanceText = distance != null
            ? '${(distance / 1000).toStringAsFixed(1)} km away'
            : 'Distance unknown';

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getWaypointColor(waypoint.category),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(_getWaypointIcon(waypoint.category),
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          waypoint.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(distanceText,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 16),
              Text(waypoint.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (waypoint.address != null)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(child: Text(waypoint.address!,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700))),
                  ],
                ),
              const SizedBox(height: 16),
              if (waypoint.description != null)
                Text(waypoint.description!,
                    style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _mapController.move(
                      LatLng(waypoint.latitude, waypoint.longitude), 17.0);
                },
                icon: const Icon(Icons.navigation, size: 24),
                label: const Text('Navigate', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getWaypointIcon(String category) {
    switch (category.toLowerCase()) {
      case 'attraction':
        return Icons.star;
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'hotel':
      case 'accommodation':
        return Icons.hotel;
      case 'museum':
        return Icons.museum;
      case 'park':
        return Icons.park;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transport':
        return Icons.directions_transit;
      case 'medical':
        return Icons.local_hospital;
      default:
        return Icons.place;
    }
  }

  Color _getWaypointColor(String category) {
    switch (category.toLowerCase()) {
      case 'attraction':
        return Colors.red.shade700;
      case 'restaurant':
      case 'food':
        return Colors.orange.shade700;
      case 'hotel':
      case 'accommodation':
        return Colors.purple.shade700;
      case 'museum':
        return Colors.brown.shade700;
      case 'park':
        return Colors.green.shade700;
      case 'shopping':
        return Colors.pink.shade700;
      case 'transport':
        return Colors.blue.shade700;
      case 'medical':
        return Colors.red.shade900;
      default:
        return Colors.grey.shade700;
    }
  }
}
