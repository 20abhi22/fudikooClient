import 'package:dio/dio.dart';

class CreateCateringInqueryModel {
  final String lat;
  final String lng;
  final String menuItems;
  final String people;
  final String time;
  final String date;
  final String estimatedAmount;
  final String searchRadius;
  final String expirationDate;
  final String expirationTime;

  CreateCateringInqueryModel({
    required this.lat,
    required this.lng,
    required this.menuItems,
    required this.people,
    required this.time,
    required this.date,
    required this.estimatedAmount,
    required this.searchRadius,
    required this.expirationDate,
    required this.expirationTime,
  });

  FormData toFormData() {
    return FormData.fromMap({
      "lat": lat,
      "lng": lng,
      "menu_items": menuItems,
      "people": people,
      "time": time,
      "date": date,
      "estimated_amount": estimatedAmount,
      "search_radius": searchRadius,
      "expiration_date": expirationDate,
      "expiration_time": expirationTime,
    });
  }
}

class CreateCateringInqueryModelResponse {
  final bool status;
  final String message;

  CreateCateringInqueryModelResponse({
    required this.status,
    required this.message,
  });

  factory CreateCateringInqueryModelResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return CreateCateringInqueryModelResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
    );
  }
}