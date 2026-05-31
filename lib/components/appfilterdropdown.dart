import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.toggleDropdown,
          child: Container(
            height: widget.height ?? 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
               boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.10),
        offset: const Offset(0, 0),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.imageIconPath != null|| widget.icon != null)
                  Positioned(
                    left: 12,
                    child: Image.asset(
                      widget.imageIconPath!,
                      width: widget.imageIconSize ?? 20,
                      fit: BoxFit.cover,
                      height: widget.imageIconSize?? 20,
                    )?? Icon(
                      widget.icon,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),

                Center(
                  child: AppText(
                    text:selectedValue ?? widget.hint,
                     size: widget.textSize ?? 14,
                      color: widget.textColor ?? Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                ),

                Positioned(
                  right: 12,
                  child: Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 24,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        //tazhenn varunnath

      ],
    );
  }
}
