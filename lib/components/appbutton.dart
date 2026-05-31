import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/translator_service.dart';

class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {

    String _translated = '';

     @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _translate();
    }
  }

  Future<void> _translate() async {
    final result = await TranslatorService.translate(widget.text);

    if (mounted) {
      setState(() {
        _translated = result;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.buttonwidth,
      height: widget.buttonheight ?? 60.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(  widget.borderRadius?.r ?? 20.r),
        gradient: widget.bgColor1 == null && widget.bgColor2 == null
            ? const LinearGradient(
                colors: [Color(0xFFC95F05), Color(0xFFF97A0D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  widget.bgColor1 ?? const Color(0xFFC95F05),
                  widget.bgColor2 ?? const Color(0xFFF97A0D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: widget.isShadow == false
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
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius?.r ?? 20.r),
          ),
        ),
        child:  Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    if ((widget.icon != null || widget.imageIconPath != null) && !widget.isLoading) ...[
      widget.imageIconPath != null
          ? Image.asset(
              widget.imageIconPath!,
              width: (widget.iconSize ?? 24).w,
              height: (widget.iconSize ?? 24).h,
            )
          : Icon(
              widget.icon,
              color: Colors.white,
              size: widget.iconSize?.sp ?? 25.sp,
            ),

      // SizedBox(width: 5.w),
    ],

    if (widget.isLoading)
      SizedBox(
        width: 20.w,
        height: 20.h,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
      ),

    if (widget.isLoading) SizedBox(width: 12.w),

    AppText(
        text: widget.isLoading ? 'Please wait...' : widget.text,
      size: widget.size?.sp ?? 13.sp,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  ],
),
      ),
    );
  }
}
