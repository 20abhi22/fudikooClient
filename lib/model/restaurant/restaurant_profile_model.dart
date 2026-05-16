import 'restaurant-model.dart';

class RestaurantDetailsResponseModel {
  final bool status;
  final Restaurant? restaurant;

  RestaurantDetailsResponseModel({
    required this.status,
    required this.restaurant,
  });

  factory RestaurantDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    return RestaurantDetailsResponseModel(
      status: json['status'] ?? false,
      restaurant: json['restaurant'] != null
          ? Restaurant.fromJson(json['restaurant'])
          : null,
    );
  }
}

class Restaurant {
  final String uuid;
  final String name;
  final String type;
  final String address;
  final String phone;
  final String lat;
  final String lng;
  final String description;
  final String availableDishes;
  final int takeawayService;
  final int deliveryService;
  final String deliveryServiceArea;
  final String restaurantType;
  final String status;
  final String? image;           // banner image
  final List<String> images;     // gallery images
  final List<OfferModel> offers;  // offers for the restaurant
  final bool isFavourite;

  Restaurant({
    required this.uuid,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.description,
    required this.availableDishes,
    required this.takeawayService,
    required this.deliveryService,
    required this.deliveryServiceArea,
    required this.restaurantType,
    required this.status,
    this.image,
    this.images = const [],
    this.offers = const [],
    required this.isFavourite,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      lat: json['lat'] ?? '',
      lng: json['lng'] ?? '',
      description: json['description'] ?? '',
      availableDishes: json['available_dishes'] ?? '',
      takeawayService: json['takeaway_service'] ?? 0,
      deliveryService: json['delivery_service'] ?? 0,
      deliveryServiceArea: json['delivery_service_area'] ?? '',
      restaurantType: json['restaurant_type'] ?? '',
      status: json['status'] ?? '',
      image: json['image']?.toString(),
        offers: (json['offers'] as List? ?? [])
          .map((item) => OfferModel.fromJson(item))
          .toList(),
      isFavourite: json['is_favourite'] == true || json['is_favourite'] == 1,
      images: (json['images'] as List? ?? [])
          .map((img) => img['image']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList(),
    );
  }
}