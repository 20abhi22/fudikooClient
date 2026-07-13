import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/inquery/response_model.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class DeclineBox extends StatefulWidget {
  final Future<void> Function() onCancelTap;
  final Future<void> Function()? onRestoreTap;
  final ResponseModel response;

  const DeclineBox({
    super.key,
    required this.onCancelTap,
    required this.response,
    this.onRestoreTap,
  });

  @override
  State<DeclineBox> createState() => _DeclineBoxState();
}

class _DeclineBoxState extends State<DeclineBox> {
  bool _isDeleting = false;
  bool _isRestoring = false;

  Future<void> _deleteDeclinedResponse() async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);
    await widget.onCancelTap();

    if (!mounted) return;
    setState(() => _isDeleting = false);
  }

  Future<void> _restoreDeclinedResponse() async {
    if (_isRestoring || widget.onRestoreTap == null) return;

    setState(() => _isRestoring = true);
    await widget.onRestoreTap?.call();

    if (!mounted) return;
    setState(() => _isRestoring = false);
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    final metrics = _DeclineBoxMetrics.fromContext(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: metrics.confirmDialogInsetHorizontal,
          vertical: metrics.confirmDialogInsetVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.confirmDialogRadius),
        ),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: metrics.confirmDialogMaxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.confirmDialogHorizontalPadding,
              vertical: metrics.confirmDialogVerticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  text: 'Are you sure you want to restore this enquiry?',
                  isCentered: true,
                  lineSpacing: metrics.confirmTextLineSpacing,
                  size: metrics.confirmTextSize,
                  fontWeight: FontWeight.w500,
                  color: appTextColor2,
                ),
                SizedBox(height: metrics.confirmGap),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: metrics.confirmButtonHeight,
                        child: AppButton(
                          text: 'Yes',
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _restoreDeclinedResponse();
                          },
                          size: metrics.confirmButtonTextSize,
                          bgColor1: const Color(0xFF73B256),
                          bgColor2: const Color(0xFF73B256),
                          borderRadius: metrics.confirmButtonRadius,
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.confirmButtonGap),
                    Expanded(
                      child: SizedBox(
                        height: metrics.confirmButtonHeight,
                        child: AppButton(
                          text: 'No',
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          size: metrics.confirmButtonTextSize,
                          bgColor1: const Color(0xFFCE3F3F),
                          bgColor2: const Color(0xFFCE3F3F),
                          borderRadius: metrics.confirmButtonRadius,
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
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final metrics = _DeclineBoxMetrics.fromContext(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: metrics.confirmDialogInsetHorizontal,
          vertical: metrics.confirmDialogInsetVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.confirmDialogRadius),
        ),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: metrics.confirmDialogMaxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.confirmDialogHorizontalPadding,
              vertical: metrics.confirmDialogVerticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  text: 'Are you sure you want to delete this enquiry?',
                  isCentered: true,
                  lineSpacing: metrics.confirmTextLineSpacing,
                  size: metrics.confirmTextSize,
                  fontWeight: FontWeight.w500,
                  color: appTextColor2,
                ),
                SizedBox(height: metrics.confirmGap),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: metrics.confirmButtonHeight,
                        child: AppButton(
                          text: 'Yes',
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            _deleteDeclinedResponse();
                          },
                          size: metrics.confirmButtonTextSize,
                          bgColor1: const Color(0xFF73B256),
                          bgColor2: const Color(0xFF73B256),
                          borderRadius: metrics.confirmButtonRadius,
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.confirmButtonGap),
                    Expanded(
                      child: SizedBox(
                        height: metrics.confirmButtonHeight,
                        child: AppButton(
                          text: 'No',
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          size: metrics.confirmButtonTextSize,
                          bgColor1: const Color(0xFFCE3F3F),
                          bgColor2: const Color(0xFFCE3F3F),
                          borderRadius: metrics.confirmButtonRadius,
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
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _DeclineBoxMetrics.fromContext(context);
    final DateTime parsedDate =
        DateTime.tryParse(widget.response.date) ?? DateTime.now();
    final String displayDate = DateFormat('MMM d').format(parsedDate);

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
                          text: widget.response.couponId,
                          size: metrics.idTextSize,
                          fontWeight: FontWeight.bold,
                          color: appTextColor3,
                        ),
                        SizedBox(height: metrics.idBottomGap),
                        _richRow(context, shopIcon, [
                          _span(
                            context,
                            widget.response.restaurantName,
                            FontWeight.w500,
                            restoLinkColor.withValues(alpha: .9),
                          ),
                        ]),
                        SizedBox(height: metrics.rowGap),
                        _richRow(context, walletIcon, [
                          _span(
                            context,
                            '${widget.response.pricePerPerson} ',
                            FontWeight.w400,
                            appTextColor5,
                          ),
                          _span(
                            context,
                            'Per Person',
                            FontWeight.w400,
                            appTextColor5,
                          ),
                        ]),
                        SizedBox(height: metrics.rowGap),
                        _richRow(context, offerIcon, [
                          _span(
                            context,
                            widget.response.discount,
                            FontWeight.w400,
                            appTextColor5,
                          ),
                        ]),
                        SizedBox(height: metrics.rowGap),
                        _richRow(context, commentIcon, [
                          _span(
                            context,
                            widget.response.message,
                            FontWeight.w400,
                            Colors.black,
                          ),
                        ]),
                      ],
                    ),
                  ),
                  SizedBox(width: metrics.expiryColumnGap),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: displayDate,
                        size: metrics.expiryTextSize,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: metrics.expiryTextGap),
                      AppText(
                        text: widget.response.time,
                        size: metrics.expiryTextSize,
                        fontWeight: FontWeight.w400,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: metrics.actionsTopGap),
              Align(
                alignment: Alignment.centerRight,
                child: _actionButtons(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    final metrics = _DeclineBoxMetrics.fromContext(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: metrics.actionButtonWidth,
          height: metrics.actionButtonHeight,
          child: _LoadingActionButton(
            text: "Delete",
            isLoading: _isDeleting,
            isDisabled: _isRestoring,
            textSize: metrics.actionButtonTextSize,
            radius: metrics.actionButtonRadius,
            color: const Color(0xFFCE3F3F),
            onTap: () => _showDeleteDialog(context),
          ),
        ),
        SizedBox(width: metrics.actionButtonGap),
        SizedBox(
          width: metrics.actionButtonWidth,
          height: metrics.actionButtonHeight,
          child: _LoadingActionButton(
            text: "Restore",
            isLoading: _isRestoring,
            isDisabled: widget.onRestoreTap == null || _isDeleting,
            textSize: metrics.actionButtonTextSize,
            radius: metrics.actionButtonRadius,
            color: const Color(0xFF4662EC),
            onTap: () => _showRestoreDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _richRow(
    BuildContext context,
    String imageIcon,
    List<TextSpan> spans,
  ) {
    final metrics = _DeclineBoxMetrics.fromContext(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIcon,
          color: appTextColor5,
          height: metrics.infoIconSize,
          width: metrics.infoIconSize,
        ),
        SizedBox(width: metrics.infoIconGap),
        Expanded(
          child: RichText(
            softWrap: true,
            overflow: TextOverflow.visible,
            text: TextSpan(children: spans),
          ),
        ),
      ],
    );
  }

  TextSpan _span(
    BuildContext context,
    String text,
    FontWeight weight,
    Color color,
  ) {
    final metrics = _DeclineBoxMetrics.fromContext(context);

    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: metrics.infoTextSize,
        fontWeight: weight,
        color: color,
      ),
    );
  }
}

