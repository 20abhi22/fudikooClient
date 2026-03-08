import 'package:flutter/material.dart';
import 'package:fudikoclient/utils/constants.dart';

class AppDropDown extends StatefulWidget {
  final List<String> items;
  final String hint;
  final IconData? icon;
  final IconData? suffixIcon;
  final Color? textColor;

  const AppDropDown({
    super.key,
    required this.items,
    required this.hint,
    this.icon,
    this.suffixIcon,
    this.textColor
  });

  @override
  _AppDropDownState createState() => _AppDropDownState();
}

class _AppDropDownState extends State<AppDropDown> {
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
    return Container(
      // To allow dropdown to expand beyond height, use IntrinsicWidth + Column outside this if needed
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (shows selected or hint + toggle icon)
          GestureDetector(
            onTap: toggleDropdown,
            child: Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 40),
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
                  if (widget.icon != null)
                    Icon(widget.icon, color: Colors.grey),
                  if (widget.icon != null) SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedValue ?? widget.hint,
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedValue == null
                            ?  Colors.grey
                            : Colors.black,
                        fontWeight: selectedValue == null
                            ? FontWeight.w400
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.grey,
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
          // Dropdown items list
          // Inside _AppDropDownState -> build method, replace the if (isOpen) section with this:
          if (isOpen)
            Container(
              margin: const EdgeInsets.only(top: 6, left: 0, right: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
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
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            // horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? appTextColor : Colors.transparent,
                            borderRadius: BorderRadius.vertical(
                              top: index == 0
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                              bottom: index == widget.items.length - 1
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                item,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                          Divider(color: Colors.grey),

                      ],
                    ),
                  );
                },
              ),
            ),

        ],
      ),
    );
  }
}
