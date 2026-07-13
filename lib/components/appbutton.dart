import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';

class AppButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final Color? bgColor1;
  final Color? bgColor2;
  final double? size;
  final IconData? icon;
  final String? imageIconPath;
  final double? iconSize;
  final double? borderRadius;
  final bool isLoading;
  final double? buttonwidth;
  final bool? isShadow;
  final double? buttonheight;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor1,
    this.bgColor2,
    this.size,
    this.icon,
    this.imageIconPath,
    this.iconSize,
    this.borderRadius,
    this.isLoading = false,
    this.buttonwidth,
    this.isShadow,
    this.buttonheight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isMobile = Breakpoints.isMobile(availableWidth);
        final resolvedHeight = buttonheight ?? (isMobile ? 60.76 : 60.0);
        final resolvedRadius = borderRadius ?? 20.0;
        final resolvedIconSize = iconSize ?? (isMobile ? 22.0 : 24.0);
        final resolvedTextSize = size ?? AppDimensions.body(context);

        return SizedBox(
          width: buttonwidth ?? double.infinity,
          height: resolvedHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(resolvedRadius),
              gradient: LinearGradient(
                colors: [
                  bgColor1 ?? const Color(0xFFD3690E),
                  bgColor2 ?? const Color(0xFFFE943A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: isShadow == true
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: Offset(0, 0),
                      ),
                    ],
            ),
            child: TextButton(
              onPressed: isLoading ? null : onPressed,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.gap(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(resolvedRadius),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((icon != null || imageIconPath != null) &&
                      !isLoading) ...[
                    imageIconPath != null
                        ? Image.asset(
                            imageIconPath!,
                            width: resolvedIconSize,
                            height: resolvedIconSize,
                          )
                        : Icon(
                            icon,
                            color: Colors.white,
                            size: resolvedIconSize,
                          ),
                    SizedBox(width: AppDimensions.gap(context) / 2),
                  ],
                  if (isLoading) ...[
                    SizedBox(
                      width: resolvedIconSize,
                      height: resolvedIconSize,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: AppDimensions.gap(context) / 2),
                  ],
                  AppText(
                    text: isLoading ? '' : text,
                    size: resolvedTextSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
