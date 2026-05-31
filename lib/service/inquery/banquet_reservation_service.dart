import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/banquet/banquet_reservation_modal.dart';
import 'package:fudikoclient/utils/tokens.dart';

class BanquetReservationService {
  Future<BanquetReservationListResponse> fetchReservations() async {
    final token = await getToken();

    try {
      final response = await DioClient.dio.get(
        '/customer/enquiry/reservations/all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return BanquetReservationListResponse.fromJson(response.data);
      }

      return BanquetReservationListResponse(
        status: false,
        message: 'Failed to fetch reservations: ${response.statusCode}',
        reservations: [],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Banquet reservation fetch error: $e');
      }
      return BanquetReservationListResponse(
        status: false,
        message: 'Something went wrong: $e',
        reservations: [],
      );
    }
  }

  Future<BanquetReservationListResponse> searchReservations(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      return BanquetReservationListResponse(
        status: true,
        message: '',
        reservations: [],
      );
    }

    final token = await getToken();

    try {
      final response = await DioClient.dio.get(
        '/customer/enquiry/reservations/search',
        queryParameters: {'id': trimmedId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return BanquetReservationListResponse.fromJson(response.data);
      }

      return BanquetReservationListResponse(
        status: false,
        message: 'Failed to search reservations: ${response.statusCode}',
        reservations: [],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Banquet reservation search error: $e');
      }
      return BanquetReservationListResponse(
        status: false,
        message: 'Something went wrong: $e',
        reservations: [],
      );
    }
  }

  Future<Map<String, dynamic>> cancelReservation(String reservationId) async {
    final trimmedReservationId = reservationId.trim();
    if (trimmedReservationId.isEmpty) {
      return {'status': false, 'message': 'Reservation id is missing.'};
    }

    final token = await getToken();

    try {
      final response = await DioClient.dio.post(
        '/customer/enquiry/reservation/cancel',
        data: FormData.fromMap({'reservation_id': trimmedReservationId}),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }

      return {
        'status': response.statusCode == 200,
        'message': response.statusCode == 200
            ? 'Reservation cancelled successfully'
            : 'Failed to cancel reservation',
      };
    } catch (e) {
      if (e is DioException && e.response?.data is Map<String, dynamic>) {
        return e.response!.data as Map<String, dynamic>;
      }

      if (kDebugMode) {
        print('Banquet reservation cancel error: $e');
      }
      return {'status': false, 'message': 'Something went wrong: $e'};
    }
  }
}
