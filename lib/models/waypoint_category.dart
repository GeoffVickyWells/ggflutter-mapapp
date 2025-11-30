import 'package:flutter/material.dart';

/// Category classification for waypoints with associated colors and icons
enum WaypointCategory {
  restaurant,
  hotel,
  museum,
  historical,
  shopping,
  entertainment,
  transport,
  attraction,
  viewpoint,
  park;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  IconData get icon {
    switch (this) {
      case WaypointCategory.restaurant:
        return Icons.restaurant;
      case WaypointCategory.hotel:
        return Icons.hotel;
      case WaypointCategory.museum:
        return Icons.museum;
      case WaypointCategory.historical:
        return Icons.history;
      case WaypointCategory.shopping:
        return Icons.shopping_bag;
      case WaypointCategory.entertainment:
        return Icons.theater_comedy;
      case WaypointCategory.transport:
        return Icons.directions_car;
      case WaypointCategory.attraction:
        return Icons.star;
      case WaypointCategory.viewpoint:
        return Icons.camera_alt;
      case WaypointCategory.park:
        return Icons.park;
    }
  }

  Color get color {
    switch (this) {
      case WaypointCategory.restaurant:
        return const Color(0xFFFF6B6B);
      case WaypointCategory.hotel:
        return const Color(0xFF4ECDC4);
      case WaypointCategory.museum:
        return const Color(0xFF45B7D1);
      case WaypointCategory.historical:
        return const Color(0xFF96CEB4);
      case WaypointCategory.shopping:
        return const Color(0xFFFECA57);
      case WaypointCategory.entertainment:
        return const Color(0xFFFF9FF3);
      case WaypointCategory.transport:
        return const Color(0xFF54A0FF);
      case WaypointCategory.attraction:
        return const Color(0xFFFD79A8);
      case WaypointCategory.viewpoint:
        return const Color(0xFFFDCB6E);
      case WaypointCategory.park:
        return const Color(0xFF6C5CE7);
    }
  }

  /// Parse category from string (case-insensitive)
  static WaypointCategory fromString(String value) {
    try {
      return WaypointCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return WaypointCategory.attraction; // Default fallback
    }
  }
}
