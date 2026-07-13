
import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';

const Color _activeColor = Color(0xFFE8820C);
const Color _inactiveColor = Color(0xFF545450);

class Bottomnav extends StatelessWidget {
  const Bottomnav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.reservationBadgeCount = 0,
    this.favoriteBadgeCount = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final int reservationBadgeCount;
  final int favoriteBadgeCount;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    // Device-class decision (icon/font/padding sizing) — must use shortest
    // side, not raw width. A phone in landscape easily has width >= 600
    // and would otherwise be misclassified as a tablet and get oversized
    // nav elements.
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
        label: 'Reservation',
        iconPath: 'assets/icons/reservation_inactive 1.png',
        badge: reservationBadgeCount,
      ),
      _BottomNavItem(
        label: 'Favorite',
        iconPath: 'assets/icons/heart_inactive 1.png',
        badge: favoriteBadgeCount,
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
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
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
            final isSelected = index == selectedIndex;
            final color = isSelected ? _activeColor : _inactiveColor;

            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label: item.label,
                child: InkWell(
                  onTap: () => onTabSelected(index),
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
                              color: color,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              size: metrics.labelSize,
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
    return _BottomNavMetrics(
      verticalPadding: isTablet
          ? AppDimensions.gap(context) * 0.75
          : isCompactPhone
          ? 8.0
          : 10.0,
      itemVerticalPadding: isTablet
          ? 4.0
          : isCompactPhone
          ? 2.0
          : 4.0,
      iconSize: isTablet
          ? 32.0
          : isCompactPhone
          ? 24.0
          : 25.0,
      labelSize: isTablet
          ? 13.0
          : isCompactPhone
          ? 10.0
          : 11.0,
      labelTopGap: isTablet
          ? 6.0
          : isCompactPhone
          ? 3.0
          : 4.0,
      labelHorizontalPadding: isTablet ? 4.0 : 2.0,
      badgeSize: isTablet
          ? 20.0
          : isCompactPhone
          ? 17.0
          : 19.0,
      badgeFontSize: isTablet
          ? 11.0
          : isCompactPhone
          ? 10.0
          : 11.0,
    );
  }
}


















// import 'package:flutter/material.dart';
// import 'package:fudikoclient/components/apptext.dart';
// import 'package:fudikoclient/core/responsive/app_dimensions.dart';
// import 'package:fudikoclient/core/responsive/breakpoints.dart';

// const Color _activeColor = Color(0xFFE8820C);
// const Color _inactiveColor = Color(0xFF545450);

// class Bottomnav extends StatelessWidget {
//   const Bottomnav({
//     super.key,
//     required this.selectedIndex,
//     required this.onTabSelected,
//     this.reservationBadgeCount = 0,
//     this.favoriteBadgeCount = 0,
//   });

//   final int selectedIndex;
//   final ValueChanged<int> onTabSelected;
//   final int reservationBadgeCount;
//   final int favoriteBadgeCount;

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.sizeOf(context).width;
//     final height = MediaQuery.sizeOf(context).height;
//     final isTablet = Breakpoints.isTablet(width);
//     final isCompactPhone = width < 360 || height < 700;

//     final metrics = _BottomNavMetrics.fromWidth(
//       context: context,
//       width: width,
//       isCompactPhone: isCompactPhone,
//       isTablet: isTablet,
//     );

//     final items = [
//       const _BottomNavItem(
//         label: 'Home',
//         iconPath: 'assets/icons/home_inactive 1.png',
//       ),
//       _BottomNavItem(
//         label: 'Reservation',
//         iconPath: 'assets/icons/reservation_inactive 1.png',
//         badge: reservationBadgeCount,
//       ),
//       _BottomNavItem(
//         label: 'Favorite',
//         iconPath: 'assets/icons/heart_inactive 1.png',
//         badge: favoriteBadgeCount,
//       ),
//       const _BottomNavItem(
//         label: 'Profile',
//         iconPath: 'assets/icons/user_inactive 1.png',
//       ),
//     ];

