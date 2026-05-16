import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';
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
    this.controller,
  });

  @override
  State<DescriptionTextArea> createState() => _DescriptionTextAreaState();
}

class _DescriptionTextAreaState extends State<DescriptionTextArea> {
  int _charCount = 0;

  Widget _buildTextField() {
    // Use expanding text field only when a fixed parent height is provided.
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
            hintText: widget.hintText,
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
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 12.sp),
        border: InputBorder.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding:  EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: widget.iconColor ?? const Color(0xFFC95F05)),
              SizedBox(width: 10.w),
              widget.topHintText != null ? AppText(text: widget.topHintText!, size: 14, fontWeight: FontWeight.w600,color: appTextColor2,) : const SizedBox(),
              const Spacer(),
              Text(
                '$_charCount/${widget.maxLength}',
                style:  TextStyle(color: Colors.grey, fontSize: 12.sp),
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
