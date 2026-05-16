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