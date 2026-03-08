import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/restaurant/restaurant_profile_model.dart';
import 'package:fudikoclient/utils/tokens.dart';   

class RestaurantDetailsService {
  Future<RestaurantDetailsResponseModel> getRestaurantDetails(String uuid) async {
    try {
String? token = await getToken();  
      final response = await DioClient.dio.post(
        '/customer/restaurant/show',
        data: {
          "id": uuid,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );
print("----------------------------------------");
      print("STATUS CODE: ${response.statusCode}");
      print("FULL RESPONSE: ${response.data}");

      if (response.statusCode == 200) {
        return RestaurantDetailsResponseModel.fromJson(response.data);
      } else {
        return RestaurantDetailsResponseModel(
          status: false,
          restaurant: null,
        );
      }

    } catch (e) {
      print("Restaurant Details Error: $e");
      return RestaurantDetailsResponseModel(
        status: false,
        restaurant: null,
      );
    }
  }
}