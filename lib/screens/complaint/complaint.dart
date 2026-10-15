import 'package:flutter/material.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/service/complaint/complaint_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _complaintController = TextEditingController();
  final ComplaintService _complaintService = ComplaintService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    final complaint = _complaintController.text.trim();
    if (complaint.isEmpty || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _complaintService.registerComplaint(complaint);

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    showSuccessSnack(
      context,
      success
          ? 'Complaint submitted successfully.'
          : 'Unable to submit complaint. Please try again.',
    );

    if (success) {
      _complaintController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final metrics = _ComplaintLayoutMetrics.fromConstraints(
                  context: context,
                  constraints: constraints,
                  orientation: orientation,
                );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.pageHorizontalPadding,
                    vertical: metrics.pageVerticalPadding,
                  ),
                  child: metrics.isLandscape
                      ? _buildLandscape(context, metrics)
                      : _buildPortrait(context, metrics),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackButton(_ComplaintLayoutMetrics metrics) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Image.asset(
        backOrange,
        width: metrics.backSize,
        height: metrics.backSize,
      ),
    );
  }

  Widget _buildSubmitButton(_ComplaintLayoutMetrics metrics) {
    return Center(
      child: SizedBox(
        width: metrics.buttonWidth,
        height: metrics.buttonHeight,
        child: AppButton(
          text: 'Submit',
          onPressed: _submitComplaint,
          size: metrics.buttonTextSize,
          borderRadius: metrics.buttonRadius,
          isLoading: _isSubmitting,
        ),
      ),
    );
  }

  // Portrait: back button floats above a single scrolling column, same as before.
  Widget _buildPortrait(BuildContext context, _ComplaintLayoutMetrics metrics) {
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: metrics.backTop + metrics.backSize + metrics.headerGap,
              bottom: metrics.bottomPadding,
            ),
            child: FractionallySizedBox(
              widthFactor: metrics.contentWidthFactor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text:
                        'If you encounter any issues or have a complaint, please register it below. Provide as much detail as possible so we can assist you promptly and effectively. Your feedback helps us improve your experience with Fudikoo.',
                    size: metrics.bodySize,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                    lineSpacing: 1.5,
                    softWrap: true,
                    maxLines: 10,
                  ),
                  SizedBox(height: metrics.formTopGap),
                  DescriptionTextArea(
                    hintText: 'Write your complaint briefly',
                    maxLength: 300,
                    maxLines: metrics.textAreaLines,
                    controller: _complaintController,
                  ),
                  SizedBox(height: metrics.buttonTopGap),
                  _buildSubmitButton(metrics),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: metrics.backTop,
          left: 0,
          child: _buildBackButton(metrics),
        ),
      ],
    );
  }

  // Landscape: two columns side by side so height is never the bottleneck.
  // Left = back button + intro copy. Right = text area + submit, filling
  // the available height instead of stacking below a tall paragraph.
  Widget _buildLandscape(
    BuildContext context,
    _ComplaintLayoutMetrics metrics,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: metrics.leftFlex,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBackButton(metrics),
                SizedBox(height: metrics.headerGap),
                AppText(
                  text:
                      'If you encounter any issues or have a complaint, please register it below. Provide as much detail as possible so we can assist you promptly and effectively. Your feedback helps us improve your experience with Fudikoo.',
                  size: metrics.bodySize,
                  fontWeight: FontWeight.w400,
                  color: appTextColor2,
                  lineSpacing: 1.5,
                  softWrap: true,
                  maxLines: 12,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: metrics.columnGap),
        Expanded(
          flex: metrics.rightFlex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // DescriptionTextArea only fills available space when given an
              // explicit `height` (it switches internally to expands: true).
              // Measure the space with LayoutBuilder and feed it in, rather
              // than guessing a maxLines count for every landscape size.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, textAreaConstraints) {
                    return DescriptionTextArea(
                      hintText: 'Write your complaint briefly',
                      maxLength: 300,
                      height: textAreaConstraints.maxHeight,
                      controller: _complaintController,
                    );
                  },
                ),
              ),
              SizedBox(height: metrics.buttonTopGap),
              _buildSubmitButton(metrics),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComplaintLayoutMetrics {
  const _ComplaintLayoutMetrics({
    required this.pageHorizontalPadding,
    required this.pageVerticalPadding,
    required this.contentWidthFactor,
    required this.bottomPadding,
    required this.backTop,
    required this.backSize,
    required this.headerGap,
    required this.formTopGap,
    required this.buttonTopGap,
    required this.bodySize,
    required this.textAreaLines,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.buttonTextSize,
    required this.buttonRadius,
    required this.isTablet,
    required this.isLandscape,
    required this.leftFlex,
    required this.rightFlex,
    required this.columnGap,
  });

  final double pageHorizontalPadding;
  final double pageVerticalPadding;
  final double contentWidthFactor;
  final double bottomPadding;
  final double backTop;
  final double backSize;
  final double headerGap;
  final double formTopGap;
  final double buttonTopGap;
  final double bodySize;
  final int textAreaLines;
  final double buttonWidth;
  final double buttonHeight;
  final double buttonTextSize;
  final double buttonRadius;
  final bool isTablet;
  final bool isLandscape;
  final int leftFlex;
  final int rightFlex;
  final double columnGap;

  factory _ComplaintLayoutMetrics.fromConstraints({
    required BuildContext context,
    required BoxConstraints constraints,
    required Orientation orientation,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = orientation == Orientation.landscape;
    final isCompactPhone = width < 390 || height < 640;
    final isCompactLandscape = isLandscape && height < 500;
    final isTablet = Breakpoints.isTabletDevice(size);
    final isTabletLandscape = isTablet && isLandscape;

    final pageHorizontalPadding = isTablet
        ? (isLandscape ? width * 0.05 : width * 0.08)
        : isLandscape
        ? width * 0.05
        : isCompactPhone
        ? width * 0.06
        : width * 0.075;

    final pageVerticalPadding = isLandscape
        ? (isCompactLandscape ? 8.0 : 14.0)
        : 0.0;

    return _ComplaintLayoutMetrics(
      pageHorizontalPadding: pageHorizontalPadding,
      pageVerticalPadding: pageVerticalPadding,
      contentWidthFactor: isTablet ? (isTabletLandscape ? 0.56 : 0.7) : 1.0,
      bottomPadding: isTablet
          ? (isLandscape
                ? AppDimensions.gap(context)
                : AppDimensions.margin(context))
          : isCompactPhone
          ? 20.0
          : 24.0,
      backTop: isTablet
          ? (isLandscape ? 0.0 : 36.0)
          : isLandscape
          ? 0.0
          : isCompactPhone
          ? 22.0
          : 40.0,
      backSize: isTablet
          ? (isLandscape ? 28.0 : 34.0)
          : isCompactLandscape
          ? 24.0
          : isLandscape
          ? 26.0
          : isCompactPhone
          ? 26.0
          : 30.0,
      headerGap: isTablet
          ? (isLandscape
                ? AppDimensions.gap(context) * 0.75
                : AppDimensions.gap(context) * 1.25)
          : isLandscape
          ? (isCompactLandscape ? 10.0 : 14.0)
          : 20.0,
      formTopGap: isTablet
          ? (isLandscape ? 40.0 : 58.0)
          : isCompactPhone
          ? 36.0
          : 50.0,
      buttonTopGap: isTablet
          ? (isLandscape ? 20.0 : 44.0)
          : isLandscape
          ? (isCompactLandscape ? 10.0 : 14.0)
          : 30.0,
      bodySize: isTablet
          ? (isLandscape
                ? AppDimensions.body(context) * 0.95 + 2
                : AppDimensions.body(context) + 3)
          : isCompactLandscape
          ? 12.5
          : isLandscape
          ? 13.5
          : isCompactPhone
          ? 14.0
          : 15.0,
      // Only used in portrait — landscape passes an explicit `height` to
      // DescriptionTextArea instead (see _buildLandscape), so it fills the
      // available space rather than being sized by a guessed line count.
      textAreaLines: isTablet
          ? 18
          : isCompactPhone
          ? 13
          : 15,
      buttonWidth: isTablet
          ? (isLandscape ? 260.0 : 320.0)
          : isLandscape
          ? 170.0
          : isCompactPhone
          ? 180.0
          : 200.0,
      buttonHeight: isTablet
          ? (isLandscape ? 46.0 : 52.0)
          : isLandscape
          ? (isCompactLandscape ? 36.0 : 40.0)
          : 40.0,
      buttonTextSize: isTablet
          ? (isLandscape
                ? AppDimensions.body(context) * 0.95 + 1
                : AppDimensions.body(context) + 2)
          : isCompactLandscape
          ? 13.0
          : isLandscape
          ? 14.0
          : isCompactPhone
          ? 14.0
          : 15.0,
      buttonRadius: isTablet ? (isLandscape ? 14.0 : 16.0) : 10.0,
      isTablet: isTablet,
      isLandscape: isLandscape,
      leftFlex: isTablet ? 5 : 4,
      rightFlex: isTablet ? 6 : 6,
      columnGap: isTablet ? 32.0 : (isCompactLandscape ? 16.0 : 24.0),
    );
  }
}
