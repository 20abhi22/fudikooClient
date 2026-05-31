import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/translator_service.dart';

class AppTextFeild extends StatefulWidget {
  final String? text;
  final bool? enableInteractiveSelection;
  final VoidCallback? onSuffixTap;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  final IconData? icon;
  final IconData? secondIcon;
  final IconData? suffixIcon;

  final String? iconImagePath;
  final String? secondIconImagePath;

  final Color? iconImagecolor;
  final Color? secondIconImageColor;

  final Color? iconColor;
  final Color? secondIconColor;

  final int? maxlines;
  final double? size;
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
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
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

  final bool? expands;
  final InputDecoration? decoration;
  final TextAlignVertical? textAlignVertical;

  // DATE & TIME FIELD
  final bool? isDateTimeField;
  final String? secondText;

  const AppTextFeild({
    super.key,
    this.text,
    this.controller,
    this.icon,
    this.secondIcon,
    this.enableInteractiveSelection,
    this.onSuffixTap,
    this.suffixIcon,
    this.maxlines,
    this.size,
    this.validator,
    this.iconColor,
    this.secondIconColor,
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
    this.onFieldSubmitted,
    this.focusNode,
    this.textInputAction,
    this.iconImagecolor,
    this.secondIconImageColor,
    this.iconImagePath,
    this.secondIconImagePath,
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
    this.expands,
    this.decoration,
    this.textAlignVertical,
    this.isDateTimeField,
    this.secondText,
  });

  @override
  State<AppTextFeild> createState() => _AppTextFeildState();
}

class _AppTextFeildState extends State<AppTextFeild> {
  String _translated = '';

