import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class EarnPoints extends StatelessWidget {
  const EarnPoints({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/earnPoints.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                Positioned(
                  bottom: 30.h,
                  left: 30.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: "Earn",
                        size: 45,
                        fontWeight: FontWeight.w600,
                        isCentered: true,
                        color: appTextColor2,
                      ),
                      AppText(
                        text: "Unlimited",
                        size: 40,
                        fontWeight: FontWeight.w600,
                        isCentered: true,
                        color: appTextColor2,
                      ),
                      AppText(
                        text: "Points!!",
                        size: 35,
                        fontWeight: FontWeight.w600,
                        isCentered: true,
                        color: appTextColor2,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 30,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: appTextColor3,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 60.w),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Image.asset(
                    'assets/images/earnMoney.png',
                    height: 200.h,
                    width: 200.w,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 30.h),
                  AppText(
                    text: "Invite Your Friends & Earn",
                    size: 20,
                    fontWeight: FontWeight.w500,
                    isCentered: true,
                    color: appTextColor,
                  ),
                  SizedBox(height: 10.h),
                  AppText(
                    text: "15 Points Each!",
                    size: 20,
                    fontWeight: FontWeight.w500,
                    isCentered: true,
                    color: appTextColor,
                  ),
                  SizedBox(height: 40.h),
                  AppText(
                    text:
                        "Get rewarded for sharing the love! For every friend you invite who signs up, you’ll earn 15 points—no limits, no catch.",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    isCentered: true,
                    color: appTextColor2,
                    lineSpacing: 1.2,
                  ),
                  SizedBox(height: 30.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      text: "Here’s how it works:",
                      size: 12,
                      fontWeight: FontWeight.w500,
                      color: appTextColor2,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_right_outlined,
                        color: appTextColor,
                        size: 20,
                      ),
                      AppText(
                        text: "Share your unique invite link.",
                        size: 12,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_right_outlined,
                        color: appTextColor,
                        size: 20,
                      ),
                      AppText(
                        text: " Your friend signs up using your link.",
                        size: 12,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_right_outlined,
                        color: appTextColor,
                        size: 20,
                      ),
                      AppText(
                        text: "You both get rewarded—you earn 15 points!",
                        size: 12,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  SizedBox(
                    width: 200.w,
                    height: 40.h,
                    child: AppButton(
                      text: "Share Your Link",
                      onPressed: () {},
                      bgColor1: appLinkColor2,
                      bgColor2: appLinkColor2,
                      size: 15,
                      borderRadius: 10.r,
                    ),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
