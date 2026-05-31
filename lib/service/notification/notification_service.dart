import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/utils/tokens.dart';

class NotificationSettingsModel {
  final bool newOffers;
  final bool newPromotions;
  final bool reservationReminders;
  final bool orderStatus;

  NotificationSettingsModel({
    required this.newOffers,
    required this.newPromotions,
    required this.reservationReminders,
    required this.orderStatus,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      newOffers: _toBool(json['new_offers']),
      newPromotions: _toBool(json['new_promotions']),
      reservationReminders: _toBool(json['reservation_reminders']),
      orderStatus: _toBool(json['order_status']),
    );
  }
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

class NotificationService {
  Future<NotificationSettingsModel?> fetchNotificationSettings() async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.get(
        '/customer/notification-settings',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return NotificationSettingsModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  Future<bool> saveNotificationSettings({
    required bool newOffers,
    required bool newPromotions,
    required bool reservationReminders,
    required bool orderStatus,
  }) async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.post(
        '/customer/notification-settings/store',
        data: FormData.fromMap({
          'new_offers': newOffers ? '1' : '0',
          'new_promotions': newPromotions ? '1' : '0',
          'reservation_reminders': reservationReminders ? '1' : '0',
          'order_status': orderStatus ? '1' : '0',
        }),
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