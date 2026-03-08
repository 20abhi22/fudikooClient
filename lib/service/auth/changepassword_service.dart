import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/auth/change_password_response_model.dart';
import 'package:fudikoclient/model/auth/changepassword_model.dart';
import 'package:fudikoclient/utils/tokens.dart';   

class ChangePasswordService {
  Future<ChangePasswordResponseModel> changePassword(
      ChangePasswordModel model) async {
    try {

      String? token = await getToken();  

      if (token == null) {
        return ChangePasswordResponseModel(
          status: false,
          message: "User not logged in",
        );
      }

      final formData = model.toFormData();

      final response = await DioClient.dio.post(
        '/change-password',
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",  
          },
        ),
      );

      if (response.statusCode == 200) {
        return ChangePasswordResponseModel.fromJson(response.data);
      } else {
        return ChangePasswordResponseModel(
          status: false,
          message: "Failed: ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      return ChangePasswordResponseModel(
        status: false,
        message: e.response?.data['message'] ?? "Something went wrong",
      );
    } catch (e) {
      return ChangePasswordResponseModel(
        status: false,
        message: "Unexpected error occurred",
      );
    }
  }
}