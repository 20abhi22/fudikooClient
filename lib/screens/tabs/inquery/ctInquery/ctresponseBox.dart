import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/inquery/response_model.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class CtResponseBox extends StatefulWidget {
  final ResponseModel response;
  final VoidCallback onCancelTap;
  final VoidCallback onAcceptTap;
  final VoidCallback viewRequestClick;
  const CtResponseBox({
    super.key,
    required this.response,
    required this.onCancelTap,
    required this.onAcceptTap,
    required this.viewRequestClick,
  });

  @override
  State<CtResponseBox> createState() => _CtResponseBoxState();
}

class _CtResponseBoxState extends State<CtResponseBox> {
  bool _isDeclineLoading = false;

  Future<void> _showDeclineDialog(BuildContext context) async {
    final metrics = _CtResponseBoxMetrics.fromContext(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: metrics.confirmDialogInsetHorizontal,
          vertical: metrics.confirmDialogInsetVertical,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.confirmDialogRadius),
        ),
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
                  text: 'Are you sure you want to decline this enquiry?',
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
                            _declineResponse(context);
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

  Future<void> _declineResponse(BuildContext context) async {
    if (_isDeclineLoading) return;

    setState(() => _isDeclineLoading = true);

    final String responseId = widget.response.uuid;

    final result = await InqueryService().declineCateringEnquiry(responseId);

    if (!context.mounted || !mounted) return;

    showStatusSnack(
      context,
      result['status'] == true,
      result['status'] == true
          ? (result['message']?.toString() ??
                'Enquiry response declined successfully')
          : (result['message']?.toString() ?? 'Something went wrong'),
    );

    if (result['status'] == true) {
      widget.onCancelTap();
    }

    if (mounted) {
      setState(() => _isDeclineLoading = false);
    }
  }

  String _formatDateLabel() {
    if (widget.response.createdAt != null) {
      return DateFormat('MMM d').format(widget.response.createdAt!);
    }
    if (widget.response.date.isNotEmpty) {
      final parsed = DateTime.tryParse(widget.response.date);
      if (parsed != null) {
        return DateFormat('MMM d').format(parsed);
      }
      return widget.response.date;
    }
    return '';
  }

