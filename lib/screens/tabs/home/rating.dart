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

  const RatingPage({super.key, this.restaurantId, this.restaurantName});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final ReviewService _reviewService = ReviewService();
  final List<_UserReview> _newReviews = [];

  Future<void> _showAddReviewDialog() async {
    final TextEditingController commentController = TextEditingController();
    int selectedRating = 0;
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24.w,
                right: 24.w,
                top: 20.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    AppText(
                      text: "Add Your Review",
                      size: 18,
                      fontWeight: FontWeight.w600,
                      color: appTextColor3,
                    ),
                    SizedBox(height: 20.h),

                    // Interactive stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedRating = index + 1),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Icon(
                              Icons.star,
                              size: 40.w,
                              color: index < selectedRating
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 8.h),
                    AppText(
                      text: selectedRating == 0
                          ? "Tap to rate"
                          : _ratingLabel(selectedRating),
                      size: 13,
                      fontWeight: FontWeight.w400,
                      color: selectedRating == 0
                          ? Colors.grey
                          : appTextColor3,
                    ),
                    SizedBox(height: 20.h),

                    // Comment field
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: appButtonColor),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appButtonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final comment = commentController.text.trim();
                                if (selectedRating == 0) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text('Please select a rating')),
                                  );
                                  return;
                                }
                                if (comment.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text('Please write a comment')),
                                  );
                                  return;
                                }
                                if (widget.restaurantId == null ||
                                    widget.restaurantId!.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Restaurant ID is missing')),
                                  );
                                  return;
                                }

                                setSheetState(() => isSubmitting = true);

                                try {
                                  final response =
                                      await _reviewService.submitReview(
                                    ReviewRequest(
                                      restaurantId: widget.restaurantId!,
                                      stars: selectedRating,
                                      comment: comment,
                                    ),
                                  );

                                  if (!mounted) return;

                                  if (response.status) {
                                    Navigator.pop(ctx); // close sheet
                                    setState(() {
                                      _newReviews.insert(
                                        0,
                                        _UserReview(
                                          rating: selectedRating,
                                          comment: comment,
                                        ),
                                      );
                                    });
                                    _showSuccessSnackbar();
                                  } else {
                                    setSheetState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                          content: Text(response.message.isNotEmpty
                                              ? response.message
                                              : 'Failed to submit review')),
                                    );
                                  }
                                } catch (e) {
                                  setSheetState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Error: ${e.toString()}')),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    commentController.dispose();
  }

  String _ratingLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }

  void _showSuccessSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 6,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20.w),
            SizedBox(width: 10.w),
            AppText(
              text: 'Review submitted successfully!',
              size: 13,
              fontWeight: FontWeight.w600,
              color: appTextColor3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalReviews = 35 + _newReviews.length;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 50.h),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: widget.restaurantName ?? "Restaurant",
                          size: 30,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                        AppText(
                          text: "Reviews",
                          size: 20,
                          fontWeight: FontWeight.w500,
                          color: appTextColor3,
                        ),
                      ],
                    ),
                  ),
                  // Add review button
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => FeedBack(
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
    ),
  ),
),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: appButtonColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18.w),
                          SizedBox(width: 4.w),
                          Text(
                            'Review',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),

              // Overall rating
              AppText(
                text: "Overall Rating",
                size: 16,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
              ),
              SizedBox(height: 10.h),
              AppText(
                text: "4.8",
                size: 50,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
              ),
              SizedBox(height: 10.h),
              Wrap(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    color: index < 5 ? Colors.amber : Colors.grey,
                    size: 40,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              AppText(
                text: "Based on $totalReviews reviews",
                size: 15,
                fontWeight: FontWeight.w400,
                color: appTextColor2,
              ),
              SizedBox(height: 40.h),

              // New reviews (locally added)
              if (_newReviews.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _newReviews.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) =>
                      _NewReviewCard(review: _newReviews[index]),
                ),

              // Static existing reviews
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) => const RatingCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserReview {
  final int rating;
  final String comment;
  const _UserReview({required this.rating, required this.comment});
}

class _NewReviewCard extends StatelessWidget {
  final _UserReview review;
  const _NewReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: appButtonColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  color: index < review.rating ? Colors.amber : Colors.grey,
                  size: 18.w,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            AppText(
              text: review.comment,
              size: 13,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
            ),
          ],
        ),
      ),
    );
  }
}