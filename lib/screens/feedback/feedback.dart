import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/utils/constants.dart';

class FeedBack extends StatefulWidget {
  const FeedBack({super.key});

  @override
  State<FeedBack> createState() => _FeedBackState();
}

class _FeedBackState extends State<FeedBack> {
  bool isSubmitClicked = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: Stack(
          children: [


            Positioned.fill(
              child: Center(
                child: SingleChildScrollView(
                  padding:  EdgeInsets.symmetric(horizontal: 30.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/feedback.png',
                        height: 160.h,
                        width: 160.w,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 20.h),
                      AppText(
                        text: "We Value Your",
                        size: 30,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 8.h),
                      AppText(
                        text: "Feedback!",
                        size: 30,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 20.h),
                      AppText(
                        text: "How would you rate your experience?",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                      SizedBox(height: 20.h),
                      Wrap(
                        spacing: 10,
                        runSpacing: 20,
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            color: index >= 3 ? appTextColor2 : Colors.amber,
                            size: 40,
                          );
                        }),
                      ),
                      SizedBox(height: 50.h),
                      DescriptionTextArea(
                        hintText: "How was your experience?",
                        maxLength: 300,
                        icon: Icons.handshake,
                      ),
                        SizedBox(height: 50.h),
                      SizedBox(
                        width: 150.w,
                        height: 40.h,
                        child: AppButton(
                          text: "Submit",
                          onPressed: () {
                            setState(() {
                              isSubmitClicked = !isSubmitClicked;
                            });
                          },
                          size: 13,
                          borderRadius: 10.r,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
             Positioned(
              top: 30.h,
              left: 30.w,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: appTextColor3,
                  size: 28.r,
                ),
              ),
            ),
            if (isSubmitClicked) _confirmModal(),
          ],
        ),
      ),
    );
  }

  Widget _confirmModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding:  EdgeInsets.all(20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isSubmitClicked = !isSubmitClicked;
                      });
                    },
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.close, size: 25.r, color: appTextColor3),
                    ),
                  ),
                  Image.asset(
                    'assets/images/handshake.png',
                    height: 90.h,
                    width: 90.w,
                    fit: BoxFit.contain,
                  ),
                  AppText(
                    text: "Thank you for your",
                    size: 22,
                    fontWeight: FontWeight.w600,
                    color: appLinkColor2,
                  ),
                  SizedBox(height: 8.h),
                  AppText(
                    text: "feedback!",
                    size: 22,
                    fontWeight: FontWeight.w700,
                    color: appLinkColor2,
                  ),
                  SizedBox(height: 15.h),
                  AppText(
                    text: "We appreciate your input and",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    text: "will use it to improve.",
                      size: 15,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                  SizedBox(height: 35.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
