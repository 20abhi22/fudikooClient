import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';

class TakeAwayBox extends StatelessWidget {
  const TakeAwayBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: AssetImage('assets/images/boxbg.png'),fit:BoxFit.cover),
      
        gradient: const LinearGradient(
          colors: [Color(0xFF6e7525),Color(0xFFbac43e) ],
          end: Alignment.topCenter,
          begin: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [


          Positioned(
            bottom: -13,
            right: 20,
            child: Image.asset(
              'assets/images/boxbg2.png',
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
                  text: "Take Away",
                  size: 30,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  isShadow: true,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: "Discount",
                        size: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: "up to ",
                            size: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: AppText(
                                text: "40%",
                                size: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF83953D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
