import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class About2 extends StatelessWidget {
  final VoidCallback? onPress;
  const About2({super.key, this.onPress});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset(
            'assets/images/abt2.png',
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
            onTap: onPress,
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
