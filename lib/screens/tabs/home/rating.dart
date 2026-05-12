import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/screens/tabs/home/ratingCard.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:dio/dio.dart';

class RatingPage extends StatefulWidget {
  final String? restaurantId;

  const RatingPage({super.key, this.restaurantId});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final List<_UserReview> _newReviews = [];

  void _showReviewSuccessPopup() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 6,
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        content: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 18.w),
            SizedBox(width: 4.w),
            Icon(Icons.star, color: Colors.amber, size: 20.w),
            SizedBox(width: 4.w),
            Icon(Icons.star, color: Colors.amber, size: 18.w),
            SizedBox(width: 10.w),
            Expanded(
              child: AppText(
                text: 'Review updated successfully',
                size: 13,
                fontWeight: FontWeight.w600,
                color: appTextColor3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddReviewDialog() async {
    final TextEditingController commentController = TextEditingController();
    int selectedRating = 0;

    final _UserReview? review = await showDialog<_UserReview>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Review'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your rating'),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = index + 1;
                            });
                          },
                          icon: Icon(
                            Icons.star,
                            color: index < selectedRating
                                ? Colors.amber
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write your comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appButtonColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final String comment = commentController.text.trim();
                    if (selectedRating == 0 || comment.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please add rating and comment'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _UserReview(rating: selectedRating, comment: comment),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    commentController.dispose();

    if (review == null || !mounted) return;

    // Try to submit to server. If restaurantId is missing, show error.
    if (widget.restaurantId == null || widget.restaurantId!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant id missing. Cannot submit.')),
      );
      return;
    }

    final bool success = await _submitReviewToServer(review);

    if (!mounted) return;

    if (success) {
      setState(() {
        _newReviews.insert(0, review);
      });

      _showReviewSuccessPopup();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit review. Please try again.')),
      );
    }
  }

  Future<bool> _submitReviewToServer(_UserReview review) async {
    try {
      DioClient.addInterceptor();

      final formData = FormData.fromMap({
        'restaurant_id': widget.restaurantId,
        'stars': review.rating.toString(),
        'comment': review.comment,
      });

      final response = await DioClient.dio.post('customer/restaurant/review', data: formData);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['status'] == true) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Bollywood",
                              size: 35,
                              fontWeight: FontWeight.w600,
                              color: appTextColor3,
                            ),
                            AppText(
                              text: "Restaurant",
                              size: 25,
                              fontWeight: FontWeight.w600,
                              color: appTextColor3,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: appButtonColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: IconButton(
                          onPressed: _showAddReviewDialog,
                          icon: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 22.w,
                          ),
                          tooltip: 'Add review',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 15.w, color: appTextColor3),
                      SizedBox(width: 5.w),
                      AppText(
                        text: "Ulitsa Serpukhovskiy Val-14",
                        size: 15,
                        fontWeight: FontWeight.w400,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 40.h),
              Column(
                children: [
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
                        color: index < 3 ? Colors.amber : Colors.grey,
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
                  if (_newReviews.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _newReviews.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final review = _newReviews[index];
                        return _NewReviewCard(review: review);
                      },
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) => const RatingCard(),
                  ),
                ],
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
