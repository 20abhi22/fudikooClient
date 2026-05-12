import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class FilterBottomModal extends StatefulWidget {
  //added
  final Future<void> Function(int? discountIndex, int? typeIndex, double distance) onApply;
  final int? initialDiscountIndex;
  final int? initialTypeIndex;
  final double initialDistance;

  const FilterBottomModal({
    super.key,
    required this.onApply,
    this.initialDiscountIndex,
    this.initialTypeIndex,
    this.initialDistance = 0,
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
  double _currentDistance = 0;

  @override
  void initState() {
    super.initState();
    selectedDiscountIndex = widget.initialDiscountIndex;
    selectedTypeIndex = widget.initialTypeIndex;
    _currentDistance = widget.initialDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: 16.h),

          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height.h * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(16.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 20.w, color: Colors.black),
                      SizedBox(width: 10.w),
                      AppText(
                        text: "Filter",
                        size: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  SizedBox(height: 50.h),
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      menuList.length,
                      (index) => _discountBox(
                        menuList[index],
                        selectedDiscountIndex == index,
                        () {
                          setState(() {
                            selectedDiscountIndex =
                                selectedDiscountIndex == index ? null : index;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 50.h),
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      typeList.length,
                      (index) => _discountBox(
                        typeList[index],
                        selectedTypeIndex == index,
                        () {
                          setState(() {
                            selectedTypeIndex =
                                selectedTypeIndex == index ? null : index;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 50.h),
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
                      SizedBox(width: 10.w),
                      Text(
                        "${_currentDistance.toInt()} km",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50.h),
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
                              _currentDistance = 0;
                            });
                          },
                          child: AppText(
                            text: "Clear all",
                            size: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            isCentered: true,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: 150.w,
                          height: 50.h,
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
                            size: 15,
                          ),
                        ),
                        SizedBox(height: 20.h),
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

  Widget _discountBox(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? appTextColor3 : Colors.grey[400],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
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
}
