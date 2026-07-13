import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/screens/splashscreen/splashscreen.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';

class About4 extends StatelessWidget {
  const About4({super.key});

  Future<void> _finishOnboarding(BuildContext context) async {
    await saveIsFirstUse(false);
    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset(
            'assets/images/abt4.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: size.height * 0.04,
          right: size.width * 0.05,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _finishOnboarding(context),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03,
                vertical: size.height * 0.012,
              ),
              child: AppText(
                text: "Next",
                size: 15,
                fontWeight: FontWeight.w400,
                color: abtNextColor2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
