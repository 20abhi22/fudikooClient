import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/utils/constants.dart';

class ComplaintPage extends StatelessWidget {
  const ComplaintPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding:  EdgeInsets.only(left: 30.w,right: 30.w,top: 20.h),
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: appTextColor3,
                      size: 28.r,
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                AppText(
                  text:
                      "If you encounter any issues or have a complaint, please register it below. Provide as much detail as possible so we can assist you promptly and effectively. Your feedback helps us improve your experience with Fudikoo.",
                  size: 12,
                  fontWeight: FontWeight.w400,
                  color: appTextColor2,
                  lineSpacing: 1.5,
                ),
                SizedBox(height: 50.h),
                DescriptionTextArea(hintText: "Write your complaint briefly",maxLength: 300,maxLines: 15,icon: Icons.report,iconColor: Colors.red,),
                SizedBox(height: 30.h),
                Padding(
                      padding:  EdgeInsets.symmetric(horizontal: 80.w,),
                  child: SizedBox(
                    height: 40.h,
                    child: AppButton(text: "Submit", onPressed: (){},size: 15,borderRadius: 10.r,),
                  )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
