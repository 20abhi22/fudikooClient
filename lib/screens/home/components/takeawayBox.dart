import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';

class TakeAwayBox extends StatelessWidget {
  const TakeAwayBox({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _CardMetrics.from(context, constraints);

        return Container(
          width: double.infinity,
          height: metrics.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: AssetImage('assets/images/mainBoxBg.png'),
              fit: BoxFit.cover,
            ),
            gradient: const LinearGradient(
              colors: [Color(0xFF6e7525), Color(0xFFbac43e)],
              end: Alignment.topCenter,
              begin: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: metrics.imageBottom,
                right: metrics.rightPadding,
                child: Image.asset(
                  'assets/images/boxbg2.png',
                  width: metrics.image,
                  height: metrics.image,
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: metrics.verticalPadding,
                  bottom: metrics.verticalPadding,
                  left: metrics.leftPadding,
                  right: metrics.textRightPadding,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        text: "Take Away",
                        size: metrics.title,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        isShadow: true,
                      ),
                      SizedBox(height: metrics.titleGap),
                      Padding(
                        padding: EdgeInsets.only(left: metrics.contentIndent),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Discount",
                              size: metrics.subtitle,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                            SizedBox(height: metrics.subtitleGap),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: "up to ",
                                  size: metrics.body,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                                SizedBox(width: metrics.badgeGap),
                                Container(
                                  height: metrics.badgeHeight,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: metrics.badgeHorizontalPadding,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      metrics.badgeRadius,
                                    ),
                                  ),
                                  child: Center(
                                    child: AppText(
                                      text: "40%",
                                      size: metrics.badgeText,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF83953D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardMetrics {
  const _CardMetrics({
    required this.height,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.image,
    required this.leftPadding,
    required this.rightPadding,
    required this.textRightPadding,
    required this.verticalPadding,
    required this.contentIndent,
    required this.titleGap,
    required this.subtitleGap,
    required this.badgeGap,
    required this.badgeHeight,
    required this.badgeText,
    required this.badgeHorizontalPadding,
    required this.badgeRadius,
    required this.imageBottom,
  });

  final double height;
  final double title;
  final double subtitle;
  final double body;
  final double image;
  final double leftPadding;
  final double rightPadding;
  final double textRightPadding;
  final double verticalPadding;
  final double contentIndent;
  final double titleGap;
  final double subtitleGap;
  final double badgeGap;
  final double badgeHeight;
  final double badgeText;
  final double badgeHorizontalPadding;
  final double badgeRadius;
  final double imageBottom;

  factory _CardMetrics.from(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final width = constraints.hasBoundedWidth && constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : screenSize.width;
    final isTablet = width >= 600;
    final fallbackHeight = (screenSize.height * (isTablet ? 0.19 : 0.17))
        .clamp(isTablet ? 190.0 : 145.0, isTablet ? 250.0 : 190.0)
        .toDouble();
    final height = constraints.hasBoundedHeight && constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : fallbackHeight;
    final title = (height * (isTablet ? 0.2 : 0.18))
        .clamp(isTablet ? 32.0 : 22.0, isTablet ? 42.0 : 30.0)
        .toDouble();
    final image = (height * (isTablet ? 0.92 : 0.78))
        .clamp(isTablet ? 160.0 : 92.0, isTablet ? 220.0 : 132.0)
        .toDouble();
    final rightPadding = isTablet
        ? (width * 0.07).clamp(32.0, 64.0).toDouble()
        : 20.0;

    return _CardMetrics(
      height: height,
      title: title,
      subtitle: (title * 0.76)
          .clamp(isTablet ? 24.0 : 16.0, isTablet ? 32.0 : 20.0)
          .toDouble(),
      body: (title * 0.55)
          .clamp(isTablet ? 17.0 : 13.0, isTablet ? 22.0 : 16.0)
          .toDouble(),
      image: image,
      leftPadding: width < 360
          ? 28.0
          : isTablet
          ? (width * 0.08).clamp(56.0, 88.0).toDouble()
          : 45.0,
      rightPadding: rightPadding,
      textRightPadding: isTablet ? image + rightPadding + 20 : 0,
      verticalPadding: isTablet ? 24.0 : 16.0,
      contentIndent: isTablet ? 42.0 : 30.0,
      titleGap: isTablet ? 12.0 : 8.0,
      subtitleGap: isTablet ? 7.0 : 4.0,
      badgeGap: isTablet ? 8.0 : 5.0,
      badgeHeight: (height * (isTablet ? 0.2 : 0.18))
          .clamp(isTablet ? 32.0 : 24.0, isTablet ? 42.0 : 30.0)
          .toDouble(),
      badgeText: (title * 0.65)
          .clamp(isTablet ? 20.0 : 16.0, isTablet ? 27.0 : 20.0)
          .toDouble(),
      badgeHorizontalPadding: isTablet ? 12.0 : 8.0,
      badgeRadius: isTablet ? 8.0 : 6.0,
      imageBottom: isTablet ? -16.0 : -13.0,
    );
  }
}
