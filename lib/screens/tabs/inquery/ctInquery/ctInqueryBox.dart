import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/inquery/list-catering-inquery-model.dart';
import 'package:fudikoclient/screens/tabs/inquery/ctInquery/updatectinquery.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/model/inquery/delete-inquery-model.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class CtInqueryBox extends StatefulWidget {
  final CateringInqueryModel enquiry;
  final VoidCallback onCancelTap;
  final VoidCallback onEdit;

  const CtInqueryBox({
    super.key,
    required this.enquiry,
    required this.onCancelTap,
    required this.onEdit,
  });

  @override
  State<CtInqueryBox> createState() => _CtInqueryBoxState();
}

class _CtInqueryBoxState extends State<CtInqueryBox> {
  final InqueryService inqueryService = InqueryService();

  String placeName = '';
  late DateTime expiryDateTime;
  String countdown = '';
  Timer? timer;
  bool isExpired = false;
  bool _isWithdrawLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPlace();

    final dateTimeString =
        "${widget.enquiry.expirationDate} ${widget.enquiry.expirationTime}";
    expiryDateTime = DateFormat("yyyy-MM-dd hh:mm a").parse(dateTimeString);
    isExpired = DateTime.now().isAfter(expiryDateTime);
    startCountdown();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = expiryDateTime.difference(DateTime.now());
      if (remaining.isNegative) {
        setState(() {
          countdown = "Expired";
          isExpired = true;
        });
        timer?.cancel();
      } else {
        final h = remaining.inHours.toString().padLeft(2, '0');
        final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
        final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        setState(() => countdown = "$h:$m:$s");
      }
    });
  }

  void onEdit() {
    final metrics = _CtInqueryBoxMetrics.fromContext(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: metrics.editDialogInsetHorizontal,
          vertical: metrics.editDialogInsetVertical,
        ),
        backgroundColor: Colors.white,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: metrics.editDialogMinWidth,
            maxWidth: metrics.editDialogMaxWidth,
          ),
          child: UpdateCtInquery(
            enquiry: widget.enquiry,
            placeName: placeName,
            onEdit: widget.onEdit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Future<void> fetchPlace() async {
  //   final response = await mapService.getPlaceName(
  //     widget.enquiry.lat,
  //     widget.enquiry.lng,
  //   );
  //   setState(() {
  //     placeName = (response != null && response.isNotEmpty)
  //         ? response.split(',')[1]
  //         : "Unknown Location";
  //   });
  // }

  Future<void> fetchPlace() async {
    try {
      final lat = double.parse(widget.enquiry.lat);
      final lng = double.parse(widget.enquiry.lng);
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          placeName = [
            place.subLocality,
            place.locality,
          ].where((p) => p != null && p.isNotEmpty).join(', ');
          if (placeName.isEmpty) {
            placeName =
                place.country ?? "${widget.enquiry.lat}, ${widget.enquiry.lng}";
          }
        });
      } else {
        setState(() {
          placeName = "${widget.enquiry.lat}, ${widget.enquiry.lng}";
        });
      }
    } catch (_) {
      setState(() {
        placeName = "${widget.enquiry.lat}, ${widget.enquiry.lng}";
      });
    }
  }
  // Future<void> fetchPlace() async {
  //   final response = await mapService.getPlaceName(
  //     widget.enquiry.lat,
  //     widget.enquiry.lng,
  //   );
  //   setState(() {
  //     if (response != null && response.isNotEmpty) {
  //       final parts = response.split(',');
  //       placeName = parts.length > 1
  //           ? parts[1]
  //                 .trim() // "City" part
  //           : parts[0].trim(); // fallback to first part if no comma
  //     } else {
  //       placeName =
  //           "${widget.enquiry.lat}, ${widget.enquiry.lng}"; // raw coords as fallback
  //     }
  //   });
  // }

  Future<void> deleteEnquiry() async {
    final response = await inqueryService.deleteCateringInquery(
      DeleteInqueryModel(enquiryId: widget.enquiry.uuid),
    );

    if (!mounted) return;

    showStatusSnack(
      context,
      response.status,
      response.status
          ? "Enquiry withdrawn successfully"
          : "Something went wrong",
    );

    if (response.status) widget.onCancelTap();
  }

  Future<void> _withdrawEnquiry() async {
    if (_isWithdrawLoading) return;

    setState(() => _isWithdrawLoading = true);
    await deleteEnquiry();
    if (!mounted) return;
    setState(() => _isWithdrawLoading = false);
  }

  Widget _infoRow(
    String imageIcon,
    String text, {
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    int? maxLines,
  }) {
    final metrics = _CtInqueryBoxMetrics.fromContext(context);

    return Padding(
      padding: EdgeInsets.only(bottom: metrics.infoRowBottomGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imageIcon,
            width: metrics.infoIconSize,
            height: metrics.infoIconSize,
          ),
          SizedBox(width: metrics.infoIconGap),
          Expanded(
            child: AppText(
              text: text,
              size: metrics.infoTextSize,
              fontWeight: fontWeight,
              color: color ?? appTextColor5,
              maxLines: maxLines,
              overflow: maxLines == null
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _CtInqueryBoxMetrics.fromContext(context);
    final isConfirmed = widget.enquiry.status.toLowerCase() == "confirmed";

    final amount =
        double.tryParse(widget.enquiry.estimatedAmount)?.toInt() ??
        widget.enquiry.estimatedAmount;

    final radius =
        double.tryParse(widget.enquiry.searchRadius)?.toInt() ??
        widget.enquiry.searchRadius;

    final parsedEnquiryDate = DateTime.tryParse(widget.enquiry.date);
    final formattedEnquiryDate = parsedEnquiryDate != null
        ? DateFormat('MMM d').format(parsedEnquiryDate)
        : widget.enquiry.date;

    return Padding(
      padding: EdgeInsets.only(bottom: metrics.cardBottomGap),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(metrics.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: metrics.cardShadowBlur,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(metrics.cardPadding),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: widget.enquiry.enquiryId,
                          size: metrics.idTextSize,
                          fontWeight: FontWeight.bold,
                          color: appTextColor3,
                        ),

                        SizedBox(height: metrics.idBottomGap),

                        _infoRow(
                          walletIcon,
                          "$amount Per Person",
                          fontWeight: FontWeight.w900,
                        ),

                        _infoRow(
                          calenderIcon,
                          "$formattedEnquiryDate - ${widget.enquiry.time}",
                          fontWeight: FontWeight.w700,
                        ),

                        _infoRow(
                          peopleIcon,
                          "${widget.enquiry.people} Person",
                          fontWeight: FontWeight.w700,
                        ),

                        _infoRow(
                          menuIcon,
                          // The menu field is multi-line, so items arrive
                          // separated by newlines as well as commas. Split on
                          // both so the list reads as one comma-separated run
                          // instead of breaking onto a line per item.
                          widget.enquiry.menuItems
                              .split(RegExp(r'[,\n\r]+'))
                              .map((item) => item.trim())
                              .where((item) => item.isNotEmpty)
                              .join(', '),
                        ),

                        _infoRow(
                          radiusIcon,
                          placeName.isEmpty
                              ? "${widget.enquiry.lat}, ${widget.enquiry.lng} - ${radius}km Radius"
                              : "$placeName - ${radius}km Radius",
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: metrics.expiryColumnGap),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: DateFormat('d MMM').format(expiryDateTime),
                        size: metrics.expiryTextSize,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),

                      SizedBox(height: metrics.expiryTextGap),

                      AppText(
                        text: widget.enquiry.expirationTime,
                        size: metrics.expiryTextSize,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: metrics.statusTopGap),

              // ✅ Same as InqueryBox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      isConfirmed
                          ? Icon(
                              Icons.check_circle,
                              size: metrics.statusIconSize,
                              color: Colors.green,
                            )
                          : Image.asset(
                              stopwatchIcon,
                              width: metrics.statusIconSize,
                              height: metrics.statusIconSize,
                            ),
                      SizedBox(width: metrics.statusIconGap),

                      SizedBox(
                        width: metrics.statusTextWidth,
                        child: Text(
                          isConfirmed ? "Confirmed" : countdown,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontSize: metrics.statusTextSize,
                            fontWeight: FontWeight.w600,
                            color: isConfirmed ? Colors.green : Colors.red,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Hide buttons if confirmed OR expired
                  if (!isConfirmed && !isExpired)
                    Row(
                      children: [
                        SizedBox(width: metrics.actionLeadingGap),

                        SizedBox(
                          width: metrics.withdrawButtonWidth,
                          height: metrics.withdrawButtonHeight,
                          child: _ConfirmActionButton(
                            isLoading: _isWithdrawLoading,
                            text: "Withdraw",
                            textSize: metrics.withdrawButtonTextSize,
                            radius: metrics.withdrawButtonRadius,
                            color: const Color(0xFFCE3F3F),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => Dialog(
                                  insetPadding: EdgeInsets.symmetric(
                                    horizontal:
                                        metrics.confirmDialogInsetHorizontal,
                                    vertical:
                                        metrics.confirmDialogInsetVertical,
                                  ),
                                  elevation: 18,
                                  shadowColor: Colors.black.withValues(
                                    alpha: 0.18,
                                  ),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      metrics.confirmDialogRadius,
                                    ),
                                    side: BorderSide(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: metrics.confirmDialogMaxWidth,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: metrics
                                            .confirmDialogHorizontalPadding,
                                        vertical: metrics
                                            .confirmDialogVerticalPadding,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppText(
                                            text:
                                                "Are you sure you want to withdraw this enquiry?",
                                            isCentered: true,
                                            lineSpacing:
                                                metrics.confirmTextLineSpacing,
                                            size: metrics.confirmTextSize,
                                            fontWeight: FontWeight.w500,
                                            color: appTextColor2,
                                          ),
                                          SizedBox(height: metrics.confirmGap),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: metrics
                                                      .confirmButtonHeight,
                                                  child: AppButton(
                                                    text: "Yes",
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        dialogContext,
                                                      );
                                                      _withdrawEnquiry();
                                                    },
                                                    size: metrics
                                                        .confirmButtonTextSize,
                                                    bgColor1: const Color(
                                                      0xFF73B256,
                                                    ),
                                                    bgColor2: const Color(
                                                      0xFF73B256,
                                                    ),
                                                    borderRadius: metrics
                                                        .confirmButtonRadius,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: metrics.confirmButtonGap,
                                              ),
                                              Expanded(
                                                child: SizedBox(
                                                  height: metrics
                                                      .confirmButtonHeight,
                                                  child: AppButton(
                                                    text: "No",
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          dialogContext,
                                                        ),
                                                    size: metrics
                                                        .confirmButtonTextSize,
                                                    bgColor1: const Color(
                                                      0xFFCE3F3F,
                                                    ),
                                                    bgColor2: const Color(
                                                      0xFFCE3F3F,
                                                    ),
                                                    borderRadius: metrics
                                                        .confirmButtonRadius,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmActionButton extends StatelessWidget {
  const _ConfirmActionButton({
    required this.text,
    required this.textSize,
    required this.radius,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  final String text;
  final double textSize;
  final double radius;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Center(
          child: isLoading
              ? const _ThreeDotLoader()
              : AppText(
                  text: text,
                  size: textSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  maxLines: 1,
                ),
        ),
      ),
    );
  }
}

class _ThreeDotLoader extends StatefulWidget {
  const _ThreeDotLoader();

  @override
  State<_ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<_ThreeDotLoader> {
  int _activeDot = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 260), (_) {
      if (!mounted) return;
      setState(() => _activeDot = (_activeDot + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index == _activeDot;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isActive ? 6 : 5,
          height: isActive ? 6 : 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isActive ? 1 : 0.45),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _CtInqueryBoxMetrics {
  const _CtInqueryBoxMetrics({
    required this.cardBottomGap,
    required this.cardRadius,
    required this.cardShadowBlur,
    required this.cardPadding,
    required this.idTextSize,
    required this.idBottomGap,
    required this.infoRowBottomGap,
    required this.infoIconSize,
    required this.infoIconGap,
    required this.infoTextSize,
    required this.expiryColumnGap,
    required this.expiryTextSize,
    required this.expiryTextGap,
    required this.statusTopGap,
    required this.statusIconSize,
    required this.statusIconGap,
    required this.statusTextSize,
    required this.statusTextWidth,
    required this.actionLeadingGap,
    required this.withdrawButtonWidth,
    required this.withdrawButtonHeight,
    required this.withdrawButtonTextSize,
    required this.withdrawButtonRadius,
    required this.confirmDialogInsetHorizontal,
    required this.confirmDialogInsetVertical,
    required this.confirmDialogMaxWidth,
    required this.confirmDialogRadius,
    required this.confirmDialogHorizontalPadding,
    required this.confirmDialogVerticalPadding,
    required this.confirmTextSize,
    required this.confirmTextLineSpacing,
    required this.confirmGap,
    required this.confirmButtonHeight,
    required this.confirmButtonGap,
    required this.confirmButtonTextSize,
    required this.confirmButtonRadius,
    required this.editDialogInsetHorizontal,
    required this.editDialogInsetVertical,
    required this.editDialogMinWidth,
    required this.editDialogMaxWidth,
  });

  final double cardBottomGap;
  final double cardRadius;
  final double cardShadowBlur;
  final double cardPadding;
  final double idTextSize;
  final double idBottomGap;
  final double infoRowBottomGap;
  final double infoIconSize;
  final double infoIconGap;
  final double infoTextSize;
  final double expiryColumnGap;
  final double expiryTextSize;
  final double expiryTextGap;
  final double statusTopGap;
  final double statusIconSize;
  final double statusIconGap;
  final double statusTextSize;
  final double statusTextWidth;
  final double actionLeadingGap;
  final double withdrawButtonWidth;
  final double withdrawButtonHeight;
  final double withdrawButtonTextSize;
  final double withdrawButtonRadius;
  final double confirmDialogInsetHorizontal;
  final double confirmDialogInsetVertical;
  final double confirmDialogMaxWidth;
  final double confirmDialogRadius;
  final double confirmDialogHorizontalPadding;
  final double confirmDialogVerticalPadding;
  final double confirmTextSize;
  final double confirmTextLineSpacing;
  final double confirmGap;
  final double confirmButtonHeight;
  final double confirmButtonGap;
  final double confirmButtonTextSize;
  final double confirmButtonRadius;
  final double editDialogInsetHorizontal;
  final double editDialogInsetVertical;
  final double editDialogMinWidth;
  final double editDialogMaxWidth;

  factory _CtInqueryBoxMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final scale = (size.width / 768).clamp(1.0, 1.16).toDouble();
      final verticalScale = (size.height / 1024).clamp(1.0, 1.18).toDouble();
      double s(double value) => value * scale;
      double v(double value) => value * verticalScale;
      final dialogMaxWidth = (size.width - s(72))
          .clamp(420.0, 760.0)
          .toDouble();

      return _CtInqueryBoxMetrics(
        cardBottomGap: v(24),
        cardRadius: s(20),
        cardShadowBlur: s(10),
        cardPadding: s(24),
        idTextSize: 21,
        idBottomGap: v(12),
        infoRowBottomGap: v(11),
        infoIconSize: s(20),
        infoIconGap: s(7),
        infoTextSize: 16,
        expiryColumnGap: s(14),
        expiryTextSize: 11,
        expiryTextGap: v(5),
        statusTopGap: v(22),
        statusIconSize: s(17),
        statusIconGap: s(6),
        statusTextSize: 12,
        statusTextWidth: s(74),
        actionLeadingGap: s(6),
        withdrawButtonWidth: s(100),
        withdrawButtonHeight: v(40),
        withdrawButtonTextSize: 12,
        withdrawButtonRadius: s(6),
        confirmDialogInsetHorizontal: s(40),
        confirmDialogInsetVertical: v(24),
        confirmDialogMaxWidth: s(420),
        confirmDialogRadius: s(12),
        confirmDialogHorizontalPadding: s(34),
        confirmDialogVerticalPadding: v(24),
        confirmTextSize: 13,
        confirmTextLineSpacing: 1.5,
        confirmGap: v(24),
        confirmButtonHeight: v(34),
        confirmButtonGap: s(12),
        confirmButtonTextSize: 12,
        confirmButtonRadius: s(10),
        editDialogInsetHorizontal: s(36),
        editDialogInsetVertical: v(24),
        editDialogMinWidth: (size.width * 0.58).clamp(420.0, 620.0).toDouble(),
        editDialogMaxWidth: dialogMaxWidth,
      );
    }

    if (isWideShortPhone) {
      return const _CtInqueryBoxMetrics(
        cardBottomGap: 16,
        cardRadius: 16,
        cardShadowBlur: 8,
        cardPadding: 16,
        idTextSize: 17,
        idBottomGap: 8,
        infoRowBottomGap: 8,
        infoIconSize: 15,
        infoIconGap: 5,
        infoTextSize: 13,
        expiryColumnGap: 8,
        expiryTextSize: 9,
        expiryTextGap: 4,
        statusTopGap: 16,
        statusIconSize: 13,
        statusIconGap: 5,
        statusTextSize: 10,
        statusTextWidth: 58,
        actionLeadingGap: 5,
        withdrawButtonWidth: 72,
        withdrawButtonHeight: 32,
        withdrawButtonTextSize: 10,
        withdrawButtonRadius: 5,
        confirmDialogInsetHorizontal: 24,
        confirmDialogInsetVertical: 18,
        confirmDialogMaxWidth: 360,
        confirmDialogRadius: 10,
        confirmDialogHorizontalPadding: 24,
        confirmDialogVerticalPadding: 18,
        confirmTextSize: 11,
        confirmTextLineSpacing: 1.4,
        confirmGap: 16,
        confirmButtonHeight: 28,
        confirmButtonGap: 8,
        confirmButtonTextSize: 10,
        confirmButtonRadius: 8,
        editDialogInsetHorizontal: 20,
        editDialogInsetVertical: 18,
        editDialogMinWidth: 300,
        editDialogMaxWidth: 460,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _CtInqueryBoxMetrics(
        cardBottomGap: s(16),
        cardRadius: s(16),
        cardShadowBlur: s(8),
        cardPadding: s(15),
        idTextSize: s(17),
        idBottomGap: s(8),
        infoRowBottomGap: s(8),
        infoIconSize: s(15),
        infoIconGap: s(5),
        infoTextSize: s(13),
        expiryColumnGap: s(8),
        expiryTextSize: s(9),
        expiryTextGap: s(4),
        statusTopGap: s(16),
        statusIconSize: s(13),
        statusIconGap: s(5),
        statusTextSize: s(10),
        statusTextWidth: s(58),
        actionLeadingGap: s(5),
        withdrawButtonWidth: s(72),
        withdrawButtonHeight: s(32),
        withdrawButtonTextSize: s(10),
        withdrawButtonRadius: s(5),
        confirmDialogInsetHorizontal: s(20),
        confirmDialogInsetVertical: s(16),
        confirmDialogMaxWidth: double.infinity,
        confirmDialogRadius: s(10),
        confirmDialogHorizontalPadding: s(22),
        confirmDialogVerticalPadding: s(18),
        confirmTextSize: s(11),
        confirmTextLineSpacing: 1.4,
        confirmGap: s(16),
        confirmButtonHeight: s(28),
        confirmButtonGap: s(8),
        confirmButtonTextSize: s(10),
        confirmButtonRadius: s(8),
        editDialogInsetHorizontal: s(18),
        editDialogInsetVertical: s(16),
        editDialogMinWidth: s(280),
        editDialogMaxWidth: size.width - s(36),
      );
    }

    return _CtInqueryBoxMetrics(
      cardBottomGap: 20,
      cardRadius: 20.r,
      cardShadowBlur: 10,
      cardPadding: 20.w,
      idTextSize: 20,
      idBottomGap: 10.h,
      infoRowBottomGap: 10.h,
      infoIconSize: 18.w,
      infoIconGap: 5.w,
      infoTextSize: 15.sp,
      expiryColumnGap: 10.w,
      expiryTextSize: 10,
      expiryTextGap: 5,
      statusTopGap: 20.h,
      statusIconSize: 15.w,
      statusIconGap: 5.w,
      statusTextSize: 11,
      statusTextWidth: 64.w,
      actionLeadingGap: 5.w,
      withdrawButtonWidth: 80.w,
      withdrawButtonHeight: 35.h,
      withdrawButtonTextSize: 11,
      withdrawButtonRadius: 5,
      confirmDialogInsetHorizontal: 24.w,
      confirmDialogInsetVertical: 20.h,
      confirmDialogMaxWidth: double.infinity,
      confirmDialogRadius: 10.r,
      confirmDialogHorizontalPadding: 30.w,
      confirmDialogVerticalPadding: 20.h,
      confirmTextSize: 12,
      confirmTextLineSpacing: 1.5,
      confirmGap: 20.h,
      confirmButtonHeight: 30.h,
      confirmButtonGap: 10.w,
      confirmButtonTextSize: 11,
      confirmButtonRadius: 10,
      editDialogInsetHorizontal: 24.w,
      editDialogInsetVertical: 20.h,
      editDialogMinWidth: (MediaQuery.sizeOf(context).width - 48.w)
          .clamp(280.0, 600.0)
          .toDouble(),
      editDialogMaxWidth: 600,
    );
  }
}
