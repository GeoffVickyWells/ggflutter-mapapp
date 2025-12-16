import 'package:flutter/foundation.dart';

/// Map display modes - these are COMPLETELY SEPARATE
enum MapMode {
  online, // Streams tiles from internet
  offline, // Only shows pre-downloaded tiles
}

/// Map Mode Service - manages online vs offline mode
/// CRITICAL: These modes do NOT share data
/// - Online mode: Downloads tiles dynamically as needed
/// - Offline mode: ONLY displays locally stored tiles
class MapModeService extends ChangeNotifier {
  MapMode _currentMode = MapMode.online;
  String? _selectedOfflineMapId = 'barcelona'; // Default to barcelona

  MapMode get currentMode => _currentMode;
  String? get selectedOfflineMapId => _selectedOfflineMapId;

  bool get isOnline => _currentMode == MapMode.online;
  bool get isOffline => _currentMode == MapMode.offline;

  /// Get the tile URL template based on current mode
  String getTileUrlTemplate() {
    if (_currentMode == MapMode.online) {
      // OpenStreetMap tile server
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    } else {
      // Offline tiles stored locally
      // Will be replaced with actual local file path
      return 'file:///offline_tiles/{z}/{x}/{y}.png';
    }
  }

  /// Switch to online mode
  void switchToOnline() {
    debugPrint('🔵 MapModeService: Switching to ONLINE mode');
    _currentMode = MapMode.online;
    notifyListeners();
  }

  /// Switch to offline mode
  /// Returns false if no offline map is selected
  bool switchToOffline() {
    if (_selectedOfflineMapId == null) {
      debugPrint(
          '⚠️ MapModeService: Cannot switch to offline - no map selected');
      return false;
    }

    debugPrint('🔵 MapModeService: Switching to OFFLINE mode (map: $_selectedOfflineMapId)');
    _currentMode = MapMode.offline;
    notifyListeners();
    return true;
  }

  /// Select an offline map
  void selectOfflineMap(String mapId) {
    debugPrint('✅ MapModeService: Selected offline map: $mapId');
    _selectedOfflineMapId = mapId;
    notifyListeners();
  }

  /// Deselect offline map
  void deselectOfflineMap() {
    debugPrint('🔵 MapModeService: Deselected offline map');
    _selectedOfflineMapId = null;

    // If we're in offline mode, switch back to online
    if (_currentMode == MapMode.offline) {
      switchToOnline();
    } else {
      notifyListeners();
    }
  }

  /// Check if we have an offline map selected
  bool get hasOfflineMapSelected => _selectedOfflineMapId != null;
}
