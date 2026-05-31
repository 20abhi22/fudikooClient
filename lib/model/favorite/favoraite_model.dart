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
    this.image, this.distance,
  });

  factory FavouriteRestaurantModel.fromJson(Map<String, dynamic> json) {
    return FavouriteRestaurantModel(
      uuid: json['uuid'],
      name: json['name'],
      type: json['type'],
      address: json['address'],
      phone: json['phone'],
      lat: json['lat'],
      lng: json['lng'],
      description: json['description'],
      availableDishes: json['available_dishes'],
      takeAwayService: json['takeaway_service'],
      deliveryService: json['delivery_service'],
      deliveryServiceArea: json['delivery_service_area'],
      restaurantType: json['restaurant_type'],
      status: json['status'],
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

  FavouriteRestaurantModelResponse({required this.status, required this.restaurant});

  factory FavouriteRestaurantModelResponse.fromJson(Map<String, dynamic> json) {
    return FavouriteRestaurantModelResponse(
      status: json['status'],
      restaurant: (json['restaurants'] as List)
          .map((item) => FavouriteRestaurantModel.fromJson(item))
          .toList(),
    );
  }
}
