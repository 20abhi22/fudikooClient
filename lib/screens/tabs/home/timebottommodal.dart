import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';

class TimeBottomModal extends StatefulWidget {
  final Future<void> Function(DateTime selectedDateTime) onApply;
  final DateTime initialDateTime;

  const TimeBottomModal({
    super.key,
    required this.onApply,
    required this.initialDateTime,
  });

  @override
  State<TimeBottomModal> createState() => _TimeBottomModalState();
}

class _TimeBottomModalState extends State<TimeBottomModal> {
  late DateTime _selectedDateTime;
  // Fixed once when the modal opens rather than recomputed every rebuild —
  // CupertinoDatePicker asserts minimumDate <= initialDateTime, and a live
  // DateTime.now() on each rebuild could drift past an already-selected
  // _selectedDateTime (e.g. selecting "now" then rebuilding a second later),
  // crashing the picker.
  late final DateTime _minimumDateTime;
  int? selectedDiscountIndex = 0;
  int? selectedTypeIndex = 0;

  @override
  void initState() {
    super.initState();
    _minimumDateTime = DateTime.now();
    _selectedDateTime = widget.initialDateTime.isBefore(_minimumDateTime)
        ? _minimumDateTime
        : widget.initialDateTime;
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
    final pickerHeight = isTablet
        ? (isLandscape
              ? (size.height * 0.18).clamp(210.0, 260.0).toDouble()
              : (size.height * 0.24).clamp(260.0, 330.0).toDouble())
        : isCompactLandscape
        ? (size.height * 0.34).clamp(180.0, 240.0).toDouble()
        : 250.h;
    final sectionGap = isTablet
        ? (isLandscape ? 22.0 : 38.0)
        : isCompactLandscape
        ? 18.0
        : 50.h;
    final clearTextSize = isTablet
        ? AppDimensions.caption(context)
        : isCompactPhone
        ? 11.0
        : 12.0;
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
      child: SingleChildScrollView(
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon(Icons.tune, size: 20.w, color: Colors.black),
                      // Icon(
                      //   Icons.event_available,
                      //   size: 20.w,
                      //   color: Colors.black,
                      // ),
                      Image.asset(
                        "assets/images/filter_calendar.png",
                        width: iconSize,
                        height: iconSize,
                        color: Colors.black,
                      ),
                      SizedBox(width: isTablet ? 12.0 : 10.w),
                      AppText(
                        // text: "Filter",
                        text: "Select Date & Time",

                        size: titleSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: isTablet ? (isLandscape ? 12.0 : 20.0) : 16.h,
                  ),
                  SizedBox(
                    height: pickerHeight,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.dateAndTime,
                      // initialDateTime: DateTime.now(),
                      initialDateTime: _selectedDateTime,
                      minimumDate: _minimumDateTime,
                      use24hFormat: false,
                      onDateTimeChanged: (DateTime newDateTime) {
                        // Handle date & time change
                        setState(() {
                          // Belt-and-suspenders: the picker itself already
                          // can't scroll below minimumDate.
                          _selectedDateTime =
                              newDateTime.isBefore(_minimumDateTime)
                              ? _minimumDateTime
                              : newDateTime;
                        });
                      },
                    ),
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
                              _selectedDateTime = DateTime.now(); // reset
                            });
                          },
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDateTime = DateTime.now();
                              });
                            },
                            child: AppText(
                              text: "Clear all",
                              size: clearTextSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              isCentered: true,
                            ),
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
                            borderRadius: 10.r,
                            size: buttonTextSize,
                            onPressed: () async {
                              await widget.onApply(_selectedDateTime);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
