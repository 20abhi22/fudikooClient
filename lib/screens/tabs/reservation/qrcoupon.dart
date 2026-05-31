import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
import 'package:fudikoclient/service/reservation/offer_code_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCoupon extends StatefulWidget {
  final BookingModel? booking;
  final OfferCodeReservationType reservationType;
  final String? offerText;
  final int? pricePerPerson;

  const QrCoupon({
    super.key,
    this.booking,
    this.reservationType = OfferCodeReservationType.restaurant,
    this.offerText,
    this.pricePerPerson,
  });

  @override
  State<QrCoupon> createState() => _QrCouponState();
}

class _QrCouponState extends State<QrCoupon> {
  late final Future<OfferCodeResponse>? _offerCodeFuture;

  DateTime get _eventDate => widget.booking?.eventDate ?? DateTime.now();

  String get _restaurantName =>
      widget.booking?.restaurantName ?? 'Reservation Coupon';

  String get _couponId => widget.booking?.couponId ?? 'QR0000';

  int get _persons => widget.booking?.persons ?? 2;

  int get _pricePerPerson =>
      widget.pricePerPerson ?? widget.booking?.pricePerPerson ?? 0;

  bool get _isCateringEnquiry =>
      widget.reservationType == OfferCodeReservationType.cateringEnquiry;

  double get _discount => widget.booking?.discount ?? 25;

  String get _discountStr => _discount % 1 == 0
      ? _discount.toInt().toString()
      : _discount.toStringAsFixed(1);

  String get _offerText =>
      widget.offerText ??
      '$_discountStr% offer for ${widget.booking?.applicableFor ?? 'entire menu'}';

  String get _reservationId {
    final booking = widget.booking;
    if (booking == null) return '';
    if (booking.uuid.trim().isNotEmpty) return booking.uuid;
    if (booking.couponId.trim().isNotEmpty) return booking.couponId;
    return booking.id;
  }

  String get _fallbackQrData =>
      _reservationId.isNotEmpty ? _reservationId : _couponId;

  @override
  void initState() {
    super.initState();
    _offerCodeFuture = _reservationId.isEmpty
        ? null
        : OfferCodeService().fetchOfferCode(
            reservationId: _reservationId,
            type: widget.reservationType,
          );
  }

  Uint8List? _decodeQrImage(String qrImage) {
    final String trimmed = qrImage.trim();
    if (trimmed.isEmpty) return null;

    final String base64Value = trimmed.contains(',')
        ? trimmed.substring(trimmed.indexOf(',') + 1)
        : trimmed;

    try {
      return base64Decode(
        base64.normalize(base64Value.replaceAll(RegExp(r'\s+'), '')),
      );
    } on FormatException {
      return null;
    }
  }

  Widget _buildQrCard() {
    Widget qrWidget(String data, {String qrImage = ''}) {
      final imageBytes = _decodeQrImage(qrImage);
      if (imageBytes != null) {
        return Image.memory(
          imageBytes,
          width: 160.w,
          height: 160.w,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );
      }

      return QrImageView(
        data: data.isNotEmpty ? data : _fallbackQrData,
        size: 160.w,
        backgroundColor: Colors.white,
      );
    }

    return Container(
      height: 250.h,
      width: 220.w,
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_offerCodeFuture == null)
              qrWidget(_fallbackQrData)
            else
              FutureBuilder<OfferCodeResponse>(
                future: _offerCodeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      width: 160.w,
                      height: 160.w,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final response = snapshot.data;
                  final qrData = response?.verificationUrl.isNotEmpty == true
                      ? response!.verificationUrl
                      : _fallbackQrData;

                  return qrWidget(qrData, qrImage: response?.qrImage ?? '');
                },
              ),
            SizedBox(height: 6.h),
            // SizedBox(
            //   width: 180.w,
            //   child: Text(
            //     _fallbackQrData,
            //     maxLines: 2,
            //     overflow: TextOverflow.ellipsis,
            //     textAlign: TextAlign.center,
            //     style: TextStyle(fontSize: 11.sp, color: Colors.black87),
            //   ),
            // ),
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
                        child: Icon(
                          Icons.close,
                          color: appTextColor,
                          size: 30.r,
                        ),
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
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _isCateringEnquiry
                            ? Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  AppText(
                                    text: 'Free',
                                    size: 20.sp,
                                    fontWeight: FontWeight.w700,
                                    color: appTextColor5.withValues(alpha: .9),
                                    isCentered: true,
                                    maxLines: 1,
                                  ),
                                  AppText(
                                    text: ' delivery included',
                                    size: 20.sp,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor5.withValues(alpha: .9),
                                    isCentered: true,
                                    maxLines: 1,
                                  ),
                                ],
                              )
                            : AppText(
                                text: _offerText,
                                size: 20.sp,
                                fontWeight: FontWeight.w500,
                                color: appTextColor5.withValues(alpha: .9),
                                isCentered: true,
                              ),
                        if (widget.pricePerPerson != null &&
                            _pricePerPerson > 0) ...[
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppText(
                                text: '$_pricePerPerson',
                                size: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: appTextColor5.withValues(alpha: .9),
                                isCentered: true,
                              ),
                              AppText(
                                text: ' per person',
                                size: 20.sp,
                                fontWeight: FontWeight.w500,
                                color: appTextColor5.withValues(alpha: .9),
                                isCentered: true,
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              text: '$_persons',
                              size: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: appTextColor5.withValues(alpha: .9),
                              isCentered: true,
                            ),
                            AppText(
                              text: ' Person',
                              size: 20.sp,
                              fontWeight: FontWeight.w500,
                              color: appTextColor5.withValues(alpha: .9),
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
