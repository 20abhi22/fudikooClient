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
            child: Image.asset( 
              backOrange,
              width: 22.w,
              height: 22.h,
            ),
          ),

          // Tappable location
          GestureDetector(
            onTap: onLocationTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  text: "City",
                  size: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: locationTextColor.withOpacity(0.7),
                ),
                // SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: appButtonColor),
                    SizedBox(width: 4.w),
                    AppText(
                      text: city,
                      size: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: locationTextColor.withOpacity(0.7),
                    ),
                    SizedBox(width: 2.w),
                    // Icon(Icons.keyboard_arrow_down, size: 14, color: locationTextColor),
                  ],
                ),
              ],
            ),
          ),

          Image.asset(  
            searchOrange,
            width: 21.w,
            height: 21.h,
          ),
          // Image.asset(  
          //   'assets/images/search_icon.png',
          //   width: 30.w,
          //   height: 30.h,
          // ),
        ],
      ),
    );
  }
}