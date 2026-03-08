import 'package:flutter/material.dart';

class AppFilterDropDown extends StatefulWidget {
  final String hint;
  final IconData? icon;
  final IconData? suffixIcon;
  final Color? textColor;
  final double? height;
  final VoidCallback? toggleDropdown;

  const AppFilterDropDown({
    super.key,
    required this.hint,
    this.icon,
    this.suffixIcon,
    this.textColor,
    this.height,
    this.toggleDropdown
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
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.icon != null)
                  Positioned(
                    left: 12,
                    child: Icon(widget.icon, size: 20, color: Colors.black87),
                  ),

                Center(
                  child: Text(
                    selectedValue ?? widget.hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.textColor ?? Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
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
