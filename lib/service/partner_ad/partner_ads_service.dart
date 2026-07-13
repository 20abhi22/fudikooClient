import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/partner_ad/partner_ad_model.dart';


class PartnerAdsService {
  PartnerAdsService._internal();
  static final PartnerAdsService _instance = PartnerAdsService._internal();
  factory PartnerAdsService() => _instance;

  // Future<List<PartnerAdModel>> getPartnerAds() async {
  //   try {
  //     final response = await DioClient.dio.get('/customer/partner-ads');

  //     if (response.statusCode == 200 && response.data != null) {
  //       final List<dynamic> list = response.data['partnerAds'] ?? [];
  //       return list.map((e) => PartnerAdModel.fromJson(e)).toList();
  //     }
  //     return [];
  //   } catch (e) {
  //     print('PartnerAdsService.getPartnerAds error: $e');
  //     return [];
  //   }
  // }

  Future<List<PartnerAdModel>> getPartnerAds() async {
    print('PartnerAdsService: starting request');
    try {
      final response = await DioClient.dio.get('/customer/partner-ads');
      print('PartnerAdsService: status ${response.statusCode}');
      print('PartnerAdsService: data ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data['partnerAds'] ?? [];
        print('PartnerAdsService: parsed ${list.length} ads');
        return list.map((e) => PartnerAdModel.fromJson(e)).toList();
      }
      return [];
    } catch (e, st) {
      print('PartnerAdsService.getPartnerAds error: $e');
      print(st);
      return [];
    }
  }
}