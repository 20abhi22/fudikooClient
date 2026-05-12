import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/screens/splashscreen/splashscreen.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';

class About4 extends StatelessWidget {
  const About4({super.key});
  

  @override
  Widget build(BuildContext context) {
    Size screenSize= MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        height: screenSize.height,
        width: double.infinity,
        child: Stack(
          children: [
            Stack(
              children: [
                
                Positioned(
                  top: screenSize.height * 0.48,
                  right: screenSize.width * -0.22,
                  child: Image.asset(
                    'assets/images/pizza4.png',
                    width: 300.w,
                    height: 300.w,
                  ),
                ),

                Positioned(
                  top: screenSize.height * 0.498,
                  right: screenSize.width * -0.29,
                  child: Container(
                    width: 268.w,
                    height: 268.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 25.w,
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Padding(
                padding:  EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 40.w,
                ),
                child: GestureDetector(
                  onTap: () async {
                    await saveIsFirstUse(false);
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SplashScreen(),
                      ),
                    );
                  },
                  child: AppText(
                    text: "Next",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: abtNextColor2,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 220,
              left: 50,
              right: 20,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: "Endless Food ",
                    size: 35,
                    fontWeight: FontWeight.w700,
                    color: abtTextColor2,
                  ),
                  AppText(
                    text: "Possibilities!",
                    size: 35,
                    fontWeight: FontWeight.w700,
                    color: abtTextColor2,
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Discounts, bookings, catering",
                    size: 20,
                    fontWeight: FontWeight.w500,
                    color: abtTextColor2.withOpacity(.58),
                  ),
                  AppText(
                    text: "& more—right at your",
                    size: 20,
                    fontWeight: FontWeight.w500,
                    color: abtTextColor2.withOpacity(.58) ,
                  ),
                  AppText(
                    text: "fingertips",
                    size: 20,
                    fontWeight: FontWeight.w500,
                    color: abtTextColor2.withOpacity(.58),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -81,
              left: -60,
              child: Container(
                width: 259.w,
                height: 259.w,
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
              bottom: -screenSize.height*0.078,
              left: -screenSize.width*0.31,
              child: Container(
                width: 322.w,
                height: 322.w,
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
              top: 150,
              right: -50,
              child: Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFF97A0D).withOpacity(0.58),
                    width: 10.w   ,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
