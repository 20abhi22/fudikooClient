import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final Color? bgColor1;
  final Color? bgColor2;
  final double? size;
  final IconData? icon;
  final double? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor1,
    this.bgColor2,
    this.size,
    this.icon,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60.h,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius?.r ?? 20.r),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (icon != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:  EdgeInsets.only(left: 16.w),
                  child: Icon(icon, color: Colors.white,size: 25.sp,),
                ),
              ),
            Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: size?.sp ?? 20.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
