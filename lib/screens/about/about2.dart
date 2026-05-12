import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class About2 extends StatelessWidget {
  final VoidCallback? onPress;
  const About2({super.key, this.onPress});

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
                Positioned(
                  top: -screenSize.height * 0.115,
                  right: -screenSize.width * 0.689,
                  child: Image.asset(
                    'assets/images/pizza3l.png',
                    width: screenSize.width * 1.5,
                    height: screenSize.width * 1.5,
                  ),
                ),
                Positioned(
                  top: screenSize.height * 0.05,
                  right: screenSize.width * -0.57,
                  child: Container(
                    width: 310.w,
                    height: 310.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFFD9D9D9).withOpacity(.58),
                        width: 20.w,
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                  ),
                ),

                Positioned(
                  bottom: -screenSize.height * 0.17,
                  right: -screenSize.width * 0.34,
                  child: Image.asset(
                    'assets/images/pizza2.png',
                    width: 495.w,
                    height: 495.w,
                  ),
                ),
                Positioned(
                  bottom: -screenSize.height * 0.1,
                  right: -screenSize.width * 0.2,
                  child: Container(
                    width: 375.w,
                    height: 375.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFF545450).withOpacity(0.22),
                        width: 20.w,
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                  ),
                ),
              ],
            ),

            Align(
              heightFactor: 0.8,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: "Find the Perfect ",
                    size: 36.sp,
                    fontWeight: FontWeight.w700,
                    color: abtTextColor2,
                  ),
                  AppText(
                    text: "Venue!",
                    size: 36.sp,
                    fontWeight: FontWeight.w700,
                    color: abtTextColor2,
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Book banquets for weddings, ",
                    size: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: abtTextColor2.withOpacity(0.5),
                  ),
                  AppText(
                    text: "birthdays, and events—",
                    size: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: abtTextColor2.withOpacity(0.5),
                  ),
                  AppText(
                    text: "hassle-free",
                    size: 20,
                    fontWeight: FontWeight.w400,
                    color: abtTextColor2.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: screenSize.height * 0.06,
              left: screenSize.width * -0.35,
              child: Container(
                width: 245.w,
                height: 245.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFF97A0D).withOpacity(0.58),
                    width: 10.w,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
              ),
            ),
            Positioned(
              top: screenSize.height * .14,
              left: screenSize.width * -0.148,
              child: Container(
                width: 113.w,
                height: 113.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFF97A0D).withOpacity(0.58),
                    width: 10.w,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
              ),
            ),
            Positioned(
              top: screenSize.height * 0,
              right: screenSize.width * 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
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
          ],
        ),
      ),
    );
  }
}
