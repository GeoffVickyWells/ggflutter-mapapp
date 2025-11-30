# GeezerGuides Flutter - Session Progress

## ✅ Completed This Session

### 1. Flutter Setup Verified
- Flutter 3.35.4 installed and working
- Xcode 26.1.1 configured
- iOS development environment ready

### 2. Dependencies Updated
**Switched from flutter_map to MapLibre GL:**
- ✅ Added `maplibre_gl: ^0.20.0` - Full offline map support
- ✅ Kept `geolocator: ^13.0.2` - GPS location services
- ✅ Kept `permission_handler: ^11.3.1` - Runtime permissions
- ✅ Kept `path_provider: ^2.1.4` - File system access
- ✅ Kept `sqflite: ^2.3.3+1` - Local database
- ✅ Kept `provider: ^6.1.2` - State management

**Dependencies installed successfully** via `flutter pub get`

### 3. Migration Plan Created
- Comprehensive **MAPLIBRE_MIGRATION_PLAN.md** in Swift project
- 4-phase implementation guide
- Code examples for all features
- Timeline: 9-13 hours over 4 sessions

---

## 📋 Next Session Tasks

### Phase 1: Data Models (30-45 min)

**Create lib/models/waypoint.dart:**
```dart
class Waypoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final String notes;
  final bool isVisited;
  final bool isWishlist;

  // Constructor, fromJson, toJson methods
}
```

**Create lib/models/guidebook.dart:**
```dart
class GuideBook {
  final String name;
  final String version;
  final List<Waypoint> waypoints;

  // Constructor, fromJson, toJson methods
}
```

### Phase 2: Basic Map Display (1-2 hours)

**Create lib/screens/map_screen.dart:**
```dart
import 'package:maplibre_gl/maplibre_gl.dart';

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MaplibreMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MaplibreMap(
        styleString: 'https://demotiles.maplibre.org/style.json',
        initialCameraPosition: CameraPosition(
          target: LatLng(41.3874, 2.1686), // Barcelona
          zoom: 12.0,
        ),
        onMapCreated: (controller) {
          setState(() {
            _mapController = controller;
          });
        },
        myLocationEnabled: true,
      ),
    );
  }
}
```

### Phase 3: Offline Maps Management (Next Priority)

1. **Sign up for MapTiler** (free tier): https://www.maptiler.com/
2. Get API key for tile downloads
3. Implement offline region download
4. Create UI for managing offline regions

---

## 🎯 Current Status

**What Works:**
- ✅ Flutter project structure
- ✅ MapLibre GL dependency installed
- ✅ iOS build environment ready

**What's Next:**
1. Port data models from Swift
2. Create basic map display
3. Add offline region management
4. Port .geezerguide file import

---

## 📁 Project Structure (Target)

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── waypoint.dart        # Waypoint data model
│   ├── guidebook.dart       # GuideBook container
│   └── offline_region.dart  # Offline map regions
├── services/
│   ├── map_service.dart     # Map operations
│   ├── offline_manager.dart # Offline downloads
│   └── location_service.dart # GPS tracking
├── screens/
│   ├── map_screen.dart      # Main map view
│   ├── offline_maps_screen.dart # Manage downloads
│   └── guides_screen.dart   # Import .geezerguide files
└── widgets/
    ├── waypoint_marker.dart # Custom map markers
    └── liquid_glass_card.dart # UI components
```

---

## ⚡ Quick Start Next Session

```bash
# 1. Navigate to Flutter project
cd "/Users/geoffmacbook/xCode Projects/geezer_guides_flutter"

# 2. Verify dependencies
flutter pub get

# 3. Create models directory
mkdir -p lib/models

# 4. Start coding!
# Create waypoint.dart and guidebook.dart

# 5. Run on simulator
flutter run
```

---

## 🔑 Key Decisions Made

1. **Use MapLibre GL** instead of flutter_map for offline support
2. **Start with MapTiler** free tier for tiles (upgrade later if needed)
3. **iOS first**, Android second (single codebase works for both)
4. **Port existing .geezerguide format** - keep file compatibility

---

## 📝 Notes

- MapLibre GL v0.20.0 installed (v0.24.1 available but using stable)
- uni_links discontinued, will need to migrate to app_links eventually
- 14 packages have newer versions - can upgrade after MVP works

---

**Ready to build proper offline maps! 🗺️**
