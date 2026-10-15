import 'package:fudikoclient/api/api_config.dart';

class CustomerProfileModel {
  final String badge;
  final String? badgeImage;
  final double rating;
  final String name;
  final String email;
  final String place;
  final String contactInfo;
  final String profilePicture;
  final String lat;
  final String lng;

  CustomerProfileModel({
    required this.badge,
    this.badgeImage,
    required this.rating,
    required this.name,
    required this.email,
    required this.place,
    required this.contactInfo,
    required this.profilePicture,
    required this.lat,
    required this.lng,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    final currentBadge = json['current_badge'];
    final badgeData = currentBadge is Map
        ? Map<String, dynamic>.from(currentBadge)
        : <String, dynamic>{};

    return CustomerProfileModel(
      // The current profile endpoint returns badge details under
      // `current_badge` and the rating as a string under
      // `reliability_rating`.
      badge: (badgeData['name'] ?? json['badge'] ?? '-').toString(),
      badgeImage: _imageUrl(badgeData['image']),
      rating: _toDouble(json['reliability_rating'] ?? json['rating']),
      name: json['name'] ?? '-',
      email: json['email'] ?? '-',
      place: json['place'] ?? '-',
      contactInfo: json['contact_info'] ?? '-',
      profilePicture: json['profile_picture'] ?? '-',
      lat: (json['lat'] ?? '').toString(),
      lng: (json['lng'] ?? '').toString(),
    );
  }

  CustomerProfileModel copyWith({String? place}) {
    return CustomerProfileModel(
      badge: badge,
      badgeImage: badgeImage,
      rating: rating,
      name: name,
      email: email,
      place: place ?? this.place,
      contactInfo: contactInfo,
      profilePicture: profilePicture,
      lat: lat,
      lng: lng,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _imageUrl(dynamic value) {
    final path = value?.toString().trim() ?? '';
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${ApiConfig.origin}${path.startsWith('/') ? path : '/$path'}';
  }
}
