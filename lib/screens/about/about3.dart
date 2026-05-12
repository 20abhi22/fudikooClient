import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class About3 extends StatelessWidget {
  final VoidCallback? onPress;
  const About3({super.key,this.onPress});

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
                  top: screenSize.height * 0.092,
                  left: -screenSize.width * 0.088,
                  child: Image.asset(
                    'assets/images/pizza3r.png',
                    width: screenSize.width * 0.65,
                    height: screenSize.height * 0.28,
                  ),
                ),
                Positioned(
                  top: screenSize.height * 0.05,
                  left: -screenSize.width * 0.197,
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
              ],
            ),
            
            Positioned(
                  bottom: -screenSize.height*0.17,
                  left: -screenSize.width*0.88,
                  child: Image.asset(
                    'assets/images/pizza2.png',
                    width: 495.w,
                    height: 495.h,
                  ),
                ),
                Positioned(
                  bottom: -screenSize.height*.1,
                  left: -screenSize.width*0.73,
                  child: Container(
                    width: 375.w,
                    height: 375.h,
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
            Positioned(
              top: 400.h,
              left: 50.w,
              right: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: "Catering That Fits",
                    size: 35,
                    fontWeight: FontWeight.w700,
                    color: abtTextColor2,
                  ),
                  AppText(
                    text: "Your Budget!",
                    size: 35,
                    fontWeight: FontWeight.w700,
                    color: abtTextColor2,
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "From home parties to big",
                    size: 20,
                    fontWeight: FontWeight.w500,
                    color: abtTextColor2.withOpacity(.58),
                  ),
                  AppText(
                    text: "events—get the best food",
                    size: 20,
                    fontWeight: FontWeight.w500,
                    color: abtTextColor2.withOpacity(0.58),
                  ),
                  AppText(
                    text: "delivered",
                    size: 20,
                    fontWeight: FontWeight.w500,
                    color: abtTextColor2.withOpacity(0.58),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -screenSize.height*0.095,
              right: -screenSize.width*0.48,
              child: Container(
                width: 259.w,
                height: 259.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFF97A0D).withOpacity(0.58),
                    width: 5.w,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
              ),
            ),
            Positioned(
              bottom: -screenSize.height*0.071,
              right: -screenSize.width*0.48,
              child: Container(
                width: 322.w,
                height: 322.h,
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
              top: 40.h,
              right: 20.w,
              child: GestureDetector(
                onTap: onPress,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
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
