import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/location_service.dart';
import 'services/map_mode_service.dart';
import 'screens/startup_screen.dart';
import 'screens/map_screen.dart';

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
  @override
  void initState() {
    super.initState();
    _initializeApp();
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
        return const MapScreen();
      },
    );
  }
}
