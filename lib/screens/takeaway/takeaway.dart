import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class TakeAway extends StatelessWidget {
  const TakeAway({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 30, top: 30),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: appTextColor3,
                  size: 28,
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, size: 150, color: Colors.black),
                    SizedBox(height: 15,),
                    AppText(text: "Takeaway Coming Soon", size: 16, fontWeight: FontWeight.w600,color: Colors.black,),
                    SizedBox(height: 4,),
                    AppText(text: "This feature will be available shortly.", size: 16, fontWeight: FontWeight.w400,color: appTextColor2,),
                    SizedBox(height: 4,),
                    AppText(text: "Stay tuned!", size: 16, fontWeight: FontWeight.w400,color: appTextColor2,),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}