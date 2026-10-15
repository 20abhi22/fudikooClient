import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/utils/constants.dart';

class FilterBottomModal extends StatefulWidget {
  //added
  final Future<void> Function(
    int? discountIndex,
    int? typeIndex,
    double distance,
  )
  onApply;
  final int? initialDiscountIndex;
  final int? initialTypeIndex;
  final double initialDistance;
  final VoidCallback? onClear;

  const FilterBottomModal({
    super.key,
    required this.onApply,
    this.initialDiscountIndex,
    this.initialTypeIndex,
    this.initialDistance = 10,
    this.onClear,
  });
  @override
  State<FilterBottomModal> createState() => _FilterBottomModalState();
}

class _FilterBottomModalState extends State<FilterBottomModal> {
  List<String> menuList = [
    "Up to 10%",
    "Up to 20%",
    "Up to 30%",
    "Up to 40%",
    "Up to 50%",
    "Up to 60%",
    "Up to 70%",
    "Up to 80%",
  ];

  List<String> typeList = ["Restaurant", "Cafe", "Cool Bar", "Bar", "Buffet"];

  int? selectedDiscountIndex;
  int? selectedTypeIndex;
  double _currentDistance = 10;

  @override
  void initState() {
    super.initState();
    selectedDiscountIndex = widget.initialDiscountIndex;
    selectedTypeIndex = widget.initialTypeIndex;
    _currentDistance = widget.initialDistance;
  }

  String _discountSummary() {
    if (selectedDiscountIndex == null ||
        selectedDiscountIndex! < 0 ||
        selectedDiscountIndex! >= menuList.length) {
      return 'Any discount';
    }
    return menuList[selectedDiscountIndex!];
  }

  String _typeSummary() {
    if (selectedTypeIndex == null ||
        selectedTypeIndex! < 0 ||
        selectedTypeIndex! >= typeList.length) {
      return 'Any type';
    }
    return typeList[selectedTypeIndex!];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    // Any landscape orientation on a phone gets the tightened spacing below —
    // a phone's landscape height is its shortest side, which is always
    // constrained relative to portrait, not just the sub-500 band.
    final isCompactLandscape = isLandscape;
    final isTablet = Breakpoints.isTabletDevice(size);
    final isCompactPhone = size.width < 390 || size.height < 700;
    final horizontalPadding = isTablet
        ? (isLandscape ? 22.0 : 28.0)
        : isCompactLandscape
        ? 14.0
        : 20.w;
    final verticalPadding = isTablet
        ? (isLandscape ? 14.0 : 20.0)
        : isCompactLandscape
        ? 10.0
        : 16.h;
    final handleWidth = isTablet
        ? (isLandscape ? 40.0 : 48.0)
        : isCompactLandscape
        ? 34.0
        : 40.w;
    final handleHeight = isTablet
        ? 5.0
        : isCompactLandscape
        ? 4.0
        : 5.h;
    final contentHeight = isTablet
        ? (isLandscape
              ? (size.height * 0.58).clamp(320.0, 460.0).toDouble()
              : (size.height * 0.46).clamp(430.0, 560.0).toDouble())
        : isCompactLandscape
        ? (size.height * 0.78).clamp(260.0, 380.0).toDouble()
        : MediaQuery.of(context).size.height.h * 0.5;
    final contentPadding = isTablet
        ? (isLandscape ? 18.0 : 24.0)
        : isCompactLandscape
        ? 12.0
        : 16.w;
    final titleSize = isTablet
        ? (isLandscape
              ? AppDimensions.body(context)
              : AppDimensions.body(context) + 1)
        : isCompactPhone
        ? 13.0
        : 14.0;
    final iconSize = isTablet
        ? (isLandscape ? 20.0 : 22.0)
        : isCompactLandscape
        ? 18.0
        : 20.w;
    final sectionGap = isTablet
        ? (isLandscape ? 20.0 : 36.0)
        : isCompactLandscape
        ? 18.0
        : 50.h;
    final wrapGap = isTablet
        ? (isLandscape ? 10.0 : 12.0)
        : isCompactLandscape
        ? 8.0
        : 10.0;
    final chipTextSize = isTablet
        ? AppDimensions.caption(context)
        : isCompactPhone
        ? 11.0
        : 12.sp;
    final optionTextSize = isTablet ? AppDimensions.caption(context) : 13.0;
    final buttonWidth = isTablet
        ? (isLandscape ? 160.0 : 180.0)
        : isCompactLandscape
        ? 132.0
        : 150.w;
    final buttonHeight = isTablet
        ? (isLandscape ? 46.0 : 54.0)
        : isCompactLandscape
        ? 42.0
        : 50.h;
    final buttonTextSize = isTablet ? AppDimensions.body(context) : 15.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: handleWidth,
            height: handleHeight,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: isTablet ? 18.0 : 16.h),

