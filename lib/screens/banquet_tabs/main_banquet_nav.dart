import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/banquet_tabs/banquet_bottomnav.dart';
import 'package:fudikoclient/screens/banquet_tabs/inquery/banquet_inquery.dart';
import 'package:fudikoclient/screens/banquet_tabs/reservartion/banquet_reservation.dart';
import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
import 'package:fudikoclient/screens/home/homepage.dart' as root_home;
import 'package:fudikoclient/service/notification/badge_controller.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tab_navigation.dart';

class MainBanquetNavPage extends StatefulWidget {
  final String? city;
  final double? lat;
  final double? lng;

  const MainBanquetNavPage({super.key, this.city, this.lat, this.lng});

  @override
  State<MainBanquetNavPage> createState() => _MainBanquetNavPageState();
}

class _MainBanquetNavPageState extends State<MainBanquetNavPage> {
  static const int _tabCount = 4;
  static const int _inquiryTabIndex = 1;
  static const int _reservationTabIndex = 2;

  int currentIndex = _inquiryTabIndex;

  final List<int> _tabHistory = [];
  final List<bool> _tabCanPop = List<bool>.filled(_tabCount, false);

  final GlobalKey<BanquetInqueryState> _inquiryKey =
      GlobalKey<BanquetInqueryState>();
  final GlobalKey<BanquetReservationState> _reservationKey =
      GlobalKey<BanquetReservationState>();

  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final List<TabStackObserver> _observers;
  int? _pendingRefreshTab;

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
    // Listener only, no subscribe(): the bottom bar keeps the poll alive, and
    // this just gives a popup-blocked refresh another chance each tick.
    BadgeController.instance.addListener(_flushPendingRefresh);
  }

  @override
  void dispose() {
    BadgeController.instance.removeListener(_flushPendingRefresh);
    super.dispose();
  }

  /// Reloads whichever tab is open. Called when its badge count changes, so a
  /// list never sits stale under a bumped badge.
  ///
  /// Held back while a dialog or bottom sheet covers the shell: reloading the
  /// list underneath would pull the ground out from under whatever the customer
  /// has open. The reload runs on the next badge poll once the popup is gone.
  /// The Inquiries tab applies the same rule to its own inline overlays.
  void _refreshTab(int index) {
    if (_isPopupOpen) {
      _pendingRefreshTab = index;
      return;
    }

    _pendingRefreshTab = null;
    if (index == _inquiryTabIndex) {
      _inquiryKey.currentState?.refresh();
    } else if (index == _reservationTabIndex) {
      _reservationKey.currentState?.refreshReservations();
    }
  }

  /// True while a route (dialog, bottom sheet, pushed page) sits above the
  /// shell.
  bool get _isPopupOpen => ModalRoute.of(context)?.isCurrent == false;

  /// Retries a refresh that a popup blocked. Driven by the badge poll, so it
  /// gets a chance every tick until the popup closes.
  void _flushPendingRefresh() {
    final pending = _pendingRefreshTab;
    if (pending == null || _isPopupOpen) return;
    if (pending != currentIndex) {
      _pendingRefreshTab = null;
      return;
    }
    _refreshTab(pending);
  }

  void _syncCanPop(int index) {
    if (!mounted) return;

    final canPop = _navigatorKeys[index].currentState?.canPop() ?? false;

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

    if (index == _reservationTabIndex) {
      _reservationKey.currentState?.refreshReservations();
    }

    if (index == currentIndex) return;

    setState(() {
      _tabHistory.add(currentIndex);
      currentIndex = index;
    });
  }

  Future<void> _handleBack() async {
    final didPop =
        await _navigatorKeys[currentIndex].currentState?.maybePop() ?? false;

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
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    if (rootNavigator.canPop()) {
      rootNavigator.pop();
      return;
    }

    rootNavigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const root_home.HomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const SizedBox.shrink(),
      BanquetInquery(key: _inquiryKey),
      BanquetReservation(key: _reservationKey),
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
            : SafeArea(
                top: false,
                child: BanquetBottomnav(
                  selectedIndex: currentIndex,
                  onTabSelected: onTabChanged,
                  onSelectedTabBadgeChanged: () => _refreshTab(currentIndex),
                ),
              ),

        body: SafeArea(
          top: false,
          maintainBottomViewPadding: true,
          child: buildNestedTabNavigators(
            currentIndex: currentIndex,
            navigatorKeys: _navigatorKeys,
            observers: _observers,
            children: screens,
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
