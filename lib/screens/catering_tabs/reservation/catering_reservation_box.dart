import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
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

  /// Called once the QR coupon page opened from this card is popped, so the
  /// list behind it can refresh with whatever changed there.
  final VoidCallback? onCouponClosed;

  const CateringReservationBox({
    super.key,
    required this.reservation,
    this.onCancelTap,
    this.onRequestTap,
    this.onCouponClosed,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = _CateringReservationBoxMetrics.fromContext(context);
    final isConfirmed = reservation.status == "Confirmed";
    final isCancelled =
        reservation.status == "Cancelled" || reservation.status == "Canceled";
    final isCompleted = reservation.status == "Completed";
    final statusColor = isConfirmed
        ? const Color(0xFF32BA7C).withValues(alpha: .9)
        : isCancelled
        ? const Color(0xFFFB5858).withValues(alpha: .9)
        : const Color(0xFF3954DB).withValues(alpha: .9);
    final eventDate = DateFormat("MMM d").format(reservation.eventDate);
    final eventTime = DateFormat("h:mm a").format(reservation.eventDate);
    final bookingDate = DateFormat("MMM d").format(reservation.bookingDate);
    final bookingTime = DateFormat("h:mm a").format(reservation.bookingDate);
    final offerText = _offerText();

    return Padding(
      padding: EdgeInsets.only(bottom: metrics.cardBottomGap),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(metrics.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: const Offset(0, 0),
              blurRadius: metrics.cardShadowBlur,
              spreadRadius: metrics.cardShadowSpread,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.cardHorizontalPadding,
            vertical: metrics.cardVerticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppText(
                      text: reservation.couponId,
                      size: metrics.idTextSize,
                      fontWeight: FontWeight.w700,
                      color: appTextColor6,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: metrics.headerGap),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: bookingDate,
                        size: metrics.bookingTextSize,
                        fontWeight: FontWeight.w600,
                        color: appTextColor6,
                      ),
                      AppText(
                        text: bookingTime.toLowerCase(),
                        size: metrics.bookingTextSize,
                        fontWeight: FontWeight.w400,
                        color: appTextColor6,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: metrics.idBottomGap),
              _iconRow(
                metrics,
                shopIcon,
                reservation.restaurantName,
                const Color(0xff485599).withValues(alpha: .9),
                FontWeight.w600,
                textsize: metrics.restaurantTextSize,
              ),
              SizedBox(height: metrics.rowGap),
              _iconRowWithEmphasis(
                metrics,
                walletIcon,
                reservation.pricePerPerson.toString(),
                ' Per Person',
              ),
              SizedBox(height: metrics.rowGap),
              _iconRow(
                metrics,
                offerIcon,
                offerText,
                appTextColor5,
                FontWeight.w500,
                maxLines: null,
              ),
              if (reservation.message.isNotEmpty) ...[
                SizedBox(height: metrics.rowGap),
                _iconRow(
                  metrics,
                  commentIcon,
                  reservation.message,
                  appTextColor5,
                  FontWeight.w400,
                  maxLines: null,
                ),
              ],
              SizedBox(height: metrics.rowGap),
              _iconRowWithEmphasis(
                metrics,
                calenderIcon,
                eventDate,
                ' - $eventTime',
              ),
              SizedBox(height: metrics.rowGap),
              _iconRow(
                metrics,
                peopleIcon,
                '${reservation.persons} Person',
                appTextColor5,
                FontWeight.w400,
              ),
              SizedBox(height: metrics.statusTopGap),
              Row(
                children: [
                  Image.asset(
                    statusIcon,
                    width: metrics.infoIconSize,
                    height: metrics.infoIconSize,
                  ),
                  SizedBox(width: metrics.infoIconGap),
                  AppText(
                    text: reservation.status,
                    size: metrics.statusTextSize,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ],
              ),
              SizedBox(height: metrics.actionsTopGap),
              if (!isCancelled)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final links = _actionLinks(
                      metrics,
                      isCompleted: isCompleted,
                    );
                    final coupon = _couponButton(
                      context,
                      metrics,
                      enabled: isConfirmed,
                    );

                    if (constraints.maxWidth < metrics.actionsStackBreakpoint) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          links,
                          SizedBox(height: metrics.actionsStackGap),
                          Align(
                            alignment: Alignment.centerRight,
                            child: coupon,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: links),
                        SizedBox(width: metrics.actionsGap),
                        coupon,
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconRow(
    _CateringReservationBoxMetrics metrics,
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
          width: metrics.infoIconSize,
          height: metrics.infoIconSize,
        ),
        SizedBox(width: metrics.infoIconGap),
        Flexible(
          child: AppText(
            text: text,
            size: textsize ?? metrics.infoTextSize,
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
    _CateringReservationBoxMetrics metrics,
    String imageIconPath,
    String boldText,
    String regularText,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIconPath,
          width: metrics.infoIconSize,
          height: metrics.infoIconSize,
        ),
        SizedBox(width: metrics.infoIconGap),
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppText(
                text: boldText,
                size: metrics.infoTextSize,
                fontWeight: FontWeight.w700,
                color: appTextColor5,
              ),
              AppText(
                text: regularText,
                size: metrics.infoTextSize,
                fontWeight: FontWeight.w500,
                color: appTextColor5,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _offerText() {
    final extraOffer = reservation.extraOffer.trim();
    if (extraOffer.isNotEmpty) return extraOffer;

    final applicableFor = reservation.applicableFor?.trim();
    final discount = reservation.discount % 1 == 0
        ? reservation.discount.toStringAsFixed(0)
        : reservation.discount.toStringAsFixed(1);

    if (applicableFor == null || applicableFor.isEmpty) {
      return '$discount% off';
    }

    return '$discount% $applicableFor';
  }

  Widget _actionLinks(
    _CateringReservationBoxMetrics metrics, {
    required bool isCompleted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onRequestTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                detailsIcon,
                width: metrics.detailIconSize,
                height: metrics.detailIconSize,
                color: const Color(0xFF3954DB),
              ),
              SizedBox(width: metrics.detailIconGap),
              AppText(
                text: "View request",
                size: metrics.detailTextSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3954DB),
              ),
            ],
          ),
        ),
        if (!isCompleted) ...[
          SizedBox(height: metrics.cancelTopGap),
          GestureDetector(
            onTap: onCancelTap,
            child: AppText(
              text: "Cancel",
              size: metrics.cancelTextSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFCE3F3F).withValues(alpha: .9),
            ),
          ),
        ],
      ],
    );
  }

  Widget _couponButton(
    BuildContext context,
    _CateringReservationBoxMetrics metrics, {
    required bool enabled,
  }) {
    return SizedBox(
      width: metrics.couponButtonWidth,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: IgnorePointer(
          ignoring: !enabled,
          child: AppButton(
            buttonheight: metrics.couponButtonHeight,
            bgColor1: const Color(0xFFFE943A),
            bgColor2: const Color(0xFFFE943A),
            imageIconPath: couponIcon,
            iconSize: metrics.couponIconSize,
            text: " Coupon",
            size: metrics.couponTextSize,
            borderRadius: metrics.couponButtonRadius,
            onPressed: () {
              slideRightWidget(
                newPage: QrCoupon(
                  booking: reservation.toBookingModel(),
                  reservationType: OfferCodeReservationType.cateringEnquiry,
                  pricePerPerson: reservation.pricePerPerson,
                ),
                context: context,
              ).then((_) => onCouponClosed?.call());
            },
          ),
        ),
      ),
    );
  }
}

