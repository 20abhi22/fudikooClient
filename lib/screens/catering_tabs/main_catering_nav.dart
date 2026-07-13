import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/catering_tabs/catering_bottomnav.dart';
import 'package:fudikoclient/screens/catering_tabs/inquery/catering_inquery.dart';
import 'package:fudikoclient/screens/catering_tabs/reservation/catering_reservation.dart';
import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
import 'package:fudikoclient/screens/home/homepage.dart' as root_home;
import 'package:fudikoclient/service/notification/notification_badges_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tab_navigation.dart';

class MainCateringNavPage extends StatefulWidget {
  final String? city;
  final double? lat;
  final double? lng;

  const MainCateringNavPage({super.key, this.city, this.lat, this.lng});

  @override
  State<MainCateringNavPage> createState() => _MainCateringNavPageState();
}

class _MainCateringNavPageState extends State<MainCateringNavPage> {
  static const int _tabCount = 4;
  static const int _inquiryTabIndex = 1;

  int currentIndex = _inquiryTabIndex;
  final List<int> _tabHistory = [];
  final List<bool> _tabCanPop = List<bool>.filled(_tabCount, false);
  final GlobalKey<CateringInqueryState> _inquiryKey =
      GlobalKey<CateringInqueryState>();
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final List<TabStackObserver> _observers;
  int _inquiryBadgeCount = 0;
  int _reservationBadgeCount = 0;

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
      _inquiryBadgeCount = badges.cateringEnquiries;
      _reservationBadgeCount = badges.cateringReservations;
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
      _returnToRootHome();
      return;
    }

    if (index == _inquiryTabIndex) {
      _resetToInquiry();
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

    if (currentIndex != _inquiryTabIndex) {
      _resetToInquiry();
      return;
    }

    _returnToRootHome();
  }

  void _resetToInquiry() {
    for (final navigatorKey in _navigatorKeys) {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    _inquiryKey.currentState?.resetToBookACatering();

    setState(() {
      currentIndex = _inquiryTabIndex;
      _tabHistory.clear();
      for (var index = 0; index < _tabCanPop.length; index++) {
        _tabCanPop[index] = false;
      }
    });
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
      const SizedBox.shrink(),
      CateringInquery(key: _inquiryKey),
      const CateringReservation(),
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
                child: CateringBottomnav(
                  selectedIndex: currentIndex,
                  onTabSelected: onTabChanged,
                  inquiryBadgeCount: _inquiryBadgeCount,
                  reservationBadgeCount: _reservationBadgeCount,
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
