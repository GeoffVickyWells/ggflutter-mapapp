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

  // Track added symbols for updates
  final Map<String, Symbol> _waypointSymbols = {};
  Circle? _userLocationCircle;

  @override
  Widget build(BuildContext context) {
    // Just render the map - no UI controls
    // MainScreen handles all UI overlays
    return _buildMap();
  }

  Widget _buildMap() {
    return Consumer3<LocationService, MapModeService, GuideBookService>(
      builder: (context, locationService, mapModeService, guideBookService,
          child) {
        final position = locationService.currentPosition;
        final center = position != null
            ? LatLng(position.latitude, position.longitude)
            : LatLng(41.3851, 2.1734); // Default: Barcelona

        // Update or remove user location marker based on GPS tracking state
        if (_mapController != null) {
          if (locationService.isTracking && position != null) {
            _updateUserMarker(position.latitude, position.longitude);
          } else {
            _removeUserMarker();
          }
        }

        return MapLibreMap(
          key: ValueKey(mapModeService.isOnline), // Force rebuild when mode changes
          styleString: mapModeService.isOnline
              ? 'https://tiles.openfreemap.org/styles/liberty'
              : _getOfflineStyleUrl(),
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: 15.0,
          ),
          minMaxZoomPreference: MinMaxZoomPreference(3.0, 19.0),
          myLocationEnabled: false, // Disabled - we handle location display ourselves
          onMapCreated: (controller) async {
            _mapController = controller;
            debugPrint('✅ MapLibre map created (${mapModeService.isOnline ? "ONLINE" : "OFFLINE"} mode)');

            // Load waypoints after map is ready
            await Future.delayed(const Duration(milliseconds: 500));
            _updateWaypoints(guideBookService.activeGuideBook?.waypoints ?? []);
          },
          onMapClick: (point, coordinates) {
            debugPrint('🔵 Map clicked at: $coordinates');
          },
        );
      },
    );
  }

  String _getOfflineStyleUrl() {
    // TODO: Implement actual offline style loading from local storage
    // For now, use a visually different online style (satellite) so user can see the toggle working
    return 'https://tiles.openfreemap.org/styles/satellite';
  }

  Future<void> _updateUserMarker(double lat, double lng) async {
    if (_mapController == null) return;

    try {
      // Remove old circle if exists
      if (_userLocationCircle != null) {
        await _mapController!.removeCircle(_userLocationCircle!);
      }

      // Add blue circle for user location
      _userLocationCircle = await _mapController!.addCircle(
        CircleOptions(
          geometry: LatLng(lat, lng),
          circleRadius: 8.0,
          circleColor: '#4285F4', // Google Maps blue
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2.0,
        ),
      );
      debugPrint('✅ User location updated: $lat, $lng');
    } catch (e) {
      debugPrint('⚠️ Error updating user location: $e');
    }
  }

  Future<void> _removeUserMarker() async {
    if (_mapController == null || _userLocationCircle == null) return;

    try {
      await _mapController!.removeCircle(_userLocationCircle!);
      _userLocationCircle = null;
      debugPrint('✅ User location marker removed');
    } catch (e) {
      debugPrint('⚠️ Error removing user location: $e');
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

      // Add new waypoint symbols (all waypoints visible for now)
      for (final waypoint in waypoints) {
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

      debugPrint('✅ Updated ${waypoints.length} waypoint markers');
    } catch (e) {
      debugPrint('⚠️ Error updating waypoints: $e');
    }
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
