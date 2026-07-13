import 'package:flutter/material.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/notification/notification_setting.dart';
import 'package:fudikoclient/utils/constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const _notifications = [
    _NotificationItem(
      label: '10 minutes ago',
      imagePath: 'assets/images/notification.png',
    ),
    _NotificationItem(
      label: '1 day ago',
      imagePath: 'assets/images/notification.png',
    ),
  ];

  int _currentNotificationIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: null,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppDimensions.padding(context)),
            child: IconButton(
              tooltip: 'Notification settings',
              icon: Icon(
                Icons.settings,
                color: Colors.black,
                size: Breakpoints.isTabletContext(context) ? 30 : 26,
              ),
              onPressed: () {
                slideRightWidget(
                  newPage: const NotificationSettingsPage(),
                  context: context,
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final isCompactPhone = width < 390 || height < 640;
final size = MediaQuery.sizeOf(context);

final isTablet = Breakpoints.isTabletDevice(size);
                final isDesktop = Breakpoints.isDesktop(width);
                final horizontalPadding = isDesktop
                    ? width * 0.14
                    : isTablet
                    ? width * 0.08
                    : isCompactPhone
                    ? width * 0.05
                    : width * 0.065;
                final verticalPadding = isCompactPhone
                    ? AppDimensions.gap(context)
                    : AppDimensions.padding(context);

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: _NotificationPager(
                    notifications: _notifications,
                    currentIndex: _currentNotificationIndex,
                    isCompactPhone: isCompactPhone,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                    orientation: orientation,
                    onPageChanged: (index) {
                      if (_currentNotificationIndex == index) return;
                      setState(() => _currentNotificationIndex = index);
                    },
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

class _NotificationPager extends StatelessWidget {
  const _NotificationPager({
    required this.notifications,
    required this.currentIndex,
    required this.isCompactPhone,
    required this.isTablet,
    required this.isDesktop,
    required this.orientation,
    required this.onPageChanged,
  });

  final List<_NotificationItem> notifications;
  final int currentIndex;
  final bool isCompactPhone;
  final bool isTablet;
  final bool isDesktop;
  final Orientation orientation;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = notifications.length;
        final activeIndex = currentIndex.clamp(0, count - 1).toInt();
        final dense =
            isCompactPhone ||
            constraints.maxHeight < 520 ||
            constraints.maxWidth < 360;
        final indicatorSize = isTablet || isDesktop
            ? 8.0
            : dense
            ? 6.0
            : 7.0;
        final activeIndicatorHeight = isTablet || isDesktop
            ? 24.0
            : dense
            ? 18.0
            : 21.0;
        final indicatorGap = dense ? 5.0 : 7.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: count,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return _NotificationPoster(
                  item: notifications[index],
                  index: index,
                  count: count,
                  dense: dense,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  orientation: orientation,
                );
              },
            ),
            Positioned(
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < count; index++) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: indicatorSize,
                      height: activeIndex == index
                          ? activeIndicatorHeight
                          : indicatorSize,
                      decoration: BoxDecoration(
                        color: activeIndex == index
                            ? appButtonColor
                            : appTextColor2.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(indicatorSize),
                      ),
                    ),
                    if (index != count - 1) SizedBox(height: indicatorGap),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationPoster extends StatelessWidget {
  const _NotificationPoster({
    required this.item,
    required this.index,
    required this.count,
    required this.dense,
    required this.isTablet,
    required this.isDesktop,
    required this.orientation,
  });

  final _NotificationItem item;
  final int index;
  final int count;
  final bool dense;
  final bool isTablet;
  final bool isDesktop;
  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelSize = dense || constraints.maxHeight < 520
            ? 11.5
            : isTablet || isDesktop
            ? AppDimensions.caption(context)
            : 13.0;
        final imagePadding = dense ? 6.0 : 10.0;
        final widthFactor = _contentWidthFactor(constraints.maxWidth);

        return Center(
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notification ${index + 1} of $count',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: labelSize,
                          fontWeight: FontWeight.w500,
                          color: appTextColor2,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: dense ? 6 : 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(imagePadding),
                    child: Image.asset(
                      item.imagePath,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _contentWidthFactor(double availableWidth) {
    if (isDesktop) return 0.48;
    if (isTablet && orientation == Orientation.landscape) return 0.56;
    if (isTablet) return 0.72;
    if (dense) return 0.94;
    return availableWidth > 520 ? 0.82 : 0.92;
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.label,
    required this.imagePath,
  });

  final String label;
  final String imagePath;
}
