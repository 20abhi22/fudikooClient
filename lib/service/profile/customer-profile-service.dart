import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/profile/customer-profile-model.dart';
import 'package:fudikoclient/utils/tokens.dart';

class CustomerProfileService {
  Future<CustomerProfileModel> getProfile() async {
    try {
      final token = await getToken();
      final response = await DioClient.dio.get(
        '/customer/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('Profile response: ${response.data}');
      print('Response type: ${response.data.runtimeType}');

      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;

      return CustomerProfileModel.fromJson(data);
    } catch (e) {
      print('Profile fetch error: $e');
      throw UnimplementedError();
    }
  }

  Future<void> updateProfilePhoto(String imagePath) async {
    try {
      final token = await getToken();
      final formData = FormData.fromMap({
        'profile_picture': await MultipartFile.fromFile(imagePath),
      });

      await DioClient.dio.post(
        '/customer/update-profile',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      print('Profile photo update error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String lat,
    required String lng,
    String? profilePicturePath,
  }) async {
    try {
      final token = await getToken();
      final Map<String, dynamic> data = {
        'name': name,
        'phone': phone,
        'lat': lat,
        'lng': lng,
      };

      final imagePath = profilePicturePath?.trim();
      if (imagePath != null && imagePath.isNotEmpty) {
        data['profile_picture'] = await MultipartFile.fromFile(imagePath);
      }

      final response = await DioClient.dio.post(
        '/customer/update-profile',
        data: FormData.fromMap(data),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      return {
        'status': response.statusCode == 200 || response.statusCode == 201,
        'message': response.statusCode == 200 || response.statusCode == 201
            ? 'Profile updated successfully'
            : 'Unable to update profile',
      };
    } catch (e) {
      print('Profile update error: $e');
      if (e is DioException && e.response?.statusCode == 413) {
        return {
          'status': false,
          'message':
              'Profile photo is too large. Please choose a smaller image.',
        };
      }

      if (e is DioException && e.response?.data is Map<String, dynamic>) {
        return e.response!.data as Map<String, dynamic>;
      }

      return {'status': false, 'message': 'Unable to update profile'};
    }
  }
}
