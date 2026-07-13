// import 'package:flutter/widgets.dart';

// class Breakpoints {
//   const Breakpoints._();

//   static const double mobileMax = 599;
//   static const double tabletMin = 600;
//   static const double tabletMax = 1199;
//   static const double desktopMin = 1200;

//   static bool isMobile(double width) => width < tabletMin;

//   static bool isTablet(double width) =>
//       width >= tabletMin && width < desktopMin;

//   static bool isDesktop(double width) => width >= desktopMin;

//   static bool isTabletDevice(Size size) => size.shortestSide >= tabletMin;

//   static bool isDesktopDevice(Size size) => size.longestSide >= desktopMin;

//   static bool isMobileDevice(Size size) => size.shortestSide < tabletMin;

//   static bool isMobileContext(BuildContext context) =>
//       isMobile(MediaQuery.sizeOf(context).width);

//   static bool isTabletContext(BuildContext context) =>
//       isTabletDevice(MediaQuery.sizeOf(context));

//   static bool isDesktopContext(BuildContext context) =>
//       isDesktopDevice(MediaQuery.sizeOf(context));
// }

import 'package:flutter/widgets.dart';

class Breakpoints {
  const Breakpoints._();

  static const double mobileMax = 599;
  static const double tabletMin = 600;
  static const double tabletMax = 1199;
  static const double desktopMin = 1200;

  /// Width-only check. A phone in landscape routinely has width >= 600,
  /// so this alone is NOT safe for "is this device a tablet" decisions
  /// (fonts, padding, icon sizes, card dimensions). Use [isTabletDevice]
  /// for those. Reserve this for genuine "how much horizontal space do I
  /// have right now" layout math — grid column counts, whether content
  /// fits at the current constraints, split-view thresholds, etc.
  static bool isMobile(double width) => width < tabletMin;

  /// See [isMobile] — width-only, same caveat applies.
  static bool isTablet(double width) =>
      width >= tabletMin && width < desktopMin;

  /// See [isMobile] — width-only, same caveat applies.
  static bool isDesktop(double width) => width >= desktopMin;

  /// Shortest-side check. Use this for device-class decisions (styling,
  /// sizing, sheet widths) that should stay stable across orientation —
  /// a phone rotated to landscape should still be styled like a phone.
  static bool isTabletDevice(Size size) => size.shortestSide >= tabletMin;

  static bool isDesktopDevice(Size size) => size.longestSide >= desktopMin;

  static bool isMobileDevice(Size size) => size.shortestSide < tabletMin;

  static bool isMobileContext(BuildContext context) =>
      isMobile(MediaQuery.sizeOf(context).width);

  static bool isTabletContext(BuildContext context) =>
      isTabletDevice(MediaQuery.sizeOf(context));

  static bool isDesktopContext(BuildContext context) =>
      isDesktopDevice(MediaQuery.sizeOf(context));
}