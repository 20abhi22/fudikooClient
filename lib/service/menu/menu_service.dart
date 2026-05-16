import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/menu/menu_model.dart';
import 'package:fudikoclient/utils/tokens.dart';

class MenuService {
  Future<MenuResponse> getMenu(String restaurantId) async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.post(
        '/customer/restaurant/menu',
        data: FormData.fromMap({'restaurant_id': restaurantId}),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return MenuResponse.fromJson(response.data);
      }
      return MenuResponse(status: false, pdfs: [], individualMenu: []);
    } catch (e) {
      print('Menu fetch error: $e');
      return MenuResponse(status: false, pdfs: [], individualMenu: []);
    }
  }
}