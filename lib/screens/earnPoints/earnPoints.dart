import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fudikoclient/service/invite/referral_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/utils/constants.dart';

class EarnPoints extends StatefulWidget {
  const EarnPoints({super.key});

  @override
  State<EarnPoints> createState() => _EarnPointsState();
}

class _EarnPointsState extends State<EarnPoints> {
  static const List<String> _steps = [
    'Share your unique invite link.',
    'Your friend signs up using your link.',
    'You both get rewarded - you earn 15 points!',
  ];

  final ReferralService _referralService = ReferralService();
  String? _referralLink;

  @override
  void initState() {
    super.initState();
    _fetchReferralLink();
  }

  Future<void> _fetchReferralLink() async {
    final result = await _referralService.getReferralLink();
    if (!mounted) return;
    setState(() {
      _referralLink = result?.referralLink;
    });
  }

  Future<void> _shareReferralLink() async {
    final link = _referralLink;
    if (link == null || link.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: link));
    await Share.share(link);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final metrics = _EarnPointsLayoutMetrics.fromConstraints(
                  context: context,
                  constraints: constraints,
                  orientation: orientation,
                );

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _EarnHero(metrics: metrics),
                        _EarnContent(
                          metrics: metrics,
                          referralLink: _referralLink,
                          onShare: _shareReferralLink,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EarnContent extends StatelessWidget {
  const _EarnContent({
    required this.metrics,
    required this.referralLink,
    required this.onShare,
  });

  final _EarnPointsLayoutMetrics metrics;
  final String? referralLink;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.contentHorizontalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: metrics.contentTopGap),
          Image.asset(
            'assets/images/earnMoney.png',
            height: metrics.moneyImageSize,
            width: metrics.moneyImageSize,
            fit: BoxFit.contain,
          ),
          SizedBox(height: metrics.titleGap),
          AppText(
            text: 'Invite Your Friends & Earn',
            size: metrics.titleSize,
            fontWeight: FontWeight.w500,
            isCentered: true,
            color: appTextColor,
          ),
          SizedBox(height: metrics.smallGap),
          AppText(
            text: '15 Points Each!',
            size: metrics.titleSize,
            fontWeight: FontWeight.w500,
            isCentered: true,
            color: appTextColor,
          ),
          SizedBox(height: metrics.sectionGap),
          AppText(
            text:
                "Get rewarded for sharing the love! For every friend you invite who signs up, you'll earn 15 points - no limits, no catch.",
            size: metrics.bodySize,
            fontWeight: FontWeight.w400,
            isCentered: true,
            color: appTextColor2,
            lineSpacing: 1.2,
          ),
          SizedBox(height: metrics.titleGap),
          Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              text: "Here's how it works:",
              size: metrics.captionSize,
              fontWeight: FontWeight.w500,
              color: appTextColor2,
            ),
          ),
          SizedBox(height: metrics.smallGap),
          for (final step in _EarnPointsState._steps) ...[
            _InviteStep(text: step, metrics: metrics),
            SizedBox(height: metrics.smallGap),
          ],
          SizedBox(height: metrics.titleGap),
          if (metrics.showButton)
            SizedBox(
              width: metrics.buttonWidth,
              height: metrics.buttonHeight,
              child: AppButton(
                text: 'Share Your Link',
                onPressed: referralLink == null ? null : onShare,
                isLoading: referralLink == null,
                bgColor1: appLinkColor2,
                bgColor2: appLinkColor2,
                size: metrics.buttonTextSize,
                borderRadius: metrics.buttonRadius,
              ),
            ),
          if (metrics.showButton) SizedBox(height: metrics.bottomGap),
        ],
      ),
    );

    if (metrics.isTablet) {
      return Center(child: content);
    }

    return content;
  }
}

class _EarnHero extends StatelessWidget {
  const _EarnHero({required this.metrics});