class _CateringReservationBoxMetrics {
  const _CateringReservationBoxMetrics({
    required this.cardBottomGap,
    required this.cardRadius,
    required this.cardShadowBlur,
    required this.cardShadowSpread,
    required this.cardHorizontalPadding,
    required this.cardVerticalPadding,
    required this.idTextSize,
    required this.headerGap,
    required this.bookingTextSize,
    required this.idBottomGap,
    required this.rowGap,
    required this.infoIconSize,
    required this.infoIconGap,
    required this.infoTextSize,
    required this.restaurantTextSize,
    required this.statusTopGap,
    required this.statusTextSize,
    required this.actionsTopGap,
    required this.actionsGap,
    required this.actionsStackGap,
    required this.actionsStackBreakpoint,
    required this.detailIconSize,
    required this.detailIconGap,
    required this.detailTextSize,
    required this.cancelTopGap,
    required this.cancelTextSize,
    required this.couponButtonWidth,
    required this.couponButtonHeight,
    required this.couponButtonRadius,
    required this.couponIconSize,
    required this.couponTextSize,
  });

  final double cardBottomGap;
  final double cardRadius;
  final double cardShadowBlur;
  final double cardShadowSpread;
  final double cardHorizontalPadding;
  final double cardVerticalPadding;
  final double idTextSize;
  final double headerGap;
  final double bookingTextSize;
  final double idBottomGap;
  final double rowGap;
  final double infoIconSize;
  final double infoIconGap;
  final double infoTextSize;
  final double restaurantTextSize;
  final double statusTopGap;
  final double statusTextSize;
  final double actionsTopGap;
  final double actionsGap;
  final double actionsStackGap;
  final double actionsStackBreakpoint;
  final double detailIconSize;
  final double detailIconGap;
  final double detailTextSize;
  final double cancelTopGap;
  final double cancelTextSize;
  final double couponButtonWidth;
  final double couponButtonHeight;
  final double couponButtonRadius;
  final double couponIconSize;
  final double couponTextSize;

