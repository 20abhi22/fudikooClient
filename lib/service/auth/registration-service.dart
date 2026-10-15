import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/auth/complete-registration.dart';
import 'package:fudikoclient/model/auth/registration-model.dart';
import 'package:fudikoclient/utils/error_messages.dart';
import 'package:fudikoclient/utils/tokens.dart';

class RegistrationAuthService {
  Future<RegistrationResponseModel> registerUser(RegistrationModel user) async {
    try {
      final formData = user.toFormData();

      final response = await DioClient.dio.post('/register', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(response.data);
        // Some responses arrive as a raw string (e.g. non-JSON content-type),
        // which would make fromJson throw.
        final raw = response.data;
        final Map<String, dynamic> json = raw is String
            ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
            : Map<String, dynamic>.from(raw as Map);
        return RegistrationResponseModel.fromJson(json);
      } else {
        return RegistrationResponseModel(
          status: false,
          message: statusCodeMessage(
            response.statusCode,
            fallback: 'We could not create your account. Please try again.',
          ),
          token: null,
        );
      }
    } catch (e, st) {
      print('registerUser failed: $e\n$st');
      return RegistrationResponseModel(
        status: false,
        message: friendlyErrorMessage(
          e,
          fallback: 'We could not create your account. Please try again.',
        ),
        token: null,
      );
    }
  }

  Future<CompleteRegistrationModelResponse> completeRegistration(
    CompleteRegistrationModel details, {
    String? tokenOverride,
  }) async {
    try {
      final formData = await details.toFormData();
      final token = tokenOverride ?? await getToken();
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
      if (e is DioException && e.response?.statusCode == 413) {
        return CompleteRegistrationModelResponse(
          status: false,
          message: "Profile photo is too large. Please choose a smaller image.",
        );
      }

      return CompleteRegistrationModelResponse(
        status: false,
        message: friendlyErrorMessage(
          e,
          fallback: 'We could not finish your registration. Please try again.',
        ),
      );
    }
  }
}
