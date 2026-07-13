import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/badge/badge_model.dart';

class BadgesService {
  BadgesService._internal();
  static final BadgesService _instance = BadgesService._internal();
  factory BadgesService() => _instance;

  Future<BadgesResponseModel?> getBadges() async {
    try {
      final response = await DioClient.dio.get('/customer/badges');

      if (response.statusCode == 200 && response.data != null) {
        return BadgesResponseModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('BadgesService.getBadges error: $e');
      return null;
    }
  }
}