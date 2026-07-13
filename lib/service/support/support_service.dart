
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/support/support_information_model.dart';


class SupportService {
  SupportService._internal();
  static final SupportService _instance = SupportService._internal();
  factory SupportService() => _instance;

  Future<SupportInformationModel?> getSupportInformation() async {
    try {
      final response = await DioClient.dio.get('/customer/support-information');

      if (response.statusCode == 200 && response.data != null) {
        return SupportInformationModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('SupportService.getSupportInformation error: $e');
      return null;
    }
  }
}