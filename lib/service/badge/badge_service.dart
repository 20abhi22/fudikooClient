import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/badge/badge_model.dart';
import 'package:fudikoclient/utils/error_messages.dart';
import 'package:fudikoclient/utils/service_result.dart';

class BadgesService {
  BadgesService._internal();
  static final BadgesService _instance = BadgesService._internal();
  factory BadgesService() => _instance;

  Future<ServiceResult<BadgesResponseModel>> fetchBadges() async {
    try {
      final response = await DioClient.dio.get('/customer/badges');

      if (response.statusCode == 200 && response.data != null) {
        return ServiceResult.success(
          BadgesResponseModel.fromJson(response.data),
        );
      }
      return ServiceResult.failure(
        statusCodeMessage(
          response.statusCode,
          fallback: 'We could not load your badges. Please try again.',
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        friendlyErrorMessage(
          e,
          fallback: 'We could not load your badges. Please try again.',
        ),
      );
    }
  }

  Future<BadgesResponseModel?> getBadges() async => (await fetchBadges()).data;
}
