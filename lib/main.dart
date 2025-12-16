import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/location_service.dart';
import 'services/map_mode_service.dart';
import 'services/guide_book_service.dart';
import 'services/import_handler_service.dart';
import 'services/tile_server_service.dart';
import 'services/vector_map_service.dart';
import 'screens/startup_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const GeezerGuidesApp());
}

class GeezerGuidesApp extends StatelessWidget {
  const GeezerGuidesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => MapModeService()),
        ChangeNotifierProvider(create: (_) => GuideBookService()),
        Provider(create: (_) => TileServerService()),
        ChangeNotifierProvider(create: (_) => VectorMapService()),
      ],
      child: MaterialApp(
        title: 'GeezerGuides',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          // Large, readable text for seniors
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 18),
            bodyMedium: TextStyle(fontSize: 16),
            labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// App Initializer - handles startup sequence
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  ImportHandlerService? _importHandler;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _importHandler?.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // CRITICAL: Check location permissions IMMEDIATELY on launch
    final locationService = context.read<LocationService>();
    final success = await locationService.initialize();

    if (!success) {
      // Permission denied - stay on startup screen
      debugPrint('❌ App initialization failed - no location permission');
      return;
    }

    // Initialize guide book service (load saved guides)
    final guideBookService = context.read<GuideBookService>();
    await guideBookService.initialize();

    // Initialize import handler (for deep links and file sharing)
    _importHandler = ImportHandlerService(guideBookService);
    await _importHandler!.initialize();

    debugPrint('✅ App initialization complete');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        // Show startup screen until location permission is granted
        if (!locationService.isReady) {
          return StartupScreen(
            errorMessage: locationService.errorMessage,
            onRetry: () => _initializeApp(),
          );
        }

        // Location permission granted - show main app
        return const MainScreen();
      },
    );
  }
}
