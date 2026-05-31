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
                Transform.translate(
  offset: Offset(
    -screenSize.width * 0.452, // responsive left overflow
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
    -screenSize.width * 0.388, // responsive left overflow
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
            
            // Positioned(
            //       bottom: -screenSize.height*0.17,
            //       left: -screenSize.width*0.88,
            //       child: Image.asset(
            //         'assets/images/pizza2.png',
            //         width: 495.w,
            //         height: 495.h,
            //       ),
            //     ),
                // Positioned(
                //   bottom: -screenSize.height*.1,
                //   left: -screenSize.width*0.73,
                //   child: Container(
                //     width: 375.w,
                //     height: 375.h,
                //     decoration: BoxDecoration(
                //       shape: BoxShape.circle,
                //       border: Border.all(
                //         color: Color(0xFF545450).withOpacity(0.22),
                //         width: 20.w,
                //       ),
                //     ),
                //     clipBehavior: Clip.hardEdge,
                //   ),
                // ),
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
            // Positioned(
            //   top: -screenSize.height*0.095,
            //   right: -screenSize.width*0.48,
            //   child: Container(
            //     width: 259.w,
            //     height: 259.h,
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       border: Border.all(
            //         color: Color(0xFFF97A0D).withOpacity(0.58),
            //         width: 5.w,
            //       ),
            //     ),
            //     clipBehavior: Clip.hardEdge,
            //   ),
            // ),
            // Positioned(
            //   bottom: -screenSize.height*0.071,
            //   right: -screenSize.width*0.48,
            //   child: Container(
            //     width: 322.w,
            //     height: 322.h,
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
           
            // 🔶 Top circle
    Transform.translate(
      offset: Offset(
        screenSize.width * 0.32,
        -screenSize.height * 0.095,
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: screenSize.width * 0.55,
          height: screenSize.width * 0.55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFF97A0D).withOpacity(0.58),
              width: screenSize.width * 0.55 * 0.02,
            ),
          ),
        ),
      ),
    ),

    // 🔶 Bottom circle
    Transform.translate(
      offset: Offset(
        screenSize.width * 0.58,
        screenSize.height * 0.071,
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          width: screenSize.width * 0.7,
          height: screenSize.width * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFF97A0D).withOpacity(0.58),
              width: screenSize.width * 0.7 * 0.02,
            ),
          ),
        ),
      ),
    ),

                // 🍕 Image
    Transform.translate(
      offset: Offset(
       - screenSize.width * 0.8, // responsive right overflow
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
        -screenSize.width * 0.8, // responsive right overflow
        screenSize.height * 0.149, // responsive downward shift
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

          ],
        ),
      ),
    );
  }
}
