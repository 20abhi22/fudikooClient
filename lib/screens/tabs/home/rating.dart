import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/restaurant/review_model.dart';
import 'package:fudikoclient/screens/feedback/feedback.dart';
import 'package:fudikoclient/screens/tabs/home/ratingCard.dart';
import 'package:fudikoclient/service/reservation/review_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class RatingPage extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantAddress;

  const RatingPage({
    super.key,
    this.restaurantId,
    this.restaurantName,
    this.restaurantAddress,
  });

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final ReviewService _reviewService = ReviewService();
  List<RestaurantReviewModel> _reviews = [];
  double _averageRating = 0;
  bool _isLoadingReviews = false;
  String _reviewsError = '';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (widget.restaurantId == null || widget.restaurantId!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _reviews = [];
        _averageRating = 0;
        _reviewsError = 'Restaurant ID is missing';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingReviews = true;
      _reviewsError = '';
    });

    try {
      final response = await _reviewService.getRestaurantReviews(
        widget.restaurantId!,
      );
      if (!mounted) return;
      setState(() {
        _reviews = response.reviews;
        _averageRating = response.averageRating;
        _reviewsError = response.status
            ? ''
            : (response.message.isNotEmpty
                  ? response.message
                  : 'Unable to load reviews');
        _isLoadingReviews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reviews = [];
        _averageRating = 0;
        _reviewsError = e.toString();
        _isLoadingReviews = false;
      });
    }
  }

  Widget _buildOverallStars(double rating) {
    final filledStars = rating.floor().clamp(0, 5);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => Icon(
          index < filledStars ? Icons.star : Icons.star_border,
          color: const Color(0xFFF0D128),
          size: 45.sp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalReviews = _reviews.length;
    final String ratingText = _averageRating > 0
        ? _averageRating.toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.fromLTRB(28.w, 56.h, 28.w, 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: AppText(
                  text: widget.restaurantName ?? "Restaurant",
                  size: 36,
                  fontWeight: FontWeight.w600,
                  color: appTextColor6,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: AppText(
                  text: "Restaurant",
                  size: 24,
                  fontWeight: FontWeight.w500,
                  color: appTextColor6,
                ),
              ),
              if (widget.restaurantAddress?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: appTextColor6, size: 17.sp),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: AppText(
                          text: widget.restaurantAddress!,
                          size: 13,
                          fontWeight: FontWeight.w400,
                          color: appTextColor6,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 50.h),

              // Overall rating
              Center(
                child: Column(
                  children: [
                    AppText(
                      text: "Overall Rating",
                      size: 17,
                      fontWeight: FontWeight.w500,
                      color: appTextColor2,
                    ),
                    SizedBox(height: 4.h),
                    AppText(
                      text: ratingText,
                      size: 48,
                      fontWeight: FontWeight.w600,
                      color: appTextColor2,
                    ),
                    _buildOverallStars(_averageRating),
                    SizedBox(height: 8.h),
                    AppText(
                      text: "Based on $totalReviews reviews",
                      size: 15,
                      fontWeight: FontWeight.w400,
                      color:appTextColor5,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 52.h),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FeedBack(
                          restaurantId: widget.restaurantId,
                          restaurantName: widget.restaurantName,
                        ),
                      ),
                    );

                    if (result == true && mounted) {
                      await _loadReviews();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: appButtonColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: AppText(
                      text: 'Add Review',
                      color: Colors.white,
                      size: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              if (_isLoadingReviews)
                const Center(child: CircularProgressIndicator())
              else if (_reviewsError.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: AppText(
                    text: _reviewsError,
                    size: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.red,
                    isCentered: true,
                  ),
                )
              else if (_reviews.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: AppText(
                    text: 'No reviews yet',
                    size: 14,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                    isCentered: true,
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reviews.length,
                  padding: EdgeInsets.only(bottom: 30.h),
                  itemBuilder: (context, index) =>
                      RatingCard(review: _reviews[index]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
