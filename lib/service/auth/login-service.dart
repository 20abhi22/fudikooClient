import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/auth/login-model.dart';

class LoginAuthService {
  Future<LoginResponseModel> loginUser(UserLoginModel user) async {
    try {
      final formData = user.toFormData();

      final response = await DioClient.dio.post('/login', data: formData);

      if (response.statusCode == 200) {
        return LoginResponseModel.fromJson(response.data);
      } else {
        return LoginResponseModel(
          status: false,
          message: 'Login failed: ${response.statusCode}',
          token: null,
        );
      }
    } catch (e) {
      return LoginResponseModel(
        status: false,
        message: 'Something went wrong: $e',
        token: null,
      );
    }
  }
}