  factory _CateringReservationBoxMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final horizontalScale = (size.width / 768).clamp(1.0, 1.16).toDouble();
      final verticalScale = (size.height / 1024).clamp(1.0, 1.18).toDouble();
      double s(double value) => value * horizontalScale;
      double v(double value) => value * verticalScale;

      return _CateringReservationBoxMetrics(
        cardBottomGap: v(24),
        cardRadius: s(20),
        cardShadowBlur: s(12),
        cardShadowSpread: s(2),
        cardHorizontalPadding: s(24),
        cardVerticalPadding: v(24),
        idTextSize: 21,
        headerGap: s(14),
        bookingTextSize: 11,
        idBottomGap: v(12),
        rowGap: v(10),
        infoIconSize: s(20),
        infoIconGap: s(9),
        infoTextSize: 15,
        restaurantTextSize: 17,
        statusTopGap: v(8),
        statusTextSize: 16,
        actionsTopGap: v(24),
        actionsGap: s(18),
        actionsStackGap: v(14),
        actionsStackBreakpoint: s(360),
        detailIconSize: s(13),
        detailIconGap: s(4),
        detailTextSize: 12,
        cancelTopGap: v(5),
        cancelTextSize: 16,
        couponButtonWidth: s(150),
        couponButtonHeight: v(48),
        couponButtonRadius: s(12),
        couponIconSize: s(34),
        couponTextSize: 18,
      );
    }

    if (isWideShortPhone) {
      return const _CateringReservationBoxMetrics(
        cardBottomGap: 16,
        cardRadius: 16,
        cardShadowBlur: 8,
        cardShadowSpread: 1.5,
        cardHorizontalPadding: 16,
        cardVerticalPadding: 17,
        idTextSize: 17,
        headerGap: 8,
        bookingTextSize: 9,
        idBottomGap: 8,
        rowGap: 7,
        infoIconSize: 15,
        infoIconGap: 6,
        infoTextSize: 12.5,
        restaurantTextSize: 14,
        statusTopGap: 5,
        statusTextSize: 13,
        actionsTopGap: 16,
        actionsGap: 10,
        actionsStackGap: 10,
        actionsStackBreakpoint: 300,
        detailIconSize: 10,
        detailIconGap: 3,
        detailTextSize: 10,
        cancelTopGap: 3,
        cancelTextSize: 13,
        couponButtonWidth: 118,
        couponButtonHeight: 34,
        couponButtonRadius: 9,
        couponIconSize: 25,
        couponTextSize: 13,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _CateringReservationBoxMetrics(
        cardBottomGap: s(16),
        cardRadius: s(16),
        cardShadowBlur: s(8),
        cardShadowSpread: s(1.5),
        cardHorizontalPadding: s(15),
        cardVerticalPadding: s(16),
        idTextSize: s(17),
        headerGap: s(8),
        bookingTextSize: s(9),
        idBottomGap: s(8),
        rowGap: s(7),
        infoIconSize: s(15),
        infoIconGap: s(6),
        infoTextSize: s(12.5),
        restaurantTextSize: s(14),
        statusTopGap: s(5),
        statusTextSize: s(13),
        actionsTopGap: s(16),
        actionsGap: s(10),
        actionsStackGap: s(10),
        actionsStackBreakpoint: s(300),
        detailIconSize: s(10),
        detailIconGap: s(3),
        detailTextSize: s(10),
        cancelTopGap: s(3),
        cancelTextSize: s(13),
        couponButtonWidth: s(118),
        couponButtonHeight: s(34),
        couponButtonRadius: s(9),
        couponIconSize: s(25),
        couponTextSize: s(13),
      );
    }

    return _CateringReservationBoxMetrics(
      cardBottomGap: 20.h,
      cardRadius: 17.r,
      cardShadowBlur: 10,
      cardShadowSpread: 2,
      cardHorizontalPadding: 20.w,
      cardVerticalPadding: 22.h,
      idTextSize: 20,
      headerGap: 10.w,
      bookingTextSize: 10,
      idBottomGap: 10.h,
      rowGap: 8.h,
      infoIconSize: 18.w,
      infoIconGap: 8.w,
      infoTextSize: 14,
      restaurantTextSize: 16,
      statusTopGap: 6.h,
      statusTextSize: 15,
      actionsTopGap: 20.h,
      actionsGap: 12.w,
      actionsStackGap: 12.h,
      actionsStackBreakpoint: 300.w,
      detailIconSize: 11.w,
      detailIconGap: 2.w,
      detailTextSize: 11,
      cancelTopGap: 3.h,
      cancelTextSize: 15,
      couponButtonWidth: 136.w,
      couponButtonHeight: 45.h,
      couponButtonRadius: 12.r,
      couponIconSize: 35,
      couponTextSize: 18,
    );
  }
}
