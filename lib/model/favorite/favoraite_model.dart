import 'package:fudikoclient/model/restaurant/restaurant-model.dart';

class FavouriteRestaurantModel {
  final String uuid;
  final String name;
  final String type;
  final String address;
  final String phone;
  final String lat;
  final String lng;
  final String description;
  final String availableDishes;
  final int takeAwayService;
  final int deliveryService;
  final String deliveryServiceArea;
  final String restaurantType;
  final String status;
  final double? averageReview;
  final double? distance;
  final List<OfferModel> offers;
  final String? image;

  FavouriteRestaurantModel({
    required this.uuid,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.description,
    required this.availableDishes,
    required this.takeAwayService,
    required this.deliveryService,
    required this.deliveryServiceArea,
    required this.restaurantType,
    required this.status,
    this.averageReview,
    required this.offers,
    this.image,
    this.distance,
  });

  static String _str(dynamic v) => v?.toString() ?? '';

  static int _int(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  factory FavouriteRestaurantModel.fromJson(Map<String, dynamic> json) {
    return FavouriteRestaurantModel(
      // Backend may send null for optional fields (e.g. delivery_service_area,
      // description); a hard cast would throw and blank the whole list.
      uuid: _str(json['uuid']),
      name: _str(json['name']),
      type: _str(json['type']),
      address: _str(json['address']),
      phone: _str(json['phone']),
      lat: _str(json['lat']),
      lng: _str(json['lng']),
      description: _str(json['description']),
      availableDishes: _str(json['available_dishes']),
      takeAwayService: _int(json['takeaway_service']),
      deliveryService: _int(json['delivery_service']),
      deliveryServiceArea: _str(json['delivery_service_area']),
      restaurantType: _str(json['restaurant_type']),
      status: _str(json['status']),
      averageReview: json['average_review'] != null
          ? double.tryParse(json['average_review'].toString())
          : null,
      offers: (json['offers'] as List<dynamic>? ?? [])
          .map((item) => OfferModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      image: json['image']?.toString(),
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : null,
    );
  }
}

class FavouriteRestaurantModelResponse {
  final bool status;
  final List<FavouriteRestaurantModel> restaurant;

  /// Why the request failed, ready to show to the user. Empty on success.
  final String message;

  FavouriteRestaurantModelResponse({
    required this.status,
    required this.restaurant,
    this.message = '',
  });

  factory FavouriteRestaurantModelResponse.fromJson(Map<String, dynamic> json) {
    return FavouriteRestaurantModelResponse(
      status: json['status'],
      restaurant: (json['restaurants'] as List)
          .map((item) => FavouriteRestaurantModel.fromJson(item))
          .toList(),
    );
  }
}
