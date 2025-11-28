/// Waypoint data model - matches .geezerguide JSON format
class Waypoint {
  final String id;
  final String name;
  final String category;
  final String? description;
  final String? address;
  final String bookId;
  final double latitude;
  final double longitude;
  bool isVisited;
  bool isWishlist;

  Waypoint({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.address,
    required this.bookId,
    required this.latitude,
    required this.longitude,
    this.isVisited = false,
    this.isWishlist = false,
  });

  /// Create from JSON (from .geezerguide file)
  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      bookId: json['book_id'] as String? ?? json['bookID'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isVisited: json['is_visited'] as bool? ?? json['isVisited'] as bool? ?? false,
      isWishlist: json['is_wishlist'] as bool? ?? json['isWishlist'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'address': address,
      'bookID': bookId,
      'latitude': latitude,
      'longitude': longitude,
      'isVisited': isVisited,
      'isWishlist': isWishlist,
    };
  }

  /// Get icon name based on category
  String get iconName {
    switch (category.toLowerCase()) {
      case 'attraction':
        return 'place';
      case 'restaurant':
        return 'restaurant';
      case 'hotel':
        return 'hotel';
      case 'museum':
        return 'museum';
      case 'park':
        return 'park';
      case 'shopping':
        return 'shopping_bag';
      default:
        return 'place';
    }
  }
}
