import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/favorite/favoraite_model.dart';
import 'package:fudikoclient/model/reservation/new-reservation-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/utils/tokens.dart';

class FavouriteRestaurantService {
  Future<FavouriteRestaurantModelResponse> getFavouriteRestaurants() async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.get(
        '/customer/restaurant/favourites',
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
}
