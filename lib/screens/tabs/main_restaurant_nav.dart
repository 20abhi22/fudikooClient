import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
import 'package:fudikoclient/screens/home/homepage.dart' as root_home;
import 'package:fudikoclient/screens/tabs/bottomnav.dart';
import 'package:fudikoclient/screens/tabs/favorite/favorite.dart';
import 'package:fudikoclient/screens/tabs/home/home.dart';
import 'package:fudikoclient/screens/tabs/reservation/reservation.dart';
import 'package:fudikoclient/service/notification/notification_badges_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tab_navigation.dart';

class MainRestaurantNavPage extends StatefulWidget {
  final String? city;
  final double? lat;
  final double? lng;

  const MainRestaurantNavPage({super.key, this.city, this.lat, this.lng});

  @override
  State<MainRestaurantNavPage> createState() => _MainRestaurantNavPageState();
}

class _MainRestaurantNavPageState extends State<MainRestaurantNavPage> {
  static const int _tabCount = 4;

  int currentIndex = 0;
  final List<int> _tabHistory = [];
  final List<bool> _tabCanPop = List<bool>.filled(_tabCount, false);
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final List<TabStackObserver> _observers;
  int _reservationBadgeCount = 0;
  int _favoriteBadgeCount = 0;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List.generate(
      _tabCount,
      (_) => GlobalKey<NavigatorState>(),
    );
    _observers = List.generate(
      _tabCount,
      (index) => TabStackObserver(onStackChanged: () => _syncCanPop(index)),
    );
    _loadNotificationBadges();
  }

  Future<void> _loadNotificationBadges() async {
    final badges = await NotificationBadgesService().fetchBadges();
    if (!mounted) return;
    setState(() {
      _reservationBadgeCount = badges.restaurantReservations;
      _favoriteBadgeCount = badges.restaurantFavourites;
    });
  }

  void _syncCanPop(int index) {
    if (!mounted) return;
    final canPop = _navigatorKeys[index].currentState?.canPop() ?? false;
    if (_tabCanPop[index] == canPop) return;
    setState(() => _tabCanPop[index] = canPop);
  }

  void onTabChanged(int index) {
    if (index == 0) {
      for (final navigatorKey in _navigatorKeys) {
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }

      setState(() {
        currentIndex = 0;
        _tabHistory.clear();
        for (var tab = 0; tab < _tabCanPop.length; tab++) {
          _tabCanPop[tab] = false;
        }
      });
      return;
    }

    if (index == currentIndex) return;

    setState(() {
      _tabHistory.add(currentIndex);
      currentIndex = index;
    });
  }

  Future<void> _handleBack() async {
    final didPopTabRoute =
        await _navigatorKeys[currentIndex].currentState?.maybePop() ?? false;
    if (didPopTabRoute) return;

    if (_tabHistory.isNotEmpty) {
      setState(() => currentIndex = _tabHistory.removeLast());
      return;
    }

    _returnToRootHome();
  }

  void _returnToRootHome() {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
      return;
    }

    rootNavigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const root_home.HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      Home(
        currentCity: widget.city ?? "Locating...",
        currentLat: widget.lat,
        currentLng: widget.lng,
      ),
      const Reservation(),
      Favorite(currentLat: widget.lat, currentLng: widget.lng),
      const CustomerProfile(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        bottomNavigationBar: _tabCanPop[currentIndex]
            ? null
            : SafeArea(
                top: false,
                child: Bottomnav(
                  selectedIndex: currentIndex,
                  onTabSelected: onTabChanged,
                  reservationBadgeCount: _reservationBadgeCount,
                  favoriteBadgeCount: _favoriteBadgeCount,
                ),
              ),
        body: SafeArea(
          top: false,
          maintainBottomViewPadding: true,
          child: buildNestedTabNavigators(
            currentIndex: currentIndex,
            navigatorKeys: _navigatorKeys,
            children: screens,
            observers: _observers,
          ),
        ),
      ),
    );
  }
}
