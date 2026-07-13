import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/utils/constants.dart';

class Reward extends StatelessWidget {
  const Reward({super.key});

  static const _rewardParagraphs = [
    'Each badge brings exclusive rewards, appreciation certificates, welcome gifts, discount packs, and more just for you! ',
    'Keep enjoying offers, placing orders, and exploring restaurants to earn points faster.The more you use Fudikoo, the more you earn. Let your next achievement unlock something exciting!',
    "Tap the current badge to explore upcoming badges and see what's waiting for you next.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final metrics = _RewardLayoutMetrics.fromConstraints(
                  context: context,
                  constraints: constraints,
                );

                final contentTopInset =
                    metrics.backTop + metrics.backSize + metrics.titleTopGap;

                return Stack(
                  children: [
                    Positioned(
                      top: metrics.backTop,
                      left: metrics.horizontalPadding,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          backOrange,
                          height: metrics.backSize,
                          width: metrics.backSize,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: contentTopInset,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: metrics.bottomPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                constraints.maxHeight -
                                contentTopInset -
                                metrics.bottomPadding,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppText(
                                text: 'Climber',
                                size: metrics.titleSize,
                                fontWeight: FontWeight.w600,
                                isCentered: true,
                                color: Colors.amber,
                              ),
                              SizedBox(height: metrics.smallGap),
                              Center(
                                child: Image.asset(
                                  'assets/images/badge1.png',
                                  width: metrics.badgeSize,
                                  height: metrics.badgeSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: metrics.badgeBottomGap),
                              AppText(
                                text: 'Your next badge is on its way!',
                                size: metrics.captionSize,
                                fontWeight: FontWeight.w400,
                                isCentered: true,
                                color: Colors.black,
                              ),
                              SizedBox(height: metrics.bodyGap),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      metrics.progressHorizontalPadding,
                                ),
                                child: _GradientProgressBar(
                                  percentage: 70,
                                  height: metrics.progressHeight,
                                ),
                              ),
                              SizedBox(height: metrics.bodyGap),
                              AppText(
                                text: '87/100',
                                size: metrics.bodySize,
                                fontWeight: FontWeight.w500,
                                isCentered: true,
                                color: Colors.black,
                              ),
                              SizedBox(height: metrics.sectionGap),
                              AppText(
                                text: "You're on your Reward Journey!",
                                size: metrics.bodySize,
                                fontWeight: FontWeight.w600,
                                isCentered: true,
                                color: appTextColor,
                              ),
                              SizedBox(height: metrics.bodyGap),
                              AppText(
                                text:
                                    'Only 13 more points to unlock your next badge.',
                                size: metrics.bodySize,
                                fontWeight: FontWeight.w400,
                                isCentered: true,
                                color: appTextColor2,
                              ),
                              SizedBox(height: metrics.bodyGap),
                              for (final paragraph
                                  in _rewardParagraphs) ...[
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        metrics.paragraphHorizontalPadding,
                                  ),
                                  child: AppText(
                                    text: paragraph,
                                    size: metrics.bodySize,
                                    fontWeight: FontWeight.w400,
                                    isCentered: true,
                                    color: appTextColor,
                                    lineSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: metrics.bodyGap),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({
    required this.percentage,
    required this.height,
  });

  final double percentage;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clampedPercentage = percentage.clamp(0, 100).toDouble();
        final radius = height / 2;

        return Stack(
          children: [
            Container(
              height: height,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                height: height,
                width: constraints.maxWidth * (clampedPercentage / 100),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.pink],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RewardLayoutMetrics {
  const _RewardLayoutMetrics({
    required this.horizontalPadding,
    required this.paragraphHorizontalPadding,
    required this.progressHorizontalPadding,
    required this.backTop,
    required this.backSize,
    required this.titleTopGap,
    required this.smallGap,
    required this.bodyGap,
    required this.badgeBottomGap,
    required this.sectionGap,
    required this.bottomPadding,
    required this.badgeSize,
    required this.progressHeight,
    required this.titleSize,
    required this.bodySize,
    required this.captionSize,
  });

  final double horizontalPadding;
  final double paragraphHorizontalPadding;
  final double progressHorizontalPadding;
  final double backTop;
  final double backSize;
  final double titleTopGap;
  final double smallGap;
  final double bodyGap;
  final double badgeBottomGap;
  final double sectionGap;
  final double bottomPadding;
  final double badgeSize;
  final double progressHeight;
  final double titleSize;
  final double bodySize;
  final double captionSize;

  factory _RewardLayoutMetrics.fromConstraints({
    required BuildContext context,
    required BoxConstraints constraints,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isCompactPhone = width < 390 || height < 640;
    final isCompactLandscape = isLandscape && height < 500;
    final isTablet = Breakpoints.isTabletDevice(size);

    return _RewardLayoutMetrics(
      horizontalPadding: isTablet
          ? width * 0.055
        : isCompactLandscape
        ? width * 0.045
          : isCompactPhone
          ? width * 0.06
          : width * 0.075,
      paragraphHorizontalPadding: isTablet
          ? width * 0.12
        : isCompactLandscape
        ? width * 0.08
          : isCompactPhone
          ? width * 0.1
          : width * 0.125,
      progressHorizontalPadding: isTablet
          ? width * 0.14
        : isCompactLandscape
        ? width * 0.09
          : isCompactPhone
          ? width * 0.1
          : width * 0.125,
      backTop: isTablet
        ? (isLandscape ? 14.0 : 18.0)
        : isCompactLandscape
        ? 8.0
          : isCompactPhone
          ? 8.0
          : 10.0,
      backSize: isTablet
        ? (isLandscape ? 30.0 : 34.0)
        : isCompactLandscape
        ? 24.0
          : isCompactPhone
          ? 28.0
          : 30.0,
      titleTopGap: isTablet
        ? (isLandscape ? AppDimensions.gap(context) * 0.85 : AppDimensions.gap(context) * 1.6)
        : isCompactLandscape
        ? 10.0
          : isCompactPhone
          ? 16.0
          : 20.0,
      smallGap: isTablet
        ? (isLandscape ? AppDimensions.gap(context) * 0.5 : AppDimensions.gap(context) * 0.8)
        : isCompactLandscape
        ? 6.0
          : isCompactPhone
          ? 8.0
          : 10.0,
      bodyGap: isTablet
        ? (isLandscape ? AppDimensions.gap(context) * 0.7 : AppDimensions.gap(context) * 1.1)
        : isCompactLandscape
        ? 8.0
          : isCompactPhone
          ? 16.0
          : 20.0,
      badgeBottomGap: isTablet
        ? (isLandscape ? AppDimensions.margin(context) * 0.5 : AppDimensions.margin(context) * 0.85)
        : isCompactLandscape
        ? 14.0
          : isCompactPhone
          ? 22.0
          : 30.0,
      sectionGap: isTablet
        ? (isLandscape ? AppDimensions.margin(context) * 0.75 : AppDimensions.margin(context) * 1.25)
        : isCompactLandscape
        ? 18.0
          : isCompactPhone
          ? 36.0
          : 50.0,
      bottomPadding: isTablet
        ? (isLandscape ? AppDimensions.gap(context) * 1.1 : AppDimensions.margin(context))
        : isCompactLandscape
        ? 12.0
          : isCompactPhone
          ? 18.0
          : 24.0,
      badgeSize: isTablet
        ? (isLandscape ? 140.0 : 170.0)
        : isCompactLandscape
        ? 118.0
          : isCompactPhone
          ? 132.0
          : 150.0,
      progressHeight: isTablet
        ? (isLandscape ? 8.0 : 10.0)
        : isCompactLandscape
        ? 7.0
          : isCompactPhone
          ? 8.0
          : 10.0,
      titleSize: isTablet ? AppDimensions.title(context) : 20.0,
      bodySize: isTablet
          ? AppDimensions.body(context)
        : isCompactLandscape
        ? 13.0
          : isCompactPhone
          ? 14.0
          : 15.0,
      captionSize: isTablet
          ? AppDimensions.caption(context)
        : isCompactLandscape
        ? 10.5
          : isCompactPhone
          ? 11.0
          : 12.0,
    );
  }
}
