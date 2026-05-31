import 'package:dio/dio.dart';

class RestaurantFilterRequest {
  final double lat;
  final double lng;
  final double searchRadiusKm;
  final String? type;
  final int? offerPercentage;

  const RestaurantFilterRequest({
    required this.lat,
    required this.lng,
    this.searchRadiusKm = 10,
    this.type,
    this.offerPercentage,
  });

  FormData toFormData() {
    final int radiusInMeters =
        searchRadiusKm <= 0 ? 100000 : (searchRadiusKm * 1000).round();

    return FormData.fromMap({
      'lat': lat.toString(),
      'lng': lng.toString(),
      'search_radius': radiusInMeters.toString(),
      if (type != null && type!.trim().isNotEmpty) 'type': type!.trim(),
      if (offerPercentage != null) 'offer_percentage': offerPercentage.toString(),
    });
  }
}
