import 'package:flutter/material.dart';
import 'package:fudikoclient/utils/constants.dart';

class AppTextFeild extends StatelessWidget {
  final String? text;
  final TextEditingController? controller;
  final IconData? icon;
  final IconData? suffixIcon;
  final int? maxlines;
  final double? size;
  final Color? iconColor;
  final bool? isObscure;
  final Color? textColor;
  final bool? isTextCenter;
  final VoidCallback? iconOnTap;
  final VoidCallback? suffixIconOnTap;
  final VoidCallback? onboxTap;
  final bool? isreadonly;

  const 
  AppTextFeild({
    super.key,
    this.text,
    this.controller,
    this.icon,
    this.suffixIcon,
    this.maxlines,
    this.size,
    this.iconColor,
    this.isObscure,
    this.textColor,
    this.isTextCenter,
    this.iconOnTap,
    this.isreadonly, this.suffixIconOnTap, this.onboxTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onboxTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            icon != null
                ? GestureDetector(
                  onTap: iconOnTap,
                    child: Icon(icon, color: iconColor ?? Colors.grey),
                  )
                : SizedBox.shrink(),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                onTap: onboxTap,
                readOnly: isreadonly ?? false,
                maxLines: maxlines ?? 1,
                controller: controller,
                cursorColor: appTextColor,
                obscureText: isObscure ?? false,
                textAlign: isTextCenter == null
                    ? TextAlign.start
                    : TextAlign.center,
                decoration: InputDecoration(
                  hintText: text,
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: textColor ?? Colors.grey,
                    fontSize: size ?? 16,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            suffixIcon != null
                ? InkWell(onTap: (){
                  suffixIconOnTap!();
                },child: Icon(suffixIcon, color: iconColor ??Colors.grey))
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
