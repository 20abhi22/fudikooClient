import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/utils/tokens.dart';

enum OfferCodeReservationType { restaurant, enquiry, cateringEnquiry }

class OfferCodeResponse {
  final bool status;
  final String offerCodeStatus;
  final String verificationUrl;
  final String qrImage;
  final String message;

  const OfferCodeResponse({
    required this.status,
    this.offerCodeStatus = '',
    this.verificationUrl = '',
    this.qrImage = '',
    this.message = '',
  });

  factory OfferCodeResponse.fromJson(Map<String, dynamic> json) {
    return OfferCodeResponse(
      status: json['status'] == true,
      offerCodeStatus: (json['offer_code_status'] ?? '').toString(),
      verificationUrl: (json['verification_url'] ?? '').toString(),
      qrImage: (json['qr_image'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class OfferCodeService {
  Future<OfferCodeResponse> fetchOfferCode({
    required String reservationId,
    required OfferCodeReservationType type,
  }) async {
    final trimmedReservationId = reservationId.trim();
    if (trimmedReservationId.isEmpty) {
      return const OfferCodeResponse(
        status: false,
        message: 'Reservation id is missing.',
      );
    }

    final endpoint = switch (type) {
      OfferCodeReservationType.enquiry =>
        '/customer/enquiry/reservation/offer-code',
      OfferCodeReservationType.cateringEnquiry =>
        '/customer/catering-enquiry/reservation/offer-code',
      OfferCodeReservationType.restaurant =>
        '/customer/restaurant/reservation/offer-code',
    };

    final token = await getToken();

    try {
      final response = await DioClient.dio.post(
        endpoint,
        data: FormData.fromMap({'reservation_id': trimmedReservationId}),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data is Map<String, dynamic>) {
        return OfferCodeResponse.fromJson(response.data);
      }

      return OfferCodeResponse(
        status: response.statusCode == 200,
        message: response.statusCode == 200
            ? ''
            : 'Failed to load QR code: ${response.statusCode}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Offer code fetch error: $e');
      }

      if (e is DioException && e.response?.data is Map<String, dynamic>) {
        return OfferCodeResponse.fromJson(
          e.response!.data as Map<String, dynamic>,
        );
      }

      return OfferCodeResponse(
        status: false,
        message: 'Something went wrong: $e',
      );
    }
  }
}
