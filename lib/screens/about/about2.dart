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
                // Positioned(
                //   top: -screenSize.height * 0.115,
                //   right: -screenSize.width * 0.689,
                //   child: Image.asset(
                //     pizzaUp2,
                //     width: screenSize.width * 1.5,
                //     height: screenSize.width * 1.5,
                //   ),
                // ),
                Transform.translate(
  offset: Offset(
    screenSize.width * 0.55, // responsive right overflow
    screenSize.height * 0.05, // responsive top overflow
  ),
  child: Align(
    alignment: Alignment.topRight,
    child: Image.asset(
      pizzaUp2,
      width: screenSize.width *0.7,
      height: screenSize.width *0.7,
      fit: BoxFit.contain,
    ),
  ),
),
Transform.translate(
  offset: Offset(
    screenSize.width * 0.606, // responsive right overflow
    screenSize.height * 0.024, // responsive downward position
  ),
  child: Align(
    alignment: Alignment.topRight,
    child: Container(
  width: screenSize.width *0.82,
  height: screenSize.width *0.82,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: const Color(0xFFD9D9D9).withOpacity(.58),
      width: screenSize.width *0.8 * 0.05,
    ),
  ),
)
  ),
),

                Transform.translate(
  offset: Offset(
    -screenSize.width * 0.148, // responsive right overflow
    screenSize.height * 0.14, // responsive downward position
  ),
  child: Align(
    alignment: Alignment.topLeft,
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
      // clipBehavior: Clip.hardEdge,
    ),
  ),
),

       // 🍕 Image
    Transform.translate(
      offset: Offset(
        screenSize.width * 0.2, // responsive right overflow
        screenSize.height * 0.15, // responsive downward shift
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Image.asset(
          pizzaDn2,
          width: screenSize.width * 1.2,
          height: screenSize.width * 1.2,
          fit: BoxFit.contain,
        ),
      ),
    ),

    // ⚪ Circle border
    Transform.translate(
      offset: Offset(
        screenSize.width * 0.2, // responsive right overflow
        screenSize.height * 0.15, // responsive downward shift
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          width: screenSize.width * 1.2,
          height: screenSize.width * 1.2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF545450).withOpacity(0.22),
              width: screenSize.width * 0.035,
            ),
          ),
        ),
      ),
    ),



    Transform.translate(
  offset: Offset(
    -screenSize.width * 0.455, // move left outside screen
    screenSize.height * -0.06, // move upward (same as original)
  ),
  child: Align(
    alignment: Alignment.bottomLeft,
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
      // clipBehavior: Clip.,
    ),
  ),
),

                Align(
  alignment: Alignment.topRight,
  child: Padding(
    padding: EdgeInsets.only(
      top: screenSize.height * 0.05,
      right: screenSize.width * 0.05,
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
)
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
            // Positioned(
            //   bottom: screenSize.height * 0.06,
            //   left: screenSize.width * -0.35,
            //   child: Container(
            //     width: 245.w,
            //     height: 245.w,
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
            // Positioned(
            //   top: screenSize.height * .14,
            //   left: screenSize.width * -0.148,
            //   child: Container(
            //     width: 113.w,
            //     height: 113.w,
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
          ],
        ),
      ),
    );
  }
}
