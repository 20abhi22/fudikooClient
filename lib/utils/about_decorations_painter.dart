import 'package:flutter/material.dart';

enum AboutDecorStyle { style1, style2, style3, style4 }

class AboutDecorationsPainter extends CustomPainter {
  final AboutDecorStyle style;
  AboutDecorationsPainter({required this.style});

  void _drawRing(Canvas canvas, Offset center, double radius,
      Color color, double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (style) {
      case AboutDecorStyle.style1:
        // Top-left large grey ring (around food image)
        _drawRing(canvas, Offset(w * -0.05, h * -0.045),
            w * 0.475, Colors.grey.shade300, w * 0.06);
        // Top-right small orange ring
        _drawRing(canvas, Offset(w * 1.08, h * 0.148),
            w * 0.145, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.026);
        // Bottom-right medium orange ring
        _drawRing(canvas, Offset(w * 1.12, h * 0.935),
            w * 0.31, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.026);
        // Bottom-left small orange ring
        _drawRing(canvas, Offset(w * -0.08, h * 1.04),
            w * 0.22, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.051);
        break;

      case AboutDecorStyle.style2:
        // Top-right grey ring
        _drawRing(canvas, Offset(w * 1.18, h * 0.145),
            w * 0.395, const Color(0xFFD9D9D9).withOpacity(0.58), w * 0.051);
        // Bottom-right dark grey ring (around bottom pizza)
        _drawRing(canvas, Offset(w * 1.05, h * 1.08),
            w * 0.48, const Color(0xFF545450).withOpacity(0.22), w * 0.051);
        // Bottom-left orange ring
        _drawRing(canvas, Offset(w * -0.25, h * 0.935),
            w * 0.31, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.026);
        // Top-left small orange ring
        _drawRing(canvas, Offset(w * -0.08, h * 0.148),
            w * 0.145, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.026);
        break;

      case AboutDecorStyle.style3:
        // Top-right large grey ring (around food image)
        _drawRing(canvas, Offset(w * 1.05, h * -0.045),
            w * 0.475, Colors.grey.shade300, w * 0.06);
        // Top-left small orange ring
        _drawRing(canvas, Offset(w * -0.08, h * 0.148),
            w * 0.145, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.026);
        // Bottom-left medium orange ring
        _drawRing(canvas, Offset(w * -0.12, h * 0.935),
            w * 0.31, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.026);
        // Bottom-right small orange ring
        _drawRing(canvas, Offset(w * 1.08, h * 1.04),
            w * 0.22, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.051);
        break;

      case AboutDecorStyle.style4:
        // Top-left thin orange ring
        _drawRing(canvas, Offset(w * -0.08, h * -0.055),
            w * 0.33, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.013);
        // Top-right medium orange ring
        _drawRing(canvas, Offset(w * 1.08, h * 0.085),
            w * 0.25, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.026);
        // Bottom-right grey ring (around food image)
        _drawRing(canvas, Offset(w * 1.05, h * 0.72),
            w * 0.345, Colors.grey.shade300, w * 0.064);
        // Bottom-left thick orange ring
        _drawRing(canvas, Offset(w * -0.05, h * 1.06),
            w * 0.41, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.026);
        // Top-right small orange ring
        _drawRing(canvas, Offset(w * 1.08, h * 0.185),
            w * 0.115, const Color(0xFFF97A0D).withOpacity(0.58), w * 0.026);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant AboutDecorationsPainter old) =>
      old.style != style;
}