import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/badge/badge_model.dart';
import 'package:fudikoclient/service/badge/badge_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class BadgeInfo extends StatefulWidget {
  const BadgeInfo({super.key});

  static const int _gridColumns = 5;

  @override
  State<BadgeInfo> createState() => _BadgeInfoState();
}

class _BadgeInfoState extends State<BadgeInfo> {
  final BadgesService _badgesService = BadgesService();
  BadgesResponseModel? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBadges();
  }

  Future<void> _fetchBadges() async {
    final result = await _badgesService.getBadges();
    if (!mounted) return;
    setState(() {
      _data = result;
      _isLoading = false;
    });
  }

  ({double percentage, int target}) _progressToNextBadge(
    int currentPoints,
    List<BadgeItemModel> badges,
  ) {
    final nextBadge = badges
        .where((b) => b.points > currentPoints)
        .fold<BadgeItemModel?>(null, (closest, b) {
          if (closest == null || b.points < closest.points) return b;
          return closest;
        });

    if (nextBadge == null) {
      return (percentage: 100.0, target: currentPoints);
    }

    final percentage = nextBadge.points == 0
        ? 0.0
        : (currentPoints / nextBadge.points * 100).clamp(0.0, 100.0);

    return (percentage: percentage, target: nextBadge.points);
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
                final badges = _data?.badges ?? [];
                final currentPoints = _data?.currentPoints ?? 0;
                final hasCurrentBadge = _data?.currentBadge != null &&
                    _data!.currentBadge!.isNotEmpty;

                final metrics = _BadgeInfoLayoutMetrics.fromConstraints(
                  context: context,
                  constraints: constraints,
                  orientation: orientation,
                  badgeCount: badges.isEmpty ? 1 : badges.length,
                );

                final progress = _progressToNextBadge(currentPoints, badges);

                final content = _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: metrics.isTablet
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppText(
                            text: hasCurrentBadge ? "Your Badge" : "No Badge Yet",
                            size: metrics.titleSize,
                            fontWeight: FontWeight.w600,
                            isCentered: true,
                            color: hasCurrentBadge ? Colors.amber : Colors.grey,
                          ),
                          SizedBox(height: metrics.smallGap),
                          Center(
                            child: hasCurrentBadge
                                ? Image.network(
                                    _data!.currentBadge!,
                                    width: metrics.mainBadgeSize,
                                    height: metrics.mainBadgeSize,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        _greyscaleBadgePlaceholder(metrics.mainBadgeSize),
                                  )
                                : _greyscaleBadgePlaceholder(metrics.mainBadgeSize),
                          ),
                          SizedBox(height: metrics.mainBadgeBottomGap),
                          AppText(
                            text: hasCurrentBadge
                                ? "Keep going to earn more badges!"
                                : "Your next badge is on its way!",
                            size: metrics.captionSize,
                            fontWeight: FontWeight.w400,
                            isCentered: true,
                            color: Colors.black,
                          ),
                          SizedBox(height: metrics.bodyGap),
                          Center(
                            child: SizedBox(
                              width: metrics.progressWidth,
                              child: _GradientProgressBar(
                                percentage: progress.percentage,
                                height: metrics.progressHeight,
                              ),
                            ),
                          ),
                          SizedBox(height: metrics.bodyGap),
                          AppText(
                            text: '$currentPoints/${progress.target}',
                            size: metrics.bodySize,
                            fontWeight: FontWeight.w500,
                            isCentered: true,
                            color: Colors.black,
                          ),
                          SizedBox(height: metrics.gridTopGap),
                          if (badges.isEmpty)
                            AppText(
                              text: "No badges available",
                              size: metrics.bodySize,
                              fontWeight: FontWeight.w400,
                              isCentered: true,
                              color: appTextColor2,
                            )
                          else
                            Center(
                              child: SizedBox(
                                width: metrics.gridWidth,
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: metrics.gridGap,
                                  runSpacing: metrics.gridGap,
                                  children: badges.map((badge) {
                                    final isEarned =
                                        badge.points <= currentPoints;
                                    final badgeImage = Image.network(
                                      badge.image,
                                      width: metrics.gridBadgeSize,
                                      height: metrics.gridBadgeSize,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/images/badge2.png',
                                        width: metrics.gridBadgeSize,
                                        height: metrics.gridBadgeSize,
                                        fit: BoxFit.contain,
                                      ),
                                    );

                                    if (isEarned) return badgeImage;

                                    return ColorFiltered(
                                      colorFilter: const ColorFilter.matrix(<double>[
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0, 0, 0, 1, 0,
                                      ]),
                                      child: badgeImage,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.pageHorizontalPadding,
                  ),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.only(
                          top: metrics.contentTopInset,
                          bottom: metrics.bottomPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (constraints.maxHeight -
                                    metrics.contentTopInset -
                                    metrics.bottomPadding)
                                .clamp(0.0, double.infinity),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: metrics.contentWidth,
                              child: content,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: metrics.backTop,
                        left: 0,
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
              },
            );
          },
        ),
      ),
    );
  }

  Widget _greyscaleBadgePlaceholder(double size) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: Image.asset(
        'assets/images/badge1.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
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
                    colors: [Color(0xFFFF5722), Color(0xFFFC9E4D), Color(0xFFFFE044),Color(0xFF8FFF8F)],
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

class _BadgeInfoLayoutMetrics {
  const _BadgeInfoLayoutMetrics({
    required this.pageHorizontalPadding,
    required this.contentWidth,
    required this.horizontalPadding,
    required this.progressWidth,
    required this.gridWidth,
    required this.backTop,
    required this.backSize,
    required this.contentTopInset,
    required this.titleTopGap,
    required this.smallGap,
    required this.bodyGap,
    required this.mainBadgeBottomGap,
    required this.gridTopGap,
    required this.bottomPadding,
    required this.mainBadgeSize,
    required this.gridBadgeSize,
    required this.gridGap,
    required this.progressHeight,
    required this.titleSize,
    required this.bodySize,
    required this.captionSize,
    required this.isTablet,
  });

  final double pageHorizontalPadding;
  final double contentWidth;
  final double horizontalPadding;
  final double progressWidth;
  final double gridWidth;
  final double backTop;
  final double backSize;
  final double contentTopInset;
  final double titleTopGap;
  final double smallGap;
  final double bodyGap;
  final double mainBadgeBottomGap;
  final double gridTopGap;
  final double bottomPadding;
  final double mainBadgeSize;
  final double gridBadgeSize;
  final double gridGap;
  final double progressHeight;
  final double titleSize;
  final double bodySize;
  final double captionSize;
  final bool isTablet;

  /// Computes how many rows the badge grid will need at [_gridColumns]
  /// columns, then derives a badge size that keeps the same 5-column
  /// presentation while shrinking as [badgeCount] grows, so large badge
  /// catalogs still fit comfortably without changing the visual layout.
  factory _BadgeInfoLayoutMetrics.fromConstraints({
    required BuildContext context,
    required BoxConstraints constraints,
    required Orientation orientation,
    required int badgeCount,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isCompactPhone = width < 390 || height < 640;
    final isCompactLandscape = isLandscape && height < 500;
    final isTablet = Breakpoints.isTabletDevice(size);
    final isTabletLandscape = isTablet && isLandscape;

    final columns = BadgeInfo._gridColumns;
    final rows = (badgeCount / columns).ceil().clamp(1, 1000);

    final gridGap = isTablet
      ? (isLandscape ? AppDimensions.gap(context) * 0.6 : AppDimensions.gap(context) * 0.8)
      : isCompactLandscape
      ? 6.0
      : isCompactPhone
      ? 8.0
      : 10.0;

    // Base badge size for a "normal" catalog (roughly up to 5 rows / 25
    // badges), matching the original fixed sizing.
    final baseGridBadgeSize = isTablet
      ? ((width * (isTabletLandscape ? 0.44 : 0.56) - (gridGap * 4)) / 5)
          .clamp(52.0, 76.0)
      : isCompactLandscape
      ? 38.0
      : isCompactPhone
      ? 44.0
      : 50.0;

    // Shrink badge size as the catalog grows beyond 5 rows, so more rows
    // still fit on screen with the same 5-column layout. Clamp to a sane
    // minimum so badges never become illegible.
    final shrinkFactor = rows <= 5 ? 1.0 : (5 / rows).clamp(0.45, 1.0);
    final gridBadgeSize = (baseGridBadgeSize * shrinkFactor).clamp(28.0, baseGridBadgeSize);
    final effectiveGridGap = rows <= 5 ? gridGap : gridGap * shrinkFactor.clamp(0.6, 1.0);

    final gridWidth =
        (gridBadgeSize * columns) + (effectiveGridGap * (columns - 1));

    final pageHorizontalPadding = isTablet
      ? (isLandscape ? width * 0.06 : width * 0.08)
      : isCompactLandscape
      ? width * 0.045
      : isCompactPhone
      ? width * 0.06
      : width * 0.075;
    final contentWidth = isTablet
      ? (gridWidth + width * 0.08).clamp(360.0, width * 0.78)
      : width - (pageHorizontalPadding * 2);
    final titleTopGap = isTablet
      ? (isLandscape ? AppDimensions.gap(context) * 0.9 : AppDimensions.margin(context))
      : isCompactLandscape
      ? 12.0
      : isCompactPhone
      ? 22.0
      : 30.0;
    final progressWidth = isTablet
      ? (contentWidth * (isLandscape ? 0.7 : 0.78)).clamp(240.0, 420.0)
      : isCompactLandscape
      ? width * 0.75
      : isCompactPhone
      ? width * 0.8
      : width * 0.75;
    final backTop = isTablet
      ? (isLandscape ? 18.0 : 36.0)
      : isCompactLandscape
      ? 10.0
      : isCompactPhone
      ? 22.0
      : 40.0;
    final backSize = isTablet
      ? (isLandscape ? 30.0 : 34.0)
      : isCompactLandscape
      ? 24.0
      : isCompactPhone
      ? 28.0
      : 30.0;

    return _BadgeInfoLayoutMetrics(
        pageHorizontalPadding: pageHorizontalPadding,
        contentWidth: contentWidth,
        horizontalPadding: isTablet
          ? (isLandscape ? width * 0.045 : width * 0.055)
          : isCompactLandscape
          ? width * 0.04
          : isCompactPhone
          ? width * 0.06
          : width * 0.075,
      progressWidth: progressWidth,
      gridWidth: gridWidth,
      backTop: backTop,
      backSize: backSize,
      contentTopInset: backTop + backSize + titleTopGap,
      titleTopGap: titleTopGap,
        smallGap: isTablet
          ? (isLandscape ? AppDimensions.gap(context) * 0.6 : AppDimensions.gap(context) * 0.8)
          : isCompactLandscape
          ? 6.0
          : isCompactPhone
          ? 8.0
          : 10.0,
        bodyGap: isTablet
          ? (isLandscape ? AppDimensions.gap(context) * 0.9 : AppDimensions.gap(context) * 1.1)
          : isCompactLandscape
          ? 8.0
          : isCompactPhone
          ? 16.0
          : 20.0,
        mainBadgeBottomGap: isTablet
          ? (isLandscape ? AppDimensions.margin(context) * 0.5 : AppDimensions.margin(context) * 0.85)
          : isCompactLandscape
          ? 12.0
          : isCompactPhone
          ? 22.0
          : 30.0,
        gridTopGap: isTabletLandscape
          ? AppDimensions.margin(context)
          : isTablet
          ? AppDimensions.margin(context) * 1.35
          : isCompactLandscape
          ? 28.0
          : isCompactPhone
          ? 44.0
          : 60.0,
        bottomPadding: isTablet
          ? (isLandscape ? AppDimensions.gap(context) : AppDimensions.margin(context))
          : isCompactLandscape
          ? 14.0
          : isCompactPhone
          ? 22.0
          : 30.0,
        mainBadgeSize: isTablet
          ? (isLandscape ? 140.0 : 170.0)
          : isCompactLandscape
          ? 110.0
          : isCompactPhone
          ? 132.0
          : 150.0,
        gridBadgeSize: gridBadgeSize,
        gridGap: effectiveGridGap,
        progressHeight: isTablet
          ? (isLandscape ? 8.0 : 10.0)
          : isCompactLandscape
          ? 7.0
          : isCompactPhone
          ? 8.0
          : 10.0,
        titleSize: isTablet ? (isLandscape ? AppDimensions.title(context) * 0.95 : AppDimensions.title(context)) : 20.0,
        bodySize: isTablet
          ? (isLandscape ? AppDimensions.body(context) * 0.95 : AppDimensions.body(context))
          : isCompactLandscape
          ? 13.0
          : isCompactPhone
          ? 14.0
          : 15.0,
        captionSize: isTablet
          ? (isLandscape ? AppDimensions.caption(context) * 0.95 : AppDimensions.caption(context))
          : isCompactLandscape
          ? 9.0
          : isCompactPhone
          ? 9.5
          : 10.0,
      isTablet: isTablet,
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:fudikoclient/components/apptext.dart';
// import 'package:fudikoclient/core/responsive/app_dimensions.dart';
// import 'package:fudikoclient/core/responsive/breakpoints.dart';
// import 'package:fudikoclient/utils/constants.dart';

// class BadgeInfo extends StatelessWidget {
//   const BadgeInfo({super.key});

//   static const int _badgeCount = 25;
//   static const int _gridColumns = 5;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: OrientationBuilder(
//           builder: (context, orientation) {
//             return LayoutBuilder(
//               builder: (context, constraints) {
//                 final metrics = _BadgeInfoLayoutMetrics.fromConstraints(
//                   context: context,
//                   constraints: constraints,
//                   orientation: orientation,
//                 );

//                 final content = Column(
//                   mainAxisAlignment: metrics.isTablet
//                       ? MainAxisAlignment.center
//                       : MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     AppText(
//                       text: 'Climber',
//                       size: metrics.titleSize,
//                       fontWeight: FontWeight.w600,
//                       isCentered: true,
//                       color: Colors.amber,
//                     ),
//                     SizedBox(height: metrics.smallGap),
//                     Center(
//                       child: Image.asset(
//                         'assets/images/badge1.png',
//                         width: metrics.mainBadgeSize,
//                         height: metrics.mainBadgeSize,
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//                     SizedBox(height: metrics.mainBadgeBottomGap),
//                     AppText(
//                       text: 'Your next badge is on its way!',
//                       size: metrics.captionSize,
//                       fontWeight: FontWeight.w400,
//                       isCentered: true,
//                       color: Colors.black,
//                     ),
//                     SizedBox(height: metrics.bodyGap),
//                     Center(
//                       child: SizedBox(
//                         width: metrics.progressWidth,
//                         child: _GradientProgressBar(
//                           percentage: 70,
//                           height: metrics.progressHeight,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: metrics.bodyGap),
//                     AppText(
//                       text: '87/100',
//                       size: metrics.bodySize,
//                       fontWeight: FontWeight.w500,
//                       isCentered: true,
//                       color: Colors.black,
//                     ),
//                     SizedBox(height: metrics.gridTopGap),
//                     Center(
//                       child: SizedBox(
//                         width: metrics.gridWidth,
//                         child: Wrap(
//                           alignment: WrapAlignment.center,
//                           spacing: metrics.gridGap,
//                           runSpacing: metrics.gridGap,
//                           children: List.generate(
//                             _badgeCount,
//                             (index) => Image.asset(
//                               'assets/images/badge2.png',
//                               width: metrics.gridBadgeSize,
//                               height: metrics.gridBadgeSize,
//                               fit: BoxFit.contain,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 );

//                 return Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: metrics.pageHorizontalPadding,
//                   ),
//                   child: Stack(
//                     children: [
                      
//                       SingleChildScrollView(
//                         padding: EdgeInsets.only(
//                           top: metrics.contentTopInset,
//                           bottom: metrics.bottomPadding,
//                         ),
//                         child: ConstrainedBox(
//                           constraints: BoxConstraints(
//                             minHeight: (constraints.maxHeight -
//                                     metrics.contentTopInset -
//                                     metrics.bottomPadding)
//                                 .clamp(0.0, double.infinity),
//                           ),
//                           child: Center(
//                             child: SizedBox(
//                               width: metrics.contentWidth,
//                               child: content,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         top: metrics.backTop,
//                         left: 0,
//                         child: GestureDetector(
//                           onTap: () => Navigator.pop(context),
//                           child: Image.asset(
//                             backOrange,
//                             height: metrics.backSize,
//                             width: metrics.backSize,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class _GradientProgressBar extends StatelessWidget {
//   const _GradientProgressBar({
//     required this.percentage,
//     required this.height,
//   });

//   final double percentage;
//   final double height;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final clampedPercentage = percentage.clamp(0, 100).toDouble();
//         final radius = height / 2;

//         return Stack(
//           children: [
//             Container(
//               height: height,
//               width: constraints.maxWidth,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(radius),
//               ),
//             ),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(radius),
//               child: Container(
//                 height: height,
//                 width: constraints.maxWidth * (clampedPercentage / 100),
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.orange, Colors.pink],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class _BadgeInfoLayoutMetrics {
//   const _BadgeInfoLayoutMetrics({
//     required this.pageHorizontalPadding,
//     required this.contentWidth,
//     required this.horizontalPadding,
//     required this.progressWidth,
//     required this.gridWidth,
//     required this.backTop,
//     required this.backSize,
//     required this.contentTopInset,
//     required this.titleTopGap,
//     required this.smallGap,
//     required this.bodyGap,
//     required this.mainBadgeBottomGap,
//     required this.gridTopGap,
//     required this.bottomPadding,
//     required this.mainBadgeSize,
//     required this.gridBadgeSize,
//     required this.gridGap,
//     required this.progressHeight,
//     required this.titleSize,
//     required this.bodySize,
//     required this.captionSize,
//     required this.isTablet,
//   });

//   final double pageHorizontalPadding;
//   final double contentWidth;
//   final double horizontalPadding;
//   final double progressWidth;
//   final double gridWidth;
//   final double backTop;
//   final double backSize;
//   final double contentTopInset;
//   final double titleTopGap;
//   final double smallGap;
//   final double bodyGap;
//   final double mainBadgeBottomGap;
//   final double gridTopGap;
//   final double bottomPadding;
//   final double mainBadgeSize;
//   final double gridBadgeSize;
//   final double gridGap;
//   final double progressHeight;
//   final double titleSize;
//   final double bodySize;
//   final double captionSize;
//   final bool isTablet;

//   factory _BadgeInfoLayoutMetrics.fromConstraints({
//     required BuildContext context,
//     required BoxConstraints constraints,
//     required Orientation orientation,
//   }) {
//     final width = constraints.maxWidth;
//     final height = constraints.maxHeight;
//     final isCompactPhone = width < 390 || height < 640;
//     final isTablet = Breakpoints.isTablet(width);
//     final isTabletLandscape = isTablet && orientation == Orientation.landscape;
//     final gridGap = isTablet
//         ? AppDimensions.gap(context) * 0.8
//         : isCompactPhone
//         ? 8.0
//         : 10.0;
//     final gridBadgeSize = isTablet
//         ? ((width * (isTabletLandscape ? 0.48 : 0.56) - (gridGap * 4)) / 5)
//               .clamp(56.0, 76.0)
//         : isCompactPhone
//         ? 44.0
//         : 50.0;
//     final gridWidth =
//         (gridBadgeSize * BadgeInfo._gridColumns) +
//         (gridGap * (BadgeInfo._gridColumns - 1));
//     final pageHorizontalPadding = isTablet
//         ? width * 0.08
//         : isCompactPhone
//         ? width * 0.06
//         : width * 0.075;
//     final contentWidth = isTablet
//         ? (gridWidth + width * 0.08).clamp(360.0, width * 0.78)
//         : width - (pageHorizontalPadding * 2);
//     final titleTopGap = isTablet
//         ? AppDimensions.margin(context)
//         : isCompactPhone
//         ? 22.0
//         : 30.0;
//     final progressWidth = isTablet
//         ? (contentWidth * 0.78).clamp(260.0, 420.0)
//         : isCompactPhone
//         ? width * 0.8
//         : width * 0.75;
//     final backTop = isTablet
//         ? 36.0
//         : isCompactPhone
//         ? 22.0
//         : 40.0;
//     final backSize = isTablet
//         ? 34.0
//         : isCompactPhone
//         ? 28.0
//         : 30.0;

//     return _BadgeInfoLayoutMetrics(
//       pageHorizontalPadding: pageHorizontalPadding,
//       contentWidth: contentWidth,
//       horizontalPadding: isTablet
//           ? width * 0.055
//           : isCompactPhone
//           ? width * 0.06
//           : width * 0.075,
//       progressWidth: progressWidth,
//       gridWidth: gridWidth,
//       backTop: backTop,
//       backSize: backSize,
//       contentTopInset: backTop + backSize + titleTopGap,
//       titleTopGap: titleTopGap,
//       smallGap: isTablet
//           ? AppDimensions.gap(context) * 0.8
//           : isCompactPhone
//           ? 8.0
//           : 10.0,
//       bodyGap: isTablet
//           ? AppDimensions.gap(context) * 1.1
//           : isCompactPhone
//           ? 16.0
//           : 20.0,
//       mainBadgeBottomGap: isTablet
//           ? AppDimensions.margin(context) * 0.85
//           : isCompactPhone
//           ? 22.0
//           : 30.0,
//       gridTopGap: isTabletLandscape
//           ? AppDimensions.margin(context)
//           : isTablet
//           ? AppDimensions.margin(context) * 1.35
//           : isCompactPhone
//           ? 44.0
//           : 60.0,
//       bottomPadding: isTablet
//           ? AppDimensions.margin(context)
//           : isCompactPhone
//           ? 22.0
//           : 30.0,
//       mainBadgeSize: isTablet
//           ? 170.0
//           : isCompactPhone
//           ? 132.0
//           : 150.0,
//       gridBadgeSize: gridBadgeSize,
//       gridGap: gridGap,
//       progressHeight: isTablet
//           ? 10.0
//           : isCompactPhone
//           ? 8.0
//           : 10.0,
//       titleSize: isTablet ? AppDimensions.title(context) : 20.0,
//       bodySize: isTablet
//           ? AppDimensions.body(context)
//           : isCompactPhone
//           ? 14.0
//           : 15.0,
//       captionSize: isTablet
//           ? AppDimensions.caption(context)
//           : isCompactPhone
//           ? 9.5
//           : 10.0,
//       isTablet: isTablet,
//     );
//   }
// }
