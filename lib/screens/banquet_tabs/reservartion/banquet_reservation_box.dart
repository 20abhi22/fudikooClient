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

class BanquetReservationBox extends StatelessWidget {
  final BanquetReservationModal reservation;
  final VoidCallback? onCancelTap;
  final VoidCallback? onRequestTap;

  const BanquetReservationBox({
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
    final isCompleted = reservation.status == "Completed";
    final statusColor = isConfirmed
        ? const Color(0xFF32BA7C).withOpacity(.9)
        : isCancelled
        ? const Color(0xFFFB5858).withOpacity(.9)
        : const Color(0xFF3954DB).withOpacity(.9);
    final eventDate = DateFormat("MMM d").format(reservation.eventDate);
    final eventTime = DateFormat("h:mm a").format(reservation.eventDate);
    final bookingDate = DateFormat("MMM d").format(reservation.bookingDate);
    final bookingTime = DateFormat("h:mm a").format(reservation.bookingDate);
    final applicableFor = reservation.applicableFor?.trim();
    final offerSuffix = applicableFor == null || applicableFor.isEmpty
        ? ''
        : '% $applicableFor';

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10), // #000000 10%
              offset: const Offset(0, 0), // X: 0, Y: 0
              blurRadius: 10, // Blur: 10
              spreadRadius: 2, // Spread: 2
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    text: reservation.couponId,
                    size: 20,
                    fontWeight: FontWeight.w700,
                    color: appTextColor6,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: bookingDate,
                        size: 10,
                        fontWeight: FontWeight.w600,
                        color: appTextColor6,
                      ),
                      AppText(
                        text: bookingTime.toLowerCase(),
                        size: 10,
                        fontWeight: FontWeight.w400,
                        color: appTextColor6,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              _iconRow(
                shopIcon,
                reservation.restaurantName,
                const Color(0xff485599).withOpacity(.9),
                FontWeight.w600,
                textsize: 16,
              ),
              SizedBox(height: 8.h),
              _iconRowWithEmphasis(
                walletIcon,
                reservation.pricePerPerson.toString(),
                ' Per Person',
              ),
              SizedBox(height: 8.h),
              _iconRowWithEmphasis(
                offerIcon,
                reservation.discount.toStringAsFixed(0),
                offerSuffix,
              ),
              if (reservation.message.isNotEmpty) ...[
                SizedBox(height: 8.h),
                _iconRow(
                  commentIcon,
                  reservation.message,
                  appTextColor5,
                  FontWeight.w400,
                  maxLines: null,
                ),
              ],
              SizedBox(height: 8.h),
              _iconRowWithEmphasis(calenderIcon, eventDate, ' - $eventTime'),
              SizedBox(height: 8.h),
              _iconRow(
                peopleIcon,
                '${reservation.persons} Person',
                appTextColor5,
                FontWeight.w400,
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Image.asset(statusIcon, width: 18.w, height: 18.h),
                  SizedBox(width: 8.w),
                  AppText(
                    text: reservation.status,
                    size: 15,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              if (!isCancelled)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: onRequestTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon(
                              //   Icons.open_in_new,
                              //   size: 8.sp,
                              //   color: const Color(0xFF3954DB),
                              // ),
                              Image.asset(
                                detailsIcon,
                                width: 11.w,
                                height: 11.h,
                                color: const Color(0xFF3954DB),
                              ),
                              SizedBox(width: 2.w),
                              AppText(
                                text: "View request",
                                size: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3954DB),
                              ),
                            ],
                          ),
                        ),
                        if (!isCompleted) ...[
                          SizedBox(height: 3.h),
                          GestureDetector(
                            onTap: onCancelTap,
                            child: AppText(
                              text: "Cancel",
                              size: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFCE3F3F).withOpacity(.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      // width: 88.w,
                      // height: 32.h,
                      child: Opacity(
                        opacity: isConfirmed ? 1 : 0.45,
                        child: IgnorePointer(
                          ignoring: !isConfirmed,
                          child: AppButton(
                            buttonheight: 45.h,
                            bgColor1: const Color(0xFFFE943A),
                            bgColor2: const Color(0xFFFE943A),
                            imageIconPath: couponIcon,
                            iconSize: 35,
                            text: " Coupon",
                            size: 18,
                            borderRadius: 12.r,
                            onPressed: () {
                              slideRightWidget(
                                newPage: QrCoupon(
                                  booking: reservation.toBookingModel(),
                                  reservationType:
                                      OfferCodeReservationType.enquiry,
                                  pricePerPerson: reservation.pricePerPerson,
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

  Widget _iconRow(
    String imageIconPath,
    String text,
    Color? textColor,
    FontWeight? fontWeight, {
    int? maxLines = 2,
    double? textsize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIconPath,
          width: 18.w,
          height: 18.h,
          // color: appTextColor5,
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: AppText(
            text: text,
            size: textsize ?? 14,
            fontWeight: fontWeight ?? FontWeight.w500,
            color: textColor ?? appTextColor5,
            maxLines: maxLines,
            overflow: maxLines == null
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
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
          // color: const Color(0xFF000000).withOpacity(.9),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppText(
                text: boldText,
                size: 14,
                fontWeight: FontWeight.w700,
                color: appTextColor5,
              ),
              AppText(
                text: regularText,
                size: 14,
                fontWeight: FontWeight.w500,
                color: appTextColor5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