class _LoadingActionButton extends StatelessWidget {
  const _LoadingActionButton({
    required this.text,
    required this.isLoading,
    required this.isDisabled,
    required this.textSize,
    required this.radius,
    required this.color,
    required this.onTap,
  });

  final String text;
  final bool isLoading;
  final bool isDisabled;
  final double textSize;
  final double radius;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || isDisabled;

    return Material(
      color: disabled && !isLoading ? color.withValues(alpha: 0.55) : color,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: disabled ? null : onTap,
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
  Timer? _timer;
  int _activeDot = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 220), (_) {
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _activeDot;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isActive ? 5 : 4,
          height: isActive ? 5 : 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isActive ? 1 : 0.45),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _DeclineBoxMetrics {
  const _DeclineBoxMetrics({
    required this.cardBottomGap,
    required this.cardRadius,
    required this.cardShadowBlur,
    required this.cardPadding,
    required this.idTextSize,
    required this.idBottomGap,
    required this.rowGap,
    required this.infoIconSize,
    required this.infoIconGap,
    required this.infoTextSize,
    required this.expiryColumnGap,
    required this.expiryTextSize,
    required this.expiryTextGap,
    required this.actionsTopGap,
    required this.actionButtonWidth,
    required this.actionButtonHeight,
    required this.actionButtonTextSize,
    required this.actionButtonRadius,
    required this.actionButtonGap,
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
    required this.confirmButtonTextSize,
    required this.confirmButtonRadius,
    required this.confirmButtonGap,
  });

  final double cardBottomGap;
  final double cardRadius;
  final double cardShadowBlur;
  final double cardPadding;
  final double idTextSize;
  final double idBottomGap;
  final double rowGap;
  final double infoIconSize;
  final double infoIconGap;
  final double infoTextSize;
  final double expiryColumnGap;
  final double expiryTextSize;
  final double expiryTextGap;
  final double actionsTopGap;
  final double actionButtonWidth;
  final double actionButtonHeight;
  final double actionButtonTextSize;
  final double actionButtonRadius;
  final double actionButtonGap;
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
  final double confirmButtonTextSize;
  final double confirmButtonRadius;
  final double confirmButtonGap;

  factory _DeclineBoxMetrics.fromContext(BuildContext context) {
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

      return _DeclineBoxMetrics(
        cardBottomGap: v(24),
        cardRadius: s(22),
        cardShadowBlur: s(12),
        cardPadding: s(24),
        idTextSize: 21,
        idBottomGap: v(12),
        rowGap: v(11),
        infoIconSize: s(20),
        infoIconGap: s(7),
        infoTextSize: 16,
        expiryColumnGap: s(14),
        expiryTextSize: 11,
        expiryTextGap: v(5),
        actionsTopGap: v(24),
        actionButtonWidth: s(98),
        actionButtonHeight: v(34),
        actionButtonTextSize: 13,
        actionButtonRadius: s(6),
        actionButtonGap: s(12),
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
        confirmButtonTextSize: 12,
        confirmButtonRadius: s(10),
        confirmButtonGap: s(12),
      );
    }

    if (isWideShortPhone) {
      return const _DeclineBoxMetrics(
        cardBottomGap: 16,
        cardRadius: 16,
        cardShadowBlur: 8,
        cardPadding: 16,
        idTextSize: 17,
        idBottomGap: 8,
        rowGap: 8,
        infoIconSize: 15,
        infoIconGap: 5,
        infoTextSize: 13,
        expiryColumnGap: 8,
        expiryTextSize: 9,
        expiryTextGap: 4,
        actionsTopGap: 16,
        actionButtonWidth: 72,
        actionButtonHeight: 30,
        actionButtonTextSize: 10.5,
        actionButtonRadius: 5,
        actionButtonGap: 8,
        confirmDialogInsetHorizontal: 24,
        confirmDialogInsetVertical: 18,
        confirmDialogMaxWidth: 360,
        confirmDialogRadius: 10,
        confirmDialogHorizontalPadding: 24,
        confirmDialogVerticalPadding: 18,
        confirmTextSize: 11,
        confirmTextLineSpacing: 1.4,
        confirmGap: 16,
        confirmButtonHeight: 30,
        confirmButtonTextSize: 10.5,
        confirmButtonRadius: 10,
        confirmButtonGap: 10,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _DeclineBoxMetrics(
        cardBottomGap: s(16),
        cardRadius: s(16),
        cardShadowBlur: s(8),
        cardPadding: s(15),
        idTextSize: s(17),
        idBottomGap: s(8),
        rowGap: s(8),
        infoIconSize: s(15),
        infoIconGap: s(5),
        infoTextSize: s(13),
        expiryColumnGap: s(8),
        expiryTextSize: s(9),
        expiryTextGap: s(4),
        actionsTopGap: s(16),
        actionButtonWidth: s(72),
        actionButtonHeight: s(30),
        actionButtonTextSize: s(10.5),
        actionButtonRadius: s(5),
        actionButtonGap: s(8),
        confirmDialogInsetHorizontal: s(20),
        confirmDialogInsetVertical: s(16),
        confirmDialogMaxWidth: double.infinity,
        confirmDialogRadius: s(10),
        confirmDialogHorizontalPadding: s(22),
        confirmDialogVerticalPadding: s(18),
        confirmTextSize: s(11),
        confirmTextLineSpacing: 1.4,
        confirmGap: s(16),
        confirmButtonHeight: s(30),
        confirmButtonTextSize: s(10.5),
        confirmButtonRadius: s(10),
        confirmButtonGap: s(10),
      );
    }

    return _DeclineBoxMetrics(
      cardBottomGap: 20.h,
      cardRadius: 20.r,
      cardShadowBlur: 10,
      cardPadding: 20.w,
      idTextSize: 20,
      idBottomGap: 10.h,
      rowGap: 10.h,
      infoIconSize: 18.w,
      infoIconGap: 5.w,
      infoTextSize: 15,
      expiryColumnGap: 10.w,
      expiryTextSize: 11,
      expiryTextGap: 5.h,
      actionsTopGap: 20.h,
      actionButtonWidth: 80.w,
      actionButtonHeight: 26.h,
      actionButtonTextSize: 12,
      actionButtonRadius: 5,
      actionButtonGap: 10.w,
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
      confirmButtonTextSize: 11,
      confirmButtonRadius: 10,
      confirmButtonGap: 10.w,
    );
  }
}
