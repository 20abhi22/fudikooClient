import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
import 'package:fudikoclient/screens/tabs/bottomnav.dart';
import 'package:fudikoclient/screens/tabs/favorite/favorite.dart';
import 'package:fudikoclient/screens/tabs/home/home.dart';
import 'package:fudikoclient/screens/tabs/reservation/reservation.dart';
import 'package:fudikoclient/utils/constants.dart';

class MainRestaurantNavPage extends StatefulWidget {
  final String? city;
  final double? lat;
  final double? lng;

  const MainRestaurantNavPage({this.city, this.lat, this.lng});

  @override
  State<MainRestaurantNavPage> createState() => _MainRestaurantNavPageState();
}

class _MainRestaurantNavPageState extends State<MainRestaurantNavPage> {
  int currentIndex = 0;
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
      Home(
        currentCity: widget.city ?? "Locating...",
        currentLat: widget.lat,
        currentLng: widget.lng,
      ),

      // Inquery(),
      Reservation(),
      Favorite(),
      CustomerProfile(),
    ];
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        bottomNavigationBar: Bottomnav(
          selectedIndex: currentIndex,
          onTabSelected: onTabChanged,
        ),
        body: Stack(children: [screens[currentIndex]]),
      ),
    );
  }
}
