import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Location service - handles GPS and permissions
/// CRITICAL: Location permission is MANDATORY for app to function
class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _permissionGranted = false;
  bool _serviceEnabled = false;
  String? _errorMessage;

  Position? get currentPosition => _currentPosition;
  bool get permissionGranted => _permissionGranted;
  bool get serviceEnabled => _serviceEnabled;
  String? get errorMessage => _errorMessage;

  /// Check if app is ready to use (has location permission)
  bool get isReady => _permissionGranted && _serviceEnabled;

  /// Initialize location service - MUST be called at app startup
  Future<bool> initialize() async {
    debugPrint('🔵 LocationService: Initializing...');

    // Step 1: Check if location services are enabled on device
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_serviceEnabled) {
      _errorMessage =
          'Location services are disabled. Please enable them in Settings.';
      debugPrint('❌ LocationService: Location services disabled');
      notifyListeners();
      return false;
    }

    // Step 2: Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('🔵 LocationService: Current permission: $permission');

    // Step 3: Request permission if needed
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage =
            'GeezerGuides requires location access to function. Please enable location permissions in Settings.';
        debugPrint('❌ LocationService: Permission denied by user');
        notifyListeners();
        return false;
      }
    }

    // Step 4: Handle permanently denied
    if (permission == LocationPermission.deniedForever) {
      _errorMessage =
          'Location permissions are permanently denied. Please enable them in Settings > GeezerGuides > Location.';
      debugPrint('❌ LocationService: Permission permanently denied');
      notifyListeners();
      return false;
    }

    // Step 5: Permission granted!
    _permissionGranted = true;
    _errorMessage = null;
    debugPrint('✅ LocationService: Permission granted');

    // Step 6: Get initial position
    await updatePosition();

    // Step 7: Start listening for position updates
    startPositionStream();

    notifyListeners();
    return true;
  }

  /// Update current position (works offline - GPS doesn't need internet)
  Future<void> updatePosition() async {
    if (!_permissionGranted) {
      debugPrint('⚠️ LocationService: Cannot update position - no permission');
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      );
      debugPrint(
          '✅ LocationService: Position updated: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get GPS position: $e';
      debugPrint('❌ LocationService: Error getting position: $e');
      notifyListeners();
    }
  }

  /// Start listening to position changes (for real-time tracking)
  void startPositionStream() {
    if (!_permissionGranted) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _currentPosition = position;
      notifyListeners();
    });

    debugPrint('✅ LocationService: Position stream started');
  }

  /// Open device settings (for when permission is denied)
  Future<void> openSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Calculate distance to a coordinate (returns meters)
  double? distanceTo(double latitude, double longitude) {
    if (_currentPosition == null) return null;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }
}
