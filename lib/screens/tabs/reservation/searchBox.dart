import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/tabs/reservation/qrcoupon.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class SearchBox extends StatelessWidget {
  final VoidCallback? onCancelTap;
  final VoidCallback? onRequestTap;
  final BookingModel booking;

  const SearchBox({
    super.key,
    this.onCancelTap,
    this.onRequestTap,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = _SearchBoxMetrics.fromContext(context);
    final bool isConfirmed = booking.status == "Confirmed";
    final bool isCancelled =
        booking.status == "Cancelled" || booking.status == "Canceled";

    final Color statusColor = booking.status == "Confirmed"
        ? const Color(0xFF32BA7C).withValues(alpha: .9)
        : booking.status == "Processing"
        ? const Color(0xFF3954DB).withValues(alpha: .9)
        : booking.status == "Completed"
        ? const Color.fromARGB(255, 1, 128, 5).withValues(alpha: .9)
        : const Color(0xFFFB5858).withValues(alpha: .9);

    final String eventDateStr = DateFormat("MMM d").format(booking.eventDate);

    final String eventTimeStr = DateFormat("h:mm a").format(booking.eventDate);

    final String bookingDateStr = DateFormat(
      "MMM d",
    ).format(booking.bookingDate);

    final String bookingTimeStr = DateFormat(
      "h:mm a",
    ).format(booking.bookingDate);

    return Padding(
      padding: EdgeInsets.only(bottom: metrics.bottomMargin),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(metrics.radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: metrics.shadowBlur,
              offset: Offset(0, metrics.shadowOffset),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(metrics.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    text: booking.couponId,
                    size: metrics.couponTextSize,
                    fontWeight: FontWeight.w700,
                    color: appTextColor3,
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: bookingDateStr,
                        size: metrics.dateTextSize,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),

                      SizedBox(height: metrics.smallGap),

                      AppText(
                        text: bookingTimeStr,
                        size: metrics.dateTextSize,
                        fontWeight: FontWeight.w400,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: metrics.headerGap),

              // ── Restaurant name ───────────────────────
              _iconRow(
                shopIcon,
                booking.restaurantName,
                Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: metrics.bodyTextSize,
                iconSize: metrics.iconSize,
                iconGap: metrics.iconGap,
              ),

              SizedBox(height: metrics.rowGap),

              // ── Discount info ─────────────────────────
              _iconRowWithEmphasis(
                offerIcon,
                booking.discount.toStringAsFixed(0),
                '% offer for ${booking.applicableFor ?? 'entire menu'}',
                fontSize: metrics.bodyTextSize,
                iconSize: metrics.iconSize,
                iconGap: metrics.iconGap,
              ),

              SizedBox(height: metrics.rowGap),

              // ── Event date/time ───────────────────────
              _iconRowWithEmphasis(
                calenderIcon,
                eventDateStr,
                ' - $eventTimeStr',
                fontSize: metrics.bodyTextSize,
                iconSize: metrics.iconSize,
                iconGap: metrics.iconGap,
              ),

              SizedBox(height: metrics.rowGap),

              // ── Persons ───────────────────────────────
              _iconRow(
                peopleIcon,
                '${booking.persons} Person',
                Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: metrics.bodyTextSize,
                iconSize: metrics.iconSize,
                iconGap: metrics.iconGap,
              ),

              SizedBox(height: metrics.statusTopGap),

              // ── Status ────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    statusIcon,
                    width: metrics.iconSize,
                    height: metrics.iconSize,
                    fit: BoxFit.fill,
                  ),

                  SizedBox(width: metrics.iconGap),

                  AppText(
                    text: booking.status,
                    size: metrics.statusTextSize,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ],
              ),

              SizedBox(height: metrics.actionTopGap),

              if (!isCancelled && booking.status != "Completed") ...[
                // ── Action buttons ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onCancelTap,
                      child: AppText(
                        text: "Cancel",
                        size: metrics.cancelTextSize,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFCE3F3F).withValues(alpha: .9),
                      ),
                    ),

                    SizedBox(width: metrics.actionGap),

                    if (booking.status == "Completed") ...[
                      SizedBox(height: metrics.actionTopGap),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: metrics.couponButtonWidth,
                            height: metrics.couponButtonHeight,
                            child: AppButton(
                              bgColor1: const Color(0xFFFE943A),
                              bgColor2: const Color(0xFFFE943A),
                              imageIconPath: couponIcon,
                              iconSize: metrics.couponButtonIconSize,
                              text: "Coupon",
                              size: metrics.couponButtonTextSize,
                              borderRadius: metrics.couponButtonRadius,
                              onPressed: () {
                                final offerText =
                                    '${booking.discount.toStringAsFixed(0)}% offer for ${booking.applicableFor ?? 'entire menu'}';
                                slideRightWidget(
                                  newPage: QrCoupon(
                                    booking: booking,
                                    offerText: offerText,
                                  ),
                                  context: context,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(
                      width: metrics.couponButtonWidth,
                      height: metrics.couponButtonHeight,
                      child: Opacity(
                        opacity: isConfirmed ? 1 : 0.45,
                        child: IgnorePointer(
                          ignoring: !isConfirmed,
                          child: AppButton(
                            bgColor1: const Color(0xFFFE943A),
                            bgColor2: const Color(0xFFFE943A),
                            imageIconPath: couponIcon,
                            iconSize: metrics.couponButtonIconSize,
                            text: "Coupon",
                            size: metrics.couponButtonTextSize,
                            borderRadius: metrics.couponButtonRadius,
                            onPressed: () {
                              final offerText =
                                  '${booking.discount.toStringAsFixed(0)}% offer for ${booking.applicableFor ?? 'entire menu'}';
                              slideRightWidget(
                                newPage: QrCoupon(
                                  booking: booking,
                                  offerText: offerText,
                                ),
                                context: context,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Icon row helper ───────────────────────────────────────

  Widget _iconRow(
    String imageIconPath,
    String text,
    Color textColor, {
    FontWeight fontWeight = FontWeight.w500,
    double fontSize = 14,
    double iconSize = 18,
    double iconGap = 8,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIconPath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          color: const Color(0xFF000000).withValues(alpha: .9),
        ),

        SizedBox(width: iconGap),

        Flexible(
          child: AppText(
            text: text,
            size: fontSize,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ── Mixed bold + regular row helper ──────────────────────

  Widget _iconRowWithEmphasis(
    String imageIconPath,
    String boldText,
    String regularText, {
    double fontSize = 15,
    double iconSize = 18,
    double iconGap = 8,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIconPath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          color: const Color(0xFF000000).withValues(alpha: .9),
        ),

        SizedBox(width: iconGap),

        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppText(
                text: boldText,
                size: fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),

              AppText(
                text: regularText,
                size: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchBoxMetrics {
  const _SearchBoxMetrics({
    required this.isTablet,
    required this.bottomMargin,
    required this.radius,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.padding,
    required this.couponTextSize,
    required this.dateTextSize,
    required this.smallGap,
    required this.headerGap,
    required this.rowGap,
    required this.statusTopGap,
    required this.actionTopGap,
    required this.iconSize,
    required this.iconGap,
    required this.bodyTextSize,
    required this.statusTextSize,
    required this.cancelTextSize,
    required this.actionGap,
    required this.couponButtonWidth,
    required this.couponButtonHeight,
    required this.couponButtonIconSize,
    required this.couponButtonTextSize,
    required this.couponButtonRadius,
  });

  final bool isTablet;
  final double bottomMargin;
  final double radius;
  final double shadowBlur;
  final double shadowOffset;
  final double padding;
  final double couponTextSize;
  final double dateTextSize;
  final double smallGap;
  final double headerGap;
  final double rowGap;
  final double statusTopGap;
  final double actionTopGap;
  final double iconSize;
  final double iconGap;
  final double bodyTextSize;
  final double statusTextSize;
  final double cancelTextSize;
  final double actionGap;
  final double couponButtonWidth;
  final double couponButtonHeight;
  final double couponButtonIconSize;
  final double couponButtonTextSize;
  final double couponButtonRadius;

  factory _SearchBoxMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      return const _SearchBoxMetrics(
        isTablet: true,
        bottomMargin: 20,
        radius: 8,
        shadowBlur: 16,
        shadowOffset: 4,
        padding: 22,
        couponTextSize: 19,
        dateTextSize: 12,
        smallGap: 3,
        headerGap: 16,
        rowGap: 11,
        statusTopGap: 14,
        actionTopGap: 30,
        iconSize: 18,
        iconGap: 8,
        bodyTextSize: 14.5,
        statusTextSize: 12,
        cancelTextSize: 14,
        actionGap: 14,
        couponButtonWidth: 178,
        couponButtonHeight: 40,
        couponButtonIconSize: 26,
        couponButtonTextSize: 13,
        couponButtonRadius: 7,
      );
    }

    if (isWideShortPhone) {
      return const _SearchBoxMetrics(
        isTablet: false,
        bottomMargin: 16,
        radius: 16,
        shadowBlur: 7,
        shadowOffset: 2,
        padding: 14,
        couponTextSize: 18,
        dateTextSize: 10,
        smallGap: 2,
        headerGap: 11,
        rowGap: 8,
        statusTopGap: 10,
        actionTopGap: 12,
        iconSize: 16,
        iconGap: 7,
        bodyTextSize: 12.5,
        statusTextSize: 13,
        cancelTextSize: 12.5,
        actionGap: 10,
        couponButtonWidth: 132,
        couponButtonHeight: 36,
        couponButtonIconSize: 24,
        couponButtonTextSize: 13,
        couponButtonRadius: 8,
      );
    }

    if (isCompactPhone) {
      return const _SearchBoxMetrics(
        isTablet: false,
        bottomMargin: 14,
        radius: 16,
        shadowBlur: 7,
        shadowOffset: 2,
        padding: 12,
        couponTextSize: 17,
        dateTextSize: 9.5,
        smallGap: 2,
        headerGap: 10,
        rowGap: 8,
        statusTopGap: 10,
        actionTopGap: 12,
        iconSize: 15,
        iconGap: 6,
        bodyTextSize: 12,
        statusTextSize: 13,
        cancelTextSize: 12,
        actionGap: 8,
        couponButtonWidth: 104,
        couponButtonHeight: 36,
        couponButtonIconSize: 28,
        couponButtonTextSize: 15,
        couponButtonRadius: 8,
      );
    }

    return _SearchBoxMetrics(
      isTablet: false,
      bottomMargin: 20.h,
      radius: 20.r,
      shadowBlur: 8.r,
      shadowOffset: 2.r,
      padding: 16.w,
      couponTextSize: 21.sp,
      dateTextSize: 11.sp,
      smallGap: 2.h,
      headerGap: 14.h,
      rowGap: 10.h,
      statusTopGap: 12.h,
      actionTopGap: 16.h,
      iconSize: 18,
      iconGap: 8.w,
      bodyTextSize: 14.sp,
      statusTextSize: 15.sp,
      cancelTextSize: 14.sp,
      actionGap: 10.w,
      couponButtonWidth: 121.w,
      couponButtonHeight: 42.h,
      couponButtonIconSize: 32,
      couponButtonTextSize: 18,
      couponButtonRadius: 10.r,
    );
  }
}
