import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/restaurant/restaurant_filter_model.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/utils/error_messages.dart';
import 'package:fudikoclient/utils/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestaurantService {
  static const String _cacheKeyLat = 'cached_lat';
  static const String _cacheKeyLng = 'cached_lng';

  Future<RestaurantListResponse> getRestaurantList({
    double? lat,
    double? lng,
    double? searchRadiusKm,
    String? type,
    int? offerPercentage,
    int? startPercentage,
    DateTime? dateTime,
  }) async {
    final token = await getToken();
    try {
      final double? resolvedLat = lat ?? await _getCachedLatitude();
      final double? resolvedLng = lng ?? await _getCachedLongitude();

      if (resolvedLat != null && resolvedLng != null) {
        return filterRestaurants(
          RestaurantFilterRequest(
            lat: resolvedLat,
            lng: resolvedLng,
            searchRadiusKm: searchRadiusKm,
            type: type,
            offerPercentage: offerPercentage,
            startPercentage: startPercentage,
            dateTime: dateTime,
          ),
        );
      }

      final response = await DioClient.dio.get(
        '/customer/restaurants',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);
        return RestaurantListResponse.fromJson(response.data);
      } else {
        print(response.data);
        return RestaurantListResponse(
          status: false,
          restaurant: const [],
          message: statusCodeMessage(
            response.statusCode,
            fallback: 'We could not load restaurants. Please try again.',
          ),
        );
      }
    } catch (e) {
      return RestaurantListResponse(
        status: false,
        restaurant: const [],
        message: friendlyErrorMessage(
          e,
          fallback: 'We could not load restaurants. Please try again.',
        ),
      );
    }
  }
  //   Future<RestaurantListResponse> getRestaurantList() async {
  //   final token = await getToken();
  //   print('TOKEN BEING SENT: $token');
  //   try {
  //     final response = await DioClient.dio.get(
  //       '/customer/restaurants',
  //       options: Options(headers: {'Authorization': 'Bearer $token'}),
  //     );
  //     if (response.statusCode == 200) {
  //       print('RESPONSE TYPE: ${response.headers['content-type']}');
  //       print('RAW DATA: ${response.data}');              // ← add here
  //       final result = RestaurantListResponse.fromJson(response.data);
  //       print('PARSED COUNT: ${result.restaurant.length}'); // ← add here
  //       return result;
  //     } else {
  //       return RestaurantListResponse(status: false, restaurant: []);
  //     }
  //   } catch (e) {
  //     print('Error: $e');
  //     return RestaurantListResponse(status: false, restaurant: []);
  //   }
  // }

  Future<RestaurantLikedDislikedResponseModel> changeStatus(
    RestaurantLikedDislikedModel uuiddata,
  ) async {
    final token = await getToken();
    final data = uuiddata.toFormData();
    try {
      final response = await DioClient.dio.post(
        '/customer/restaurant/update-favourite',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);

        return RestaurantLikedDislikedResponseModel.fromJson(response.data);
      } else {
        print(response.data);

        return RestaurantLikedDislikedResponseModel(
          status: false,
          message: statusCodeMessage(
            response.statusCode,
            fallback: 'We could not update your favourites. Please try again.',
          ),
        );
      }
    } catch (e) {
      return RestaurantLikedDislikedResponseModel(
        status: false,
        message: friendlyErrorMessage(
          e,
          fallback: 'We could not update your favourites. Please try again.',
        ),
      );
    }
  }

  Future<RestaurantListResponse> filterRestaurants(
    RestaurantFilterRequest request,
  ) async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.post(
        '/customer/filter',
        data: request.toFormData(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        print('Filter response: ${response.data}');
        return RestaurantListResponse.fromJson(response.data);
      } else {
        print('Filter error: ${response.data}');
        return RestaurantListResponse(
          status: false,
          restaurant: const [],
          message: statusCodeMessage(
            response.statusCode,
            fallback: 'We could not load restaurants. Please try again.',
          ),
        );
      }
    } catch (e) {
      return RestaurantListResponse(
        status: false,
        restaurant: const [],
        message: friendlyErrorMessage(
          e,
          fallback: 'We could not load restaurants. Please try again.',
        ),
      );
    }
  }

  Future<RestaurantListResponse> searchRestaurants({
    required String name,
    double? lat,
    double? lng,
  }) async {
    final token = await getToken();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return RestaurantListResponse(status: true, restaurant: []);
    }

    try {
      final double? resolvedLat = lat ?? await _getCachedLatitude();
      final double? resolvedLng = lng ?? await _getCachedLongitude();

      final response = await DioClient.dio.get(
        '/customer/restaurants/search',
        queryParameters: {
          if (resolvedLat != null) 'lat': resolvedLat.toString(),
          if (resolvedLng != null) 'lng': resolvedLng.toString(),
          'name': trimmedName,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return RestaurantListResponse.fromJson(response.data);
      } else {
        return RestaurantListResponse(
          status: false,
          restaurant: const [],
          message: statusCodeMessage(
            response.statusCode,
            fallback: 'We could not search restaurants. Please try again.',
          ),
        );
      }
    } catch (e) {
      return RestaurantListResponse(
        status: false,
        restaurant: const [],
        message: friendlyErrorMessage(
          e,
          fallback: 'We could not search restaurants. Please try again.',
        ),
      );
    }
  }

  Future<double?> _getCachedLatitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_cacheKeyLat);
  }

  Future<double?> _getCachedLongitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_cacheKeyLng);
  }
}
