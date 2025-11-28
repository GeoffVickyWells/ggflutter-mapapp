import 'waypoint.dart';

/// GuideBook data model - matches .geezerguide JSON format
class GuideBook {
  final String id;
  final String version;
  final String guidebookId;
  final String title;
  final String city;
  final String country;
  final String author;
  final DateTime lastUpdated;
  final List<Waypoint> waypoints;

  GuideBook({
    required this.id,
    required this.version,
    required this.guidebookId,
    required this.title,
    required this.city,
    required this.country,
    required this.author,
    required this.lastUpdated,
    required this.waypoints,
  });

  /// Create from JSON (from .geezerguide file)
  factory GuideBook.fromJson(Map<String, dynamic> json) {
    final waypointsList = json['waypoints'] as List<dynamic>? ?? [];
    final waypoints = waypointsList
        .map((w) => Waypoint.fromJson(w as Map<String, dynamic>))
        .toList();

    return GuideBook(
      id: json['id'] as String,
      version: json['version'] as String,
      guidebookId: json['guidebook_id'] as String? ?? json['guidebookID'] as String,
      title: json['title'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      author: json['author'] as String,
      lastUpdated: DateTime.parse(json['last_updated'] as String? ?? json['lastUpdated'] as String),
      waypoints: waypoints,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'guidebookID': guidebookId,
      'title': title,
      'city': city,
      'country': country,
      'author': author,
      'lastUpdated': lastUpdated.toIso8601String(),
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
    };
  }

  int get waypointCount => waypoints.length;
}
