import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/restaurant/restaurant_filter_model.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/utils/tokens.dart';

class RestaurantService {
  Future<RestaurantListResponse> getRestaurantList() async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.get(
        '/customer/restaurants',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);
        return RestaurantListResponse.fromJson(response.data);
      } else {
        print(response.data);
        return RestaurantListResponse(status: false, restaurant: []);
      }
    } catch (e) {
      print(e);
      return RestaurantListResponse(status: false, restaurant: []);
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

  Future<RestaurantLikedDislikedResponseModel> changeStatus(RestaurantLikedDislikedModel uuiddata) async {
    final token = await getToken();
    final data = uuiddata.toFormData();
    try{
      final response = await DioClient.dio.post(
        '/customer/restaurant/update-favourite',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if(response.statusCode == 200){
        print(response.data);

        return RestaurantLikedDislikedResponseModel.fromJson(response.data);
      }
      else{
        print(response.data);

        return RestaurantLikedDislikedResponseModel(status: false, message: response.data.toString());
      }
    }catch(e){
      print(e);

      return RestaurantLikedDislikedResponseModel(status: false, message: e.toString());
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
      return RestaurantListResponse(status: false, restaurant: []);
    }
  } catch (e) {
    print('Filter exception: $e');
    return RestaurantListResponse(status: false, restaurant: []);
  }
}
}
