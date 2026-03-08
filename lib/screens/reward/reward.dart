import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class Reward extends StatelessWidget {
  const Reward({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: EdgeInsets.only(left: 30.w, top: 10.h),
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
              SizedBox(height: 20.h),
              AppText(
                text: "Climber",
                size: 20,
                fontWeight: FontWeight.w600,
                isCentered: true,
                color: Colors.amber,
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/badge1.png',
                    width: 150.w,
                    height: 150.h,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              AppText(
                text: "Your next badge is on its way!",
                size: 12,
                fontWeight: FontWeight.w400,
                isCentered: true,
                color: Colors.black,
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.only(left: 50.w, right: 50.w),
                child: gradientProgressBar(70),
              ),
              SizedBox(height: 20.h),
              AppText(
                text: "87/100",
                size: 15,
                fontWeight: FontWeight.w500,
                isCentered: true,
                color: Colors.black,
              ),
              SizedBox(height: 50.h),
              AppText(
                text: "You're on your Reward Journey!",
                size: 15,
                fontWeight: FontWeight.w600,
                isCentered: true,
                color: appTextColor,
              ),
              SizedBox(height: 20.h),
              AppText(
                text: "Only 13 more points to unlock your next badge.",
                size: 15,
                fontWeight: FontWeight.w400,
                isCentered: true,
                color: appTextColor2,
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.w),
                child: Column(
                  children: [
                    AppText(
                      text:
                          "Each badge brings exclusive rewards, appreciation certificates, welcome gifts, discount packs, and more just for you! ",
                      size: 15,
                      fontWeight: FontWeight.w400,
                      isCentered: true,
                      color: appTextColor,
                      lineSpacing: 1.5,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.w),
                child: Column(
                  children: [
                    AppText(
                      text:
                          "Keep enjoying offers, placing orders, and exploring restaurants to earn points faster.The more you use Fudikoo, the more you earn. Let your next achievement unlock something exciting!",
                      size: 15,
                      fontWeight: FontWeight.w400,
                      isCentered: true,
                      color: appTextColor,
                      lineSpacing: 1.5,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.w),
                child: Column(
                  children: [
                    AppText(
                      text:
                          "Tap the current badge to explore upcoming badges and see what’s waiting for you next.",
                      size: 15,
                      fontWeight: FontWeight.w400,
                      isCentered: true,
                      color: appTextColor,
                      lineSpacing: 1.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget gradientProgressBar(double percentage) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double clampedPercentage = percentage.clamp(0, 100);

        return Stack(
          children: [
            // Background
            Container(
              height: 10.h,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5.r),
              ),
            ),
            // Foreground
            ClipRRect(
              borderRadius: BorderRadius.circular(5.r),
              child: Container(
                height: 10.h,
                width: constraints.maxWidth * (clampedPercentage / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.pink],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
