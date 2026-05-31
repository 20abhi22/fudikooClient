import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/translator_service.dart';

class AppText extends StatefulWidget {
  final String text;
  final double size;
  final FontWeight fontWeight;
  final Color? color;
  final bool? isCentered;
  final TextAlign? textAlign;
  final double? lineSpacing;
  final bool? isShadow;
  final List<Shadow>? isboxShadow;
  final int? maxLines;
  final TextOverflow overflow;
  final bool softWrap;

  const AppText({
    super.key,
    required this.text,
    required this.size,
    required this.fontWeight,
    this.color,
    this.isCentered,
    this.textAlign,
    this.lineSpacing,
    this.isShadow,
    this.isboxShadow,
    this.maxLines,
    this.overflow = TextOverflow.visible,
    this.softWrap = true,
  });

  @override
  State<AppText> createState() => _AppTextState();
}

class _AppTextState extends State<AppText> {
  String _translated = '';

  @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(AppText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // re-translate if language changed
    if (oldWidget.text != widget.text) _translate();
  }

  Future<void> _translate() async {
    final result = await TranslatorService.translate(widget.text);
    if (mounted) setState(() => _translated = result);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      _translated.isEmpty ? widget.text : _translated,
      maxLines: widget.maxLines ?? 2,

      textAlign:
          widget.textAlign ??
          (widget.isCentered ?? false ? TextAlign.center : TextAlign.start),
      style: TextStyle(
        fontSize: widget.size.sp,
        fontWeight: widget.fontWeight,
        color: widget.color ?? appTextColor,
        height: widget.lineSpacing ?? 1.2,
        shadows:
            widget.isboxShadow ??
            (widget.isShadow == true
                ? [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: Offset(1.5, 1.5),
                    ),
                  ]
                : null),
      ),
    );
  }
}
