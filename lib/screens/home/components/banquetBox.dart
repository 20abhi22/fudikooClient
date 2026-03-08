import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';

class BanquetBox extends StatelessWidget {
  const BanquetBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), 
         image: DecorationImage(image: AssetImage('assets/images/boxbg.png'),fit:BoxFit.cover),
      
        gradient: const LinearGradient(
          colors: [ Color.fromARGB(255, 92, 28, 74), Color(0xFFc73fa0)],
          end: Alignment.topCenter,
          begin: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [


          Positioned(
            bottom: -8,
            right: 20,
            child: Image.asset(
              'assets/images/boxbg4.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top:20,bottom: 20,left:45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  text: "Banquets",
                  size: 30,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  isShadow: true,
                ),
                const SizedBox(height: 8),
                AppText(
                  text: "Book your entire party with",
                  size: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                AppText(
                  text: "exclusive discounts on your",
                  size: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                AppText(
                  text: "favorite dishes!",
                  size: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
