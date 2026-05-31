import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/translator_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DescriptionTextArea extends StatefulWidget {
  final String hintText;
  final int maxLength;
  final IconData icon;
  final void Function(String)? onChanged;
  final Color? iconColor;
  final int? maxLines;
  final double? height;
  final String? topHintText;
  final TextEditingController? controller;
  final String? imageIconPath;

  const DescriptionTextArea({
    super.key,
    required this.hintText,
    this.maxLength = 450,
    this.icon = Icons.list,
    this.onChanged,
    this.iconColor,
    this.maxLines,
    this.height,
    this.topHintText,
    this.controller, this.imageIconPath,
  });

  @override
  State<DescriptionTextArea> createState() => _DescriptionTextAreaState();
}

class _DescriptionTextAreaState extends State<DescriptionTextArea> {
  int _charCount = 0;
  late String _translatedHint;
  String? _translatedTopHint;

  @override
  void initState() {
    super.initState();
    _translatedHint = widget.hintText;
    _translatedTopHint = widget.topHintText;
    _charCount = widget.controller?.text.length ?? 0;
    _translateTexts();
  }

  @override
  void didUpdateWidget(covariant DescriptionTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hintText != widget.hintText ||
        oldWidget.topHintText != widget.topHintText) {
      _translateTexts();
    }
  }

  Future<void> _translateTexts() async {
    final hint = await TranslatorService.translate(widget.hintText);
    final topHint = widget.topHintText != null
        ? await TranslatorService.translate(widget.topHintText!)
        : null;

    if (mounted) {
      setState(() {
        _translatedHint = hint.isNotEmpty ? hint : widget.hintText;
        _translatedTopHint = (topHint != null && topHint.isNotEmpty)
            ? topHint
            : widget.topHintText;
      });
    }
  }

  Widget _buildTextField() {
    if (widget.height != null) {
      return Expanded(
        child: TextField(
          controller: widget.controller,
          maxLines: null,
          expands: true,
          maxLength: widget.maxLength,
          onChanged: (val) {
            setState(() => _charCount = val.length);
            if (widget.onChanged != null) widget.onChanged!(val);
          },
          decoration: InputDecoration(
            counterText: "",
            hintText: _translatedHint,
            hintStyle: TextStyle(color: Colors.grey, fontSize: 12.sp),
            border: InputBorder.none,
          ),
          textAlignVertical: TextAlignVertical.top,
        ),
      );
    }

    return TextField(
      controller: widget.controller,
      maxLines: widget.maxLines ?? 5,
      maxLength: widget.maxLength,
      onChanged: (val) {
        setState(() => _charCount = val.length);
        if (widget.onChanged != null) widget.onChanged!(val);
      },
      decoration: InputDecoration(
        counterText: "",
        hintText: _translatedHint,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 12.sp),
        border: InputBorder.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.imageIconPath != null)
                Image.asset(
                  widget.imageIconPath!,
                  width: 20.w,
                  height: 20.w,
                  color: widget.iconColor ?? const Color(0xFFC95F05),
                )
              else
                Icon(widget.icon, color: widget.iconColor ?? const Color(0xFFC95F05)),
              SizedBox(width: 10.w),
              if (_translatedTopHint != null)
                AppText(
                  text: _translatedTopHint!,
                  size: 14,
                  fontWeight: FontWeight.w600,
                  color: appTextColor2,
                )
              else
                const SizedBox(),
              const Spacer(),
              Text(
                '$_charCount/${widget.maxLength}',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _buildTextField(),
        ],
      ),
    );
  }
}