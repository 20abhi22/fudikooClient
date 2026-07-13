import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'about1.dart';
import 'about2.dart';
import 'about3.dart';
import 'about4.dart';

class AboutLayout extends StatefulWidget {
  const AboutLayout({super.key});

  @override
  State<AboutLayout> createState() => _AboutLayoutState();
}

class _AboutLayoutState extends State<AboutLayout> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: 4,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final pages = [
                  About1(onPress: _nextPage),
                  About2(onPress: _nextPage),
                  About3(onPress: _nextPage),
                  const About4(),
                ];
                return pages[index];
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? const Color(0xFFC95F05)
                            : const Color(0xFFD9D9D9),
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
