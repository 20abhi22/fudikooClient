class ReviewRequest {
  final String restaurantId;
  final int stars;
  final String comment;

  ReviewRequest({
    required this.restaurantId,
    required this.stars,
    required this.comment,
  });

  Map<String, dynamic> toMap() => {
    'restaurant_id': restaurantId,
    'stars': stars.toString(),
    'comment': comment,
  };
}

class ReviewResponse {
  final bool status;
  final String message;

  ReviewResponse({required this.status, required this.message});

  factory ReviewResponse.fromJson(Map<String, dynamic> json) => ReviewResponse(
    status: json['status'] ?? false,
    message: json['message'] ?? '',
  );
}

class RestaurantReviewModel {
  final String user;
  final String profilePicture;
  final String review;
  final String postedDate;
  final int stars;

  const RestaurantReviewModel({
    required this.user,
    required this.profilePicture,
    required this.review,
    required this.postedDate,
    this.stars = 0,
  });

  factory RestaurantReviewModel.fromJson(Map<String, dynamic> json) {
    return RestaurantReviewModel(
      user: (json['user'] ?? '').toString(),
      profilePicture: (json['profile_picture'] ?? '').toString(),
      review: (json['review'] ?? '').toString(),
      postedDate: (json['posted_date'] ?? '').toString(),
      stars: _parseStars(json['stars'] ?? json['rating'] ?? json['star']),
    );
  }
}

int _parseStars(dynamic value) {
  if (value is int) return value.clamp(0, 5);
  if (value is num) return value.round().clamp(0, 5);

  final parsed = double.tryParse((value ?? '0').toString());
  return (parsed?.round() ?? 0).clamp(0, 5);
}

class RestaurantReviewListResponse {
  final bool status;
  final double averageRating;
  final List<RestaurantReviewModel> reviews;
  final String message;

  const RestaurantReviewListResponse({
    required this.status,
    required this.averageRating,
    required this.reviews,
    required this.message,
  });

  factory RestaurantReviewListResponse.fromJson(Map<String, dynamic> json) {
    final rawReviews = (json['reviews'] as List?) ?? const [];
    return RestaurantReviewListResponse(
      status: json['status'] == true || json['status'] == 1,
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0,
      reviews: rawReviews
          .map(
            (item) => RestaurantReviewModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      message: (json['message'] ?? '').toString(),
    );
  }
}
