import 'package:dio/dio.dart';

class ChangePasswordModel {
  final String password;

  ChangePasswordModel({required this.password});

  FormData toFormData() {
    return FormData.fromMap({
      "password": password,
    });
  }
}