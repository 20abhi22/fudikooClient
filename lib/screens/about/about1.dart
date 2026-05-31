import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class About1 extends StatelessWidget {
  final VoidCallback? onPress;
  const About1({super.key, this.onPress});

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        height: screenSize.height,
        width: double.infinity,
        child: Stack(
          children: [
            Stack(
              children: [
                Transform.translate(
                  offset: Offset(
                    -screenSize.width * 0.27, // responsive left offset
                    -screenSize.width * 0.28, // responsive top offset
                  ),
                  child: Image.asset(
                    pizzaUp1,
                    width: screenSize.width * 1,
                    height: screenSize.width * 1,
                    fit: BoxFit.contain,
                  ),
                ),

                Transform.translate(
                  offset: Offset(
                    -screenSize.width * 0.25, // responsive horizontal offset
                    -screenSize.height * 0.12, // responsive vertical offset
                  ),
                  child: Container(
                    width: screenSize.width * 0.92,
                    height: screenSize.width * 0.92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 20.w,
                      ),
                    ),
                  ),
                ),

                Transform.translate(
                  offset: Offset(
                    screenSize.width * 0.128, // responsive right overflow
                    screenSize.height * 0.14, // responsive downward position
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: screenSize.width * .28,
                      height: screenSize.width * .28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF97A0D).withOpacity(0.58),
                          width: 10.w,
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                    ),
                  ),
                ),

                Transform.translate(
                  offset: Offset(
                    screenSize.width * 0.0,
                    screenSize.height * 0.0,
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 40.h,
                      ),
                      child: GestureDetector(
                        onTap: onPress,
                        child: AppText(
                          text: "Next",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: abtNextColor2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Positioned(
            //   top: screenSize.height * 0,
            //   right: screenSize.width * 0,
            //   child: Padding(
            //     padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
            //     child: GestureDetector(
            //       onTap: onPress,
            //       child: AppText(
            //         text: "Next",
            //         size: 15,
            //         fontWeight: FontWeight.w400,
            //         color: abtNextColor2,
            //       ),
            //     ),
            //   ),
            // ),
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: "Delicious Deals,",
                    size: 36.sp,
                    fontWeight: FontWeight.w700,
                    color: appTextColor6,
                  ),
                  AppText(
                    text: "Every Meal!",
                    size: 36.sp,
                    fontWeight: FontWeight.w700,
                    color: appTextColor6,
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Enjoy discounts at your",
                    size: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: appButtonColor2.withOpacity(0.58),
                  ),
                  AppText(
                    text: "favorite restaurants—every ",
                    size: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: appButtonColor2.withOpacity(0.58),
                  ),
                  AppText(
                    text: "bite, every time.",
                    size: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: appButtonColor2.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            // Positioned(
            //   bottom: screenSize.height * 0.06,
            //   right: -screenSize.width * 0.25,
            //   child: Container(
            //     width: 245.w,
            //     height: 245.h,
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       border: Border.all(
            //         color: Color(0xFFF97A0D).withOpacity(0.58),
            //         width: 10.w,
            //       ),
            //     ),
            //     clipBehavior: Clip.hardEdge,
            //   ),
            // ),
            Transform.translate(
              offset: Offset(
                screenSize.width * 0.15, // responsive right overflow
                screenSize.height * -0.06, // move upward from bottom
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: screenSize.width * 0.6,
                  height: screenSize.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF97A0D).withOpacity(0.58),
                      width: 10.w,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
              ),
            ),
            // Positioned(
            //   bottom: -screenSize.height * 0.07,
            //   left: -screenSize.width * 0.19,
            //   child: Container(
            //     width: 172.w,
            //     height: 172.h,
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       // borderRadius: BorderRadius.circular(20),
            //       border: Border.all(
            //         color: Color(0xFFF97A0D).withOpacity(0.58),
            //         width: 20.w,
            //       ),
            //     ),
            //     clipBehavior: Clip.hardEdge,
            //   ),
            // ),
            Transform.translate(
              offset: Offset(
                -screenSize.width * 0.19, // responsive left overflow
                screenSize.height * 0.07, // responsive bottom overflow
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: 172.w,
                  height: 172.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF97A0D).withOpacity(0.58),
                      width: 20.w,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
