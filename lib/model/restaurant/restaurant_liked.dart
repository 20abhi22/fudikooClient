import 'package:dio/dio.dart';

class RestaurantLikedDislikedResponseModel {
  final bool status;
  final String? message;

  const RestaurantLikedDislikedResponseModel({
    required this.status,
    this.message,
  });

  factory RestaurantLikedDislikedResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return RestaurantLikedDislikedResponseModel(
      status: json['status'] as bool,
      message: json['message'] as String?,
    );
  }
}

class RestaurantLikedDislikedModel {
  String? uuid;

  RestaurantLikedDislikedModel({this.uuid});

  FormData toFormData() {
    return FormData.fromMap({"id": uuid});
  }
}
