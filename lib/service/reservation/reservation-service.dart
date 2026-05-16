import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/reservation/new-reservation-model.dart';
import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/service/restaurant/restaurant_profile_service.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/utils/tokens.dart';

class ReservationService {
  final RestaurantDetailsService _restaurantDetailsService = RestaurantDetailsService();

  Future<List<BookingModel>> fetchReservations() async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.get(
        '/customer/restaurant/reservations/all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        final List<dynamic> reservations =
            data is Map<String, dynamic> ? (data['reservations'] as List<dynamic>? ?? []) : <dynamic>[];

        final Map<String, String> restaurantNameCache = {};

        Future<String> resolveRestaurantName(Map<String, dynamic> reservation) async {
          final String directName = (reservation['restaurant_name'] ?? '').toString().trim();
          if (directName.isNotEmpty) {
            return directName;
          }

          final dynamic restaurant = reservation['restaurant'];
          if (restaurant is Map<String, dynamic>) {
            final String nestedName = (restaurant['name'] ?? '').toString().trim();
            if (nestedName.isNotEmpty) {
              return nestedName;
            }
          }

          final String restaurantId = (reservation['restaurant_id'] ?? '').toString().trim();
          if (restaurantId.isEmpty) {
            return restaurantId;
          }

          if (restaurantNameCache.containsKey(restaurantId)) {
            return restaurantNameCache[restaurantId] ?? restaurantId;
          }

          final restaurantResponse = await _restaurantDetailsService.getRestaurantDetails(restaurantId);
          final String resolvedName = restaurantResponse.restaurant?.name.trim() ?? '';
          restaurantNameCache[restaurantId] = resolvedName.isNotEmpty ? resolvedName : restaurantId;
          return restaurantNameCache[restaurantId]!;
        }

        final List<BookingModel> bookings = [];
        for (final item in reservations.whereType<Map<String, dynamic>>()) {
          final Map<String, dynamic> merged = Map<String, dynamic>.from(item);
          merged['restaurant_name'] = await resolveRestaurantName(item);
          bookings.add(BookingModel.fromJson(merged));
        }

        return bookings;
      }

      return <BookingModel>[];
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return <BookingModel>[];
    }
  }

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
