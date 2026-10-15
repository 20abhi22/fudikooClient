import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
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

  Widget _buildOverallStars(double rating, double starSize) {
    final filledStars = rating.floor().clamp(0, 5);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => Icon(
          index < filledStars ? Icons.star : Icons.star_border,
          color: const Color(0xFFF0D128),
          size: starSize,
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
    final metrics = _RatingPageMetrics.fromContext(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            metrics.pageHorizontalPadding,
            metrics.pageTopPadding,
            metrics.pageHorizontalPadding,
            0,
          ),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: metrics.contentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: metrics.titleLeftPadding),
                      child: AppText(
                        text: widget.restaurantName ?? "Restaurant",
                        size: metrics.restaurantNameSize,
                        fontWeight: FontWeight.w600,
                        color: appTextColor6,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: metrics.titleLeftPadding),
                      child: AppText(
                        text: "Restaurant",
                        size: metrics.restaurantTypeSize,
                        fontWeight: FontWeight.w500,
                        color: appTextColor6,
                      ),
                    ),
                    if (widget.restaurantAddress?.isNotEmpty == true)
                      Padding(
                        padding: EdgeInsets.only(
                          left: metrics.titleLeftPadding,
                          top: metrics.addressTopGap,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: appTextColor6,
                              size: metrics.addressIconSize,
                            ),
                            SizedBox(width: metrics.addressIconGap),
                            Expanded(
                              child: AppText(
                                text: widget.restaurantAddress!,
                                size: metrics.addressTextSize,
                                fontWeight: FontWeight.w400,
                                color: appTextColor6,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: metrics.headerToOverallGap),

                    Center(
                      child: Column(
                        children: [
                          AppText(
                            text: "Overall Rating",
                            size: metrics.overallTitleSize,
                            fontWeight: FontWeight.w500,
                            color: appTextColor2,
                          ),
                          SizedBox(height: metrics.ratingNumberTopGap),
                          AppText(
                            text: ratingText,
                            size: metrics.ratingNumberSize,
                            fontWeight: FontWeight.w600,
                            color: appTextColor2,
                          ),
                          _buildOverallStars(_averageRating, metrics.starSize),
                          SizedBox(height: metrics.reviewCountTopGap),
                          AppText(
                            text: "Based on $totalReviews reviews",
                            size: metrics.reviewCountSize,
                            fontWeight: FontWeight.w400,
                            color: appTextColor5,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: metrics.overallToButtonGap),

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
                            horizontal: metrics.buttonHorizontalPadding,
                            vertical: metrics.buttonVerticalPadding,
                          ),
                          decoration: BoxDecoration(
                            color: appButtonColor,
                            borderRadius: BorderRadius.circular(
                              metrics.buttonRadius,
                            ),
                          ),
                          child: AppText(
                            text: 'Add Review',
                            color: Colors.white,
                            size: metrics.buttonTextSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: metrics.buttonToListGap),

                    if (_isLoadingReviews)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: metrics.emptyStateVerticalPadding,
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    else if (_reviewsError.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: metrics.emptyStateVerticalPadding,
                        ),
                        child: AppText(
                          text: _reviewsError,
                          size: metrics.emptyStateTextSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.red,
                          isCentered: true,
                        ),
                      )
                    else if (_reviews.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: metrics.emptyStateVerticalPadding,
                        ),
                        child: AppText(
                          text: 'No reviews yet',
                          size: metrics.emptyStateTextSize,
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
                        padding: EdgeInsets.only(
                          bottom: metrics.listBottomPadding,
                        ),
                        itemBuilder: (context, index) =>
                            RatingCard(review: _reviews[index]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingPageMetrics {
  const _RatingPageMetrics({
    required this.contentMaxWidth,
    required this.pageHorizontalPadding,
    required this.pageTopPadding,
    required this.titleLeftPadding,
    required this.restaurantNameSize,
    required this.restaurantTypeSize,
    required this.addressTopGap,
    required this.addressIconSize,
    required this.addressIconGap,
    required this.addressTextSize,
    required this.headerToOverallGap,
    required this.overallTitleSize,
    required this.ratingNumberTopGap,
    required this.ratingNumberSize,
    required this.starSize,
    required this.reviewCountTopGap,
    required this.reviewCountSize,
    required this.overallToButtonGap,
    required this.buttonHorizontalPadding,
    required this.buttonVerticalPadding,
    required this.buttonRadius,
    required this.buttonTextSize,
    required this.buttonToListGap,
    required this.emptyStateVerticalPadding,
    required this.emptyStateTextSize,
    required this.listBottomPadding,
  });

  final double contentMaxWidth;
  final double pageHorizontalPadding;
  final double pageTopPadding;
  final double titleLeftPadding;
  final double restaurantNameSize;
  final double restaurantTypeSize;
  final double addressTopGap;
  final double addressIconSize;
  final double addressIconGap;
  final double addressTextSize;
  final double headerToOverallGap;
  final double overallTitleSize;
  final double ratingNumberTopGap;
  final double ratingNumberSize;
  final double starSize;
  final double reviewCountTopGap;
  final double reviewCountSize;
  final double overallToButtonGap;
  final double buttonHorizontalPadding;
  final double buttonVerticalPadding;
  final double buttonRadius;
  final double buttonTextSize;
  final double buttonToListGap;
  final double emptyStateVerticalPadding;
  final double emptyStateTextSize;
  final double listBottomPadding;

  factory _RatingPageMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final contentWidth = (size.width * 0.78).clamp(620.0, 860.0).toDouble();
      final scale = (contentWidth / 760).clamp(1.0, 1.12).toDouble();
      double s(double value) => value * scale;

      return _RatingPageMetrics(
        contentMaxWidth: contentWidth,
        pageHorizontalPadding: s(44),
        pageTopPadding: s(58),
        titleLeftPadding: s(8),
        restaurantNameSize: s(46),
        restaurantTypeSize: s(30),
        addressTopGap: s(4),
        addressIconSize: s(20),
        addressIconGap: s(5),
        addressTextSize: s(16),
        headerToOverallGap: s(58),
        overallTitleSize: s(21),
        ratingNumberTopGap: s(6),
        ratingNumberSize: s(62),
        starSize: s(54),
        reviewCountTopGap: s(10),
        reviewCountSize: s(18),
        overallToButtonGap: s(58),
        buttonHorizontalPadding: s(18),
        buttonVerticalPadding: s(10),
        buttonRadius: s(12),
        buttonTextSize: s(15),
        buttonToListGap: s(18),
        emptyStateVerticalPadding: s(26),
        emptyStateTextSize: s(16),
        listBottomPadding: s(36),
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _RatingPageMetrics(
        contentMaxWidth: double.infinity,
        pageHorizontalPadding: s(20),
        pageTopPadding: s(32),
        titleLeftPadding: s(6),
        restaurantNameSize: s(28),
        restaurantTypeSize: s(19),
        addressTopGap: s(2),
        addressIconSize: s(15),
        addressIconGap: s(3),
        addressTextSize: s(11.5),
        headerToOverallGap: s(36),
        overallTitleSize: s(15),
        ratingNumberTopGap: s(3),
        ratingNumberSize: s(40),
        starSize: s(36),
        reviewCountTopGap: s(6),
        reviewCountSize: s(13),
        overallToButtonGap: s(38),
        buttonHorizontalPadding: s(10),
        buttonVerticalPadding: s(6),
        buttonRadius: s(9),
        buttonTextSize: s(11),
        buttonToListGap: s(10),
        emptyStateVerticalPadding: s(16),
        emptyStateTextSize: s(13),
        listBottomPadding: s(24),
      );
    }

    return _RatingPageMetrics(
      contentMaxWidth: double.infinity,
      pageHorizontalPadding: 28.w,
      pageTopPadding: 42.h,
      titleLeftPadding: 8,
      restaurantNameSize: 36,
      restaurantTypeSize: 24,
      addressTopGap: 0,
      addressIconSize: 17.sp,
      addressIconGap: 3.w,
      addressTextSize: 13,
      headerToOverallGap: 50.h,
      overallTitleSize: 17,
      ratingNumberTopGap: 4.h,
      ratingNumberSize: 48,
      starSize: 45.sp,
      reviewCountTopGap: 8.h,
      reviewCountSize: 15,
      overallToButtonGap: 52.h,
      buttonHorizontalPadding: 12.w,
      buttonVerticalPadding: 7.h,
      buttonRadius: 10.r,
      buttonTextSize: 12,
      buttonToListGap: 12.h,
      emptyStateVerticalPadding: 20.h,
      emptyStateTextSize: 14,
      listBottomPadding: 30.h,
    );
  }
}
