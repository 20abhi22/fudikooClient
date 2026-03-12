import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/profile/customer-profile-model.dart';
import 'package:fudikoclient/utils/tokens.dart';

class CustomerProfileService {
  Future<CustomerProfileModel> getProfile() async {
    try {
      final token = await getToken();
      final response = await DioClient.dio.get(
        '/customer/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('Profile response: ${response.data}');
      print('Response type: ${response.data.runtimeType}');

      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;

      return CustomerProfileModel.fromJson(data);
    } catch (e) {
      print('Profile fetch error: $e');
      throw UnimplementedError();
    }
  }
}