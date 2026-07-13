import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/banquet_tabs/banquet_bottomnav.dart';
import 'package:fudikoclient/screens/banquet_tabs/inquery/banquet_inquery.dart';
import 'package:fudikoclient/screens/banquet_tabs/reservartion/banquet_reservation.dart';
import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
import 'package:fudikoclient/screens/home/homepage.dart' as root_home;
import 'package:fudikoclient/service/notification/notification_badges_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tab_navigation.dart';

class MainBanquetNavPage extends StatefulWidget {
  final String? city;
  final double? lat;
  final double? lng;

  const MainBanquetNavPage({
    super.key,
    this.city,
    this.lat,
    this.lng,
  });

  @override
  State<MainBanquetNavPage> createState() => _MainBanquetNavPageState();
}

class _MainBanquetNavPageState extends State<MainBanquetNavPage> {
  static const int _tabCount = 4;
  static const int _inquiryTabIndex = 1;

  int currentIndex = _inquiryTabIndex;

  final List<int> _tabHistory = [];
  final List<bool> _tabCanPop = List<bool>.filled(_tabCount, false);

  final GlobalKey<BanquetInqueryState> _inquiryKey =
      GlobalKey<BanquetInqueryState>();

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
      (index) => TabStackObserver(
        onStackChanged: () => _syncCanPop(index),
      ),
    );

    _loadNotificationBadges();
  }

  Future<void> _loadNotificationBadges() async {
    final badges = await NotificationBadgesService().fetchBadges();

    if (!mounted) return;

    setState(() {
      _inquiryBadgeCount = badges.enquiryEnquiries;
      _reservationBadgeCount = badges.enquiryReservations;
    });
  }

  void _syncCanPop(int index) {
    if (!mounted) return;

    final canPop =
        _navigatorKeys[index].currentState?.canPop() ?? false;

    if (_tabCanPop[index] == canPop) return;

    setState(() {
      _tabCanPop[index] = canPop;
    });
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
    final didPop =
        await _navigatorKeys[currentIndex].currentState?.maybePop() ??
            false;

    if (didPop) return;

    if (currentIndex != _inquiryTabIndex) {
      _resetToInquiry();
      return;
    }

    _returnToRootHome();
  }

  void _resetToInquiry() {
    for (final key in _navigatorKeys) {
      key.currentState?.popUntil((route) => route.isFirst);
    }

    _inquiryKey.currentState?.resetToPlanAParty();

    setState(() {
      currentIndex = _inquiryTabIndex;
      _tabHistory.clear();

      for (int i = 0; i < _tabCanPop.length; i++) {
        _tabCanPop[i] = false;
      }
    });
  }

  void _returnToRootHome() {
    final rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );

    if (rootNavigator.canPop()) {
      rootNavigator.pop();
      return;
    }

    rootNavigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const root_home.HomePage(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const SizedBox.shrink(),
      BanquetInquery(key: _inquiryKey),
      const BanquetReservation(),
      const CustomerProfile(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,

        // Hide the bottom navigation whenever a nested page
        // (details/edit/etc.) is pushed.
        bottomNavigationBar: _tabCanPop[currentIndex]
            ? null
            : const SafeArea(
                top: false,
                child: SizedBox.shrink(),
              ),

        body: SafeArea(
          top: false,
          maintainBottomViewPadding: true,
          child: Column(
            children: [
              Expanded(
                child: buildNestedTabNavigators(
                  currentIndex: currentIndex,
                  navigatorKeys: _navigatorKeys,
                  observers: _observers,
                  children: screens,
                ),
              ),

              if (!_tabCanPop[currentIndex])
                BanquetBottomnav(
                  selectedIndex: currentIndex,
                  onTabSelected: onTabChanged,
                  inquiryBadgeCount: _inquiryBadgeCount,
                  reservationBadgeCount: _reservationBadgeCount,
                ),
            ],
          ),
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:fudikoclient/screens/banquet_tabs/banquet_bottomnav.dart';
// import 'package:fudikoclient/screens/banquet_tabs/inquery/banquet_inquery.dart';
// import 'package:fudikoclient/screens/banquet_tabs/reservartion/banquet_reservation.dart';
// import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
// import 'package:fudikoclient/screens/home/homepage.dart' as root_home;
// import 'package:fudikoclient/service/notification/notification_badges_service.dart';
// import 'package:fudikoclient/utils/constants.dart';
// import 'package:fudikoclient/utils/tab_navigation.dart';

// class MainBanquetNavPage extends StatefulWidget {
//   final String? city;
//   final double? lat;
//   final double? lng;

//   const MainBanquetNavPage({super.key, this.city, this.lat, this.lng});

//   @override
//   State<MainBanquetNavPage> createState() => _MainBanquetNavPageState();
// }

// class _MainBanquetNavPageState extends State<MainBanquetNavPage> {
//   static const int _tabCount = 4;
//   static const int _inquiryTabIndex = 1;

//   int currentIndex = _inquiryTabIndex;
//   final List<int> _tabHistory = [];
//   final List<bool> _tabCanPop = List<bool>.filled(_tabCount, false);
//   final GlobalKey<BanquetInqueryState> _inquiryKey =
//       GlobalKey<BanquetInqueryState>();
//   late final List<GlobalKey<NavigatorState>> _navigatorKeys;
//   late final List<TabStackObserver> _observers;
//   int _inquiryBadgeCount = 0;
//   int _reservationBadgeCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _navigatorKeys = List.generate(
//       _tabCount,
//       (_) => GlobalKey<NavigatorState>(),
//     );
//     _observers = List.generate(
//       _tabCount,
//       (index) => TabStackObserver(onStackChanged: () => _syncCanPop(index)),
//     );
//     _loadNotificationBadges();
//   }

//   Future<void> _loadNotificationBadges() async {
//     final badges = await NotificationBadgesService().fetchBadges();
//     if (!mounted) return;
//     setState(() {
//       _inquiryBadgeCount = badges.enquiryEnquiries;
//       _reservationBadgeCount = badges.enquiryReservations;
//     });
//   }

//   void _syncCanPop(int index) {
//     if (!mounted) return;
//     final canPop = _navigatorKeys[index].currentState?.canPop() ?? false;
//     if (_tabCanPop[index] == canPop) return;
//     setState(() => _tabCanPop[index] = canPop);
//   }

//   void onTabChanged(int index) {
//     if (index == 0) {
//       _returnToRootHome();
//       return;
//     }

//     if (index == _inquiryTabIndex) {
//       _resetToInquiry();
//       return;
//     }

//     if (index == currentIndex) return;

//     setState(() {
//       _tabHistory.add(currentIndex);
//       currentIndex = index;
//     });
//   }

//   Future<void> _handleBack() async {
//     final didPopTabRoute =
//         await _navigatorKeys[currentIndex].currentState?.maybePop() ?? false;
//     if (didPopTabRoute) return;

//     if (currentIndex != _inquiryTabIndex) {
//       _resetToInquiry();
//       return;
//     }

//     _returnToRootHome();
//   }

//   void _resetToInquiry() {
//     for (final navigatorKey in _navigatorKeys) {
//       navigatorKey.currentState?.popUntil((route) => route.isFirst);
//     }
//     _inquiryKey.currentState?.resetToPlanAParty();

//     setState(() {
//       currentIndex = _inquiryTabIndex;
//       _tabHistory.clear();
//       for (var index = 0; index < _tabCanPop.length; index++) {
//         _tabCanPop[index] = false;
//       }
//     });
//   }

//   void _returnToRootHome() {
//     final rootNavigator = Navigator.of(context, rootNavigator: true);
//     if (rootNavigator.canPop()) {
//       rootNavigator.pop();
//       return;
//     }

//     rootNavigator.pushAndRemoveUntil(
//       MaterialPageRoute<void>(builder: (_) => const root_home.HomePage()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screens = [
//       const SizedBox.shrink(),
//       BanquetInquery(key: _inquiryKey),
//       const BanquetReservation(),
//       const CustomerProfile(),
//     ];

//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, result) {
//         if (!didPop) _handleBack();
//       },
//       child: Scaffold(
//         backgroundColor: appSecondaryBackgroundColor,
//         bottomNavigationBar: _tabCanPop[currentIndex]
//             ? null
//             : SafeArea(
//                 top: false,
//                 child: BanquetBottomnav(
//                   selectedIndex: currentIndex,
//                   onTabSelected: onTabChanged,
//                   inquiryBadgeCount: _inquiryBadgeCount,
//                   reservationBadgeCount: _reservationBadgeCount,
//                 ),
//               ),
//         body: SafeArea(
//           top: false,
//           maintainBottomViewPadding: true,
//           child: buildNestedTabNavigators(
//             currentIndex: currentIndex,
//             navigatorKeys: _navigatorKeys,
//             children: screens,
//             observers: _observers,
//           ),
//         ),
//       ),
//     );
//   }
// }
