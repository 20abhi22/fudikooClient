import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class TakeAway extends StatelessWidget {
  const TakeAway({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/takeaway.png', width: 150),
                  const SizedBox(height: 15),
                  AppText(
                    text: "Takeaway Coming Soon",
                    size: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 37, 36, 36),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    text: "This feature will be available shortly.",
                    size: 16,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    text: "Stay tuned!",
                    size: 16,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 30,
              top: 30,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Image.asset(
                  backOrange,
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
