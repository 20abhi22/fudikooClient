import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/restaurant/review_model.dart';
import 'package:fudikoclient/utils/tokens.dart';

class ReviewService {
  Future<RestaurantReviewListResponse> getRestaurantReviews(
    String restaurantId,
  ) async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/customer/restaurant/reviews',
      queryParameters: {'restaurant_id': restaurantId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return RestaurantReviewListResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<ReviewResponse> submitReview(ReviewRequest request) async {
    final token = await getToken();
    final formData = FormData.fromMap(request.toMap());
    final response = await DioClient.dio.post(
      '/customer/restaurant/review',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ReviewResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}