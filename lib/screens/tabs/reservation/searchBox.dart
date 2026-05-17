import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
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
    final bool isConfirmed = booking.status == "Confirmed";

    final Color statusColor = booking.status == "Confirmed"
        ? const Color(0xFF32BA7C).withOpacity(.9)
        : booking.status == "Processing"
            ? const Color(0xFF3954DB).withOpacity(.9)
            : booking.status == "Completed"
                ? const Color.fromARGB(255, 1, 128, 5).withOpacity(.9)
                : const Color(0xFFFB5858).withOpacity(.9);

    final String eventDateStr =
        DateFormat("MMM d").format(booking.eventDate);

    final String eventTimeStr =
        DateFormat("h:mm a").format(booking.eventDate);

    final String bookingDateStr =
        DateFormat("MMM d").format(booking.bookingDate);

    final String bookingTimeStr =
        DateFormat("h:mm a").format(booking.bookingDate);

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.r),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    text: booking.couponId,
                    size: 21.sp,
                    fontWeight: FontWeight.w700,
                    color: appTextColor3,
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: bookingDateStr,
                        size: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),

                      SizedBox(height: 2.h),

                      AppText(
                        text: bookingTimeStr,
                        size: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 14.h),

              // ── Restaurant name ───────────────────────
              _iconRow(
                shopIcon,
                booking.restaurantName,
                Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),

              SizedBox(height: 10.h),

              // ── Discount info ─────────────────────────
              _iconRowWithEmphasis(
                offerIcon,
                booking.discount.toStringAsFixed(0),
                '% offer for ${booking.applicableFor ?? 'entire menu'}',
                fontSize: 14.sp,
              ),

              SizedBox(height: 10.h),

              // ── Event date/time ───────────────────────
              _iconRowWithEmphasis(
                calenderIcon,
                eventDateStr,
                ' - $eventTimeStr',
                fontSize: 14.sp,
              ),

              SizedBox(height: 10.h),

              // ── Persons ───────────────────────────────
              _iconRow(
                peopleIcon,
                '${booking.persons} Person',
                Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),

              SizedBox(height: 12.h),

              // ── Status ────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    statusIcon,
                    width: 18,
                    height: 18,
                    fit: BoxFit.fill,
                  ),

                  SizedBox(width: 5.w),

                  AppText(
                    text: booking.status,
                    size: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // ── Action buttons ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onCancelTap,
                    child: AppText(
                      text: "Cancel",
                      size: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFCE3F3F).withOpacity(.9),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  SizedBox(
                    width: 121.w,
                    height: 42.h,
                    child: Opacity(
                      opacity: isConfirmed ? 1 : 0.45,
                      child: IgnorePointer(
                        ignoring: !isConfirmed,
                        child: AppButton(
                          bgColor1: const Color(0xFFFE943A),
                          bgColor2: const Color(0xFFFE943A),
                          imageIconPath: couponIcon,
                          iconSize: 32,
                          text: "Coupon",
                          size: 18,
                          borderRadius: 10.r,
                          onPressed: () {
                            slideRightWidget(
                              newPage: QrCoupon(booking: booking),
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIconPath,
          width: 18,
          height: 18,
          fit: BoxFit.cover,
          color: const Color(0xFF000000).withOpacity(.9),
        ),

        SizedBox(width: 8.w),

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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIconPath,
          width: 18,
          height: 18,
          fit: BoxFit.cover,
          color: const Color(0xFF000000).withOpacity(.9),
        ),

        SizedBox(width: 8.w),

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