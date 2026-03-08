import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/auth/complete-registration.dart';
import 'package:fudikoclient/model/auth/registration-model.dart';
import 'package:fudikoclient/utils/tokens.dart';

class RegistrationAuthService {
  Future<RegistrationResponseModel> registerUser(RegistrationModel user) async {
    try {
      final formData = user.toFormData();

      final response = await DioClient.dio.post('/register', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(response.data);
        return RegistrationResponseModel.fromJson(response.data);
      } else {
        return RegistrationResponseModel(
          status: false,
          message: 'Registration failed: ${response.statusCode}',
          token: null,
        );
      }
    } catch (e) {
      return RegistrationResponseModel(
        status: false,
        message: 'Something went wrong: $e',
        token: null,
      );
    }
  }

  Future<CompleteRegistrationModelResponse> completeRegistration(
    CompleteRegistrationModel details,
  ) async {
    try {
      final formData = details.toFormData();
      final token = await getToken();
      final response = await DioClient.dio.post(
        '/customer/complete-registration',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = {
          "status": response.data['status'],
          "message": response.data['message'],
        };
        return CompleteRegistrationModelResponse.fromJson(data);
      } else {
        return CompleteRegistrationModelResponse(
          status: false,
          message: "Registration failed!",
        );
      }
    } catch (e) {
      print(e);
      return CompleteRegistrationModelResponse(
        status: false,
        message: "Something went wrong : $e",
      );
    }
  }
}
