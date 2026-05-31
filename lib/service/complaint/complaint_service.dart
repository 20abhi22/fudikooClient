import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/utils/tokens.dart';

class ComplaintService {
  Future<bool> registerComplaint(String complaint) async {
    final String trimmedComplaint = complaint.trim();
    if (trimmedComplaint.isEmpty) {
      return false;
    }

    final token = await getToken();
    try {
      final response = await DioClient.dio.post(
        '/customer/complaints/register',
        data: FormData.fromMap({'complaint': trimmedComplaint}),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }
}