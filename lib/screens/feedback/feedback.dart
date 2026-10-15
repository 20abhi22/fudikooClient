import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/restaurant/review_model.dart';
import 'package:fudikoclient/service/reservation/review_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class FeedBack extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;

  const FeedBack({super.key, this.restaurantId, this.restaurantName});

  @override
  State<FeedBack> createState() => _FeedBackState();
}

class _FeedBackState extends State<FeedBack> {
  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _isSubmitClicked = false; // ← fixed: was undeclared
  final TextEditingController _commentController =
      TextEditingController(); // ← fixed: was _feedbackController
  final ReviewService _reviewService = ReviewService();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      showErrorSnack(context, 'Please select a rating first');
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      showErrorSnack(context, 'Please write a comment');
      return;
    }
    if (widget.restaurantId == null || widget.restaurantId!.isEmpty) {
      showErrorSnack(context, 'Restaurant ID missing');
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
        showErrorSnack(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to submit review',
        );
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _FeedbackMetrics.fromContext(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.pageHorizontalPadding,
                    vertical: metrics.pageVerticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: metrics.contentMaxWidth,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: metrics.topGap),
                        Image.asset(
                          'assets/images/feedback.png',
                          height: metrics.heroImageSize,
                          width: metrics.heroImageSize,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: metrics.imageToTitleGap),
                        AppText(
                          text: "We Value Your",
                          size: metrics.titleSize,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                        SizedBox(height: metrics.titleLineGap),
                        AppText(
                          text: "Feedback!",
                          size: metrics.titleSize,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                        SizedBox(height: metrics.subtitleTopGap),
                        AppText(
                          text: "How would you rate your experience?",
                          size: metrics.subtitleSize,
                          fontWeight: FontWeight.w500,
                          color: appTextColor2,
                        ),
                        SizedBox(height: metrics.starsTopGap),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedRating = index + 1),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: metrics.starHorizontalPadding,
                                ),
                                child: Icon(
                                  Icons.star,
                                  size: metrics.starSize,
                                  color: index < _selectedRating
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: metrics.ratingLabelTopGap),
                        AppText(
                          text: _selectedRating == 0
                              ? "Tap to rate"
                              : [
                                  "",
                                  "Poor",
                                  "Fair",
                                  "Good",
                                  "Very Good",
                                  "Excellent!",
                                ][_selectedRating],
                          size: metrics.ratingLabelSize,
                          fontWeight: FontWeight.w400,
                          color: _selectedRating == 0
                              ? Colors.grey
                              : appTextColor3,
                        ),
                        SizedBox(height: metrics.commentTopGap),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: metrics.commentHorizontalPadding,
                            vertical: metrics.commentVerticalPadding,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(
                              metrics.commentRadius,
                            ),
                          ),
                          // Hint text is a plain String, so it needs
                          // TranslatedBuilder to go through the translator the
                          // way AppText does.
                          child: TranslatedBuilder(
                            text: 'How was your experience?',
                            builder: (context, hintText) => TextField(
                              controller: _commentController,
                              maxLines: metrics.commentMaxLines,
                              maxLength: 300,
                              decoration: InputDecoration(
                                hintText: hintText,
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: metrics.commentTextSize,
                                ),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              style: TextStyle(
                                color: appTextColor2,
                                fontSize: metrics.commentTextSize,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: metrics.submitTopGap),
                        SizedBox(
                          width: metrics.submitButtonWidth,
                          height: metrics.submitButtonHeight,
                          child: _isSubmitting
                              ? const Center(child: CircularProgressIndicator())
                              : AppButton(
                                  text: "Submit",
                                  onPressed: _submitReview,
                                  size: metrics.submitButtonTextSize,
                                  borderRadius: metrics.submitButtonRadius,
                                ),
                        ),
                        SizedBox(height: metrics.bottomGap),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Back button ──
            Positioned(
              top: metrics.backTop,
              left: metrics.backLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.asset(
                  backOrange,
                  width: metrics.backIconSize,
                  height: metrics.backIconSize,
                ),
              ),
            ),

            // ── Thank-you modal ──
            if (_isSubmitClicked) _confirmModal(metrics),
          ],
        ),
      ),
    );
  }

  Widget _confirmModal(_FeedbackMetrics metrics) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.modalOuterPadding,
            ),
            child: Container(
              width: metrics.modalWidth,
              padding: EdgeInsets.all(metrics.modalPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(metrics.modalRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _isSubmitClicked = false);
                      Navigator.pop(
                        context,
                        true,
                      ); // return success to RatingPage
                    },
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.close,
                        size: metrics.modalCloseIconSize,
                        color: appTextColor3,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/handshake.png',
                    height: metrics.modalImageSize,
                    width: metrics.modalImageSize,
                    fit: BoxFit.contain,
                  ),
                  AppText(
                    text: "Thank you for your",
                    size: metrics.modalTitleSize,
                    fontWeight: FontWeight.w600,
                    color: appLinkColor2,
                  ),
                  SizedBox(height: metrics.modalTitleGap),
                  AppText(
                    text: "feedback!",
                    size: metrics.modalTitleSize,
                    fontWeight: FontWeight.w700,
                    color: appLinkColor2,
                  ),
                  SizedBox(height: metrics.modalMessageTopGap),
                  AppText(
                    text: "We appreciate your input and",
                    size: metrics.modalMessageSize,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                  SizedBox(height: metrics.modalMessageLineGap),
                  AppText(
                    text: "will use it to improve.",
                    size: metrics.modalMessageSize,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                  SizedBox(height: metrics.modalBottomGap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackMetrics {
  const _FeedbackMetrics({
    required this.contentMaxWidth,
    required this.pageHorizontalPadding,
    required this.pageVerticalPadding,
    required this.topGap,
    required this.heroImageSize,
    required this.imageToTitleGap,
    required this.titleSize,
    required this.titleLineGap,
    required this.subtitleTopGap,
    required this.subtitleSize,
    required this.starsTopGap,
    required this.starHorizontalPadding,
    required this.starSize,
    required this.ratingLabelTopGap,
    required this.ratingLabelSize,
    required this.commentTopGap,
    required this.commentHorizontalPadding,
    required this.commentVerticalPadding,
    required this.commentRadius,
    required this.commentTextSize,
    required this.commentMaxLines,
    required this.submitTopGap,
    required this.submitButtonWidth,
    required this.submitButtonHeight,
    required this.submitButtonTextSize,
    required this.submitButtonRadius,
    required this.bottomGap,
    required this.backTop,
    required this.backLeft,
    required this.backIconSize,
    required this.modalOuterPadding,
    required this.modalWidth,
    required this.modalPadding,
    required this.modalRadius,
    required this.modalCloseIconSize,
    required this.modalImageSize,
    required this.modalTitleSize,
    required this.modalTitleGap,
    required this.modalMessageTopGap,
    required this.modalMessageSize,
    required this.modalMessageLineGap,
    required this.modalBottomGap,
  });

  final double contentMaxWidth;
  final double pageHorizontalPadding;
  final double pageVerticalPadding;
  final double topGap;
  final double heroImageSize;
  final double imageToTitleGap;
  final double titleSize;
  final double titleLineGap;
  final double subtitleTopGap;
  final double subtitleSize;
  final double starsTopGap;
  final double starHorizontalPadding;
  final double starSize;
  final double ratingLabelTopGap;
  final double ratingLabelSize;
  final double commentTopGap;
  final double commentHorizontalPadding;
  final double commentVerticalPadding;
  final double commentRadius;
  final double commentTextSize;
  final int commentMaxLines;
  final double submitTopGap;
  final double submitButtonWidth;
  final double submitButtonHeight;
  final double submitButtonTextSize;
  final double submitButtonRadius;
  final double bottomGap;
  final double backTop;
  final double backLeft;
  final double backIconSize;
  final double modalOuterPadding;
  final double modalWidth;
  final double modalPadding;
  final double modalRadius;
  final double modalCloseIconSize;
  final double modalImageSize;
  final double modalTitleSize;
  final double modalTitleGap;
  final double modalMessageTopGap;
  final double modalMessageSize;
  final double modalMessageLineGap;
  final double modalBottomGap;

  factory _FeedbackMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final contentWidth = (size.width * 0.64).clamp(520.0, 720.0).toDouble();
      final scale = (contentWidth / 620).clamp(1.0, 1.14).toDouble();
      double s(double value) => value * scale;

      return _FeedbackMetrics(
        contentMaxWidth: contentWidth,
        pageHorizontalPadding: s(46),
        pageVerticalPadding: s(28),
        topGap: s(24),
        heroImageSize: s(200),
        imageToTitleGap: s(18),
        titleSize: s(40),
        titleLineGap: s(3),
        subtitleTopGap: s(24),
        subtitleSize: s(19),
        starsTopGap: s(22),
        starHorizontalPadding: s(6),
        starSize: s(50),
        ratingLabelTopGap: s(10),
        ratingLabelSize: s(16),
        commentTopGap: s(34),
        commentHorizontalPadding: s(20),
        commentVerticalPadding: s(18),
        commentRadius: s(18),
        commentTextSize: s(16),
        commentMaxLines: 6,
        submitTopGap: s(38),
        submitButtonWidth: s(150),
        submitButtonHeight: s(48),
        submitButtonTextSize: s(16),
        submitButtonRadius: s(14),
        bottomGap: s(30),
        backTop: 36,
        backLeft: size.width * 0.08,
        backIconSize: 34,
        modalOuterPadding: s(42),
        modalWidth: s(430),
        modalPadding: s(28),
        modalRadius: s(24),
        modalCloseIconSize: s(26),
        modalImageSize: s(92),
        modalTitleSize: s(26),
        modalTitleGap: s(5),
        modalMessageTopGap: s(16),
        modalMessageSize: s(18),
        modalMessageLineGap: s(3),
        modalBottomGap: s(12),
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _FeedbackMetrics(
        contentMaxWidth: double.infinity,
        pageHorizontalPadding: s(22),
        pageVerticalPadding: s(14),
        topGap: s(12),
        heroImageSize: s(118),
        imageToTitleGap: s(10),
        titleSize: s(24),
        titleLineGap: s(1),
        subtitleTopGap: s(14),
        subtitleSize: s(13),
        starsTopGap: s(14),
        starHorizontalPadding: s(3),
        starSize: s(32),
        ratingLabelTopGap: s(6),
        ratingLabelSize: s(12),
        commentTopGap: s(20),
        commentHorizontalPadding: s(13),
        commentVerticalPadding: s(11),
        commentRadius: s(13),
        commentTextSize: s(12),
        commentMaxLines: 4,
        submitTopGap: s(24),
        submitButtonWidth: s(108),
        submitButtonHeight: s(34),
        submitButtonTextSize: s(12),
        submitButtonRadius: s(10),
        bottomGap: s(18),
        backTop: 22,
        backLeft: size.width * 0.06,
        backIconSize: 26,
        modalOuterPadding: s(26),
        modalWidth: double.infinity,
        modalPadding: s(16),
        modalRadius: s(18),
        modalCloseIconSize: s(20),
        modalImageSize: s(62),
        modalTitleSize: s(18),
        modalTitleGap: s(3),
        modalMessageTopGap: s(9),
        modalMessageSize: s(13),
        modalMessageLineGap: s(2),
        modalBottomGap: s(8),
      );
    }

    return _FeedbackMetrics(
      contentMaxWidth: double.infinity,
      pageHorizontalPadding: 28.w,
      pageVerticalPadding: 20.h,
      topGap: 20.h,
      heroImageSize: 150.h,
      imageToTitleGap: 14.h,
      titleSize: 30,
      titleLineGap: 2.h,
      subtitleTopGap: 18.h,
      subtitleSize: 15,
      starsTopGap: 18.h,
      starHorizontalPadding: 4.w,
      starSize: 38.r,
      ratingLabelTopGap: 8.h,
      ratingLabelSize: 13,
      commentTopGap: 26.h,
      commentHorizontalPadding: 16.w,
      commentVerticalPadding: 14.h,
      commentRadius: 16.r,
      commentTextSize: 13.sp,
      commentMaxLines: 5,
      submitTopGap: 34.h,
      submitButtonWidth: 120.w,
      submitButtonHeight: 38.h,
      submitButtonTextSize: 13,
      submitButtonRadius: 12.r,
      bottomGap: 24.h,
      backTop: 40,
      backLeft: size.width * 0.075,
      backIconSize: 30,
      modalOuterPadding: 34.w,
      modalWidth: double.infinity,
      modalPadding: 20.h,
      modalRadius: 22.r,
      modalCloseIconSize: 22.r,
      modalImageSize: 72.h,
      modalTitleSize: 21,
      modalTitleGap: 4.h,
      modalMessageTopGap: 12.h,
      modalMessageSize: 15,
      modalMessageLineGap: 2.h,
      modalBottomGap: 10.h,
    );
  }
}
