import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';

class CateringBox extends StatelessWidget {
  const CateringBox({super.key});

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
              colors: [Color(0xff43cf40), Color(0xff226920)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: metrics.imageBottom,
                right: metrics.rightPadding,
                child: Image.asset(
                  'assets/images/boxbg3.png',
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
                        text: "Catering",
                        size: metrics.title,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        isShadow: true,
                      ),
                      SizedBox(height: metrics.titleGap),
                      AppText(
                        text: "Book your functions with",
                        size: metrics.body,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      SizedBox(height: metrics.lineGap),
                      AppText(
                        text: "exclusive discounts and avail",
                        size: metrics.body,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      SizedBox(height: metrics.lineGap),
                      AppText(
                        text: "best Services in Less Price!",
                        size: metrics.body,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
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
    required this.body,
    required this.image,
    required this.leftPadding,
    required this.rightPadding,
    required this.textRightPadding,
    required this.verticalPadding,
    required this.titleGap,
    required this.lineGap,
    required this.imageBottom,
  });

  final double height;
  final double title;
  final double body;
  final double image;
  final double leftPadding;
  final double rightPadding;
  final double textRightPadding;
  final double verticalPadding;
  final double titleGap;
  final double lineGap;
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
      body: (title * (isTablet ? 0.5 : 0.43))
          .clamp(isTablet ? 16.0 : 11.0, isTablet ? 20.0 : 13.0)
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
      titleGap: isTablet ? 12.0 : 8.0,
      lineGap: isTablet ? 6.0 : 4.0,
      imageBottom: isTablet ? -8.0 : -4.0,
    );
  }
}
