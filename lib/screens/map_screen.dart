import 'dart:math' show Point;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/map_mode_service.dart';
import '../services/guide_book_service.dart';
import '../services/offline_map_service.dart';
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
    return Consumer4<LocationService, MapModeService, GuideBookService, OfflineMapService>(
      builder: (context, locationService, mapModeService, guideBookService, offlineMapService,
          child) {
        final position = locationService.currentPosition;

        // Determine center: if offline mode and target is set, use target; otherwise use user location
        final LatLng center;
        if (mapModeService.isOffline && mapModeService.targetLat != null && mapModeService.targetLng != null) {
          center = LatLng(mapModeService.targetLat!, mapModeService.targetLng!);
        } else if (position != null) {
          center = LatLng(position.latitude, position.longitude);
        } else {
          center = LatLng(41.3851, 2.1734); // Default: Barcelona
        }

        // Update or remove user location marker based on GPS tracking state
        if (_mapController != null) {
          if (locationService.isTracking && position != null) {
            _updateUserMarker(position.latitude, position.longitude);
          } else {
            _removeUserMarker();
          }

          // Move camera to target location when switching to offline mode
          if (mapModeService.isOffline && mapModeService.targetLat != null && mapModeService.targetLng != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(mapModeService.targetLat!, mapModeService.targetLng!),
                14.0,
              ),
            );
          }
        }

        return Stack(
          children: [
            MapLibreMap(
              key: ValueKey('${mapModeService.isOnline}_${mapModeService.selectedOfflineMapId}'), // Force rebuild when mode or map changes
              styleString: mapModeService.isOnline
                  ? 'https://tiles.openfreemap.org/styles/liberty'
                  : _getOfflineStyleUrl(mapModeService, offlineMapService),
              initialCameraPosition: CameraPosition(
                target: center,
                zoom: 12.0, // Zoom 12 shows city overview with detail
              ),
              minMaxZoomPreference: MinMaxZoomPreference(3.0, 19.0),
              myLocationEnabled: false, // Disabled - we handle location display ourselves
              compassEnabled: true,
              compassViewPosition: CompassViewPosition.bottomLeft,
              compassViewMargins: const Point(16, 80),
              attributionButtonMargins: const Point(-1000, -1000), // Hide attribution far off-screen
              logoViewMargins: const Point(-1000, -1000), // Hide logo far off-screen
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
            ),
            // Custom attribution overlay
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  mapModeService.isOnline ? '© OSM (ONLINE)' : '© OSM (OFFLINE - ${mapModeService.selectedOfflineMapId ?? "none"})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getOfflineStyleUrl(MapModeService mapModeService, OfflineMapService offlineMapService) {
    // If no offline map is selected, fallback to satellite (visual indicator)
    if (mapModeService.selectedOfflineMapId == null) {
      debugPrint('⚠️ No offline map selected, using satellite style as fallback');
      return 'https://tiles.openfreemap.org/styles/satellite';
    }

    // Use the cached offline style file path if available
    if (mapModeService.offlineStyleJson != null) {
      debugPrint('✅ Using cached offline style file for ${mapModeService.selectedOfflineMapId}');
      debugPrint('📁 Style file path: ${mapModeService.offlineStyleJson!}');
      return mapModeService.offlineStyleJson!;
    }

    // If style JSON not cached, fallback to satellite
    debugPrint('⚠️ Offline style JSON not cached, using satellite as fallback');
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
