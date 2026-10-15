import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/notification/notification_badges_model.dart';
import 'package:fudikoclient/service/notification/badge_controller.dart';

const Color _activeColor = Color(0xFFE8820C);
const Color _inactiveColor = Color(0xFF545450);

/// The count each tab shows, by tab index. A null means the tab has no badge
/// (Home, Profile).
const List<int Function(NotificationBadgesModel)?> _badgeSelectors = [
  null,
  _cateringEnquiries,
  _cateringReservations,
  null,
];

int _cateringEnquiries(NotificationBadgesModel b) => b.cateringEnquiries;
int _cateringReservations(NotificationBadgesModel b) => b.cateringReservations;

class CateringBottomnav extends StatefulWidget {
  const CateringBottomnav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onSelectedTabBadgeChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  /// Fired when a poll finds the *selected* tab's badge count has changed — new
  /// activity landed on the page the customer is looking at, so the shell can
  /// reload it instead of leaving a stale list under a bumped badge.
  final VoidCallback? onSelectedTabBadgeChanged;

  @override
  State<CateringBottomnav> createState() => _CateringBottomnavState();
}

class _CateringBottomnavState extends State<CateringBottomnav> {
  final BadgeController _controller = BadgeController.instance;
  late NotificationBadgesModel _badges;
  late bool _hasSeenCounts;

  @override
  void initState() {
    super.initState();
    // Seed from whatever the controller already knows so a nav mounted later
    // paints the right counts on its first frame.
    _badges = _controller.badges;
    _hasSeenCounts = _controller.hasFetchedOnce;
    _controller.addListener(_onBadgesChanged);
    _controller.subscribe();
  }

  @override
  void dispose() {
    _controller.removeListener(_onBadgesChanged);
    _controller.unsubscribe();
    super.dispose();
  }

  void _onBadgesChanged() {
    if (!mounted) return;

    final previous = _badges;
    final hadCounts = _hasSeenCounts;
    _hasSeenCounts = true;
    setState(() => _badges = _controller.badges);

    // The first counts only seed — every non-zero badge would otherwise read
    // as "changed" and refresh a page that just loaded.
    if (hadCounts &&
        _badgeFor(widget.selectedIndex, previous) !=
            _badgeFor(widget.selectedIndex, _badges)) {
      widget.onSelectedTabBadgeChanged?.call();
    }
  }

  int _badgeFor(int index, NotificationBadgesModel badges) {
    final selector = index >= 0 && index < _badgeSelectors.length
        ? _badgeSelectors[index]
        : null;
    return selector == null ? 0 : selector(badges);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    // Use shortestSide so landscape phones are not treated as tablets.
    final isTablet = Breakpoints.isTabletDevice(size);
    final isCompactPhone = width < 360 || height < 700;

    final metrics = _BottomNavMetrics.fromWidth(
      context: context,
      width: width,
      isCompactPhone: isCompactPhone,
      isTablet: isTablet,
    );

    final items = [
      const _BottomNavItem(
        label: 'Home',
        iconPath: 'assets/icons/home_inactive 1.png',
      ),
      _BottomNavItem(
        label: 'Inquries',
        iconPath: 'assets/icons/history.png',
        badge: _badgeFor(1, _badges),
      ),
      _BottomNavItem(
        label: 'Reservation',
        iconPath: 'assets/icons/reservation_inactive 1.png',
        badge: _badgeFor(2, _badges),
      ),
      const _BottomNavItem(
        label: 'Profile',
        iconPath: 'assets/icons/user_inactive 1.png',
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: metrics.verticalPadding),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 24,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == widget.selectedIndex;
            final color = isSelected ? _activeColor : _inactiveColor;

            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label: item.label,
                child: InkWell(
                  onTap: () => widget.onTabSelected(index),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: metrics.itemVerticalPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                color,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                item.iconPath,
                                width: metrics.iconSize,
                                height: metrics.iconSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (item.badge > 0)
                              _Badge(
                                count: item.badge,
                                size: metrics.badgeSize,
                                fontSize: metrics.badgeFontSize,
                              ),
                          ],
                        ),
                        SizedBox(height: metrics.labelTopGap),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: metrics.labelHorizontalPadding,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AppText(
                              text: item.label,
                              size: metrics.labelSize,
                              color: color,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.count,
    required this.size,
    required this.fontSize,
  });

  final int count;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -6,
      right: -7,
      child: Container(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        padding: EdgeInsets.symmetric(horizontal: size * 0.2),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: AppText(
          text: '$count',
          size: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          lineSpacing: 1,
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.label,
    required this.iconPath,
    this.badge = 0,
  });

  final String label;
  final String iconPath;
  final int badge;
}

class _BottomNavMetrics {
  const _BottomNavMetrics({
    required this.verticalPadding,
    required this.itemVerticalPadding,
    required this.iconSize,
    required this.labelSize,
    required this.labelTopGap,
    required this.labelHorizontalPadding,
    required this.badgeSize,
    required this.badgeFontSize,
  });

  final double verticalPadding;
  final double itemVerticalPadding;
  final double iconSize;
  final double labelSize;
  final double labelTopGap;
  final double labelHorizontalPadding;
  final double badgeSize;
  final double badgeFontSize;

  factory _BottomNavMetrics.fromWidth({
    required BuildContext context,
    required double width,
    required bool isCompactPhone,
    required bool isTablet,
  }) {
    final compactLandscape = !isTablet && width > 700;

    return _BottomNavMetrics(
      verticalPadding: compactLandscape
          ? 6
          : isTablet
          ? AppDimensions.gap(context) * 0.75
          : isCompactPhone
          ? 8
          : 10,
      itemVerticalPadding: compactLandscape
          ? 2
          : isTablet
          ? 4
          : isCompactPhone
          ? 2
          : 4,
      iconSize: compactLandscape
          ? 22
          : isTablet
          ? 32
          : isCompactPhone
          ? 24
          : 25,
      labelSize: compactLandscape
          ? 10
          : isTablet
          ? 13
          : isCompactPhone
          ? 10
          : 11,
      labelTopGap: compactLandscape
          ? 2
          : isTablet
          ? 6
          : isCompactPhone
          ? 3
          : 4,
      labelHorizontalPadding: compactLandscape
          ? 0
          : isTablet
          ? 4
          : 2,
      badgeSize: compactLandscape
          ? 16
          : isTablet
          ? 20
          : isCompactPhone
          ? 17
          : 19,
      badgeFontSize: compactLandscape
          ? 9
          : isTablet
          ? 11
          : isCompactPhone
          ? 10
          : 11,
    );
  }
}
