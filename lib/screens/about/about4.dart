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
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Stack(
          children: [
            Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).size.height/2 + 50,
                  right: -120,
                  child: Container(
                    width: 300.w,
                    height: 300.h,
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
                Positioned(
                  top: MediaQuery.of(context).size.height / 2 + 55,
                  right: -120,
                  child: Image.asset(
                    'assets/images/aboutlogo1.png',
                    width: 300.w,
                    height: 300.h,
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
                  vertical: 40.h,
                ),
                child: GestureDetector(
                  onTap: () async {
                    await saveIsFirstUse(false);
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> const SplashScreen()));
                  },
                  child: AppText(
                    text: "Next",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: appTextColor,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: "Endless Food ",
                    size: 35,
                    fontWeight: FontWeight.w700,
                    color: appTextColor6,
                  ),
                  AppText(
                    text: "Possibilities!",
                    size: 35,
                    fontWeight: FontWeight.w700,
                    color: appTextColor6,
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Discounts, bookings, catering",
                    size: 20,
                    fontWeight: FontWeight.w400,
                    color: appButtonColor2,
                  ),
                  AppText(
                    text: "& more—right at your",
                    size: 20,
                    fontWeight: FontWeight.w400,
                    color: appButtonColor2,
                  ),
                  AppText(
                    text: "fingertips",
                    size: 20,
                    fontWeight: FontWeight.w400,
                    color: appButtonColor2,
                  ),
                ],
              ),
            ),
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 350.w,
                height: 350.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color.fromARGB(112, 249, 123, 13),
                    width: 20.w,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
              ),
            ),
            Positioned(
              top: 150,
              right: -80,
              child: Container(
                width: 200.w,
                height: 200.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color.fromARGB(112, 249, 123, 13),
                    width: 20.w   ,
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
