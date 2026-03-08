import 'package:dio/dio.dart';

class CompleteRegistrationModel {
  final String phone;
  final String lat;
  final String lng;


  CompleteRegistrationModel({
    required this.phone,
    required this.lat,
    required this.lng,
  });

  FormData toFormData() {
    return FormData.fromMap({
      "phone" : phone,
      "lat" : lat,
      "lng" : lng
    });
  }
}

class CompleteRegistrationModelResponse {
  final String message;
  final bool status;
  CompleteRegistrationModelResponse({required this.message, required this.status});

  factory CompleteRegistrationModelResponse.fromJson(Map<String, dynamic> json) {
    return CompleteRegistrationModelResponse(message: json['message'], status: json['status']);
  }

}
