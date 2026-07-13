import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
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

  Widget _buildQrCard(_QrCouponMetrics metrics) {
    Widget qrWidget(String data, {String qrImage = ''}) {
      final imageBytes = _decodeQrImage(qrImage);
      if (imageBytes != null) {
        return Image.memory(
          imageBytes,
          width: metrics.qrSize,
          height: metrics.qrSize,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );
      }

      return QrImageView(
        data: data.isNotEmpty ? data : _fallbackQrData,
        size: metrics.qrSize,
        backgroundColor: Colors.white,
      );
    }

    return Container(
      height: metrics.qrCardHeight,
      width: metrics.qrCardWidth,
      padding: EdgeInsets.all(metrics.qrCardPadding),
      decoration: const BoxDecoration(color: Colors.transparent),
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
                      width: metrics.qrSize,
                      height: metrics.qrSize,
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
            SizedBox(height: metrics.qrBottomGap),
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
    final metrics = _QrCouponMetrics.fromContext(context);
    final String eventDateStr = DateFormat('MMM d').format(_eventDate);
    final String eventTimeStr = DateFormat('hh:mm a').format(_eventDate);

    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.pageHorizontalPadding,
            vertical: metrics.pageVerticalPadding,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height -
                    metrics.constrainedHeightOffset,
              ),
              child: Center(
                child: SizedBox(
                  width: metrics.contentWidth,
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
                              size: metrics.closeIconSize,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: metrics.topGap),
                      AppText(
                        text: _restaurantName,
                        size: metrics.titleTextSize,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                        isCentered: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: metrics.titleBottomGap),
                      SizedBox(
                        height: metrics.couponHeight,
                        width: metrics.couponWidth,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                "assets/images/couponbody.png",
                                height: metrics.couponHeight,
                                width: metrics.couponWidth,
                                fit: BoxFit.fill,
                              ),
                            ),
                            Positioned(
                              top: metrics.qrTop,
                              left: 0,
                              right: 0,
                              child: Center(child: _buildQrCard(metrics)),
                            ),
                            Positioned(
                              bottom: metrics.couponBottom,
                              left: 0,
                              right: 0,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppText(
                                    text: eventDateStr.toUpperCase(),
                                    size: metrics.dateTextSize,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: metrics.dateButtonGap),
                                  SizedBox(
                                    width: metrics.timeButtonWidth,
                                    height: metrics.timeButtonHeight,
                                    child: AppButton(
                                      buttonwidth: metrics.timeButtonWidth,
                                      buttonheight: metrics.timeButtonHeight,
                                      borderRadius: metrics.timeButtonRadius,
                                      bgColor1: const Color(0xFFF97A0D),
                                      bgColor2: const Color(0xFFF97A0D),
                                      text: eventTimeStr,
                                      onPressed: () {},
                                      size: metrics.timeButtonTextSize,
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
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      AppText(
                                        text: 'Free',
                                        size: metrics.detailTextSize,
                                        fontWeight: FontWeight.w700,
                                        color: appTextColor5.withValues(
                                          alpha: .9,
                                        ),
                                        isCentered: true,
                                        maxLines: 1,
                                      ),
                                      AppText(
                                        text: ' delivery included',
                                        size: metrics.detailTextSize,
                                        fontWeight: FontWeight.w500,
                                        color: appTextColor5.withValues(
                                          alpha: .9,
                                        ),
                                        isCentered: true,
                                        maxLines: 1,
                                      ),
                                    ],
                                  )
                                : AppText(
                                    text: _offerText,
                                    size: metrics.detailTextSize,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor5.withValues(alpha: .9),
                                    isCentered: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            if (widget.pricePerPerson != null &&
                                _pricePerPerson > 0) ...[
                              SizedBox(height: metrics.priceTopGap),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppText(
                                    text: '$_pricePerPerson',
                                    size: metrics.detailTextSize,
                                    fontWeight: FontWeight.w700,
                                    color: appTextColor5.withValues(alpha: .9),
                                    isCentered: true,
                                  ),
                                  AppText(
                                    text: ' per person',
                                    size: metrics.detailTextSize,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor5.withValues(alpha: .9),
                                    isCentered: true,
                                  ),
                                ],
                              ),
                            ],
                            SizedBox(height: metrics.personTopGap),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppText(
                                  text: '$_persons',
                                  size: metrics.detailTextSize,
                                  fontWeight: FontWeight.w700,
                                  color: appTextColor5.withValues(alpha: .9),
                                  isCentered: true,
                                ),
                                AppText(
                                  text: ' Person',
                                  size: metrics.detailTextSize,
                                  fontWeight: FontWeight.w500,
                                  color: appTextColor5.withValues(alpha: .9),
                                  isCentered: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: metrics.bottomGap),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrCouponMetrics {
  const _QrCouponMetrics({
    required this.contentWidth,
    required this.pageHorizontalPadding,
    required this.pageVerticalPadding,
    required this.constrainedHeightOffset,
    required this.closeIconSize,
    required this.topGap,
    required this.titleTextSize,
    required this.titleBottomGap,
    required this.couponWidth,
    required this.couponHeight,
    required this.qrTop,
    required this.couponBottom,
    required this.qrCardWidth,
    required this.qrCardHeight,
    required this.qrCardPadding,
    required this.qrSize,
    required this.qrBottomGap,
    required this.dateTextSize,
    required this.dateButtonGap,
    required this.timeButtonWidth,
    required this.timeButtonHeight,
    required this.timeButtonRadius,
    required this.timeButtonTextSize,
    required this.detailTextSize,
    required this.priceTopGap,
    required this.personTopGap,
    required this.bottomGap,
  });

  final double contentWidth;
  final double pageHorizontalPadding;
  final double pageVerticalPadding;
  final double constrainedHeightOffset;
  final double closeIconSize;
  final double topGap;
  final double titleTextSize;
  final double titleBottomGap;
  final double couponWidth;
  final double couponHeight;
  final double qrTop;
  final double couponBottom;
  final double qrCardWidth;
  final double qrCardHeight;
  final double qrCardPadding;
  final double qrSize;
  final double qrBottomGap;
  final double dateTextSize;
  final double dateButtonGap;
  final double timeButtonWidth;
  final double timeButtonHeight;
  final double timeButtonRadius;
  final double timeButtonTextSize;
  final double detailTextSize;
  final double priceTopGap;
  final double personTopGap;
  final double bottomGap;

  factory _QrCouponMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final contentWidth = (size.width * 0.62).clamp(520.0, 700.0).toDouble();
      final scale = (contentWidth / 560).clamp(1.0, 1.18).toDouble();
      double s(double value) => value * scale;

      return _QrCouponMetrics(
        contentWidth: contentWidth,
        pageHorizontalPadding: s(36),
        pageVerticalPadding: s(34),
        constrainedHeightOffset: s(120),
        closeIconSize: s(34),
        topGap: s(70),
        titleTextSize: s(32),
        titleBottomGap: s(12),
        couponWidth: contentWidth,
        couponHeight: s(650),
        qrTop: s(95),
        couponBottom: s(92),
        qrCardWidth: s(280),
        qrCardHeight: s(310),
        qrCardPadding: s(10),
        qrSize: s(220),
        qrBottomGap: s(8),
        dateTextSize: s(20),
        dateButtonGap: s(22),
        timeButtonWidth: s(190),
        timeButtonHeight: s(54),
        timeButtonRadius: s(116),
        timeButtonTextSize: s(24),
        detailTextSize: s(24),
        priceTopGap: s(8),
        personTopGap: s(12),
        bottomGap: s(34),
      );
    }

    if (isWideShortPhone) {
      return const _QrCouponMetrics(
        contentWidth: 430,
        pageHorizontalPadding: 28,
        pageVerticalPadding: 18,
        constrainedHeightOffset: 86,
        closeIconSize: 26,
        topGap: 28,
        titleTextSize: 23,
        titleBottomGap: 8,
        couponWidth: 410,
        couponHeight: 382,
        qrTop: 42,
        couponBottom: 44,
        qrCardWidth: 204,
        qrCardHeight: 214,
        qrCardPadding: 7,
        qrSize: 146,
        qrBottomGap: 5,
        dateTextSize: 13,
        dateButtonGap: 10,
        timeButtonWidth: 132,
        timeButtonHeight: 36,
        timeButtonRadius: 116,
        timeButtonTextSize: 16,
        detailTextSize: 15,
        priceTopGap: 4,
        personTopGap: 6,
        bottomGap: 16,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.84, 0.95).toDouble();
      double s(double value) => value * scale;

      return _QrCouponMetrics(
        contentWidth: double.infinity,
        pageHorizontalPadding: s(16),
        pageVerticalPadding: s(22),
        constrainedHeightOffset: s(120),
        closeIconSize: s(26),
        topGap: s(46),
        titleTextSize: s(22),
        titleBottomGap: s(4),
        couponWidth: double.infinity,
        couponHeight: s(430),
        qrTop: s(56),
        couponBottom: s(56),
        qrCardWidth: s(196),
        qrCardHeight: s(222),
        qrCardPadding: s(7),
        qrSize: s(138),
        qrBottomGap: s(5),
        dateTextSize: s(14),
        dateButtonGap: s(14),
        timeButtonWidth: s(130),
        timeButtonHeight: s(38),
        timeButtonRadius: s(116),
        timeButtonTextSize: s(17),
        detailTextSize: s(17),
        priceTopGap: s(5),
        personTopGap: s(8),
        bottomGap: s(20),
      );
    }

    return _QrCouponMetrics(
      contentWidth: double.infinity,
      pageHorizontalPadding: 20.w,
      pageVerticalPadding: 30.h,
      constrainedHeightOffset: 150.h,
      closeIconSize: 30.r,
      topGap: 80.h,
      titleTextSize: 25,
      titleBottomGap: 0,
      couponWidth: double.infinity,
      couponHeight: 500.h,
      qrTop: 70.h,
      couponBottom: 70.h,
      qrCardWidth: 220.w,
      qrCardHeight: 250.h,
      qrCardPadding: 8.r,
      qrSize: 160.w,
      qrBottomGap: 6.h,
      dateTextSize: 16,
      dateButtonGap: 18.h,
      timeButtonWidth: 147.w,
      timeButtonHeight: 44.h,
      timeButtonRadius: 116.r,
      timeButtonTextSize: 20.sp,
      detailTextSize: 20.sp,
      priceTopGap: 6.h,
      personTopGap: 10.h,
      bottomGap: 24.h,
    );
  }
}