  final _EarnPointsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: metrics.heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/earnPoints.png',
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          Positioned(
            bottom: metrics.heroTextBottom,
            left: metrics.heroHorizontalPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: 'Earn',
                  size: metrics.heroEarnSize,
                  fontWeight: FontWeight.w600,
                  color: appTextColor2,
                ),
                AppText(
                  text: 'Unlimited',
                  size: metrics.heroUnlimitedSize,
                  fontWeight: FontWeight.w600,
                  color: appTextColor2,
                ),
                AppText(
                  text: 'Points!!',
                  size: metrics.heroPointsSize,
                  fontWeight: FontWeight.w600,
                  color: appTextColor2,
                ),
              ],
            ),
          ),
          Positioned(
            // This hero draws beneath the status bar, unlike the change
            // password screen. Include the inset to keep both back buttons
            // at the same on-screen height.
            top: MediaQuery.paddingOf(context).top + metrics.backTop,
            left: metrics.backLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset(
                backOrange,
                height: metrics.backSize,
                width: metrics.backSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteStep extends StatelessWidget {
  const _InviteStep({
    required this.text,
    required this.metrics,
  });

  final String text;
  final _EarnPointsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.arrow_right_outlined,
          color: appTextColor,
          size: metrics.stepIconSize,
        ),
        Expanded(
          child: AppText(
            text: text,
            size: metrics.captionSize,
            fontWeight: FontWeight.w500,
            color: appTextColor2,
          ),
        ),
      ],
    );
  }
}

class _EarnPointsLayoutMetrics {
  const _EarnPointsLayoutMetrics({
    required this.heroHeight,
    required this.heroHorizontalPadding,
    required this.backLeft,
    required this.heroTextBottom,
    required this.backTop,
    required this.backSize,
    required this.heroEarnSize,
    required this.heroUnlimitedSize,
    required this.heroPointsSize,
    required this.contentHorizontalPadding,
    required this.contentTopGap,
    required this.moneyImageSize,
    required this.titleGap,
    required this.smallGap,
    required this.sectionGap,
    required this.bottomGap,
    required this.titleSize,
    required this.bodySize,
    required this.captionSize,
    required this.stepIconSize,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.buttonTextSize,
    required this.buttonRadius,
    required this.isTablet,
    required this.showButton,
  });

  final double heroHeight;
  final double heroHorizontalPadding;
  final double backLeft;
  final double heroTextBottom;
  final double backTop;
  final double backSize;
  final double heroEarnSize;
  final double heroUnlimitedSize;
  final double heroPointsSize;
  final double contentHorizontalPadding;
  final double contentTopGap;
  final double moneyImageSize;
  final double titleGap;
  final double smallGap;
  final double sectionGap;
  final double bottomGap;
  final double titleSize;
  final double bodySize;
  final double captionSize;
  final double stepIconSize;
  final double buttonWidth;
  final double buttonHeight;
  final double buttonTextSize;
  final double buttonRadius;
  final bool isTablet;
  final bool showButton;

