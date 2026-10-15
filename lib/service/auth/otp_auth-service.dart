import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/auth/otp-model.dart';
import 'package:fudikoclient/utils/error_messages.dart';
import 'package:fudikoclient/utils/tokens.dart';

class OtpAuthService {
  Future<SendOtpResponseModel> sendOtp({String? tokenOverride}) async {
    try {
      final token = tokenOverride ?? await getToken();
      final response = await DioClient.dio.get(
        '/send-otp',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SendOtpResponseModel.fromJson(response.data);
      } else {
        return SendOtpResponseModel(
          status: false,
          message: statusCodeMessage(
            response.statusCode,
            fallback: 'We could not send the code. Please try again.',
          ),
        );
      }
    } catch (e) {
      return SendOtpResponseModel(
        status: false,
        message: friendlyErrorMessage(
          e,
          fallback: 'We could not send the code. Please try again.',
        ),
      );
    }
  }

  Future<VerifyOtpResponseModel> verifyOtp(
    String otp,
    String otpId, {
    String? tokenOverride,
  }) async {
    try {
      final token = tokenOverride ?? await getToken();
      final formData = FormData.fromMap({'otp': otp, 'otp_id': otpId});
      final response = await DioClient.dio.post(
        '/verify-otp',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return VerifyOtpResponseModel.fromJson(response.data);
      } else {
        return VerifyOtpResponseModel(
          status: false,
          message: statusCodeMessage(
            response.statusCode,
            fallback: 'We could not verify the code. Please try again.',
          ),
        );
      }
    } catch (e) {
      return VerifyOtpResponseModel(
        status: false,
        message: friendlyErrorMessage(
          e,
          fallback: 'We could not verify the code. Please try again.',
        ),
      );
    }
  }
}
