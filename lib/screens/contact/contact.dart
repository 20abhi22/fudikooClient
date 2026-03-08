import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/utils/constants.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: (){
                Navigator.pop(context);
              },
              child: Padding(
                padding:  EdgeInsets.only(left: 30.w, top: 10.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: appTextColor3,
                    size: 28.r,
                  ),
                ),
              ),
            ),
            SizedBox(height: 50.h),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 30.w),
              child: Container(
                width: double.infinity,
                height: 70.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 20.w),
                    Icon(Icons.mail, size: 35.r, color: appButtonColor),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Mail Us',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: appTextColor3,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 50.w),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 30.w),
              child: Container(
                width: double.infinity,
                height: 70.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 20.w),
                    Icon(Icons.message, size: 35.r, color: appButtonColor),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Chat with Us',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: appTextColor3,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 50.w), // To balance icon space
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 30.w),
              child: Container(
                width: double.infinity,
                height: 70.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8.r,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 20.w),
                    Icon(Icons.phone, size: 35.r, color: appButtonColor),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Contact Us',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: appTextColor3,
                          ),
                        ),
                      ),
                    ),
                      SizedBox(width: 50.w), // To balance icon space
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
