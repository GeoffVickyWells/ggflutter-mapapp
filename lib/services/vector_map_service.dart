import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Service to manage vector map tiles (MBTiles format served via local server)
class VectorMapService extends ChangeNotifier {
  bool _isInitialized = false;

  bool get isServerRunning => _isInitialized;

  /// Available vector maps bundled with the app
  final List<VectorMapInfo> _availableMaps = [
    VectorMapInfo(
      id: 'barcelona',
      name: 'Barcelona, Spain',
      fileName: 'barcelona.mbtiles',
      centerLat: 41.3851,
      centerLng: 2.1734,
      bounds: VectorMapBounds(
        minLat: 41.32,
        maxLat: 41.47,
        minLng: 2.05,
        maxLng: 2.25,
      ),
    ),
    VectorMapInfo(
      id: 'eleuthera',
      name: 'Eleuthera, Bahamas',
      fileName: 'eleuthera.mbtiles',
      centerLat: 25.15,
      centerLng: -76.225,
      bounds: VectorMapBounds(
        minLat: 24.70,
        maxLat: 25.60,
        minLng: -76.35,
        maxLng: -76.10,
      ),
    ),
  ];

  List<VectorMapInfo> get availableMaps => _availableMaps;

  /// Initialize vector maps (no conversion needed - MBTiles served via TileServerService)
  Future<bool> startTileServer() async {
    if (_isInitialized) return true;

    debugPrint('✅ Vector maps initialized (serving MBTiles via TileServerService)');
    _isInitialized = true;
    notifyListeners();
    return true;
  }

  /// Stop (cleanup) - not needed for this implementation
  Future<void> stopTileServer() async {
    // No-op - MBTiles are served by TileServerService
  }

  /// Check if a map is ready to use (always true since MBTiles are in assets)
  bool isMapReady(String mapId) {
    return _availableMaps.any((m) => m.id == mapId);
  }

  /// Get the style JSON for a specific map
  Future<Map<String, dynamic>> getStyleJsonObject(String mapId, String tileUrl) async {
    // Load the OSM Bright style (compatible with Tilemaker OSM schema)
    final baseStyle = await rootBundle.loadString('assets/osm_bright.json');
    final styleJson = jsonDecode(baseStyle) as Map<String, dynamic>;

    // Update the source to use the local tile server URL
    styleJson['sources']['osm'] = {
      'type': 'vector',
      'tiles': [tileUrl],
      'minzoom': 0,
      'maxzoom': 14,
    };

    return styleJson;
  }

  /// Get the style JSON as a string
  Future<String> getStyleJson(String mapId, String tileUrl) async {
    final styleObj = await getStyleJsonObject(mapId, tileUrl);
    return jsonEncode(styleObj);
  }

  @override
  void dispose() {
    stopTileServer();
    super.dispose();
  }
}

/// Information about a vector map
class VectorMapInfo {
  final String id;
  final String name;
  final String fileName;
  final double centerLat;
  final double centerLng;
  final VectorMapBounds bounds;

  VectorMapInfo({
    required this.id,
    required this.name,
    required this.fileName,
    required this.centerLat,
    required this.centerLng,
    required this.bounds,
  });
}

/// Bounding box for a vector map
class VectorMapBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  VectorMapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}
