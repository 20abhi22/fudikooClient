import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/utils/constants.dart';

class Otp extends StatelessWidget {
  const Otp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:  EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/otp.png',
              width: 180.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 40.h),
            AppText(
              text:
                  "An OTP has been sent to your registered email address. Kindly enter it to continue.",
              size: 15,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
              isCentered: true,
              lineSpacing: 1.2,
            ),
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: AppTextFeild()),
                SizedBox(width: 20.w),
                Expanded(child: AppTextFeild()),
                
                SizedBox(width: 20.w),
                Expanded(child: AppTextFeild()),
                SizedBox(width: 20.w),
                Expanded(child: AppTextFeild()),
              ],
            ),
            SizedBox(height: 40.h),
            AppButton(
              text: 'Verify',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
