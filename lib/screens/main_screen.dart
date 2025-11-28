import 'dart:ui';
import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'about_screen.dart';
import 'my_maps_screen.dart';
import 'navigate_screen.dart';
import 'get_maps_screen.dart';

/// Main screen with bottom navigation
/// Tabs: About | My Maps | Navigate | Get Maps
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Start on Navigate (map) tab

  final List<Widget> _screens = [
    const AboutScreen(),
    const MyMapsScreen(),
    const MapScreen(),
    const GetMapsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade300.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.info_outline,
                    activeIcon: Icons.info,
                    label: 'About',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map,
                    label: 'My Maps',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.navigation_outlined,
                    activeIcon: Icons.navigation,
                    label: 'Navigate',
                    isPrimary: true,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.download_outlined,
                    activeIcon: Icons.download,
                    label: 'Get Maps',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool isPrimary = false,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive
        ? (isPrimary ? Colors.blue.shade700 : Colors.blue.shade700)
        : Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: isPrimary ? 28 : 24,
                color: color,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
