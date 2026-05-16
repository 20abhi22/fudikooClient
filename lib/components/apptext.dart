import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/utils/constants.dart';

class AppText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight fontWeight;
  final Color? color;
  final bool? isCentered;
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
    this.lineSpacing,
    this.isShadow,
    this.isboxShadow,
    this.maxLines,
    this.overflow = TextOverflow.visible,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      softWrap: softWrap,
      overflow: overflow,
      text,
      maxLines: maxLines ?? 2,

      textAlign: isCentered ?? false ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: size.sp,
        fontWeight: fontWeight,
        color: color ?? appTextColor,
        height: lineSpacing ?? 1.2,
        shadows:
            isboxShadow ??
            (isShadow == true
                ? [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.4),
                      offset: Offset(1.5, 1.5),
                    ),
                  ]
                : null),
      ),
    );
  }
}
