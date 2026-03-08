import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/utils/constants.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: (){
                Navigator.pop(context);
              },
              child: Padding(
                padding:  EdgeInsets.only(left: 30.w, top: 10.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.deepOrange,
                    size: 28.r,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
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
                padding:  EdgeInsets.symmetric(horizontal: 30.w,vertical: 20.h),
                child: Scrollbar(
                  thumbVisibility:true,
                  thickness: 4,
                  radius: Radius.circular(10),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Fudikoo Partner App ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: appTextColor,
                                ),
                              ),
                              TextSpan(
                                text:
                                    "is the ultimate app for food lovers who want to enjoy the best dining experiences with smart deals and seamless service. Whether you're looking for a quick takeaway, planning a party, or just craving something special, Fudikoo helps you discover great restaurants and exclusive offers near you—right when you need them. With Fudikoo, you can explore real-time deals and special discounts from top restaurants in your area. These offers are available during specific hours, dates, or low-traffic times—so you can enjoy quality food at the best prices.",
                              ),
                            ],
                          ),
                          style: TextStyle(fontSize: 15.sp, height: 1.6),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "Planning a celebration or a corporate event? The app lets you easily send banquet requests to restaurants. Just share your party details, and you'll receive customized quotations directly from venues, making it effortless to compare packages and choose the perfect spot for your event.Fudikoo also makes takeaway orders simple and fast. Browse menus, place your order, and pick it up at your convenience—no waiting, no confusion, just great food on the go.As you use the app and interact with top-rated restaurants, you'll also see badges that showcase their service quality, helping you make informed decisions and enjoy the best experiences.",
                          style: TextStyle(fontSize: 15.sp, height: 1.6),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Fudikoo Client App is your smart companion for discovering great food, unlocking amazing deals, and planning memorable dining moments.',
                          style: TextStyle(fontSize: 15.sp, height: 1.6),
                        ),

                        SizedBox(height: 50.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding:  EdgeInsets.only(bottom: 30.h),
              child: Text(
                'Version 2504.01',
                style: TextStyle(fontSize: 13.sp, color: Colors.red.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
