import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/partner_ad/partner_ad_model.dart';
import 'package:fudikoclient/utils/error_messages.dart';
import 'package:fudikoclient/utils/service_result.dart';

class PartnerAdsService {
  PartnerAdsService._internal();
  static final PartnerAdsService _instance = PartnerAdsService._internal();
  factory PartnerAdsService() => _instance;

  Future<ServiceResult<List<PartnerAdModel>>> fetchPartnerAds() async {
    try {
      final response = await DioClient.dio.get('/customer/partner-ads');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data['partnerAds'] ?? [];
        return ServiceResult.success(
          list.map((e) => PartnerAdModel.fromJson(e)).toList(),
        );
      }
      return ServiceResult.failure(
        statusCodeMessage(
          response.statusCode,
          fallback: 'We could not load offers. Please try again.',
        ),
        data: const <PartnerAdModel>[],
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('PartnerAdsService.fetchPartnerAds error: $e');
        debugPrint('$st');
      }
      return ServiceResult.failure(
        friendlyErrorMessage(
          e,
          fallback: 'We could not load offers. Please try again.',
        ),
        data: const <PartnerAdModel>[],
      );
    }
  }

  Future<List<PartnerAdModel>> getPartnerAds() async =>
      (await fetchPartnerAds()).data ?? const <PartnerAdModel>[];
}
