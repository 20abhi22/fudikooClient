import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/notification/notification_badges_model.dart';
import 'package:fudikoclient/utils/tokens.dart';

class NotificationBadgesService {
  Future<NotificationBadgesModel> fetchBadges() async {
    final token = await getToken();

    try {
      final response = await DioClient.dio.get(
        '/customer/notification/badges',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is Map) {
        return NotificationBadgesModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Notification badges fetch error: $e');
      }
    }

    return const NotificationBadgesModel();
  }
}
