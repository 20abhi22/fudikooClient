import 'package:flutter/material.dart';
import 'package:fudikoclient/core/responsive/responsive_builder.dart';
import 'package:fudikoclient/features/home/home_content.dart';
import 'package:fudikoclient/features/home/home_desktop.dart';
import 'package:fudikoclient/features/home/home_mobile.dart';
import 'package:fudikoclient/features/home/home_tablet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ResponsiveBuilder(
        mobile: (context, constraints, orientation) {
          return HomeMobile(items: homeItems, orientation: orientation);
        },
        tablet: (context, constraints, orientation) {
          return HomeTablet(items: homeItems, orientation: orientation);
        },
        // desktop: (context, constraints, orientation) {
        //   return HomeDesktop(items: homeItems, orientation: orientation);
        // },
      ),
    );
  }
}
