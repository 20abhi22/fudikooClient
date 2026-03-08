import 'package:dio/dio.dart';

class UpdateInqueryModel {
  final String enquiryId;
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

  UpdateInqueryModel({
    required this.enquiryId,
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
      'enquiry_id': enquiryId,
      'lat': lat.toString(),
      'lng': lng.toString(),
      'menu_items': menuItems,
      'people': people.toString(),
      'time': time,
      'date': date,
      'estimated_amount': estimatedAmount.toString(),
      'search_radius': searchRadius.toString(),
      'expiration_date': expirationDate,
      'expiration_time': expirationTime,
    });
  }
  Map<String, dynamic> toJson() {
    return {
      "enquiry_id": enquiryId,
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
    };
  }

}

class UpdateInqueryModelResponse {
  final bool status;
  final String message;

  UpdateInqueryModelResponse({required this.status, required this.message});

  factory UpdateInqueryModelResponse.fromJson(Map<String, dynamic> json) {
    return UpdateInqueryModelResponse(
      status: json['status'],
      message: json['message'],
    );
  }
}
