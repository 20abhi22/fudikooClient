import 'package:dio/dio.dart';

class CompleteRegistrationModel {
  final String phone;
  final String lat;
  final String lng;
  final String? profilePicturePath;

  CompleteRegistrationModel({
    required this.phone,
    required this.lat,
    required this.lng,
    this.profilePicturePath,
  });

  Future<FormData> toFormData() async {
    final Map<String, dynamic> data = {"phone": phone, "lat": lat, "lng": lng};

    final imagePath = profilePicturePath?.trim();
    if (imagePath != null && imagePath.isNotEmpty) {
      data["profile_picture"] = await MultipartFile.fromFile(imagePath);
    }

    return FormData.fromMap(data);
  }
}

class CompleteRegistrationModelResponse {
  final String message;
  final bool status;
  CompleteRegistrationModelResponse({
    required this.message,
    required this.status,
  });

  factory CompleteRegistrationModelResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return CompleteRegistrationModelResponse(
      message: json['message'],
      status: json['status'],
    );
  }
}
