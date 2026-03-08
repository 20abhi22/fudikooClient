import 'package:dio/dio.dart';

class RegistrationModel {
  final String username;
  final String email;
  final String password;

  RegistrationModel({
    required this.username,
    required this.email,
    required this.password
  });


  FormData toFormData() {
    return FormData.fromMap({
      "username": username,
      "email": email,
      "password": password,
    });
  }
}

class RegistrationResponseModel {
  final bool status;
  final String message;
  final String? token;
  final Map<String, String>? fieldErrors;

  RegistrationResponseModel({
    required this.status,
    required this.message,
    this.token,
    this.fieldErrors,
  });

  factory RegistrationResponseModel.fromJson(Map<String, dynamic> json) {
    Map<String, String>? parsedErrors;

    if (json['errors'] != null && json['errors'] is Map<String, dynamic>) {
      parsedErrors = (json['errors'] as Map<String, dynamic>).map((key, value) {
        final messages = value is List ? value : [value.toString()];
        return MapEntry(key, messages.isNotEmpty ? messages.first : '');
      });
    }

    return RegistrationResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
      token: json['token'],
      fieldErrors: parsedErrors,
    );
  }
}
