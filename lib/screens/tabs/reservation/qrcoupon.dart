
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class QrCoupon extends StatelessWidget {
  const QrCoupon({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: Padding(
          padding:  EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height  - 150.h,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(onTap: (){
                          Navigator.pop(context);
                        },child: Icon(Icons.close, color: appTextColor, size: 30.r)),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            text: "Empire Restaurant",
                            size: 25,
                            fontWeight: FontWeight.w600,
                            color: appTextColor3,
                          ),
                          Stack(
                            children: [
                              Image.asset(
                                "assets/images/couponbody.png",
                                height: 500.h,
                                width: 300.w,
                                fit: BoxFit.contain,
                              ),
                              Positioned(
                                top: 80.h,
                                left: 45.w,
                                child: Image.asset(
                                  'assets/images/qrcode.png',
                                  height: 200.h,
                                  width: 200.w,
                                ),
                              ),
                              Positioned(
                                bottom: 120.h,
                                left: 100.w,
                                child: Column(
                                  children: [
                                    AppText(text: "APR 2", size: 16 , fontWeight: FontWeight.w400,color: appTextColor3,),
                                    SizedBox(height: 10.h,),
                                    SizedBox(width: 100.w,height: 40.h,child: AppButton(text: "02:30PM", onPressed: (){},size: 15,))
                                  ],
                                ),
                              )
                            ],
                          ),
                          AppText(text: "35% offer for entire menu ", size: 20, fontWeight: FontWeight.w700,color: appTextColor2,),
                          SizedBox(height: 10.h,),
                          AppText(text: "2 Person  ", size: 20, fontWeight: FontWeight.w700,color: appTextColor2,)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
