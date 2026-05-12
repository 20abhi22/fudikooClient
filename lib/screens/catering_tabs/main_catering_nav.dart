import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/catering_tabs/catering_bottomnav.dart';
import 'package:fudikoclient/screens/catering_tabs/inquery/catering_inquery.dart';
import 'package:fudikoclient/screens/catering_tabs/reservation/catering_reservation.dart';
import 'package:fudikoclient/screens/banquet_tabs/banquet_bottomnav.dart';
import 'package:fudikoclient/screens/banquet_tabs/reservartion/banquet_reservation.dart';
import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/screens/tabs/bottomnav.dart';
import 'package:fudikoclient/screens/tabs/favorite/favorite.dart';
import 'package:fudikoclient/screens/banquet_tabs/home/homepage.dart';
import 'package:fudikoclient/screens/banquet_tabs/inquery/banquet_inquery.dart';
import 'package:fudikoclient/screens/tabs/profile/restaurantProfile.dart';
import 'package:fudikoclient/screens/tabs/reservation/reservation.dart';
import 'package:fudikoclient/utils/constants.dart';

class MainCateringNavPage extends StatefulWidget {
  final String? city;
  final double? lat;
  final double? lng;

  const MainCateringNavPage({this.city, this.lat, this.lng});

  @override
  State<MainCateringNavPage> createState() => _MainCateringNavPageState();
}

class _MainCateringNavPageState extends State<MainCateringNavPage> {
  int currentIndex = 1;
  bool isDrawerOpen = false;
  late List<Widget> screens;

  @override
  void initState() {
    super.initState();
    currentIndex = 1;
  }

  void onTabChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    screens = [
      // Home(
      //   currentCity: widget.city ?? "Locating...",
      //   currentLat: widget.lat,
      //   currentLng: widget.lng,
      // ),
      // Home(),
      HomePage(),
      

      CateringInquery(),
      CateringReservation(),
      // Favorite(),
      CustomerProfile()
    ];
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        bottomNavigationBar: CateringBottomnav(
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
