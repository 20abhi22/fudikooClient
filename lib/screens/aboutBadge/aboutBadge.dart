import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class AboutBadge extends StatelessWidget {
  const AboutBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 30, top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.deepOrange,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'About the App',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 50,
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  thickness: 4,
                  radius: Radius.circular(10),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'In App, users can earn special badges based on their activity, engagement, and points collected through the app. These badges are a fun and rewarding way to recognize loyal customers who regularly explore new restaurants, place orders, send banquet requests, or participate in offers and promotions. For example, the Food Explorer badge is given to users who try a wide variety of restaurants, while the Quick Booker badge is awarded to those who frequently make banquet or party bookings. Other badges may highlight consistent takeaway ordering, early access to deals, or providing helpful reviews. As you continue to use the app and earn more points, you unlock more badges and exclusive benefits, such as special discounts or early access to top deals. ',
                          style: TextStyle(fontSize: 15, height: 1.6),
                        ),
                        SizedBox(height: 40),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/verificationblue.png',
                              height: 25,
                              width: 25,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    text: "Champ",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor3,
                                  ),
                                  const SizedBox(height: 8),
                                  AppText(
                                    text:
                                        "Unlock an Exclusive Discount Pack and a Thank You Kit from Fudikoo.",
                                    size: 14,
                                    fontWeight: FontWeight.w400,
                                    color: appTextColor,
                                    lineSpacing: 1.5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20,),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/verificationgreen.png',
                              height: 25,
                              width: 25,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    text: "Climber",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor3,
                                  ),
                                  const SizedBox(height: 8),
                                  AppText(
                                    text:
                                        "Enjoy a Free Takeaway Coupon and an Official Digital Badge.",
                                    size: 14,
                                    fontWeight: FontWeight.w400,
                                    color: appTextColor,
                                    lineSpacing: 1.5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20,),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/verificationRed.png',
                              height: 25,
                              width: 25,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    text: "Zylo",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor3,
                                  ),
                                  const SizedBox(height: 8),
                                  AppText(
                                    text:
                                        "et a Fudikoo Appreciation Certificate and early access to new app features",
                                    size: 14,
                                    fontWeight: FontWeight.w400,
                                    color: appTextColor,
                                    lineSpacing: 1.5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20,),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/verificationBlueGreen.png',
                              height: 25,
                              width: 25,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    text: "Nerivo",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor3,
                                  ),
                                  const SizedBox(height: 8),
                                  AppText(
                                    text:
                                        "eceive priority access to banquet deals and a Free Banquet Booking Voucher.",
                                    size: 14,
                                    fontWeight: FontWeight.w400,
                                    color: appTextColor,
                                    lineSpacing: 1.5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20,),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/verificationDarkGreen.png',
                              height: 25,
                              width: 25,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    text: "Lumina",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor3,
                                  ),
                                  const SizedBox(height: 8),
                                  AppText(
                                    text:
                                        "Get a Special Feature Article about your restaurant inside the app.",
                                    size: 14,
                                    fontWeight: FontWeight.w400,
                                    color: appTextColor,
                                    lineSpacing: 1.5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),


                        SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Text(
                'Version 2504.01',
                style: TextStyle(fontSize: 13, color: Colors.red.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
