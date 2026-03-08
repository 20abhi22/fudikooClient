import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/screens/badge/badgeinfo.dart';
import 'package:fudikoclient/screens/customerProfile/donutPercentage.dart';
import 'package:fudikoclient/screens/reliability/reliabilityinfo.dart';
import 'package:fudikoclient/utils/constants.dart';

class CustomerProfile extends StatelessWidget {
  const CustomerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  'assets/images/banner1.png',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: -screenWidth / 5,
                  left: screenWidth / 2 - 95,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(4),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/avatar2.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 120),
            AppText(
              text: "John Abraham",
              size: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              isCentered: true,
            ),
            SizedBox(height: 5),
            AppText(
              text: "abcdefg@gmail.com",
              size: 15,
              fontWeight: FontWeight.w200,
              color: Colors.black,
              isCentered: true,
            ),
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> BadgeInfo()));
                              },
                              child: SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/badge1.png',
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            AppText(
                              text: "Current",
                              size: 12,
                              fontWeight: FontWeight.w400,
                              color: appButtonColor2,
                            ),
                            SizedBox(height: 5),
                            AppText(
                              text: "Badge",
                              size: 12,
                              fontWeight: FontWeight.w400,
                              color: appButtonColor2,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 100,color: appTextColor3),
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> ReliabilityInfo()));
                              },
                              child: Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: DonutChart(percentage: 0.72),
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            AppText(
                              text: "Reliability",
                              size: 12,
                              fontWeight: FontWeight.w400,
                              color: appButtonColor2,
                            ),
                            SizedBox(height: 5),
                            AppText(
                              text: "Rating",
                              size: 12,
                              fontWeight: FontWeight.w400,
                              color: appButtonColor2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),


            Padding(
              padding: const EdgeInsets.only(
                left: 30,
                right: 30,
                top: 60,
                bottom: 20,
              ),
              child: Container(
                padding: const EdgeInsets.all(30),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.edit_square,size: 20,color: appTextColor2,)
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        AppText(
                          text: "Place",
                          size: 12,
                          fontWeight: FontWeight.w600,
                          color: appTextColor2,
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Container(height: 0.5, color: appTextColor3),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),

                    Padding(
                      padding: const EdgeInsets.only(
                        top: 5,
                        right: 10,
                        left: 30,
                        bottom: 5,
                      ),
                      child: AppText(
                        text: "Tulskaya",
                        size: 12,
                        fontWeight: FontWeight.w400,
                        color: appTextColor2,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        AppText(
                          text: "Contact Info",
                          size: 12,
                          fontWeight: FontWeight.w600,
                          color: appTextColor2,
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Container(height: 0.5, color: appTextColor3),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),

                    Padding(
                      padding: const EdgeInsets.only(
                        top: 5,
                        right: 10,
                        left: 30,
                        bottom: 5,
                      ),
                      child: AppText(
                        text: "+7 9856412878    +7 895624158",
                        size: 12,
                        fontWeight: FontWeight.w400,
                        color: appTextColor2,
                      ),
                    ),
                    SizedBox(height: 5),

                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    'assets/images/inviteimage.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 150,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
