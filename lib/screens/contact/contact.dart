import 'package:flutter/material.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/support/support_information_model.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/service/support/support_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final SupportService _supportService = SupportService();

  SupportInformationModel? _supportInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSupportInformation();
  }

  Future<void> _fetchSupportInformation() async {
    final result = await _supportService.getSupportInformation();

    if (!mounted) return;
    setState(() {
      _supportInfo = result;
      _isLoading = false;
    });
  }

List<_ContactItem> get _items => [
        _ContactItem(
          label: 'Mail Us',
          icon: Icons.mail,
          onTap: () => _launchMail(_supportInfo?.contactEmail),
        ),
        _ContactItem(
          label: 'Chat with Us',
          icon: Icons.message,
          onTap: () => _launchUrl(_supportInfo?.chatLink),
        ),
        _ContactItem(
          label: 'Contact Us',
          icon: Icons.phone,
          onTap: () => _launchPhone(_supportInfo?.contactUsPhone),
        ),
      ];

  Future<void> _launchMail(String? email) async {
    if (email == null || email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String? link) async {
    if (link == null || link.isEmpty) return;
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                final metrics = _ContactLayoutMetrics.fromConstraints(
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
                            width: metrics.backSize,
                            height: metrics.backSize,
                          ),
                        ),
                      ),
                      Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            top: metrics.backTop +
                                metrics.backSize +
                                metrics.contentTopGap,
                            bottom: metrics.bottomPadding,
                          ),
                          child: FractionallySizedBox(
                            widthFactor: metrics.contentWidthFactor,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var index = 0; index < _items.length; index++) ...[
                                  _ContactCard(
                                    item: _items[index],
                                    metrics: metrics,
                                  ),
                                  if (index != _items.length - 1)
                                    SizedBox(height: metrics.cardGap),
                                ],
                              ],
                            ),
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

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.item,
    required this.metrics,
  });

  final _ContactItem item;
  final _ContactLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return InkWell(
       onTap: item.onTap,
      child: Container(
        width: double.infinity,
        height: metrics.cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(metrics.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: metrics.shadowBlur,
              offset: Offset(0, metrics.shadowOffsetY),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.cardHorizontalPadding),
          child: Row(
            children: [
              Icon(item.icon, size: metrics.iconSize, color: appButtonColor),
              SizedBox(width: metrics.iconGap),
              Expanded(
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: metrics.labelSize,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
                  ),
                ),
              ),
              SizedBox(width: metrics.trailingBalanceWidth),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactItem {
  const _ContactItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ContactLayoutMetrics {
  const _ContactLayoutMetrics({
    required this.pageHorizontalPadding,
    required this.contentWidthFactor,
    required this.backTop,
    required this.backSize,
    required this.contentTopGap,
    required this.bottomPadding,
    required this.cardHeight,
    required this.cardRadius,
    required this.cardGap,
    required this.cardHorizontalPadding,
    required this.iconSize,
    required this.iconGap,
    required this.labelSize,
    required this.trailingBalanceWidth,
    required this.shadowBlur,
    required this.shadowOffsetY,
  });

  final double pageHorizontalPadding;
  final double contentWidthFactor;
  final double backTop;
  final double backSize;
  final double contentTopGap;
  final double bottomPadding;
  final double cardHeight;
  final double cardRadius;
  final double cardGap;
  final double cardHorizontalPadding;
  final double iconSize;
  final double iconGap;
  final double labelSize;
  final double trailingBalanceWidth;
  final double shadowBlur;
  final double shadowOffsetY;

  factory _ContactLayoutMetrics.fromConstraints({
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

    return _ContactLayoutMetrics(
      pageHorizontalPadding: isTablet
          ? (isLandscape ? width * 0.06 : width * 0.08)
          : isCompactLandscape
          ? width * 0.045
          : isCompactPhone
          ? width * 0.06
          : width * 0.075,
      contentWidthFactor: isTablet
          ? (isTabletLandscape ? 0.46 : 0.58)
          : 1.0,
      backTop: isTablet
          ? (isLandscape ? 18.0 : 36.0)
          : isCompactLandscape
          ? 10.0
          : isCompactPhone
          ? 22.0
          : 40.0,
      backSize: isTablet
          ? (isLandscape ? 30.0 : 34.0)
          : isCompactLandscape
          ? 24.0
          : isCompactPhone
          ? 26.0
          : 30.0,
      contentTopGap: isTablet
          ? (isLandscape ? AppDimensions.gap(context) * 0.9 : AppDimensions.margin(context) * 1.2)
          : isCompactLandscape
          ? 18.0
          : isCompactPhone
          ? 40.0
          : 50.0,
      bottomPadding: isTablet
          ? (isLandscape ? AppDimensions.gap(context) : AppDimensions.margin(context))
          : isCompactLandscape
          ? 14.0
          : isCompactPhone
          ? 20.0
          : 24.0,
      cardHeight: isTablet
          ? (isLandscape ? 72.0 : 82.0)
          : isCompactLandscape
          ? 56.0
          : isCompactPhone
          ? 64.0
          : 70.0,
      cardRadius: isTablet
          ? (isLandscape ? 14.0 : 16.0)
          : isCompactLandscape
          ? 12.0
          : isCompactPhone
          ? 13.0
          : 15.0,
      cardGap: isTablet
          ? (isLandscape ? 18.0 : 24.0)
          : isCompactLandscape
          ? 14.0
          : 20.0,
      cardHorizontalPadding: isTablet
          ? (isLandscape ? 18.0 : 24.0)
          : isCompactLandscape
          ? 12.0
          : isCompactPhone
          ? 16.0
          : 20.0,
      iconSize: isTablet
          ? (isLandscape ? 32.0 : 38.0)
          : isCompactLandscape
          ? 26.0
          : isCompactPhone
          ? 30.0
          : 35.0,
      iconGap: isTablet
          ? (isLandscape ? 16.0 : 24.0)
          : isCompactLandscape
          ? 12.0
          : isCompactPhone
          ? 16.0
          : 20.0,
      labelSize: isTablet
          ? (isLandscape ? AppDimensions.body(context) * 0.95 : AppDimensions.body(context) + 1)
          : isCompactLandscape
          ? 14.0
          : isCompactPhone
          ? 15.0
          : 16.0,
      trailingBalanceWidth: isTablet
          ? (isLandscape ? 44.0 : 62.0)
          : isCompactLandscape
          ? 28.0
          : isCompactPhone
          ? 36.0
          : 50.0,
      shadowBlur: isTablet ? (isLandscape ? 7.0 : 10.0) : 8.0,
      shadowOffsetY: isTablet ? (isLandscape ? 1.5 : 3.0) : 2.0,
    );
  }
}