          Container(
            width: double.infinity,
            height: contentHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(contentPadding),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: iconSize, color: Colors.black),
                      SizedBox(
                        width: isTablet ? (isLandscape ? 8.0 : 12.0) : 10.w,
                      ),
                      AppText(
                        text: "Filter",
                        size: titleSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 12.0 : 10.h),
                  Wrap(
                    spacing: isTablet ? (isLandscape ? 8.0 : 10.0) : 8.0,
                    runSpacing: isTablet ? (isLandscape ? 8.0 : 10.0) : 8.0,
                    children: [
                      _selectionChip(
                        _discountSummary(),
                        chipTextSize,
                        isTablet,
                      ),
                      _selectionChip(_typeSummary(), chipTextSize, isTablet),
                      _selectionChip(
                        '${_currentDistance.toInt()} km',
                        chipTextSize,
                        isTablet,
                      ),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: wrapGap,
                    runSpacing: wrapGap,
                    children: List.generate(
                      menuList.length,
                      (index) => _discountBox(
                        menuList[index],
                        selectedDiscountIndex == index,
                        optionTextSize,
                        isTablet,
                        () {
                          setState(() {
                            selectedDiscountIndex =
                                selectedDiscountIndex == index ? null : index;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: wrapGap,
                    runSpacing: wrapGap,
                    children: List.generate(
                      typeList.length,
                      (index) => _discountBox(
                        typeList[index],
                        selectedTypeIndex == index,
                        optionTextSize,
                        isTablet,
                        () {
                          setState(() {
                            selectedTypeIndex = selectedTypeIndex == index
                                ? null
                                : index;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.orange,
                            inactiveTrackColor: Colors.grey[300],
                            thumbColor: Colors.orange,
                            overlayColor: Colors.orange.withAlpha(32),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: 100,
                            value: _currentDistance,
                            onChanged: (value) {
                              setState(() {
                                _currentDistance = value;
                              });
                            },
                          ),
                        ),
                      ),
                      // Text showing distance
                      SizedBox(width: isTablet ? 12.0 : 10.w),
                      Text(
                        "${_currentDistance.toInt()} km",
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDiscountIndex = null;
                              selectedTypeIndex = null;
                              _currentDistance = 10;
                            });
                            widget.onClear?.call();
                          },
                          child: AppText(
                            text: "Clear all",
                            size: chipTextSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            isCentered: true,
                          ),
                        ),
                        SizedBox(
                          height: isTablet ? (isLandscape ? 14.0 : 22.0) : 20.h,
                        ),
                        SizedBox(
                          width: buttonWidth,
                          height: buttonHeight,
                          child: AppButton(
                            text: "Apply",
                            onPressed: () {
                              widget.onApply(
                                selectedDiscountIndex,
                                selectedTypeIndex,
                                _currentDistance,
                              );
                              Navigator.pop(context);
                            },
                            borderRadius: 10.r,
                            size: buttonTextSize,
                          ),
                        ),
                        SizedBox(
                          height: isTablet ? (isLandscape ? 14.0 : 22.0) : 20.h,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _discountBox(
    String text,
    bool isSelected,
    double textSize,
    bool isTablet,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14.0 : 10.w,
          vertical: isTablet ? 8.0 : 6.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? appTextColor3 : Colors.grey[400],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: textSize,
            color: isSelected
                ? Colors.white
                : isSelected
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _selectionChip(String text, double textSize, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14.0 : 10.w,
        vertical: isTablet ? 8.0 : 6.h,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black87,
          fontSize: textSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
