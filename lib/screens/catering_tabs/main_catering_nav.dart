import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/catering_tabs/catering_bottomnav.dart';
import 'package:fudikoclient/screens/catering_tabs/inquery/catering_inquery.dart';
import 'package:fudikoclient/screens/catering_tabs/reservation/catering_reservation.dart';
import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
import 'package:fudikoclient/screens/home/homepage.dart' as root_home;
import 'package:fudikoclient/service/notification/badge_controller.dart';
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
  static const int _reservationTabIndex = 2;

  int currentIndex = _inquiryTabIndex;
  final List<int> _tabHistory = [];
  final List<bool> _tabCanPop = List<bool>.filled(_tabCount, false);
  final GlobalKey<CateringInqueryState> _inquiryKey =
      GlobalKey<CateringInqueryState>();
  final GlobalKey<CateringReservationState> _reservationKey =
      GlobalKey<CateringReservationState>();
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
      CateringReservation(key: _reservationKey),
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
                  onSelectedTabBadgeChanged: () => _refreshTab(currentIndex),
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
