
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

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
    return Container(
      height: 200.h,
      width: 200.w,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2,
            size: 120.r,
            color: appTextColor3,
          ),
          SizedBox(height: 8.h),
          AppText(
            text: _couponId,
            size: 12,
            fontWeight: FontWeight.w600,
            color: appTextColor2,
          ),
        ],
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
              child: IntrinsicHeight(
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
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            text: _restaurantName,
                            size: 25,
                            fontWeight: FontWeight.w600,
                            color: appTextColor3,
                          ),
                          Stack(
                            children: [
                              Image.asset(
                                "assets/images/couponbody.png",
                                height: 500.h,
                                width: 300.w,
                                fit: BoxFit.contain,
                              ),
                              Positioned(
                                top: 80.h,
                                left: 45.w,
                                child: _buildQrCard(),
                              ),
                              Positioned(
                                bottom: 120.h,
                                left: 100.w,
                                child: Column(
                                  children: [
                                    AppText(
                                      text: eventDateStr.toUpperCase(),
                                      size: 16,
                                      fontWeight: FontWeight.w400,
                                      color: appTextColor3,
                                    ),
                                    SizedBox(height: 10.h),
                                    SizedBox(
                                      width: 100.w,
                                      height: 40.h,
                                      child: AppButton(
                                        text: eventTimeStr,
                                        onPressed: () {},
                                        size: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          AppText(
                            text: '$_discountStr% offer for entire menu',
                            size: 20,
                            fontWeight: FontWeight.w700,
                            color: appTextColor2,
                          ),
                          SizedBox(height: 10.h),
                          AppText(
                            text: '$_persons Person',
                            size: 20,
                            fontWeight: FontWeight.w700,
                            color: appTextColor2,
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
      ),
    );
  }
}
