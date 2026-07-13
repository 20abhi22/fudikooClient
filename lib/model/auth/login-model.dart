import 'package:dio/dio.dart';

class UserLoginModel {
  final String username;
  final String password;

  UserLoginModel({required this.username, required this.password});

  FormData toFormData() {
    return FormData.fromMap({"username": username, "password": password});
  }
}

class LoginResponseModel {
  final bool status;
  final String message;
  final String? token;
  final bool isRegistered;
  final bool otpVerified;

  LoginResponseModel({
    required this.status,
    required this.message,
    this.token,
    this.isRegistered = false,
    this.otpVerified = false,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    return LoginResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
      token: json['token'],
      isRegistered: parseBool(json['is_registered']),
      otpVerified: parseBool(json['otp_verified'] ?? json['otp_verfied']),
    );
  }
}
