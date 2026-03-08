import 'package:dio/dio.dart';

class NewReservationModel {
  final String people;
  final String id;
  final String time;
  final String date;

  NewReservationModel({
    required this.people,
    required this.id,
    required this.time,
    required this.date,
  });

  FormData toFormData() {
    return FormData.fromMap({
      "people": people,
      "restaurant_id": id,
      "time": time,
      "date": date,
    });
  }

}

class NewReservationModelResponse{
  final bool status;
  final String message;
  final bool? couponRecieved;

  NewReservationModelResponse({required this.status, required this.message, this.couponRecieved});

  factory NewReservationModelResponse.fromJson(Map<String, dynamic> json) {
    return NewReservationModelResponse(
      status: json['status'],
      message: json['message'],
      couponRecieved: json['couponRecieved'],
    );
  }



}