import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/restaurant/review_model.dart';
import 'package:fudikoclient/utils/constants.dart';

class RatingCard extends StatelessWidget {
  final RestaurantReviewModel? review;

  const RatingCard({super.key, this.review});

  String get _reviewerName =>
      review?.user.isNotEmpty == true ? review!.user : 'Alexander Thompson';

  String get _reviewText => review?.review.isNotEmpty == true
      ? review!.review
      : 'Outstanding experience! The food was excellent and the staff went above and beyond to assist. Will definitely order again.';

  String get _postedDate {
    final rawDate = review?.postedDate.trim();
    if (rawDate == null || rawDate.isEmpty) return '3 minutes ago';
    return _formatRelativeDate(rawDate);
  }

  String _formatRelativeDate(String rawDate) {
    if (rawDate.toLowerCase().contains('ago')) return rawDate;

    DateTime? postedAt = DateTime.tryParse(rawDate);
    postedAt ??= DateTime.tryParse(rawDate.replaceFirst(' ', 'T'));
    postedAt ??= _parseDayFirstDate(rawDate);

    final timestamp = int.tryParse(rawDate);
    if (postedAt == null && timestamp != null) {
      postedAt = DateTime.fromMillisecondsSinceEpoch(
        rawDate.length <= 10 ? timestamp * 1000 : timestamp,
      );
    }

    if (postedAt == null) return rawDate;

    final difference = DateTime.now().difference(postedAt);
    if (difference.isNegative) return 'just now';

    final minutes = difference.inMinutes;
    if (minutes < 1) return 'just now';
    if (minutes < 60) {
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    final hours = difference.inHours;
    if (hours < 24) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }

    final days = difference.inDays;
    if (days < 7) {
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }

    if (days < 30) {
      return '${(days / 7).floor()}w ago';
    }

    if (days < 365) {
      return '${(days / 30).floor()}m ago';
    }

    return '${(days / 365).floor()}y ago';
  }

  DateTime? _parseDayFirstDate(String rawDate) {
    final match = RegExp(
      r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})(?:\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?$',
    ).firstMatch(rawDate);

    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    final hour = int.tryParse(match.group(4) ?? '0') ?? 0;
    final minute = int.tryParse(match.group(5) ?? '0') ?? 0;
    final second = int.tryParse(match.group(6) ?? '0') ?? 0;

    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    return DateTime(year, month, day, hour, minute, second);
  }

  Widget _buildAvatar() {
    final String? profilePicture = review?.profilePicture;
    if (profilePicture != null && profilePicture.isNotEmpty) {
      if (profilePicture.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: Image.network(
            profilePicture,
            width: 44.w,
            height: 44.w,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultAvatar(),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: Image.asset(
          profilePicture,
          width: 44.w,
          height: 44.w,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        ),
      );
    }

    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return SizedBox(
      width: 44.w,
      height: 44.w,
      child: Icon(Icons.person, color: Colors.grey.shade500, size: 38.sp),
    );
  }

  Widget _buildStars() {
    final stars = (review?.stars ?? 4).clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: const Color(0xFFF0D128),
          size: 19.sp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4).withOpacity(.52),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44.w,
              height: 44.w,
              child: Center(child: _buildAvatar()),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppText(
                          text: _reviewerName,
                          size: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF000000),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      AppText(
                        text: _postedDate,
                        size: 12,
                        fontWeight: FontWeight.w400,
                        color: appTextColor5,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  _buildStars(),
                  SizedBox(height: 10.h),
                  AppText(
                    text: _reviewText,
                    size: 13,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                    lineSpacing: 1.35,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