  @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(covariant AppTextFeild oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _translate();
    }
  }

  Future<void> _translate() async {
    if (widget.text == null) return;

    final result = await TranslatorService.translate(widget.text!);

    if (mounted) {
      setState(() {
        _translated = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double resolvedSideIconSlotWidth = widget.sideIconSlotWidth ?? 24.w;

    final double resolvedSideSpacing = widget.sideSpacing ?? 12.w;

    final List<BoxShadow> resolvedBoxShadow =
        widget.boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: const Offset(0, 0),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ];

    return GestureDetector(
      onTap: widget.onboxTap,
      child: Stack(
        children: [
          Container(
            padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 20.w),

            height: widget.height ?? 55.h,

            decoration: BoxDecoration(
              color: widget.backgroundColor ?? const Color(0xFFFFFFFF),

              borderRadius: BorderRadius.circular(
                widget.fieldBorderRadius ?? 10.r,
              ),

              boxShadow: resolvedBoxShadow,
            ),

            child: widget.isDateTimeField == true
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // FIRST ICON
                        widget.iconImagePath != null
                            ? Image.asset(
                                widget.iconImagePath!,
                                width: 17.w,
                                height: 17.h,
                                color:
                                    widget.iconImagecolor ??
                                    Color.fromARGB(255, 8, 8, 8),
                              )
                            : Icon(
                                widget.icon ?? Icons.calendar_today_sharp,
                                size: 14.sp,
                                color:
                                    widget.iconColor ??
                                    Color.fromARGB(255, 8, 8, 8),
                              ),

                        SizedBox(width: 8.w),

                        AppText(
                          text: _translated.isEmpty
                              ? (widget.text ?? 'Date')
                              : _translated,
                          size: widget.size ?? 12.sp,
                          fontWeight: FontWeight.w400,
                          color:
                              widget.textColor ?? Color.fromARGB(255, 8, 8, 8),
                        ),

                        SizedBox(width: 35.w),

                        // SECOND ICON
                        widget.secondIconImagePath != null
                            ? Image.asset(
                                widget.secondIconImagePath!,
                                width: 17.w,
                                height: 17.h,
                                color:
                                    widget.secondIconImageColor ??
                                    Color.fromARGB(255, 8, 8, 8),
                              )
                            : Icon(
                                widget.secondIcon ?? Icons.access_time_filled,
                                size: 14.sp,
                                color:
                                    widget.secondIconColor ??
                                    widget.iconColor ??
                                    Colors.grey,
                              ),

                        SizedBox(width: 8.w),

                        AppText(
                          text: widget.secondText ?? 'Time',
                          size: widget.size ?? 12.sp,
                          fontWeight: FontWeight.w400,
                          color:
                              widget.textColor ?? Color.fromARGB(255, 8, 8, 8),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: resolvedSideIconSlotWidth,

                        child:
                            (widget.icon != null ||
                                widget.iconImagePath != null)
                            ? GestureDetector(
                                onTap: widget.iconOnTap,

                                child: widget.iconImagePath != null
                                    ? SizedBox(
                                        width: resolvedSideIconSlotWidth,
                                        height: resolvedSideIconSlotWidth,

                                        child: Image.asset(
                                          widget.iconImagePath!,

                                          width: resolvedSideIconSlotWidth,

                                          height: resolvedSideIconSlotWidth,

                                          fit: BoxFit.contain,

                                          color: widget.iconImagecolor,

                                          colorBlendMode: BlendMode.srcIn,

                                          errorBuilder: (ctx, err, st) => Icon(
                                            Icons.image_not_supported,

                                            size: resolvedSideIconSlotWidth,

                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        widget.icon,

                                        color: widget.iconColor ?? Colors.grey,
                                      ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      SizedBox(width: resolvedSideSpacing),

                      Expanded(
                        child: TextFormField(
                          onTap: widget.onboxTap,

                          focusNode: widget.focusNode,

                          readOnly: widget.isreadonly ?? false,

                          maxLines: widget.expands == true
                              ? null
                              : (widget.maxlines ?? 1),

                          expands: widget.expands ?? false,

                          textAlignVertical: widget.textAlignVertical,

                          maxLength: widget.maxLength,

                          controller: widget.controller,

                          cursorColor: appTextColor,

                          obscureText: widget.isObscure ?? false,

                          textAlign: widget.isTextCenter == true
                              ? TextAlign.center
                              : TextAlign.start,

                          keyboardType: widget.keyboardType,

                          textInputAction: widget.textInputAction,

                          onFieldSubmitted: widget.onFieldSubmitted,

                          enableInteractiveSelection:
                              widget.enableInteractiveSelection ?? true,

                          onChanged: widget.onChanged,

                          validator: widget.validator,

                          autovalidateMode: AutovalidateMode.onUserInteraction,

                          inputFormatters: widget.maxLength == 1
                              ? [FilteringTextInputFormatter.digitsOnly]
                              : null,

                          decoration:
                              widget.decoration ??
                              InputDecoration(
                                counterText: '',

                                hintText: _translated.isEmpty
                                    ? widget.text
                                    : _translated,

                                hintStyle: TextStyle(
                                  fontWeight: FontWeight.w400,

                                  color: widget.textColor ?? Colors.grey,

                                  fontSize: widget.size ?? 16.sp,
                                ),

                                border: InputBorder.none,

                                isCollapsed: true,

                                contentPadding:
                                    widget.inputContentPadding ??
                                    EdgeInsets.symmetric(vertical: 16.h),
                              ),
                          style: TextStyle(
                            color: widget.textColor ?? Colors.black,
                            fontSize: (widget.size ?? 16).toDouble().sp,
                          ),
                        ),
                      ),

                      SizedBox(width: resolvedSideSpacing),

                      SizedBox(
                        width: resolvedSideIconSlotWidth,

                        child: widget.suffixIcon != null
                            ? InkWell(
                                onTap: widget.onSuffixTap,

                                borderRadius: BorderRadius.circular(20.r),

                                child: Icon(
                                  widget.suffixIcon,

                                  color: Colors.grey,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
          ),

          if (widget.isRequired == true)
            Positioned(
              right: widget.requiredRight ?? 10.w,

              top: widget.requiredTop ?? 8.h,

              child:
                  widget.requiredIndicator ??
                  Text(
                    '*',

                    style:
                        widget.requiredTextStyle ??
                        TextStyle(
                          color: const Color(0xFFF60505),

                          fontSize: 14.sp,

                          fontWeight: FontWeight.w700,
                        ),
                  ),
            ),
        ],
      ),
    );
  }
}