  String _formatTimeLabel() {
    if (widget.response.time.isNotEmpty) return widget.response.time;
    if (widget.response.createdAt != null) {
      return DateFormat(
        'h:mma',
      ).format(widget.response.createdAt!).toLowerCase();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _CtResponseBoxMetrics.fromContext(context);
    final bool canAct = widget.response.status.trim().toLowerCase() == 'active';

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
                            widget.response.restaurantName.isNotEmpty
                                ? widget.response.restaurantName
                                : 'Catering Service',
                            FontWeight.w700,
                            appLinkColor2.withValues(alpha: .9),
                          ),
                        ]),
                        SizedBox(height: metrics.rowGap),
                        _richRow(context, walletIcon, [
                          _span(
                            context,
                            '${widget.response.pricePerPerson} ',
                            FontWeight.w700,
                            appTextColor5,
                          ),
                          _span(
                            context,
                            'Per Person',
                            FontWeight.w500,
                            appTextColor5,
                          ),
                        ]),
                        SizedBox(height: metrics.rowGap),
                        _richRow(context, offerIcon, [
                          _span(
                            context,
                            widget.response.discount.isNotEmpty
                                ? widget.response.discount
                                : 'No offer added',
                            FontWeight.w500,
                            appTextColor5,
                          ),
                        ]),
                        SizedBox(height: metrics.rowGap),
                        _richRow(context, commentIcon, [
                          _span(
                            context,
                            widget.response.message.isNotEmpty
                                ? widget.response.message
                                : 'No comments provided',
                            FontWeight.w700,
                            appTextColor5,
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
                        text: _formatDateLabel(),
                        size: metrics.expiryTextSize,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: metrics.expiryTextGap),
                      AppText(
                        text: _formatTimeLabel(),
                        size: metrics.expiryTextSize,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: metrics.actionsTopGap),
              LayoutBuilder(
                builder: (context, constraints) {
                  final viewRequest = _viewRequestLink(context);
                  final actionButtons = _actionButtons(context);

                  if (constraints.maxWidth < metrics.actionsStackBreakpoint) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        viewRequest,
                        if (canAct) ...[
                          SizedBox(height: metrics.actionsStackGap),
                          Align(
                            alignment: Alignment.centerRight,
                            child: actionButtons,
                          ),
                        ],
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [viewRequest, if (canAct) actionButtons],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewRequestLink(BuildContext context) {
    final metrics = _CtResponseBoxMetrics.fromContext(context);

    return GestureDetector(
      onTap: widget.viewRequestClick,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            fit: BoxFit.cover,
            detailsIcon,
            width: metrics.detailIconSize,
            height: metrics.detailIconSize,
          ),
          SizedBox(width: metrics.detailIconGap),
          AppText(
            text: 'View Request',
            size: metrics.detailTextSize,
            fontWeight: FontWeight.w400,
            color: requestLinkColor,
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    final metrics = _CtResponseBoxMetrics.fromContext(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: metrics.actionButtonWidth,
          height: metrics.actionButtonHeight,
          child: _ConfirmActionButton(
            isLoading: _isDeclineLoading,
            text: 'Decline',
            textSize: metrics.actionButtonTextSize,
            radius: metrics.actionButtonRadius,
            color: const Color(0xFFCE3F3F),
            onTap: () => _showDeclineDialog(context),
          ),
        ),
        SizedBox(width: metrics.actionButtonGap),
        SizedBox(
          width: metrics.actionButtonWidth,
          height: metrics.actionButtonHeight,
          child: AppButton(
            text: 'Accept',
            onPressed: _isDeclineLoading ? null : widget.onAcceptTap,
            size: metrics.actionButtonTextSize,
            borderRadius: metrics.actionButtonRadius,
            bgColor1: const Color(0xFF73B256),
            bgColor2: const Color(0xFF73B256),
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
    final metrics = _CtResponseBoxMetrics.fromContext(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIcon,
          width: metrics.infoIconSize,
          height: metrics.infoIconSize,
          color: const Color.fromARGB(255, 15, 15, 15),
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
    final metrics = _CtResponseBoxMetrics.fromContext(context);

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

class _CtResponseBoxMetrics {
  const _CtResponseBoxMetrics({
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
    required this.actionsStackBreakpoint,
    required this.actionsStackGap,
    required this.detailIconSize,
    required this.detailIconGap,
    required this.detailTextSize,
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
  final double actionsStackBreakpoint;
  final double actionsStackGap;
  final double detailIconSize;
  final double detailIconGap;
  final double detailTextSize;
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

  factory _CtResponseBoxMetrics.fromContext(BuildContext context) {
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

      return _CtResponseBoxMetrics(
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
        actionsStackBreakpoint: s(330),
        actionsStackGap: v(12),
        detailIconSize: s(17),
        detailIconGap: s(7),
        detailTextSize: 13,
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
      return const _CtResponseBoxMetrics(
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
        actionsStackBreakpoint: 300,
        actionsStackGap: 10,
        detailIconSize: 13,
        detailIconGap: 5,
        detailTextSize: 11,
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

      return _CtResponseBoxMetrics(
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
        actionsStackBreakpoint: s(300),
        actionsStackGap: s(10),
        detailIconSize: s(13),
        detailIconGap: s(5),
        detailTextSize: s(11),
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

    return _CtResponseBoxMetrics(
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
      expiryTextSize: 10,
      expiryTextGap: 5.h,
      actionsTopGap: 20.h,
      actionsStackBreakpoint: 300.w,
      actionsStackGap: 10.h,
      detailIconSize: 15.w,
      detailIconGap: 5.w,
      detailTextSize: 12,
      actionButtonWidth: 80.w,
      actionButtonHeight: 28.h,
      actionButtonTextSize: 12,
      actionButtonRadius: 5.r,
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
