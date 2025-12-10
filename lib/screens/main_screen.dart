import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'map_screen.dart';
import '../services/map_mode_service.dart';
import '../services/location_service.dart';
import '../services/offline_map_service.dart';
import '../services/tile_server_service.dart';
import '../services/vector_map_service.dart';

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
  List<Location> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';

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
      isDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return _buildMapLoadSheet(setModalState);
        },
      ),
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
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
              Consumer2<LocationService, MapModeService>(
                builder: (context, locationService, mapModeService, child) {
                  return _buildControlButton(
                    icon: locationService.isTracking
                        ? Icons.gps_fixed
                        : Icons.gps_off,
                    onPressed: () {
                      if (mapModeService.isOffline && !locationService.isTracking) {
                        // Show message in offline mode
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Your current location cannot be displayed on this map'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else {
                        locationService.toggleTracking();
                      }
                    },
                    isActive: locationService.isTracking,
                  );
                },
              ),
              const SizedBox(width: 12),
              // Live/Offline toggle
              Consumer3<OfflineMapService, TileServerService, VectorMapService>(
                builder: (context, offlineMapService, tileServerService, vectorMapService, child) {
                  return _buildModeToggle(offlineMapService, tileServerService, vectorMapService);
                },
              ),
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

  Widget _buildModeToggle(OfflineMapService offlineMapService, TileServerService tileServerService, VectorMapService vectorMapService) {
    return Consumer<MapModeService>(
      builder: (context, mapModeService, child) {
        final hasAnyMaps = offlineMapService.downloadedMaps.isNotEmpty ||
                          vectorMapService.availableMaps.isNotEmpty;
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
                    onTap: () {
                      mapModeService.switchToOnline();
                      // Keep tile server running (needed for offline maps and fonts)
                    },
                  ),
                  _buildToggleOption(
                    label: 'Offline',
                    isSelected: !mapModeService.isOnline,
                    onTap: () async {
                      // Check if we have any maps
                      if (!hasAnyMaps) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'No offline maps available. Use Map Library to select a map.',
                            ),
                            action: SnackBarAction(
                              label: 'Open',
                              onPressed: _showMapLoadSheet,
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return;
                      }

                      // Ensure tile server is running for offline mode
                      if (!tileServerService.isRunning) {
                        await tileServerService.start();
                      }

                      // Check if a map is selected
                      if (!mapModeService.hasOfflineMapSelected) {
                        // Auto-select the first available map (prefer vector maps)
                        if (vectorMapService.availableMaps.isNotEmpty) {
                          final firstVectorMap = vectorMapService.availableMaps.first;
                          final tileUrl = tileServerService.getTileUrlTemplate(firstVectorMap.id, isVector: true);
                          final fontGlyphsUrl = tileServerService.getFontGlyphsUrl();
                          final styleJson = await vectorMapService.getStyleJson(firstVectorMap.id, tileUrl, fontGlyphsUrl: fontGlyphsUrl);
                          mapModeService.selectOfflineMap(
                            firstVectorMap.id,
                            styleJson: styleJson,
                            targetLat: firstVectorMap.centerLat,
                            targetLng: firstVectorMap.centerLng,
                          );
                        }
                        // Note: Raster maps are no longer supported - only vector maps
                      }

                      // Switch to offline mode
                      final success = mapModeService.switchToOffline();
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to switch to offline mode'),
                            behavior: SnackBarBehavior.floating,
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
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap(),
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

          // Settings content
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

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                Text(
                  'Map Attribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Map data © OpenStreetMap contributors\n\n'
                  'OpenStreetMap is a free, editable map of the whole world created by volunteers. '
                  'The map tiles are provided by OpenFreeMap.\n\n'
                  'This app uses MapLibre GL, an open-source library for rendering maps.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      debugPrint('🔍 Searching for: $query');
      final locations = await locationFromAddress(query);
      debugPrint('✅ Found ${locations.length} results');

      setState(() {
        _searchResults = locations;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('❌ Search error: $e');
      setState(() {
        _searchResults = [];
        _searchError = 'No results found. Try a different search term.';
        _isSearching = false;
      });
    }
  }

  Widget _buildMapLoadSheet(StateSetter setModalState) {
    return Consumer2<OfflineMapService, VectorMapService>(
      builder: (context, offlineMapService, vectorMapService, child) {
        final downloadedMaps = offlineMapService.downloadedMaps;
        // Filter out completed downloads from progress display
        final activeDownloads = Map<String, DownloadProgress>.fromEntries(
          offlineMapService.downloadProgress.entries.where((entry) => !entry.value.isComplete),
        );

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
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
                    IconButton(
                      onPressed: () async {
                        // Import pre-built MBTiles files
                        final count = await offlineMapService.importMBTilesFiles();
                        if (context.mounted) {
                          // Close the sheet first
                          Navigator.pop(context);

                          // Show result dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(count > 0 ? 'Import Complete' : 'No Maps Found'),
                              content: Text(
                                count > 0
                                    ? 'Successfully imported $count map${count > 1 ? 's' : ''}!'
                                    : 'No new .mbtiles files found to import.\n\nMake sure you copied the files using Finder > Files tab.',
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
                      },
                      icon: const Icon(Icons.upload_file),
                      tooltip: 'Import Maps',
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Vector Maps Section (Bundled with app)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Row(
                  children: [
                    Text(
                      'Vector Maps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'Bundled',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'High-quality maps included with the app',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              ...vectorMapService.availableMaps.map((vectorMap) =>
                _buildVectorMapTile(vectorMap, context, vectorMapService, setModalState)),
              const Divider(height: 32),

              // Downloaded Maps Section
              if (downloadedMaps.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        'Downloaded Maps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Slide left to delete',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                ...downloadedMaps.map((region) => _buildDownloadedMapTile(
                    region, context, offlineMapService)),
                const Divider(height: 32),
              ],

              // Download Progress Section (only show active downloads)
              if (activeDownloads.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Downloading',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                ...activeDownloads.entries.map(
                    (entry) => _buildDownloadProgressTile(entry.value, context,
                        offlineMapService)),
                const Divider(height: 32),
              ],

              // Available Maps Section (from AWS)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Available Maps',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Download high-resolution city maps',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Dropdown for available maps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Select a city to download...',
                    prefixIcon: const Icon(Icons.cloud_download),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'barcelona',
                      child: Text('Barcelona, Spain'),
                    ),
                    DropdownMenuItem(
                      value: 'eleuthera',
                      child: Text('Eleuthera, Bahamas'),
                    ),
                    DropdownMenuItem(
                      value: 'rome',
                      child: Text('Rome, Italy'),
                    ),
                    DropdownMenuItem(
                      value: 'nassau',
                      child: Text('Nassau, Bahamas'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      // TODO: Implement AWS download
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('AWS download coming soon for $value'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegionTile(
      MapRegion region, BuildContext context, OfflineMapService service) {
    final estimatedTiles = region.estimateTileCount();
    final estimatedSizeMB = (estimatedTiles * 20 / 1024).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          region.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Zoom ${region.minZoom}-${region.maxZoom} • ~$estimatedSizeMB MB',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () {
            service.downloadMap(region);
          },
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Download'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadedMapTile(
      MapRegion region, BuildContext context, OfflineMapService service) {
    return Consumer<MapModeService>(
      builder: (context, mapModeService, child) {
        final tileServerService = context.read<TileServerService>();
        final isSelected = mapModeService.selectedOfflineMapId == region.id;

        return Dismissible(
      key: Key(region.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Map'),
            content: Text('Delete ${region.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (isSelected) {
          mapModeService.deselectOfflineMap();
        }
        service.deleteMap(region.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${region.name} deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        color: isSelected ? Colors.blue.shade50 : Colors.green.shade50,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Radio<String>(
            value: region.id,
            groupValue: mapModeService.selectedOfflineMapId,
  onChanged: (value) async {
              // Note: Radio for raster maps - no longer supported
              // Vector maps are now used exclusively
            },
          ),
          title: Text(
            region.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Ready for offline use',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
onTap: () async {
            // Note: Tap handler for raster maps - no longer supported
            // Vector maps are now used exclusively
          },
        ),
      ),
    );
      },
    );
  }

  Widget _buildVectorMapTile(VectorMapInfo vectorMap, BuildContext context,
      VectorMapService vectorMapService, StateSetter setModalState) {
    return Consumer<MapModeService>(
      builder: (context, mapModeService, child) {
        final tileServerService = context.read<TileServerService>();
        final isSelected = mapModeService.selectedOfflineMapId == vectorMap.id;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Radio<String>(
              value: vectorMap.id,
              groupValue: mapModeService.selectedOfflineMapId,
              onChanged: (value) async {
                try {
                  debugPrint('🔘 Radio button tapped for ${vectorMap.name} (${vectorMap.id})');

                  // Ensure tile server is running
                  if (!tileServerService.isRunning) {
                    debugPrint('🚀 Starting tile server...');
                    await tileServerService.start();
                  }

                  // Get the tile URL and style JSON for this map
                  debugPrint('🗺️ Loading style JSON for ${vectorMap.id}...');
                  final tileUrl = tileServerService.getTileUrlTemplate(vectorMap.id, isVector: true);
                  final fontGlyphsUrl = tileServerService.getFontGlyphsUrl();
                  final styleJson = await vectorMapService.getStyleJson(vectorMap.id, tileUrl, fontGlyphsUrl: fontGlyphsUrl);

                  debugPrint('✅ Style JSON loaded, selecting map...');
                  mapModeService.selectOfflineMap(
                    vectorMap.id,
                    styleJson: styleJson,
                    targetLat: vectorMap.centerLat,
                    targetLng: vectorMap.centerLng,
                  );

                  setModalState(() {});
                  debugPrint('✅ Map selection complete for ${vectorMap.id}');
                } catch (e, stackTrace) {
                  debugPrint('❌ ERROR selecting map ${vectorMap.id}: $e');
                  debugPrint('Stack trace: $stackTrace');
                }
              },
            ),
            title: Text(
              vectorMap.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'Ready • Vector',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            onTap: () async {
              try {
                debugPrint('👆 ListTile tapped for ${vectorMap.name} (${vectorMap.id})');

                // Ensure tile server is running
                if (!tileServerService.isRunning) {
                  debugPrint('🚀 Starting tile server...');
                  await tileServerService.start();
                }

                // Get the tile URL and style JSON for this map
                debugPrint('🗺️ Loading style JSON for ${vectorMap.id}...');
                final tileUrl = tileServerService.getTileUrlTemplate(vectorMap.id, isVector: true);
                final fontGlyphsUrl = tileServerService.getFontGlyphsUrl();
                final styleJson = await vectorMapService.getStyleJson(vectorMap.id, tileUrl, fontGlyphsUrl: fontGlyphsUrl);

                debugPrint('✅ Style JSON loaded, selecting map...');
                mapModeService.selectOfflineMap(
                  vectorMap.id,
                  styleJson: styleJson,
                  targetLat: vectorMap.centerLat,
                  targetLng: vectorMap.centerLng,
                );

                setModalState(() {});
                debugPrint('✅ Map selection complete for ${vectorMap.id}');
              } catch (e, stackTrace) {
                debugPrint('❌ ERROR selecting map ${vectorMap.id} (tap): $e');
                debugPrint('Stack trace: $stackTrace');
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildDownloadProgressTile(DownloadProgress progress,
      BuildContext context, OfflineMapService service) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      color: Colors.blue.shade50,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.mapId.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    service.cancelDownload(progress.mapId);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.downloadedTiles} / ${progress.totalTiles} tiles (${(progress.progress * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
