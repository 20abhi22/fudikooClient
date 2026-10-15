import 'package:dio/dio.dart';

class ChangePasswordModel {
  final String password;
  final String? oldPassword;

  ChangePasswordModel({required this.password, this.oldPassword});

  FormData toFormData() {
    return FormData.fromMap({
      "password": password,
      if (oldPassword != null) "old_password": oldPassword,
    });
  }
}
