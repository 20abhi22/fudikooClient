import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/invite/referral_model.dart';
import 'package:fudikoclient/utils/error_messages.dart';
import 'package:fudikoclient/utils/service_result.dart';

class ReferralService {
  ReferralService._internal();
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;

  Future<ServiceResult<ReferralModel>> fetchReferralLink() async {
    try {
      final response = await DioClient.dio.get('/customer/referral');

      if (response.statusCode == 200 && response.data != null) {
        return ServiceResult.success(ReferralModel.fromJson(response.data));
      }
      return ServiceResult.failure(
        statusCodeMessage(
          response.statusCode,
          fallback: 'We could not load your invite link. Please try again.',
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        friendlyErrorMessage(
          e,
          fallback: 'We could not load your invite link. Please try again.',
        ),
      );
    }
  }

  Future<ReferralModel?> getReferralLink() async =>
      (await fetchReferralLink()).data;
}
