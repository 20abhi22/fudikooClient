import 'package:dio/dio.dart';

class DeleteInqueryModelResponse {
  final bool status;
  final String? message;

  const DeleteInqueryModelResponse({required this.status, this.message});

  factory DeleteInqueryModelResponse.fromJson(Map<String, dynamic> json) {
    return DeleteInqueryModelResponse(
      status: json['status'] as bool,
      message: json['message'] as String?,
    );
  }
}

class DeleteInqueryModel {
  final String enquiryId;

  const DeleteInqueryModel({required this.enquiryId});

  FormData toFormData() {
    return FormData.fromMap({"enquiry_id": enquiryId});
  }
}
