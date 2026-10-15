import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';

class AppFilterDropDown extends StatefulWidget {
  final String hint;
  final IconData? icon;
  final IconData? suffixIcon;
  final Color? textColor;
  final double? height;
  final VoidCallback? toggleDropdown;
  final String? imageIconPath;
  final double? imageIconSize;
  final double? textSize;

  const AppFilterDropDown({
    super.key,
    required this.hint,
    this.icon,
    this.suffixIcon,
    this.textColor,
    this.height,
    this.toggleDropdown,
    this.imageIconPath,
    this.imageIconSize,
    this.textSize,
  });

  @override
  _AppFilterDropDownState createState() => _AppFilterDropDownState();
}

class _AppFilterDropDownState extends State<AppFilterDropDown> {
  String? selectedValue;
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    final metrics = _AppFilterDropDownMetrics.fromContext(context);
    final height = widget.height ?? metrics.height;
    final iconSize = widget.imageIconSize ?? metrics.iconSize;
    final textSize = widget.textSize ?? metrics.textSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.toggleDropdown,
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: metrics.sideInset),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(metrics.radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  offset: const Offset(0, 0),
                  blurRadius: metrics.shadowBlur,
                  spreadRadius: metrics.shadowSpread,
                ),
              ],
            ),
            // Row + mainAxisSize.min instead of Stack/Positioned/Center:
            // the old layout absolutely positioned the icon/arrow and
            // centered the text, which only works when the container is
            // given a fixed width from outside. This sizes the whole pill
            // to whatever text is actually selected.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.imageIconPath != null || widget.icon != null) ...[
                  widget.imageIconPath != null
                      ? Image.asset(
                          widget.imageIconPath!,
                          width: iconSize,
                          fit: BoxFit.cover,
                          height: iconSize,
                        )
                      : Icon(
                          widget.icon,
                          size: iconSize,
                          color: Colors.black87,
                        ),
                  SizedBox(width: metrics.sideInset),
                ],
                Flexible(
                  child: AppText(
                    text: selectedValue ?? widget.hint,
                    size: textSize,
                    color: widget.textColor ?? Colors.black87,
                    fontWeight: FontWeight.w500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: metrics.sideInset),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: metrics.arrowSize,
                  color: Colors.black87,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AppFilterDropDownMetrics {
  const _AppFilterDropDownMetrics({
    required this.height,
    required this.radius,
    required this.shadowBlur,
    required this.shadowSpread,
    required this.sideInset,
    required this.iconSize,
    required this.arrowSize,
    required this.textSize,
  });

  final double height;
  final double radius;
  final double shadowBlur;
  final double shadowSpread;
  final double sideInset;
  final double iconSize;
  final double arrowSize;
  final double textSize;

  factory _AppFilterDropDownMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // Device classification should use shortestSide, not width.
    final isTablet = Breakpoints.isTabletDevice(size);

    final isCompactPhone = size.width < 390 || size.height < 700;

    // Short landscape phones (e.g. 844×390)
    final isShortLandscape =
        !isTablet && size.width > size.height && size.height < 450;

    if (isTablet) {
      return const _AppFilterDropDownMetrics(
        height: 52,
        radius: 12,
        shadowBlur: 12,
        shadowSpread: 2,
        sideInset: 16,
        iconSize: 22,
        arrowSize: 28,
        textSize: 16,
      );
    }

    if (isShortLandscape) {
      return const _AppFilterDropDownMetrics(
        height: 36,
        radius: 9,
        shadowBlur: 8,
        shadowSpread: 1,
        sideInset: 10,
        iconSize: 16,
        arrowSize: 20,
        textSize: 12,
      );
    }

    if (isCompactPhone) {
      return const _AppFilterDropDownMetrics(
        height: 38,
        radius: 9,
        shadowBlur: 8,
        shadowSpread: 1.5,
        sideInset: 10,
        iconSize: 17,
        arrowSize: 21,
        textSize: 12.5,
      );
    }

    return _AppFilterDropDownMetrics(
      height: 45,
      radius: 10.r,
      shadowBlur: 10,
      shadowSpread: 2,
      sideInset: 12,
      iconSize: 20,
      arrowSize: 24,
      textSize: 14,
    );
  }
}
