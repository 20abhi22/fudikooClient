import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
              onTap: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding: EdgeInsets.only(left: 30.w, top: 10.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(backOrange, height: 30.h, width: 30.w),
                ),
              ),
            ),
            SizedBox(height: 40.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: AppText(
                text: 'About the App',
                size: 20,
                fontWeight: FontWeight.bold,
                color: appTextColor2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                isCentered: false,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
                child: Scrollbar(
                  thumbVisibility: true,
                  thickness: 4,
                  radius: Radius.circular(10),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text:
                              "Fudikoo Partner App is the ultimate app for food lovers who want to enjoy the best dining experiences with smart deals and seamless service. Whether you're looking for a quick takeaway, planning a party, or just craving something special, Fudikoo helps you discover great restaurants and exclusive offers near you - right when you need them. With Fudikoo, you can explore real-time deals and special discounts from top restaurants in your area. These offers are available during specific hours, dates, or low-traffic times - so you can enjoy quality food at the best prices.",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: appTextColor2,
                          lineSpacing: 1.6,
                          maxLines: 20,
                        ),
                        SizedBox(height: 12.h),
                        AppText(
                          text:
                              "Planning a celebration or a corporate event? The app lets you easily send banquet requests to restaurants. Just share your party details, and you'll receive customized quotations directly from venues, making it effortless to compare packages and choose the perfect spot for your event. Fudikoo also makes takeaway orders simple and fast. Browse menus, place your order, and pick it up at your convenience - no waiting, no confusion, just great food on the go. As you use the app and interact with top-rated restaurants, you'll also see badges that showcase their service quality, helping you make informed decisions and enjoy the best experiences.",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: appTextColor2,
                          lineSpacing: 1.6,
                          maxLines: 20,
                        ),
                        SizedBox(height: 12.h),
                        AppText(
                          text:
                              'Fudikoo Client App is your smart companion for discovering great food, unlocking amazing deals, and planning memorable dining moments.',
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: appTextColor2,
                          lineSpacing: 1.6,
                          maxLines: 5,
                        ),
                        SizedBox(height: 50.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 30.h),
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final versionText =
                      snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData
                      ? 'Version ${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                      : 'Version ...';
                  return AppText(
                    text: versionText,
                    size: 13,
                    fontWeight: FontWeight.w400,
                    color: appTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    isCentered: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
