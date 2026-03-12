import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class AppSearchBar extends StatelessWidget {
  final String city;
  final VoidCallback? onLocationTap;

  const AppSearchBar({
    super.key,
    this.city = "Locating...",
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_rounded, size: 30.r, color: appTextColor3),
          ),

          // Tappable location
          GestureDetector(
            onTap: onLocationTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  text: "Near You",
                  size: 12,
                  fontWeight: FontWeight.w500,
                  color: appTextColor3,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: appButtonColor),
                    SizedBox(width: 4.w),
                    AppText(
                      text: city,
                      size: 12,
                      fontWeight: FontWeight.w600,
                      color: appTextColor3,
                    ),
                    SizedBox(width: 2.w),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: appTextColor3),
                  ],
                ),
              ],
            ),
          ),

          Icon(Icons.search_rounded, size: 30.r, color: appTextColor3),
        ],
      ),
    );
  }
}