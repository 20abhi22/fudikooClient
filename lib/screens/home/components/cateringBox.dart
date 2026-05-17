import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';

class CateringBox extends StatelessWidget {
  const CateringBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.17,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: AssetImage('assets/images/boxbg.png'),fit:BoxFit.cover),
      
        gradient: const LinearGradient(
          colors: [Color(0xff43cf40), Color(0xff226920)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [


          Positioned(
            bottom: -4,
            right: 20,
            child: Image.asset(
              'assets/images/boxbg3.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top:20,bottom: 20,left:45),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    text: "Catering",
                    size: 30,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    isShadow: true,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    text: "Book your functions with",
                    size: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    text: "exclusive discounts and avail",
                    size: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    text: "best Services in Less Price!",
                    size: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