//     return SafeArea(
//       top: false,
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: metrics.verticalPadding),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 24,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: items.asMap().entries.map((entry) {
//             final index = entry.key;
//             final item = entry.value;
//             final isSelected = index == selectedIndex;
//             final color = isSelected ? _activeColor : _inactiveColor;

//             return Expanded(
//               child: Semantics(
//                 button: true,
//                 selected: isSelected,
//                 label: item.label,
//                 child: InkWell(
//                   onTap: () => onTabSelected(index),
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(
//                       vertical: metrics.itemVerticalPadding,
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Stack(
//                           clipBehavior: Clip.none,
//                           children: [
//                             ColorFiltered(
//                               colorFilter: ColorFilter.mode(
//                                 color,
//                                 BlendMode.srcIn,
//                               ),
//                               child: Image.asset(
//                                 item.iconPath,
//                                 width: metrics.iconSize,
//                                 height: metrics.iconSize,
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                             if (item.badge > 0)
//                               _Badge(
//                                 count: item.badge,
//                                 size: metrics.badgeSize,
//                                 fontSize: metrics.badgeFontSize,
//                               ),
//                           ],
//                         ),
//                         SizedBox(height: metrics.labelTopGap),
//                         Padding(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: metrics.labelHorizontalPadding,
//                           ),
//                           child: FittedBox(
//                             fit: BoxFit.scaleDown,
//                             child: AppText(
//                               text: item.label,
//                               color: color,
//                               fontWeight: isSelected
//                                   ? FontWeight.w700
//                                   : FontWeight.w500,
//                               size: metrics.labelSize,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }

// class _Badge extends StatelessWidget {
//   const _Badge({
//     required this.count,
//     required this.size,
//     required this.fontSize,
//   });

//   final int count;
//   final double size;
//   final double fontSize;

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       top: -6,
//       right: -7,
//       child: Container(
//         constraints: BoxConstraints(minWidth: size, minHeight: size),
//         padding: EdgeInsets.symmetric(horizontal: size * 0.2),
//         decoration: const BoxDecoration(
//           color: Colors.red,
//           shape: BoxShape.circle,
//         ),
//         alignment: Alignment.center,
//         child: AppText(
//           text: '$count',
//           size: fontSize,
//           fontWeight: FontWeight.w700,
//           color: Colors.white,
//           lineSpacing: 1,
//         ),
//       ),
//     );
//   }
// }

// class _BottomNavItem {
//   const _BottomNavItem({
//     required this.label,
//     required this.iconPath,
//     this.badge = 0,
//   });

//   final String label;
//   final String iconPath;
//   final int badge;
// }

// class _BottomNavMetrics {
//   const _BottomNavMetrics({
//     required this.verticalPadding,
//     required this.itemVerticalPadding,
//     required this.iconSize,
//     required this.labelSize,
//     required this.labelTopGap,
//     required this.labelHorizontalPadding,
//     required this.badgeSize,
//     required this.badgeFontSize,
//   });

//   final double verticalPadding;
//   final double itemVerticalPadding;
//   final double iconSize;
//   final double labelSize;
//   final double labelTopGap;
//   final double labelHorizontalPadding;
//   final double badgeSize;
//   final double badgeFontSize;

//   factory _BottomNavMetrics.fromWidth({
//     required BuildContext context,
//     required double width,
//     required bool isCompactPhone,
//     required bool isTablet,
//   }) {
//     return _BottomNavMetrics(
//       verticalPadding: isTablet
//           ? AppDimensions.gap(context) * 0.75
//           : isCompactPhone
//           ? 8.0
//           : 10.0,
//       itemVerticalPadding: isTablet
//           ? 4.0
//           : isCompactPhone
//           ? 2.0
//           : 4.0,
//       iconSize: isTablet
//           ? 32.0
//           : isCompactPhone
//           ? 24.0
//           : 25.0,
//       labelSize: isTablet
//           ? 13.0
//           : isCompactPhone
//           ? 10.0
//           : 11.0,
//       labelTopGap: isTablet
//           ? 6.0
//           : isCompactPhone
//           ? 3.0
//           : 4.0,
//       labelHorizontalPadding: isTablet ? 4.0 : 2.0,
//       badgeSize: isTablet
//           ? 20.0
//           : isCompactPhone
//           ? 17.0
//           : 19.0,
//       badgeFontSize: isTablet
//           ? 11.0
//           : isCompactPhone
//           ? 10.0
//           : 11.0,
//     );
//   }
// }
