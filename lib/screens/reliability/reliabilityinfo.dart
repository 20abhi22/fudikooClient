import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/screens/reliability/donutPercentage.dart';
import 'package:fudikoclient/utils/constants.dart';

class ReliabilityInfo extends StatelessWidget {
  const ReliabilityInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 30, top: 30),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: appTextColor3,
                    size: 28,
                  ),
                ),
              ),
            ),
            SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: DonutChartStatic(percentage: 0.72),
                ),
              ],
            ),
            SizedBox(height: 40),
            AppText(
              text: "You’ve saved big on your 230 orders",
              size: 16,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
            ),
            SizedBox(height: 10),
            AppText(
              text: "using our offers and deals!",
              size: 16,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
            ),
            SizedBox(height: 40),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  AppText(
                    text: "What is Reliability Rating",
                    size: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  SizedBox(height: 20,),
                  AppText(
                    text:
                        "Reliability Rating reflects how consistently you complete your orders without cancellations. It’s calculated based on your total successful orders compared to cancellation of confirmed ones. A higher percentage means you're a reliable customer — and that helps restaurants serve you better!”",
                    size: 16,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                    lineSpacing: 1.5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
