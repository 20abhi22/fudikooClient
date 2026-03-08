import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';

class TimeBottomModal extends StatefulWidget {
  final Function(DateTime selectedDateTime) onApply; // add this
  const TimeBottomModal({super.key, required this.onApply});

  @override
  State<TimeBottomModal> createState() => _TimeBottomModalState();
}

class _TimeBottomModalState extends State<TimeBottomModal> {
  DateTime _selectedDateTime = DateTime.now(); // track selected time
  int? selectedDiscountIndex = 0;
  int? selectedTypeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: SingleChildScrollView(
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon(Icons.tune, size: 20.w, color: Colors.black),
                      Icon(
                        Icons.event_available,
                        size: 20.w,
                        color: Colors.black,
                      ),
                      SizedBox(width: 10.w),
                      AppText(
                        // text: "Filter",
                        text: "Select Date & Time",

                        size: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h), //added extra
                  SizedBox(
                    height: 250.h,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.dateAndTime,
                      // initialDateTime: DateTime.now(),
                      initialDateTime: _selectedDateTime,
                      use24hFormat: false,
                      onDateTimeChanged: (DateTime newDateTime) {
                        // Handle date & time change
                        setState(() {
                          _selectedDateTime = newDateTime; // save selection
                        });
                      },
                    ),
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
                              size: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              isCentered: true,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: 150.w,
                          height: 50.h,
                          child: AppButton(
                            text: "Apply",
                            borderRadius: 10.r,
                            size: 15,
                            onPressed: () {
                              widget.onApply(_selectedDateTime); // send back
                              Navigator.pop(context); // close modal
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
