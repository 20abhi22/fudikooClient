import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appswitch.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Padding(
              padding:  EdgeInsets.only(top: 40.h, left: 30.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_back_ios_outlined,
                    size: 30.r,
                    color: appTextColor3,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 60.h),
          Divider(color: appTextColor, thickness: 1, height: 20.h),
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: "Get notified about new offers",
                      size: 15,
                      fontWeight: FontWeight.w500,
                      color: appTextColor3,
                    ),
                  ],
                ),
                AppSwitch(initialValue: true, onToggle: (val) {}),
              ],
            ),
          ),
          Divider(color: appTextColor, thickness: 1, height: 20.h),
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: "Get notified about new Promotions",
                  size: 15,
                  fontWeight: FontWeight.w500,
                  color: appTextColor3,
                ),
                AppSwitch(initialValue: true, onToggle: (val) {}),
              ],
            ),
          ),
          Divider(color: appTextColor, thickness: 1, height: 20.h),
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: "Reservation Reminders",
                      size: 15,
                      fontWeight: FontWeight.w500,
                      color: appTextColor3,
                    ),

                  ],
                ),
                AppSwitch(initialValue: true, onToggle: (val) {}),
              ],
            ),
          ),
          Divider(color: appTextColor, thickness: 1, height: 20.h),
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: "Get notified the order status",
                      size: 15,
                      fontWeight: FontWeight.w500,
                      color: appTextColor3,
                    ),

                  ],
                ),
                AppSwitch(initialValue: true, onToggle: (val) {}),
              ],
            ),
          ),
          Divider(color: appTextColor, thickness: 1, height: 20.h),
        ],
      ),
    );
  }
}
