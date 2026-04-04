import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/banquet_tabs/banquet_bottomnav.dart';
import 'package:fudikoclient/screens/banquet_tabs/reservartion/banquet_reservation.dart';
import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
import 'package:fudikoclient/screens/tabs/bottomnav.dart';
import 'package:fudikoclient/screens/tabs/favorite/favorite.dart';
import 'package:fudikoclient/screens/banquet_tabs/home/homepage.dart';
import 'package:fudikoclient/screens/banquet_tabs/inquery/inquery.dart';
import 'package:fudikoclient/screens/tabs/profile/restaurantProfile.dart';
import 'package:fudikoclient/screens/tabs/reservation/reservation.dart';
import 'package:fudikoclient/utils/constants.dart';

class MainBanquetNavPage extends StatefulWidget {
  final String? city;
  final double? lat;
  final double? lng;

  const MainBanquetNavPage({this.city, this.lat, this.lng});

  @override
  State<MainBanquetNavPage> createState() => _MainBanquetNavPageState();
}

class _MainBanquetNavPageState extends State<MainBanquetNavPage> {
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
      // Home(
      //   currentCity: widget.city ?? "Locating...",
      //   currentLat: widget.lat,
      //   currentLng: widget.lng,
      // ),
      Home(),
      

      Inquery(),
      BanquetReservation(),
      // Favorite(),
      CustomerProfile()
    ];
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        bottomNavigationBar: BanquetBottomnav(
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
