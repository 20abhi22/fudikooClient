import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/invite/referral_model.dart';

class ReferralService {
  ReferralService._internal();
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;

  Future<ReferralModel?> getReferralLink() async {
    try {
      final response = await DioClient.dio.get('/customer/referral');

      if (response.statusCode == 200 && response.data != null) {
        return ReferralModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('ReferralService.getReferralLink error: $e');
      return null;
    }
  }
}