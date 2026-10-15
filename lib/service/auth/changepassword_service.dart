import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/auth/change_password_response_model.dart';
import 'package:fudikoclient/model/auth/changepassword_model.dart';
import 'package:fudikoclient/utils/error_messages.dart';
import 'package:fudikoclient/utils/tokens.dart';

class ChangePasswordService {
  Future<ChangePasswordResponseModel> changePassword(
    ChangePasswordModel model,
  ) async {
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
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        return ChangePasswordResponseModel.fromJson(response.data);
      } else {
        return ChangePasswordResponseModel(
          status: false,
          message: statusCodeMessage(
            response.statusCode,
            fallback: 'We could not change your password. Please try again.',
          ),
        );
      }
    } catch (e) {
      return ChangePasswordResponseModel(
        status: false,
        message: friendlyErrorMessage(
          e,
          fallback: 'We could not change your password. Please try again.',
        ),
      );
    }
  }
}
