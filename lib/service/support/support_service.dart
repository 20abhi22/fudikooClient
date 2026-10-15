import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/support/support_information_model.dart';
import 'package:fudikoclient/utils/error_messages.dart';
import 'package:fudikoclient/utils/service_result.dart';

class SupportService {
  SupportService._internal();
  static final SupportService _instance = SupportService._internal();
  factory SupportService() => _instance;

  /// Returns the support details along with a reason when the fetch fails, so
  /// the contact screen can tell "offline" apart from "nothing configured".
  Future<ServiceResult<SupportInformationModel>>
  fetchSupportInformation() async {
    try {
      final response = await DioClient.dio.get('/customer/support-information');

      if (response.statusCode == 200 && response.data != null) {
        return ServiceResult.success(
          SupportInformationModel.fromJson(response.data),
        );
      }
      return ServiceResult.failure(
        statusCodeMessage(
          response.statusCode,
          fallback: 'We could not load support details. Please try again.',
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        friendlyErrorMessage(
          e,
          fallback: 'We could not load support details. Please try again.',
        ),
      );
    }
  }

  Future<SupportInformationModel?> getSupportInformation() async =>
      (await fetchSupportInformation()).data;
}
