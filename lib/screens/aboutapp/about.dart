import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  static const _paragraphs = [
    "Fudikoo Partner App is the ultimate app for food lovers who want to enjoy the best dining experiences with smart deals and seamless service. Whether you're looking for a quick takeaway, planning a party, or just craving something special, Fudikoo helps you discover great restaurants and exclusive offers near you - right when you need them. With Fudikoo, you can explore real-time deals and special discounts from top restaurants in your area. These offers are available during specific hours, dates, or low-traffic times - so you can enjoy quality food at the best prices.",
    "Planning a celebration or a corporate event? The app lets you easily send banquet requests to restaurants. Just share your party details, and you'll receive customized quotations directly from venues, making it effortless to compare packages and choose the perfect spot for your event. Fudikoo also makes takeaway orders simple and fast. Browse menus, place your order, and pick it up at your convenience - no waiting, no confusion, just great food on the go. As you use the app and interact with top-rated restaurants, you'll also see badges that showcase their service quality, helping you make informed decisions and enjoy the best experiences.",
    'Fudikoo Client App is your smart companion for discovering great food, unlocking amazing deals, and planning memorable dining moments.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final metrics = _AboutLayoutMetrics.fromConstraints(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _CenteredContent(
                              widthFactor: metrics.contentWidthFactor,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: metrics.horizontalPadding,
                                  vertical: metrics.contentVerticalPadding,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, contentConstraints) {
                                    final minHeight =
                                        (contentConstraints.maxHeight -
                                                metrics.scrollBottomGap)
                                            .clamp(0.0, double.infinity);

                                    return SingleChildScrollView(
                                      padding: EdgeInsets.only(
                                        top: metrics.backTop +
                                            metrics.backSize +
                                            metrics.titleTopGap,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: (minHeight -
                                                  metrics.titleTopGap)
                                              .clamp(0.0, double.infinity),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              AppText(
                                                text: 'About the App',
                                                size: metrics.titleSize,
                                                fontWeight: FontWeight.bold,
                                                color: appTextColor2,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                isCentered: false,
                                              ),
                                              SizedBox(
                                                height: metrics.titleTopGap,
                                              ),
                                              for (final paragraph
                                                  in _paragraphs) ...[
                                                AppText(
                                                  text: paragraph,
                                                  size: metrics.bodySize,
                                                  fontWeight: FontWeight.w400,
                                                  color: appTextColor2,
                                                  lineSpacing: 1.6,
                                                  maxLines: 40,
                                                ),
                                                SizedBox(
                                                  height:
                                                      metrics.paragraphGap,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: metrics.versionBottom,
                            ),
                            child: FutureBuilder<PackageInfo>(
                              future: _packageInfoFuture,
                              builder: (context, snapshot) {
                                final versionText =
                                    snapshot.connectionState ==
                                                ConnectionState.done &&
                                            snapshot.hasData
                                        ? 'Version ${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                                        : 'Version ...';

                                return AppText(
                                  text: versionText,
                                  size: metrics.versionSize,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  isCentered: true,
                                );
                              },
                            ),
                          ),
                        ],
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

class _CenteredContent extends StatelessWidget {
  const _CenteredContent({
    required this.widthFactor,
    required this.child,
  });

  final double widthFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: child,
      ),
    );
  }
}

class _AboutLayoutMetrics {
  const _AboutLayoutMetrics({
    required this.contentWidthFactor,
    required this.pageHorizontalPadding,
    required this.horizontalPadding,
    required this.backTop,
    required this.backSize,
    required this.titleTopGap,
    required this.contentVerticalPadding,
    required this.paragraphGap,
    required this.scrollBottomGap,
    required this.versionBottom,
    required this.titleSize,
    required this.bodySize,
    required this.versionSize,
  });

  final double contentWidthFactor;
  final double pageHorizontalPadding;
  final double horizontalPadding;
  final double backTop;
  final double backSize;
  final double titleTopGap;
  final double contentVerticalPadding;
  final double paragraphGap;
  final double scrollBottomGap;
  final double versionBottom;
  final double titleSize;
  final double bodySize;
  final double versionSize;

  factory _AboutLayoutMetrics.fromConstraints({
    required BuildContext context,
    required BoxConstraints constraints,
    required Orientation orientation,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isCompactPhone = width < 390 || height < 640;
    final isCompactLandscape = isLandscape && height < 500;
    final isTablet = Breakpoints.isTabletDevice(size);
    final isTabletLandscape = isTablet && isLandscape;

    return _AboutLayoutMetrics(
        contentWidthFactor: isTabletLandscape
          ? 0.68
          : isTablet
          ? 0.74
          : 1.0,
        pageHorizontalPadding: isTablet
          ? (isLandscape ? width * 0.06 : width * 0.08)
          : isCompactLandscape
          ? width * 0.045
          : isCompactPhone
          ? width * 0.06
          : width * 0.075,
        horizontalPadding: isTablet
          ? (isLandscape ? width * 0.045 : width * 0.055)
          : isCompactLandscape
          ? width * 0.04
          : isCompactPhone
          ? width * 0.06
          : width * 0.075,
        backTop: isTablet
          ? (isLandscape ? 18.0 : 36.0)
          : isCompactLandscape
          ? 10.0
          : isCompactPhone
          ? 18.0
          : 40.0,
        backSize: isTablet
          ? (isLandscape ? 30.0 : 34.0)
          : isCompactLandscape
          ? 24.0
          : isCompactPhone
          ? 28.0
          : 30.0,
        titleTopGap: isTablet
          ? (isLandscape ? AppDimensions.gap(context) * 0.9 : AppDimensions.margin(context) * 1.15)
          : isCompactLandscape
          ? 12.0
          : isCompactPhone
          ? 22.0
          : 40.0,
        contentVerticalPadding: isTablet
          ? (isLandscape ? AppDimensions.gap(context) : AppDimensions.padding(context))
          : isCompactLandscape
          ? 10.0
          : isCompactPhone
          ? 12.0
          : 20.0,
        paragraphGap: isTablet
          ? (isLandscape ? AppDimensions.gap(context) * 0.8 : AppDimensions.gap(context))
          : isCompactLandscape
          ? 8.0
          : isCompactPhone
          ? 10.0
          : 12.0,
        scrollBottomGap: isTablet
          ? (isLandscape ? AppDimensions.gap(context) * 1.2 : AppDimensions.margin(context))
          : isCompactLandscape
          ? 14.0
          : isCompactPhone
          ? 24.0
          : 50.0,
        versionBottom: isTablet
          ? (isLandscape ? AppDimensions.gap(context) : AppDimensions.padding(context))
          : isCompactLandscape
          ? 10.0
          : isCompactPhone
          ? 16.0
          : 30.0,
        titleSize: isTablet ? (isLandscape ? AppDimensions.title(context) * 0.95 : AppDimensions.title(context)) : 20.0,
        bodySize: isTablet
          ? (isLandscape ? AppDimensions.body(context) * 0.95 : AppDimensions.body(context))
          : isCompactLandscape
          ? 13.0
          : isCompactPhone
          ? 14.0
          : 15.0,
        versionSize: isTablet ? AppDimensions.caption(context) : 13.0,
    );
  }
}
