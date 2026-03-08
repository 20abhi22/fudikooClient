class ChangePasswordResponseModel {
  final bool status;
  final String message;

  ChangePasswordResponseModel({
    required this.status,
    required this.message,
  });

  factory ChangePasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
    );
  }
}