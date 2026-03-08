import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class VerifiedModal extends StatelessWidget {
  const VerifiedModal({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.close, color: appTextColor, size: 25),
                ),
              ],
            ),
            SizedBox(height: 10),
            Column(
              children: [
                Image.asset(
                  'assets/images/check.png',
                  height: 60,
                  width: 60,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 20),
                AppText(text: "Coupon Verified!", size: 25, fontWeight: FontWeight.w600,color: appToggleColor,),
                SizedBox(height: 15),
                AppText(text: "You earned 55 points Reward ", size: 15, fontWeight: FontWeight.w500,color: appTextColor2,),
                SizedBox(height: 40),
                AppText(text: "Give Feedback", size: 13, fontWeight: FontWeight.w500,color: appToggleColor,),
                SizedBox(height: 10),
                AppText(text: "View your badge", size: 13, fontWeight: FontWeight.w500,color: appLinkColor,),
                SizedBox(height: 40),
              ],
            )
          ],
        ),
      ),
    );
  }
}
