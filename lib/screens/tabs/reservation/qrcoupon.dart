
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCoupon extends StatelessWidget {
  final BookingModel? booking;

  const QrCoupon({super.key, this.booking});

  DateTime get _eventDate => booking?.eventDate ?? DateTime.now();

  String get _restaurantName => booking?.restaurantName ?? 'Reservation Coupon';

  String get _couponId => booking?.couponId ?? 'QR0000';

  int get _persons => booking?.persons ?? 2;

  double get _discount => booking?.discount ?? 25;

  String get _discountStr =>
      _discount % 1 == 0 ? _discount.toInt().toString() : _discount.toStringAsFixed(1);

  Widget _buildQrCard() {
    final String data = (booking?.uuid != null && booking!.uuid.isNotEmpty)
        ? booking!.uuid
        : (booking?.couponId ?? booking?.id ?? '');

    return Container(
      height: 250.h,
      width: 220.w,
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: data,
              size: 160.w,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 6.h),
            SizedBox(
              width: 180.w,
              child: Text(
                data,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.sp, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String eventDateStr = DateFormat('MMM d').format(_eventDate);
    final String eventTimeStr = DateFormat('hh:mm a').format(_eventDate);

    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 150.h,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(Icons.close, color: appTextColor, size: 30.r),
                      ),
                    ],
                  ),
                  SizedBox(height: 80.h),
                  AppText(
                    text: _restaurantName,
                    size: 25,
                    fontWeight: FontWeight.w600,
                    color: appTextColor3,
                    isCentered: true,
                  ),
                  // SizedBox(height: 5.h),
                  SizedBox(
                    height: 500.h,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            "assets/images/couponbody.png",
                            height: 500.h,
                            width: double.infinity,
                            fit: BoxFit.fill,
                          ),
                        ),
                        Positioned(
                          top: 70.h,
                          left: 0,
                          right: 0,
                          child: Center(child: _buildQrCard()),
                        ),
                        Positioned(
                          bottom: 70.h,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                text: eventDateStr.toUpperCase(),
                                size: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                              SizedBox(height: 18.h),
                              SizedBox(
                                width: 147.w,
                                height: 44.h,
                                child: AppButton(
                                  buttonwidth: 147.w,
                                  buttonheight: 44.h,
                                  borderRadius: 116.r,
                                  bgColor1: Color(0xFFF97A0D),
                                  bgColor2: Color(0xFFF97A0D),
                                  text: eventTimeStr,
                                  onPressed: () {},
                                  size: 20.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              text: '$_discountStr%',
                              size: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: appTextColor5.withOpacity(.9),
                              isCentered: true,
                            ),
                            AppText(
                              text: ' offer for entire menu',
                              size: 20.sp,
                              fontWeight: FontWeight.w500,
                              color: appTextColor5.withOpacity(.9),
                              isCentered: true,
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              text: '$_persons',
                              size: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: appTextColor5.withOpacity(.9),
                              isCentered: true,
                            ),
                            AppText(
                              text: ' Person',
                              size: 20.sp,
                              fontWeight: FontWeight.w500,
                              color: appTextColor5.withOpacity(.9),
                              isCentered: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
