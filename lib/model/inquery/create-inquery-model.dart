import 'package:dio/dio.dart';

class CreateInqueryModel {
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

  CreateInqueryModel({
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
       "lat": lat.toString(),
      "lng": lng.toString(),
      "menu_items": menuItems,
      "people": people.toString(),
      "time": time,
      "date": date,
      "estimated_amount": estimatedAmount.toString(),
      "search_radius": searchRadius.toString(),
      "expiration_date": expirationDate,
      "expiration_time": expirationTime,
    });
  }
}

class CreateInqueryModelResponse {
  final bool status;
  final String message;

  CreateInqueryModelResponse({
    required this.status,
    required this.message,
  });

  factory CreateInqueryModelResponse.fromJson(Map<String, dynamic> json) {
    return CreateInqueryModelResponse(
      status: json['status'],
      message: json['message'],
    );
  }
}
