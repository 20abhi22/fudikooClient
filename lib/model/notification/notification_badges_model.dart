class NotificationBadgesModel {
  final int restaurantReservations;
  final int restaurantFavourites;
  final int enquiryEnquiries;
  final int enquiryReservations;
  final int cateringEnquiries;
  final int cateringReservations;

  const NotificationBadgesModel({
    this.restaurantReservations = 0,
    this.restaurantFavourites = 0,
    this.enquiryEnquiries = 0,
    this.enquiryReservations = 0,
    this.cateringEnquiries = 0,
    this.cateringReservations = 0,
  });

  factory NotificationBadgesModel.fromJson(Map<String, dynamic> json) {
    final restaurants = _mapFrom(json['restaurants']);
    final enquiries = _mapFrom(json['enquiries']);
    final cateringEnquiries = _mapFrom(json['catering_enquiries']);

    return NotificationBadgesModel(
      restaurantReservations: _toInt(restaurants['reservations']),
      restaurantFavourites: _toInt(restaurants['favourites']),
      enquiryEnquiries: _toInt(enquiries['enquiries']),
      enquiryReservations: _toInt(enquiries['reservations']),
      cateringEnquiries: _toInt(cateringEnquiries['enquiries']),
      cateringReservations: _toInt(cateringEnquiries['reservations']),
    );
  }
}

Map<String, dynamic> _mapFrom(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '0').toString()) ?? 0;
}
