import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
import 'package:fudikoclient/screens/tabs/bottomnav.dart';
import 'package:fudikoclient/screens/tabs/favorite/favorite.dart';
import 'package:fudikoclient/screens/tabs/home/home.dart';
import 'package:fudikoclient/screens/tabs/inquery/inquery.dart';
import 'package:fudikoclient/screens/tabs/profile/restaurantProfile.dart';
import 'package:fudikoclient/screens/tabs/reservation/reservation.dart';
import 'package:fudikoclient/utils/constants.dart';

class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  int currentIndex = 0;
  bool isDrawerOpen = false;
  late List<Widget> screens;

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
  }

  void onTabChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    screens = [
      Home(),
      Inquery(),
      Reservation(),
      Favorite(),
      CustomerProfile()
    ];
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        bottomNavigationBar: Bottomnav(
          selectedIndex: currentIndex,
          onTabSelected: onTabChanged,
        ),
        body: Stack(
          children: [
            screens[currentIndex],
          ],
        ),
      ),
    );
  }
}
