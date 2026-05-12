class RestaurantModel {
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
  final bool isFavorite;
  final double? distance; 

  RestaurantModel({
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
    required this.isFavorite,
     this.distance,
  });

//   factory RestaurantModel.fromJson(Map<String, dynamic> json) {
//     return RestaurantModel(
//       uuid: json['uuid'],
//       name: json['name'],
//       type: json['type'],
//       address: json['address'],
//       phone: json['phone'],
//       lat: json['lat'],
//       lng: json['lng'],
//       description: json['description'],
//       availableDishes: json['available_dishes'],
//       takeAwayService: json['takeaway_service'],
//       deliveryService: json['delivery_service'],
//       deliveryServiceArea: json['delivery_service_area'],
//       restaurantType: json['restaurant_type'],
//       status: json['status'],
//       isFavorite: json['is_favourite'],
//     );
//   }


// }
factory RestaurantModel.fromJson(Map<String, dynamic> json) {
  return RestaurantModel(
    uuid: json['uuid']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    lat: json['lat']?.toString() ?? '',
    lng: json['lng']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    availableDishes: json['available_dishes']?.toString() ?? '',
    takeAwayService: json['takeaway_service'] is int
        ? json['takeaway_service']
        : int.tryParse(json['takeaway_service'].toString()) ?? 0,
    deliveryService: json['delivery_service'] is int
        ? json['delivery_service']
        : int.tryParse(json['delivery_service'].toString()) ?? 0,
    deliveryServiceArea: json['delivery_service_area']?.toString() ?? '',
    restaurantType: json['restaurant_type']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    isFavorite: json['is_favourite'] == true || json['is_favourite'] == 1,
    distance: json['distance'] != null                // ← ADD THIS
          ? double.tryParse(json['distance'].toString())
          : null,
  );
}
}

class RestaurantListResponse {
  final bool status;
  final List<RestaurantModel> restaurant;

  RestaurantListResponse({required this.status, required this.restaurant});

  factory RestaurantListResponse.fromJson(Map<String, dynamic> json) {
    return RestaurantListResponse(
      status: json['status'],
      restaurant: (json['restaurants'] as List)
          .map((item) => RestaurantModel.fromJson(item))
          .toList(),
    );
  }
}
