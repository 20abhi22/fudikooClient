import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/utils/constants.dart';

class AboutBadgePage extends StatefulWidget {
  const AboutBadgePage({super.key});

  @override
  State<AboutBadgePage> createState() => _AboutBadgePageState();
}

class _AboutBadgePageState extends State<AboutBadgePage> {
  final ScrollController _scrollController = ScrollController();

  static final _badges = [
    _BadgeItem(
      shieldIcon: badgeChamp,
      title: 'Champ',
      description:
          'Unlock an Exclusive Discount Pack and a Thank You Kit from Fudikoo.',
    ),
    _BadgeItem(
      shieldIcon: badgeClimber,
      title: 'Climber',
      description:
          'Enjoy a Free Takeaway Coupon and an Official Digital Badge.',
    ),
    _BadgeItem(
      shieldIcon: badgeZylo,
      title: 'Zylo',
      description:
          'Get a Fudikoo Appreciation Certificate and early access to new app features.',
    ),
    _BadgeItem(
      shieldIcon: badgeNerivo,
      title: 'Nerivo',
      description:
          'Receive priority access to banquet deals and a Free Banquet Booking Voucher.',
    ),
    _BadgeItem(
      shieldIcon: badgeLumina,
      title: 'Lumina',
      description:
          'Get a Special Feature Article about your restaurant inside the app.',
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                final metrics = _AboutBadgeMetrics.fromConstraints(
                  context: context,
                  constraints: constraints,
                  orientation: orientation,
                );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.pageHorizontalPadding,
                  ),
                  child: Stack(
                    children: [
                      ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thumbColor: WidgetStateProperty.all(
                            const Color(0xFF545450).withOpacity(.3),
                          ),
                          trackColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          trackBorderColor: WidgetStateProperty.all(
                            const Color(0xFF545450).withOpacity(.0),
                          ),
                          trackVisibility: WidgetStateProperty.all(
                            metrics.showTrack,
                          ),
                          thickness: WidgetStateProperty.all(
                            metrics.showTrack ? 4.0 : 0.0,
                          ),
                          radius: const Radius.circular(4),
                        ),
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: metrics.showThumb,
                          trackVisibility: metrics.showTrack,
                          interactive: true,
                          scrollbarOrientation: ScrollbarOrientation.right,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              0,
                              metrics.backTop +
                                  metrics.backSize +
                                  metrics.headerGap,
                              metrics.showTrack ? metrics.scrollbarGap : 0,
                              metrics.bottomPadding,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: (constraints.maxHeight -
                                        metrics.topPadding -
                                        metrics.bottomPadding)
                                    .clamp(0.0, double.infinity),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: metrics.contentWidth,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      AppText(
                                        text: 'About Badges',
                                        size: metrics.titleSize,
                                        fontWeight: FontWeight.w600,
                                        color: appTextColor2,
                                        isCentered: true,
                                        maxLines: 1,
                                      ),
                                      SizedBox(
                                        height: metrics.descriptionGap,
                                      ),
                                      AppText(
                                        text:
                                            'In App, users can earn special badges based on their activity, engagement, and points collected through the app. These badges are a fun and rewarding way to recognize loyal customers who regularly explore new restaurants, place orders, send banquet requests, or participate in offers and promotions. For example, the Food Explorer badge is given to users who try a wide variety of restaurants, while the Quick Booker badge is awarded to those who frequently make banquet or party bookings. Other badges may highlight consistent takeaway ordering, early access to deals, or providing helpful reviews. As you continue to use the app and earn more points, you unlock more badges and exclusive benefits, such as special discounts or early access to top deals.',
                                        size: metrics.bodySize,
                                        fontWeight: FontWeight.w400,
                                        color: appTextColor2,
                                        lineSpacing: 1.75,
                                        textAlign: TextAlign.justify,
                                        maxLines: 40,
                                      ),
                                      SizedBox(height: metrics.tilesTopGap),
                                      for (var index = 0;
                                          index < _badges.length;
                                          index++) ...[
                                        _BadgeTile(
                                          item: _badges[index],
                                          metrics: metrics,
                                        ),
                                        if (index != _badges.length - 1)
                                          SizedBox(
                                            height: metrics.tileGap,
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
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
                            width: metrics.backSize,
                            height: metrics.backSize,
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
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.item,
    required this.metrics,
  });

  final _BadgeItem item;
  final _AboutBadgeMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: metrics.iconBoxSize,
          height: metrics.iconBoxSize,
          child: Center(
            child: Image.asset(
              item.shieldIcon,
              width: metrics.iconSize,
              height: metrics.iconSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(width: metrics.tileItemGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: item.title,
                size: metrics.tileTitleSize,
                fontWeight: FontWeight.w600,
                color: appTextColor3,
                maxLines: 1,
              ),
              SizedBox(height: metrics.tileTextGap),
              AppText(
                text: item.description,
                size: metrics.tileDescriptionSize,
                fontWeight: FontWeight.w400,
                color: appTextColor,
                lineSpacing: 1.5,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeItem {
  const _BadgeItem({
    required this.shieldIcon,
    required this.title,
    required this.description,
  });

  final String shieldIcon;
  final String title;
  final String description;
}

class _AboutBadgeMetrics {
  const _AboutBadgeMetrics({
    required this.pageHorizontalPadding,
    required this.contentWidth,
    required this.backTop,
    required this.backSize,
    required this.topPadding,
    required this.bottomPadding,
    required this.headerGap,
    required this.descriptionGap,
    required this.tilesTopGap,
    required this.tileGap,
    required this.scrollbarGap,
    required this.titleSize,
    required this.bodySize,
    required this.tileTitleSize,
    required this.tileDescriptionSize,
    required this.iconBoxSize,
    required this.iconSize,
    required this.tileItemGap,
    required this.tileTextGap,
    required this.showThumb,
    required this.showTrack,
  });

  final double pageHorizontalPadding;
  final double contentWidth;
  final double backTop;
  final double backSize;
  final double topPadding;
  final double bottomPadding;
  final double headerGap;
  final double descriptionGap;
  final double tilesTopGap;
  final double tileGap;
  final double scrollbarGap;
  final double titleSize;
  final double bodySize;
  final double tileTitleSize;
  final double tileDescriptionSize;
  final double iconBoxSize;
  final double iconSize;
  final double tileItemGap;
  final double tileTextGap;
  final bool showThumb;
  final bool showTrack;

  factory _AboutBadgeMetrics.fromConstraints({
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
    final isCompactPhoneLandscape = isPhoneLandscape && height < 500;

    // Horizontal page padding: unified across tablet and phone landscape so
    // content doesn't stretch edge-to-edge in wide short viewports; portrait
    // keeps its original narrower padding.
    final pageHorizontalPadding = isTablet
        ? width * 0.08
        : isPhoneLandscape
            ? width * 0.08
            : isCompactPhone
                ? width * 0.06
                : width * 0.075;

    return _AboutBadgeMetrics(
      pageHorizontalPadding: pageHorizontalPadding,
      // Constrain content width so long paragraphs don't stretch full-width
      // in landscape (harder to read, and tiles look sparse). Tablet already
      // had this; phone landscape now gets the same treatment instead of
      // just filling the full available width.
      contentWidth: isTablet
          ? width * (isTabletLandscape ? 0.66 : 0.74)
          : isPhoneLandscape
              ? (width - pageHorizontalPadding * 2) * 0.86
              : width - (pageHorizontalPadding * 2),
      backTop: isTablet
          ? 36.0
          : isCompactPhoneLandscape
              ? 10.0
              : isPhoneLandscape
                  ? 16.0
                  : isCompactPhone
                      ? 22.0
                      : 40.0,
      backSize: isTablet
          ? 34.0
          : isPhoneLandscape
              ? 24.0
              : isCompactPhone
                  ? 26.0
                  : 30.0,
      topPadding: isTablet
          ? 10.0
          : isPhoneLandscape
              ? 8.0
              : 16.0,
      bottomPadding: isTablet
          ? AppDimensions.margin(context)
          : isPhoneLandscape
              ? 12.0
              : 16.0,
      headerGap: isTablet
          ? 20.0
          : isPhoneLandscape
              ? 14.0
              : 24.0,
      descriptionGap: isTablet
          ? 32.0
          : isPhoneLandscape
              ? 18.0
              : 28.0,
      tilesTopGap: isTablet
          ? 44.0
          : isPhoneLandscape
              ? 24.0
              : 40.0,
      tileGap: isTablet
          ? 30.0
          : isPhoneLandscape
              ? 18.0
              : 28.0,
      scrollbarGap: isTablet
          ? 10.0
          : isPhoneLandscape
              ? 10.0
              : 0.0,
      titleSize: isTablet
          ? AppDimensions.title(context)
          : isPhoneLandscape
              ? 18.0
              : 22.0,
      bodySize: isTablet
          ? AppDimensions.body(context)
          : isPhoneLandscape
              ? 12.0
              : isCompactPhone
                  ? 13.0
                  : 14.0,
      tileTitleSize: isTablet
          ? 18.0
          : isPhoneLandscape
              ? 15.0
              : 17.0,
      tileDescriptionSize: isTablet
          ? AppDimensions.body(context)
          : isPhoneLandscape
              ? 12.0
              : isCompactPhone
                  ? 13.0
                  : 14.0,
      iconBoxSize: isTablet
          ? 42.0
          : isPhoneLandscape
              ? 30.0
              : 35.0,
      iconSize: isTablet
          ? 36.0
          : isPhoneLandscape
              ? 26.0
              : 30.0,
      tileItemGap: isTablet
          ? 18.0
          : isPhoneLandscape
              ? 14.0
              : 16.0,
      tileTextGap: isTablet ? 6.0 : 4.0,
      showThumb: isTablet || isPhoneLandscape,
      showTrack: isTablet || isPhoneLandscape,
    );
  }
}