import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/customerProfile/customerProfile.dart';
import 'package:fudikoclient/screens/home/homepage.dart' as root_home;
import 'package:fudikoclient/screens/tabs/bottomnav.dart';
import 'package:fudikoclient/screens/tabs/favorite/favorite.dart';
import 'package:fudikoclient/screens/tabs/home/home.dart';
import 'package:fudikoclient/screens/tabs/reservation/reservation.dart';
import 'package:fudikoclient/service/notification/badge_controller.dart';
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

  static const int _homeTabIndex = 0;
  static const int _reservationTabIndex = 1;
  static const int _favoriteTabIndex = 2;

  int currentIndex = 0;
  final List<int> _tabHistory = [];
  final List<bool> _tabCanPop = List<bool>.filled(_tabCount, false);
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final List<TabStackObserver> _observers;
  final GlobalKey<HomeState> _homeKey = GlobalKey<HomeState>();
  final GlobalKey<ReservationState> _reservationKey =
      GlobalKey<ReservationState>();
  final GlobalKey<FavoriteState> _favoriteKey = GlobalKey<FavoriteState>();
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
  void _refreshTab(int index) {
    if (_isPopupOpen) {
      _pendingRefreshTab = index;
      return;
    }

    _pendingRefreshTab = null;
    if (index == _homeTabIndex) {
      _homeKey.currentState?.refresh();
    } else if (index == _reservationTabIndex) {
      _reservationKey.currentState?.refresh();
    } else if (index == _favoriteTabIndex) {
      _favoriteKey.currentState?.refresh();
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
      _homeKey.currentState?.refresh();
      return;
    }

    if (index == currentIndex) return;

    setState(() {
      _tabHistory.add(currentIndex);
      currentIndex = index;
    });

    if (index == _reservationTabIndex) {
      _reservationKey.currentState?.refresh();
    } else if (index == _favoriteTabIndex) {
      _favoriteKey.currentState?.refresh();
    }
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
        key: _homeKey,
        currentCity: widget.city ?? "Locating...",
        currentLat: widget.lat,
        currentLng: widget.lng,
      ),
      Reservation(key: _reservationKey),
      Favorite(
        key: _favoriteKey,
        currentLat: widget.lat,
        currentLng: widget.lng,
      ),
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
