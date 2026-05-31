import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
import 'package:fudikoclient/model/reservation/enquiry-reservation-response-model.dart';
import 'package:fudikoclient/utils/tokens.dart';

class EnquiryResponseService {
  /// Fetch all enquiry responses and return as [BookingModel] list
  Future<List<BookingModel>> fetchEnquiryBookings() async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.get(
        '/customer/enquiry/responses',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> raw =
            (response.data['responses'] as List<dynamic>?) ?? [];
        return raw
            .whereType<Map<String, dynamic>>()
            .map((item) => EnquiryResponseModel.fromJson(item).toBookingModel())
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('fetchEnquiryBookings error: $e');
      return [];
    }
  }

  /// Decline a response by its uuid
  Future<bool> declineEnquiryResponse(String responseUuid) async {
    if (responseUuid.trim().isEmpty) return false;

    final token = await getToken();
    try {
      final response = await DioClient.dio.post(
        '/customer/enquiry/decline',
        data: FormData.fromMap({'response_id': responseUuid.trim()}),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['status'] == true;
      }
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException && e.response != null) {
        if (kDebugMode) print('declineEnquiry error body: ${e.response?.data}');
      }
      if (kDebugMode) print('declineEnquiry error: $e');
      return false;
    }
  }
}