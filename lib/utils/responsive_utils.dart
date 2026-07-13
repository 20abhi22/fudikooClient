// lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

class R {
  static late double width;
  static late double height;
  static late bool isTablet;

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    width = mq.size.width;
    height = mq.size.height;
    isTablet = mq.size.shortestSide >= 600;
  }

  /// Scale a size designed for 390px phone — capped on tablet
  static double s(double size) {
    final scale = width / 390;
    // Cap scale at 1.3x on tablets so things don't get huge
    return size * scale.clamp(0.8, 1.3);
  }

  /// Font size — even less aggressive, capped at 1.15x
  static double f(double size) {
    final scale = width / 390;
    return size * scale.clamp(0.85, 1.15);
  }

  /// Image size — capped so images don't dominate the screen
  static double img(double fraction) {
    final raw = width * fraction;
    // On tablets, cap image at 45% of screen height so they don't overflow
    final maxH = height * 0.45;
    return raw > maxH ? maxH : raw;
  }

  static double get hPad => isTablet ? width * 0.08 : width * 0.05;
  static double get vPad => isTablet ? height * 0.06 : height * 0.05;
}
