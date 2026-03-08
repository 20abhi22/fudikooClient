import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class ResponseBox extends StatelessWidget {
  final VoidCallback onCancelTap;
  final VoidCallback onAcceptTap;
  final VoidCallback viewRequestClick;
  const ResponseBox({super.key, required this.onCancelTap, required this.onAcceptTap, required this.viewRequestClick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.only(bottom: 20.h),
      child: GestureDetector(
        onTap: () {

        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding:  EdgeInsets.all(20.w),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: "P17854",
                            size: 20,
                            fontWeight: FontWeight.bold,
                            color: appTextColor3,
                          ),

                          SizedBox(height: 10.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: appTextColor5,
                                size: 18,
                              ),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Bollywood Restaurant',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: appLinkColor2,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.wallet,
                                color: appTextColor5,
                                size: 18,
                              ),
                                  SizedBox(width: 5.w),
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '950 ',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: appTextColor5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Per Person',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: appTextColor5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.discount,
                                color: appTextColor5,
                                size: 18,
                              ),
                              SizedBox(width: 5.w),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text:"5% on extra drinks",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: appTextColor5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.message,
                                color: appTextColor5,
                                size: 18,
                              ),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'If you have more than 50 people, we can offer you a price of 850 per head.',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(
                          text: "Apr 11",
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                        SizedBox(height: 5.h),
                        AppText(
                          text: "12:30pm",
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: viewRequestClick,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.manage_search_sharp, size: 15.w, color: appLinkColor2),
                          SizedBox(width: 5.w ),
                          AppText(
                            text: "View Request",
                            size: 12,
                            fontWeight: FontWeight.w400,
                            color: appLinkColor2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Column(
                      children: [
                        SizedBox(
                          width: 100.w,
                          height: 35.h,
                          child: AppButton(
                            text: "Decline",
                            onPressed: onCancelTap,
                            size: 12,
                            borderRadius: 5.r,
                            bgColor1: Colors.red,
                            bgColor2: Colors.red,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          width: 100.w,
                          height: 35.h,
                          child: AppButton(
                            text: "Accept",
                            onPressed: onAcceptTap,
                            size: 12,
                            borderRadius: 5.r,
                            bgColor1: Colors.green,
                            bgColor2: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
