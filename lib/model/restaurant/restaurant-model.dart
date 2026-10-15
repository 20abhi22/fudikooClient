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
  final double? averageReview;
  final double? distance;
  final List<OfferModel> offers;
  final String? image;

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
    this.averageReview,
    this.distance,
    required this.offers, // ← add
    this.image,
  });

  RestaurantModel copyWith({
    String? uuid,
    String? name,
    String? type,
    String? address,
    String? phone,
    String? lat,
    String? lng,
    String? description,
    String? availableDishes,
    int? takeAwayService,
    int? deliveryService,
    String? deliveryServiceArea,
    String? restaurantType,
    String? status,
    bool? isFavorite,
    double? averageReview,
    double? distance,
    List<OfferModel>? offers,
    String? image,
  }) {
    return RestaurantModel(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      description: description ?? this.description,
      availableDishes: availableDishes ?? this.availableDishes,
      takeAwayService: takeAwayService ?? this.takeAwayService,
      deliveryService: deliveryService ?? this.deliveryService,
      deliveryServiceArea: deliveryServiceArea ?? this.deliveryServiceArea,
      restaurantType: restaurantType ?? this.restaurantType,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      averageReview: averageReview ?? this.averageReview,
      distance: distance ?? this.distance,
      offers: offers ?? this.offers,
      image: image ?? this.image,
    );
  }

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
      averageReview: json['average_review'] != null
          ? double.tryParse(json['average_review'].toString())
          : null,
      distance:
          json['distance'] !=
              null // ← ADD THIS
          ? double.tryParse(json['distance'].toString())
          : null,
      offers: (json['offers'] as List? ?? const [])
          .map((item) => OfferModel.fromJson(item))
          .toList(),
      image: json['image']?.toString(),
    );
  }
}

class RestaurantListResponse {
  final bool status;
  final List<RestaurantModel> restaurant;

  /// Why the request failed, ready to show to the user. Empty on success.
  final String message;

  RestaurantListResponse({
    required this.status,
    required this.restaurant,
    this.message = '',
  });

  factory RestaurantListResponse.fromJson(Map<String, dynamic> json) {
    return RestaurantListResponse(
      status: json['status'] == true || json['status']?.toString() == 'true',
      restaurant: (json['restaurants'] as List? ?? const [])
          .map((item) => RestaurantModel.fromJson(item))
          .toList(),
    );
  }
}

class OfferModel {
  final String uuid;
  final String partnerUid;
  final double discountPercentage;
  final String applicableFor;
  final String dineType;
  final String startTime;
  final String endTime;
  final String activeDays;
  final String status;
  final List<OfferSlotModel> slots;

  OfferModel({
    required this.uuid,
    required this.partnerUid,
    required this.discountPercentage,
    required this.applicableFor,
    required this.dineType,
    required this.startTime,
    required this.endTime,
    required this.activeDays,
    required this.status,
    this.slots = const [],
  });

  OfferModel copyWith({
    String? uuid,
    String? partnerUid,
    double? discountPercentage,
    String? applicableFor,
    String? dineType,
    String? startTime,
    String? endTime,
    String? activeDays,
    String? status,
    List<OfferSlotModel>? slots,
  }) {
    return OfferModel(
      uuid: uuid ?? this.uuid,
      partnerUid: partnerUid ?? this.partnerUid,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      applicableFor: applicableFor ?? this.applicableFor,
      dineType: dineType ?? this.dineType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activeDays: activeDays ?? this.activeDays,
      status: status ?? this.status,
      slots: slots ?? this.slots,
    );
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      uuid: json['uuid']?.toString() ?? '',
      partnerUid: json['partner_uid']?.toString() ?? '',
      discountPercentage:
          double.tryParse(json['discount_percentage']?.toString() ?? '0') ??
          0.0,
      applicableFor: json['applicable_for']?.toString() ?? '',
      dineType: json['dine_type']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      activeDays: json['active_days']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      slots: (json['slots'] as List? ?? const [])
          .map((item) => OfferSlotModel.fromJson(item))
          .toList(),
    );
  }
}

class OfferSlotModel {
  final String startTime;
  final String endTime;

  const OfferSlotModel({required this.startTime, required this.endTime});

  factory OfferSlotModel.fromJson(Map<String, dynamic> json) {
    return OfferSlotModel(
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
    );
  }
}
