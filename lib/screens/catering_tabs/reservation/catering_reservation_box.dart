import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/banquet/banquet_reservation_modal.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/tabs/reservation/qrcoupon.dart';
import 'package:fudikoclient/service/reservation/offer_code_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class CateringReservationBox extends StatelessWidget {
  final BanquetReservationModal reservation;
  final VoidCallback? onCancelTap;
  final VoidCallback? onRequestTap;

  const CateringReservationBox({
    super.key,
    required this.reservation,
    this.onCancelTap,
    this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = reservation.status == "Confirmed";
    final isCancelled =
        reservation.status == "Cancelled" || reservation.status == "Canceled";
    final statusColor = isConfirmed
        ? const Color(0xFF32BA7C)
        : isCancelled
        ? const Color(0xFFFB5858)
        : const Color(0xFF3954DB);
    final eventDate = DateFormat("MMM d").format(reservation.eventDate);
    final eventTime = DateFormat("h:mm a").format(reservation.eventDate);
    final bookingDate = DateFormat("MMM d").format(reservation.bookingDate);
    final bookingTime = DateFormat("h:mm a").format(reservation.bookingDate);

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    text: reservation.couponId,
                    size: 21.sp,
                    fontWeight: FontWeight.w700,
                    color: appTextColor3,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: bookingDate,
                        size: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 2.h),
                      AppText(
                        text: bookingTime,
                        size: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _iconRow(shopIcon, reservation.restaurantName),
              SizedBox(height: 10.h),
              _iconRowWithEmphasis(
                walletIcon,
                reservation.pricePerPerson.toString(),
                ' Per Person',
              ),
              SizedBox(height: 10.h),
              _iconRowWithEmphasis(
                offerIcon,
                reservation.discount.toStringAsFixed(0),
                '% offer',
              ),
              SizedBox(height: 10.h),
              _iconRowWithEmphasis(calenderIcon, eventDate, ' - $eventTime'),
              SizedBox(height: 10.h),
              _iconRow(peopleIcon, '${reservation.persons} Person'),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Image.asset(statusIcon, width: 18.w, height: 18.h),
                  SizedBox(width: 8.w),
                  AppText(
                    text: reservation.status,
                    size: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ],
              ),
              if (reservation.message.isNotEmpty) ...[
                SizedBox(height: 10.h),
                _iconRow(commentIcon, reservation.message),
              ],
              SizedBox(height: 16.h),
              if (!isCancelled)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onCancelTap,
                      child: AppText(
                        text: "Cancel",
                        size: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFCE3F3F),
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
                                newPage: QrCoupon(
                                  booking: reservation.toBookingModel(),
                                  reservationType:
                                      OfferCodeReservationType.cateringEnquiry,
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
          ),
        ),
      ),
    );
  }

  Widget _iconRow(String imageIconPath, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIconPath,
          width: 18.w,
          height: 18.h,
          color: const Color(0xFF000000).withValues(alpha: .9),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: AppText(
            text: text,
            size: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _iconRowWithEmphasis(
    String imageIconPath,
    String boldText,
    String regularText,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIconPath,
          width: 18.w,
          height: 18.h,
          color: const Color(0xFF000000).withValues(alpha: .9),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppText(
                text: boldText,
                size: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              AppText(
                text: regularText,
                size: 14.sp,
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
