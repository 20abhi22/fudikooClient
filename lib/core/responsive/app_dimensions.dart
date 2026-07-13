import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';

class AppDimensions {
  const AppDimensions._();

  static double headline(BuildContext context) => _font(context, 28, 34, 40);

  static double title(BuildContext context) => _font(context, 20, 24, 28);

  static double body(BuildContext context) => _font(context, 14, 16, 18);

  static double caption(BuildContext context) => _font(context, 12, 13, 14);

  static double padding(BuildContext context) => _space(context, 16, 24, 32);

  static double gap(BuildContext context) => _space(context, 12, 16, 20);

  static double margin(BuildContext context) => _space(context, 16, 28, 40);

  static EdgeInsets pagePadding(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    final base = padding(context);

return EdgeInsets.fromLTRB(
  math.max(base, safePadding.left + base),
  math.max(base, safePadding.top + base),
  math.max(base, safePadding.right + base),
  math.max(base, safePadding.bottom + base),
);
  }

  static double gridGap(BuildContext context) => _space(context, 12, 18, 24);

  static int gridColumnsForWidth(double width) {
    return (width / 280).floor().clamp(1, 6).toInt();
  }

  static double _font(
    BuildContext context,
    double mobile,
    double tablet,
    double desktop,
  ) {
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cappedTextScale = textScale.clamp(1.0, 1.2).toDouble();
    final value = _select(size, mobile, tablet, desktop);

    return (value / cappedTextScale).clamp(mobile, desktop).toDouble();
  }

  static double _space(
    BuildContext context,
    double mobile,
    double tablet,
    double desktop,
  ) {
    return _select(MediaQuery.sizeOf(context), mobile, tablet, desktop);
  }

  static double _select(
    Size size,
    double mobile,
    double tablet,
    double desktop,
  ) {
    if (Breakpoints.isDesktop(size.width) ||
        Breakpoints.isDesktopDevice(size)) {
      return desktop;
    }
    if (Breakpoints.isTabletDevice(size)) return tablet;
    return mobile;
  }
}
