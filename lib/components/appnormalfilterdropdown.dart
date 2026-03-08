import 'package:flutter/material.dart';
import 'package:fudikoclient/utils/constants.dart';

class AppNormalFilterDropDown extends StatefulWidget {
  final List<String> items;
  final String hint;
  final IconData? icon;
  final IconData? suffixIcon;
  final Color? textColor;
  final double? height;

  const AppNormalFilterDropDown({
    super.key,
    required this.items,
    required this.hint,
    this.icon,
    this.suffixIcon,
    this.textColor,
    this.height,
  });

  @override
  _AppNormalFilterDropDownState createState() => _AppNormalFilterDropDownState();
}

class _AppNormalFilterDropDownState extends State<AppNormalFilterDropDown> {
  String? selectedValue;
  bool isOpen = false;

  void toggleDropdown() {
    setState(() {
      isOpen = !isOpen;
    });
  }

  void selectItem(String value) {
    setState(() {
      selectedValue = value;
      isOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: toggleDropdown,
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
        if (isOpen)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = item == selectedValue;

                return InkWell(
                  onTap: () => selectItem(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: isSelected ? appTextColor : Colors.transparent,
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