  factory _EarnPointsLayoutMetrics.fromConstraints({
    required BuildContext context,
    required BoxConstraints constraints,
    required Orientation orientation,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final isCompactPhone = width < 390 || height < 640;
    final isTablet = Breakpoints.isTablet(width);
    final isLandscape = orientation == Orientation.landscape;
    final isTabletLandscape = isTablet && isLandscape;
    final isPhoneLandscape = !isTablet && isLandscape;

    // In landscape (phone or tablet) everything below scales off heroHeight
    // so every device renders the same proportions as the tablet-landscape
    // reference layout, instead of jumping between separate fixed
    // breakpoint values. Portrait keeps its original fixed-value sizing.
    final heroHeight = isTabletLandscape
        ? height * 0.48
        : isTablet
            ? height * 0.42
            : isPhoneLandscape
                ? height * 0.42
                : isCompactPhone
                    ? height * 0.32
                    : height * 0.36;

    return _EarnPointsLayoutMetrics(
      heroHeight: heroHeight,
      heroHorizontalPadding: isLandscape
          ? width * 0.08
          : isTablet
              ? width * 0.08
              : isCompactPhone
                  ? width * 0.06
                  : width * 0.075,
      // Independent from heroHorizontalPadding: that value scales with
      // screen width and gets too large in landscape, pushing the back
      // icon away from the left edge. backLeft stays small and scales off
      // heroHeight so it looks consistent across all landscape sizes.
      backLeft: isLandscape
          ? (heroHeight * 0.06).clamp(12.0, 24.0)
          : isTablet
              ? 24.0
              : 16.0,
      heroTextBottom: isLandscape
          ? (heroHeight * 0.05).clamp(10.0, 24.0)
          : isTablet
              ? AppDimensions.margin(context)
              : isCompactPhone
                  ? 14.0
                  : 20.0,
      backTop: isLandscape
          ? (heroHeight * 0.09).clamp(12.0, 36.0)
          : isTablet
              ? 36.0
              : isCompactPhone
                  ? 22.0
                  : 40.0,
      backSize: isLandscape
          ? (heroHeight * 0.086).clamp(20.0, 34.0)
          : isTablet
              ? 34.0
              : isCompactPhone
                  ? 26.0
                  : 30.0,
      // Hero text (Earn / Unlimited / Points!!) scales off heroHeight in
      // landscape (phone or tablet), matching the tablet-landscape
      // reference proportions at any screen size. Portrait sizing for
      // compact/normal phones and tablet is unchanged.
      heroEarnSize: isLandscape
          ? (heroHeight * 0.132).clamp(18.0, 52.0)
          : isCompactPhone
              ? 31.0
              : 36.0,
      heroUnlimitedSize: isLandscape
          ? (heroHeight * 0.117).clamp(16.0, 46.0)
          : isCompactPhone
              ? 28.0
              : 32.0,
      heroPointsSize: isLandscape
          ? (heroHeight * 0.102).clamp(14.0, 40.0)
          : isCompactPhone
              ? 25.0
              : 29.0,
      contentHorizontalPadding: isTablet
          ? width * 0.12
          : isCompactPhone
              ? width * 0.1
              : width * 0.15,
      contentTopGap: isTablet
          ? AppDimensions.gap(context)
          : isCompactPhone
              ? 4.0
              : 6.0,
      moneyImageSize: isTablet
          ? 220.0
          : isCompactPhone
              ? 112.0
              : 138.0,
      titleGap: isTablet
          ? AppDimensions.margin(context)
          : isCompactPhone
              ? 8.0
              : 12.0,
      smallGap: isTablet
          ? AppDimensions.gap(context) * 0.75
          : isCompactPhone
              ? 4.0
              : 6.0,
      sectionGap: isTablet
          ? AppDimensions.margin(context) * 1.2
          : isCompactPhone
              ? 12.0
              : 16.0,
      bottomGap: isTablet
          ? AppDimensions.margin(context)
          : isCompactPhone
              ? 8.0
              : 12.0,
      titleSize: isTablet ? AppDimensions.title(context) : 20.0,
      bodySize: isTablet
          ? AppDimensions.body(context)
          : isCompactPhone
              ? 11.0
              : 12.5,
      captionSize: isTablet
          ? AppDimensions.caption(context)
          : isCompactPhone
              ? 9.5
              : 10.5,
      stepIconSize: isTablet
          ? 22.0
          : isCompactPhone
              ? 18.0
              : 20.0,
      buttonWidth: isTablet
          ? 220.0
          : isCompactPhone
              ? 190.0
              : 200.0,
      buttonHeight: isTablet
          ? 44.0
          : isCompactPhone
              ? 40.0
              : 40.0,
      buttonTextSize: isTablet
          ? AppDimensions.body(context)
          : isCompactPhone
              ? 13.0
              : 15.0,
      buttonRadius: isTablet ? 12.0 : 10.0,
      isTablet: isTablet,
      showButton: true,
    );
  }
}