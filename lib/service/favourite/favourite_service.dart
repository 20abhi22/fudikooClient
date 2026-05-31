import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/favorite/favoraite_model.dart';
import 'package:fudikoclient/model/reservation/new-reservation-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/utils/tokens.dart';

class FavouriteRestaurantService {
  Future<FavouriteRestaurantModelResponse> getFavouriteRestaurants({double? lat, double? lng}) async {
    final token = await getToken();
    try {
      final queryParameters = <String, dynamic>{};
      if (lat != null) queryParameters['lat'] = lat;
      if (lng != null) queryParameters['lng'] = lng;

      final response = await DioClient.dio.get(
        '/customer/restaurant/favourites',
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);
        return FavouriteRestaurantModelResponse.fromJson(response.data);
      } else {
        print(response.data);
        return FavouriteRestaurantModelResponse(
          status: false,
          restaurant: []
        );
      }
    } catch (e) {
      print(e);
      return FavouriteRestaurantModelResponse(
        status: false,
        restaurant: []
      );
    }
  }

  Future<FavouriteRestaurantModelResponse> searchFavouriteRestaurants(String name, {double? lat, double? lng}) async {
    final token = await getToken();
    try {
      final queryParameters = <String, dynamic>{'name': name};
      if (lat != null) queryParameters['lat'] = lat;
      if (lng != null) queryParameters['lng'] = lng;

      final response = await DioClient.dio.get(
        '/customer/restaurant/favourites/search',
        queryParameters: queryParameters,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print('Favourite search: ${response.data}');
        return FavouriteRestaurantModelResponse.fromJson(response.data);
      } else {
        print(response.data);
        return FavouriteRestaurantModelResponse(
          status: false,
          restaurant: [],
        );
      }
    } catch (e) {
      print('Favourite search error: $e');
      return FavouriteRestaurantModelResponse(
        status: false,
        restaurant: [],
      );
    }
  }
}
