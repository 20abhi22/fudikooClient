import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/restaurant/review_model.dart';

class ReviewService {
Future<ReviewResponse> submitReview(ReviewRequest request) async {
  DioClient.addInterceptor();
  // print('BASE URL: ${DioClient.dio.options.baseUrl}');
  // print('ENDPOINT: customer/restaurant/review');
  // print('PAYLOAD: ${request.toMap()}');
  final formData = FormData.fromMap(request.toMap());
  final response = await DioClient.dio.post(
    '/customer/restaurant/review',
    data: formData,
  );
  return ReviewResponse.fromJson(response.data);
}
}