import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/restaurant/review_model.dart';
import 'package:fudikoclient/service/reservation/review_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class FeedBack extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;

  const FeedBack({
    super.key,
    this.restaurantId,
    this.restaurantName,
  });

  @override
  State<FeedBack> createState() => _FeedBackState();
}

class _FeedBackState extends State<FeedBack> {
  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _isSubmitClicked = false; // ← fixed: was undeclared
  final TextEditingController _commentController = TextEditingController(); // ← fixed: was _feedbackController
  final ReviewService _reviewService = ReviewService();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating first')),
      );
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }
    if (widget.restaurantId == null || widget.restaurantId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant ID missing')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _reviewService.submitReview(
        ReviewRequest(
          restaurantId: widget.restaurantId!,
          stars: _selectedRating,
          comment: _commentController.text.trim(),
        ),
      );

      if (!mounted) return;

      if (response.status) {
        setState(() => _isSubmitClicked = true); // show thank-you modal
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isNotEmpty
                ? response.message
                : 'Failed to submit review'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),
                      Image.asset(
                        'assets/images/feedback.png',
                        height: 150.h,
                        width: 150.w,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 14.h),
                      AppText(
                        text: "We Value Your",
                        size: 30,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 2.h),
                      AppText(
                        text: "Feedback!",
                        size: 30,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 18.h),
                      AppText(
                        text: "How would you rate your experience?",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                      SizedBox(height: 18.h),

                      // ── Interactive stars ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedRating = index + 1),
                            child: Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 4.w),
                              child: Icon(
                                Icons.star,
                                size: 38.r,
                                color: index < _selectedRating
                                    ? Colors.amber
                                    : Colors.grey.shade300,
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 8.h),

                      // ── Rating label ──
                      AppText(
                        text: _selectedRating == 0
                            ? "Tap to rate"
                            : ["", "Poor", "Fair", "Good", "Very Good", "Excellent!"][_selectedRating],
                        size: 13,
                        fontWeight: FontWeight.w400,
                        color: _selectedRating == 0
                            ? Colors.grey
                            : appTextColor3,
                      ),

                      SizedBox(height: 26.h),

                      // ── Comment field ──
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: TextField(
                          controller: _commentController, // ← fixed
                          maxLines: 5,
                          maxLength: 300,
                          decoration: InputDecoration(
                            hintText: 'How was your experience?',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13.sp,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          style: TextStyle(
                            color: appTextColor2,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 34.h),

                      // ── Submit button ──
                      SizedBox(
                        width: 120.w,
                        height: 38.h,
                        child: _isSubmitting
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : AppButton(
                                text: "Submit",
                                onPressed: _submitReview, // ← fixed: calls real submit
                                size: 13,
                                borderRadius: 12.r,
                              ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),

            // ── Back button ──
            Positioned(
              top: 18.h,
              left: 18.w,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: appTextColor3,
                  size: 24.r,
                ),
              ),
            ),

            // ── Thank-you modal ──
            if (_isSubmitClicked) _confirmModal(),
          ],
        ),
      ),
    );
  }

  Widget _confirmModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 34.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _isSubmitClicked = false);
                      Navigator.pop(context); // ← go back after dismissing
                    },
                    child: Align(
                      alignment: Alignment.centerRight,
                      child:
                          Icon(Icons.close, size: 22.r, color: appTextColor3),
                    ),
                  ),
                  Image.asset(
                    'assets/images/handshake.png',
                    height: 72.h,
                    width: 72.w,
                    fit: BoxFit.contain,
                  ),
                  AppText(
                    text: "Thank you for your",
                    size: 21,
                    fontWeight: FontWeight.w600,
                    color: appLinkColor2,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    text: "feedback!",
                    size: 21,
                    fontWeight: FontWeight.w700,
                    color: appLinkColor2,
                  ),
                  SizedBox(height: 12.h),
                  AppText(
                    text: "We appreciate your input and",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                  SizedBox(height: 2.h),
                  AppText(
                    text: "will use it to improve.",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}