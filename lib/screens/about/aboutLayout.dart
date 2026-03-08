import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/screens/about/about1.dart';
import 'package:fudikoclient/screens/about/about2.dart';
import 'package:fudikoclient/screens/about/about3.dart';
import 'package:fudikoclient/screens/about/about4.dart';

class AboutLayout extends StatefulWidget {
  const AboutLayout({super.key});

  @override
  State<AboutLayout> createState() => _AboutLayoutState();
}

class _AboutLayoutState extends State<AboutLayout> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: 4,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                if(index == 0){
                  return About1(
                    onPress: () {
                      setState(() {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      });
                    },
                  );
                }
                else if(index == 1){
                  return About2(
                    onPress: () {
                      setState(() {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      });
                    },
                  );
                }else if(index == 2){
                  return About3(
                    onPress: () {
                      setState(() {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      });
                    },
                  );
                }else{
                  return About4();
                }
              }

            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:  EdgeInsets.symmetric(vertical: 20.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      margin:  EdgeInsets.symmetric(horizontal: 4.w),
                      width: 5.w,
                      height:5.h,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? Colors.orange : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
