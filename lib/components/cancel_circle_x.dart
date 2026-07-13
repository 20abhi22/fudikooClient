import 'package:flutter/material.dart';

class CancelCircleX extends StatefulWidget {
  const CancelCircleX({
    super.key,
    this.size = 96,
    this.autoPlay = true,
    this.onCompleted,
  });

  final double size;
  final bool autoPlay;
  final VoidCallback? onCompleted;

  @override
  State<CancelCircleX> createState() => CancelCircleXState();
}

class CancelCircleXState extends State<CancelCircleX>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScale;
  late final Animation<double> _circleOpacity;
  late final Animation<double> _line1Progress;
  late final Animation<double> _line2Progress;

  static const _totalDuration = Duration(milliseconds: 1700);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration);

    _circleScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.0,
              end: 1.08,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 55,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.08,
              end: 0.97,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 20,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 0.97,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 25,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 750 / 1700),
          ),
        );

    _circleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 150 / 1700, curve: Curves.easeOut),
    );

    _line1Progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(1250 / 1700, 1450 / 1700, curve: Curves.easeOut),
    );

    _line2Progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(1430 / 1700, 1650 / 1700, curve: Curves.easeOut),
    );

    if (widget.autoPlay) {
      _controller.forward();
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
  }

  void replay() {
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CancelCirclePainter(
              circleScale: _circleScale.value,
              circleOpacity: _circleOpacity.value,
              line1Progress: _line1Progress.value,
              line2Progress: _line2Progress.value,
            ),
          );
        },
      ),
    );
  }
}

class _CancelCirclePainter extends CustomPainter {
  _CancelCirclePainter({
    required this.circleScale,
    required this.circleOpacity,
    required this.line1Progress,
    required this.line2Progress,
  });

  final double circleScale;
  final double circleOpacity;
  final double line1Progress;
  final double line2Progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.49;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(circleScale);
    canvas.translate(-center.dx, -center.dy);

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFF5B55).withValues(alpha: circleOpacity),
          const Color(0xFFE33636).withValues(alpha: circleOpacity),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, gradientPaint);

    canvas.restore();

    final iconRect = Rect.fromCenter(
      center: center,
      width: radius * 2 * 0.84,
      height: radius * 2 * 0.84,
    );

    Offset lerp(Offset a, Offset b, Rect r) =>
        Offset(r.left + a.dx * r.width, r.top + a.dy * r.height);

    const start = 0.28;
    const end = 0.72;

    final line1Start = lerp(const Offset(start, start), Offset.zero, iconRect);
    final line1End = lerp(const Offset(end, end), Offset.zero, iconRect);
    final line2Start = lerp(const Offset(end, start), Offset.zero, iconRect);
    final line2End = lerp(const Offset(start, end), Offset.zero, iconRect);

    final strokeWidth = radius * 2 * 0.22;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    Path? progressiveLinePath(Offset from, Offset to, double t) {
      if (t <= 0) return null;
      final full = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
      final metric = full.computeMetrics().first;
      return metric.extractPath(0, metric.length * t.clamp(0.0, 1.0));
    }

    void drawLineShadow(Path? partial) {
      if (partial == null) return;
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawPath(
        partial.shift(Offset(radius * 0.20, radius * 0.20)),
        Paint()
          ..color = const Color(0xFF990000).withValues(alpha: 0.34)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
      );
      canvas.restore();
    }

    void drawLine(Path? partial) {
      if (partial == null) return;
      canvas.drawPath(partial, strokePaint);
    }

    final line1Path = progressiveLinePath(line1Start, line1End, line1Progress);
    final line2Path = progressiveLinePath(line2Start, line2End, line2Progress);

    drawLineShadow(line1Path);
    drawLineShadow(line2Path);
    drawLine(line1Path);
    drawLine(line2Path);
  }

  @override
  bool shouldRepaint(covariant _CancelCirclePainter oldDelegate) {
    return oldDelegate.circleScale != circleScale ||
        oldDelegate.circleOpacity != circleOpacity ||
        oldDelegate.line1Progress != line1Progress ||
        oldDelegate.line2Progress != line2Progress;
  }
}
