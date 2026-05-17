import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';

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
    return Container(
      width: buttonwidth ?? double.infinity,
      height: buttonheight ?? 60.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(  borderRadius?.r ?? 20.r),
        gradient: bgColor1 == null && bgColor2 == null
            ? const LinearGradient(
                colors: [Color(0xFFC95F05), Color(0xFFF97A0D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  bgColor1 ?? const Color(0xFFC95F05),
                  bgColor2 ?? const Color(0xFFF97A0D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: isShadow == false
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius?.r ?? 20.r),
          ),
        ),
        child:  Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    if ((icon != null || imageIconPath != null) && !isLoading) ...[
      imageIconPath != null
          ? Image.asset(
              imageIconPath!,
              width: (iconSize ?? 24).w,
              height: (iconSize ?? 24).h,
            )
          : Icon(
              icon,
              color: Colors.white,
              size: iconSize?.sp ?? 25.sp,
            ),

      // SizedBox(width: 5.w),
    ],

    if (isLoading)
      SizedBox(
        width: 20.w,
        height: 20.h,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
      ),

    if (isLoading) SizedBox(width: 12.w),

    AppText(
      text: isLoading ? 'Please wait...' : text,
      size: size?.sp ?? 13.sp,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  ],
),
      ),
    );
  }
}
