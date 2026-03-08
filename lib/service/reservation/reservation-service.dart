import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/reservation/new-reservation-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/utils/tokens.dart';

class ReservationService {
  Future<NewReservationModelResponse> createReservation(NewReservationModel reservationData) async {
    final token = await getToken();
    final data = reservationData.toFormData();
    try {
      final response = await DioClient.dio.post(
        '/customer/restaurant/reservation',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);
        return NewReservationModelResponse.fromJson(response.data);
      } else {
        print(response.data);
        return NewReservationModelResponse(status: false,message: 'Reservation failed: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      return NewReservationModelResponse(status: false, message: 'Something went wrong: $e');
    }
  }


}
