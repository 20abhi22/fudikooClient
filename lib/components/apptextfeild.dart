import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/utils/constants.dart';

class AppTextFeild extends StatelessWidget {
  final String? text;
  final bool? enableInteractiveSelection;
  final VoidCallback? onSuffixTap;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final IconData? icon;
  final Color? iconImagecolor;
  final String? iconImagePath;
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
  final TextInputType? keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final double? fieldBorderRadius;
  final bool? isRequired;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double? sideIconSlotWidth;
  final double? sideSpacing;
  final EdgeInsetsGeometry? inputContentPadding;
  final double? requiredTop;
  final double? requiredRight;
  final TextStyle? requiredTextStyle;
  final Widget? requiredIndicator;

  const AppTextFeild({
    super.key,
    this.text,
    this.controller,
    this.icon,
    this.enableInteractiveSelection,
    this.onSuffixTap,
    this.suffixIcon,
    this.maxlines,
    this.size,
    this.validator,
    this.iconColor,
    this.isObscure,
    this.textColor,
    this.isTextCenter,
    this.iconOnTap,
    this.isreadonly,
    this.suffixIconOnTap,
    this.onboxTap,
    this.keyboardType,
    this.maxLength,
    this.onChanged,
    this.focusNode,
    this.iconImagecolor,
    this.iconImagePath,
    this.fieldBorderRadius,
    this.isRequired,
    this.height,
    this.padding,
    this.backgroundColor,
    this.boxShadow,
    this.sideIconSlotWidth,
    this.sideSpacing,
    this.inputContentPadding,
    this.requiredTop,
    this.requiredRight,
    this.requiredTextStyle,
    this.requiredIndicator,
  });

  @override
  Widget build(BuildContext context) {
    final double resolvedSideIconSlotWidth = sideIconSlotWidth ?? 24;
    final double resolvedSideSpacing = sideSpacing ?? 12;
    final List<BoxShadow> resolvedBoxShadow = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 0),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ];

    return GestureDetector(
      onTap: onboxTap,
      child: Container(
        child: Stack(
          children: [
            Container(
              padding: padding ?? EdgeInsets.symmetric(horizontal: 20),
              height: height ?? 60,
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(fieldBorderRadius ?? 20.r),
                boxShadow: resolvedBoxShadow,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: resolvedSideIconSlotWidth,
                    child: (icon != null || iconImagePath != null)
                        ? GestureDetector(
                            onTap: iconOnTap,
                            child: iconImagePath != null
                                ? SizedBox(
                                    width: resolvedSideIconSlotWidth,
                                    height: resolvedSideIconSlotWidth,
                                    child: Image.asset(
                                      iconImagePath!,
                                      width: resolvedSideIconSlotWidth,
                                      height: resolvedSideIconSlotWidth,
                                      fit: BoxFit.contain,
                                      color: iconImagecolor,
                                      colorBlendMode: BlendMode.srcIn,
                                      errorBuilder: (ctx, err, st) => Icon(
                                        Icons.image_not_supported,
                                        size: resolvedSideIconSlotWidth,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : Icon(icon, color: iconColor ?? Colors.grey),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(width: resolvedSideSpacing),
                  Flexible(
                    child: TextFormField(
                      onTap: onboxTap,
                      focusNode: focusNode,
                      readOnly: isreadonly ?? false,
                      maxLines: maxlines ?? 1,
                      maxLength: maxLength,
                      controller: controller,
                      cursorColor: appTextColor,
                      obscureText: isObscure ?? false,
                      textAlign: isTextCenter == true
                          ? TextAlign.center
                          : TextAlign.start,
                      keyboardType: keyboardType,
                      enableInteractiveSelection:
                          enableInteractiveSelection ?? true,
                      onChanged: onChanged,
                      validator: validator,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      inputFormatters: maxLength == 1
                          ? [FilteringTextInputFormatter.digitsOnly]
                          : null,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: text,
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: textColor ?? Colors.grey,
                          fontSize: size ?? 16.sp,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding:
                            inputContentPadding ?? const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: resolvedSideSpacing),
                  SizedBox(
                    width: resolvedSideIconSlotWidth,
                    child: suffixIcon != null
                        ? InkWell(
                            onTap: onSuffixTap,
                            borderRadius: BorderRadius.circular(20),
                            child: Icon(suffixIcon, color: Colors.grey),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            if (isRequired == true)
              Positioned(
                right: requiredRight ?? 10,
                top: requiredTop ?? 8,
                child: requiredIndicator ??
                    Text(
                      '*',
                      style: requiredTextStyle ??
                          TextStyle(
                            color: const Color(0xFFF60505),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}






// import 'package:flutter/material.dart';
// import 'package:fudiko/utils/constants.dart';

// class AppTextFeild extends StatelessWidget {
//   final String? text;
//   final TextEditingController? controller;
//   final IconData? icon;
//   final IconData? suffixIcon;
//   final int? maxlines;
//   final double? size;
//   final Color? iconColor;
//    final TextInputType? keyboardType; 

//   const AppTextFeild({
//     super.key,
//     this.text,
//     this.controller,
//     this.icon,
//     this.suffixIcon,
//     this.maxlines,
//     this.size,
//     this.iconColor,
//     this.keyboardType,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 20),
//       height: 60,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           icon != null ? Icon(icon, color: iconColor ??Colors.grey) : SizedBox.shrink(),
//           SizedBox(width: 12),
//           Expanded(
//             child: TextField(
//               keyboardType: keyboardType,
//               maxLines: maxlines ?? 1,
//               controller: controller,
//               cursorColor: appTextColor,
//               decoration: InputDecoration(
//                 hintText: text,
//                 hintStyle: TextStyle(
//                   fontWeight: FontWeight.w400,
//                   color: Colors.grey,
//                   fontSize: size ?? 16
//                 ),
//                 border: InputBorder.none,
//                 isCollapsed: true,
//                 contentPadding: EdgeInsets.symmetric(vertical: 16),
//               ),
//             ),
//           ),
//           suffixIcon != null ? Icon(suffixIcon, color: Colors.grey,size: 40,) : SizedBox.shrink(),
//         ],
//       ),
//     );
//   }
// }
