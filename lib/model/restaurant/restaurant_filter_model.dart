import 'package:dio/dio.dart';

class RestaurantFilterRequest {
  final double lat;
  final double lng;
  final double? searchRadiusKm;
  final String? type;
  final int? offerPercentage;
  final DateTime? dateTime;

  const RestaurantFilterRequest({
    required this.lat,
    required this.lng,
    this.searchRadiusKm,
    this.type,
    this.offerPercentage,
    this.dateTime,
  });

  FormData toFormData() {
    final selectedDateTime = dateTime;

    return FormData.fromMap({
      'lat': lat.toString(),
      'lng': lng.toString(),
      if (searchRadiusKm != null && searchRadiusKm! > 0)
        'search_radius': _formatRadius(searchRadiusKm!),
      if (type != null && type!.trim().isNotEmpty) 'type': type!.trim(),
      if (offerPercentage != null)
        'offer_percentage': offerPercentage.toString(),
      if (selectedDateTime != null) 'date': _formatDate(selectedDateTime),
      if (selectedDateTime != null) 'time': _formatTime(selectedDateTime),
    });
  }

  String _formatRadius(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _formatTime(DateTime value) {
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute $suffix';
  }
}
