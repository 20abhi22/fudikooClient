import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/features/map/providers/map_providers.dart';
import 'package:fudikoclient/model/partner_ad/partner_ad_model.dart';
import 'package:fudikoclient/screens/auth/updatepassword.dart';
import 'package:fudikoclient/screens/badge/aboutbadge.dart';
import 'package:fudikoclient/screens/catering_tabs/main_catering_nav.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/service/partner_ad/partner_ads_service.dart';
import 'package:fudikoclient/utils/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fudikoclient/screens/aboutapp/about.dart';
import 'package:fudikoclient/screens/auth/login.dart';
import 'package:fudikoclient/screens/badge/badgeinfo.dart';
import 'package:fudikoclient/screens/banquet_tabs/main_banquet_nav.dart';
import 'package:fudikoclient/screens/complaint/complaint.dart';
import 'package:fudikoclient/screens/contact/contact.dart';
import 'package:fudikoclient/screens/earnPoints/earnPoints.dart';
import 'package:fudikoclient/screens/feedback/feedback.dart';
import 'package:fudikoclient/screens/home/components/banquetBox.dart';
import 'package:fudikoclient/screens/home/components/cateringBox.dart';
import 'package:fudikoclient/screens/home/components/restaurantBox.dart';
import 'package:fudikoclient/screens/home/components/takeawayBox.dart';
import 'package:fudikoclient/screens/languages/languages.dart';
import 'package:fudikoclient/screens/notification/notification.dart';
import 'package:fudikoclient/screens/reward/reward.dart';
import 'package:fudikoclient/screens/tabs/main_restaurant_nav.dart';
import 'package:fudikoclient/screens/takeaway_tabs/takeaway.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/widgets/app_shell.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(home: _HomePageContent());
  }
}

class _HomePageContent extends ConsumerStatefulWidget {
  const _HomePageContent();

  @override
  ConsumerState<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends ConsumerState<_HomePageContent> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  int _currentOfferIndex = 0;
  bool isDrawerOpen = false;
  String _currentCity = "Locating...";
  double? _currentLat;
  double? _currentLng;
  late SharedPreferences _prefs;
  late final ProviderSubscription<SelectedLocation?> _locationSubscription;
  bool _preferencesReady = false;

  bool _isLocationLoading = false;

  final ScrollController _offersScrollController = ScrollController();
  final PartnerAdsService _partnerAdsService = PartnerAdsService();
  List<PartnerAdModel> _partnerAds = [];
  bool _isAdsLoading = true;

  // Cache keys
  static const String _cacheKeyCity = 'cached_city';
  static const String _cacheKeyLat = 'cached_lat';
  static const String _cacheKeyLng = 'cached_lng';

  @override
  void initState() {
    super.initState();
    _locationSubscription = ref.listenManual<SelectedLocation?>(
      selectedLocationProvider,
      (previous, next) {
        if (next != null) _applySharedLocation(next);
      },
    );
    _initializeLocation();
    _fetchPartnerAds();
  }

  Future<void> _initializeLocation() async {
    _prefs = await SharedPreferences.getInstance();
    _preferencesReady = true;
    await _loadCachedLocation();
  }

  // Future<void> _fetchPartnerAds() async {
  //   final ads = await _partnerAdsService.getPartnerAds();
  //   if (!mounted) return;
  //   setState(() {
  //     _partnerAds = ads;
  //     _isAdsLoading = false;
  //   });
  // }
  Future<void> _fetchPartnerAds() async {
    final ads = await _partnerAdsService.getPartnerAds();
    if (!mounted) return;
    setState(() {
      _partnerAds = ads;
      _isAdsLoading = false;
    });
  }

  Future<void> _loadCachedLocation() async {
    final cachedCity = _prefs.getString(_cacheKeyCity);
    if (cachedCity != null) {
      // Use cached location
      setState(() {
        _currentCity = cachedCity;
        _currentLat = _prefs.getDouble(_cacheKeyLat);
        _currentLng = _prefs.getDouble(_cacheKeyLng);
      });
      _publishLocation(_currentCity, _currentLat, _currentLng);
    } else {
      // No cache, fetch fresh location
      await _fetchLocation();
    }
  }

  Future<void> _saveCachedLocation(
    String city,
    double? lat,
    double? lng,
  ) async {
    await _prefs.setString(_cacheKeyCity, city);
    if (lat != null) {
      await _prefs.setDouble(_cacheKeyLat, lat);
    } else {
      await _prefs.remove(_cacheKeyLat);
    }
    if (lng != null) {
      await _prefs.setDouble(_cacheKeyLng, lng);
    } else {
      await _prefs.remove(_cacheKeyLng);
    }
  }

  void _publishLocation(String city, double? latitude, double? longitude) {
    ref.read(selectedLocationProvider.notifier).state = SelectedLocation(
      city: city,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> _applySharedLocation(SelectedLocation location) async {
    final isSameLocation =
        _currentCity == location.city &&
        _currentLat == location.latitude &&
        _currentLng == location.longitude;
    if (isSameLocation || !mounted) return;

    setState(() {
      _currentCity = location.city;
      _currentLat = location.latitude;
      _currentLng = location.longitude;
    });

    if (_preferencesReady) {
      await _saveCachedLocation(
        location.city,
        location.latitude,
        location.longitude,
      );
    }
  }

  // Future<void> _fetchLocation() async {
  //   try {
  //     LocationPermission permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied ||
  //         permission == LocationPermission.deniedForever) {
  //       setState(() => _currentCity = "Location denied");
  //       return;
  //     }

  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );

  //     setState(() {
  //       _currentLat = position.latitude;
  //       _currentLng = position.longitude;
  //     });

  //     List<Placemark> placemarks = await placemarkFromCoordinates(
  //       position.latitude,
  //       position.longitude,
  //     );

  //     if (placemarks.isNotEmpty) {
  //       final p = placemarks.first;
  //       final city = p.locality ?? p.subLocality ?? p.name ?? "Unknown";
  //       setState(() {
  //         _currentCity = city;
  //       });
  //       // Cache the location
  //       await _saveCachedLocation(city, _currentLat, _currentLng);
  //     }
  //   } catch (e) {
  //     setState(() => _currentCity = "Unknown");
  //   }
  // }
  Future<void> _fetchLocation() async {
    if (mounted) setState(() => _isLocationLoading = true);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _currentCity = "Location denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality ?? p.subLocality ?? p.name ?? "Unknown";
        setState(() {
          _currentCity = city;
        });
        await _saveCachedLocation(city, _currentLat, _currentLng);
        _publishLocation(city, _currentLat, _currentLng);
      }
    } catch (e) {
      setState(() => _currentCity = "Unknown");
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  @override
  void dispose() {
    _locationSubscription.close();
    _pageController.dispose();
    _offersScrollController.dispose();

    super.dispose();
  }

  void _showServiceContent() {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final bool isMobileDevice = Breakpoints.isMobileDevice(screenSize);
    final bool isTablet = Breakpoints.isTabletDevice(screenSize);
    final bool isCompactPhone =
        isMobileDevice && (screenWidth < 390 || screenHeight < 720);
    final double horizontalPadding = isTablet
        ? screenWidth * 0.06
        : isCompactPhone
        ? screenWidth * 0.05
        : screenWidth * 0.075;
    final double contentGap = isCompactPhone
        ? screenHeight * 0.01
        : isTablet
        ? AppDimensions.gridGap(context)
        : screenHeight * 0.012;
    final double sliderWidth = screenWidth * (isTablet ? 0.28 : 0.5);
    final double drawerWidth = isTablet
        ? (screenWidth * 0.34).clamp(300.0, 360.0).toDouble()
        : isCompactPhone
        ? (screenWidth * 0.72).clamp(240.0, 280.0).toDouble()
        : screenWidth * 0.6;
    final double drawerHorizontalPadding = isTablet
        ? 28.0
        : isCompactPhone
        ? 18.0
        : screenWidth * 0.05;
    final double drawerInnerPadding = isTablet
        ? 14.0
        : isCompactPhone
        ? 10.0
        : screenWidth * 0.025;
    final double drawerLogoWidth = isTablet
        ? drawerWidth * 0.46
        : isCompactPhone
        ? drawerWidth * 0.5
        : screenWidth * 0.35;
    final double drawerSectionGap = isTablet
        ? 34.0
        : isCompactPhone
        ? 22.0
        : screenHeight * 0.06;
    final double drawerItemGap = isTablet
        ? 10.0
        : isCompactPhone
        ? 8.0
        : screenHeight * 0.012;
    final double drawerIconSize = isTablet
        ? 22.0
        : isCompactPhone
        ? 19.0
        : 21.w;
    final double drawerInfoIconSize = isTablet
        ? 23.0
        : isCompactPhone
        ? 20.0
        : 22.w;
    final double drawerLargeIconSize = isTablet
        ? 26.0
        : isCompactPhone
        ? 23.0
        : 26.w;
    final double drawerLogoutIconSize = isTablet
        ? 22.0
        : isCompactPhone
        ? 19.0
        : 20.w;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isDrawerOpen) {
          setState(() => isDrawerOpen = false);
          return;
        }
        if (_currentIndex == 1) {
          _showServiceContent();
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isCompactPhone
                          ? screenHeight * 0.016
                          : screenHeight * 0.025,
                    ),
                    child: _navBar(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: 2,
                            onPageChanged: (index) {
                              setState(() => _currentIndex = index);
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: horizontalPadding,
                                  right: horizontalPadding,
                                  top: isCompactPhone
                                      ? screenHeight * 0.016
                                      : screenHeight * 0.03,
                                  bottom: isCompactPhone
                                      ? screenHeight * 0.006
                                      : screenHeight * 0.01,
                                ),
                                child: index == 0
                                    ? _serviceContent(gap: contentGap)
                                    : _offerContent(
                                        isTablet: isTablet,
                                        compactHeight: isCompactPhone,
                                      ),
                              );
                            },
                          ),
                        ),

                        // WORKING SLIDER
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isCompactPhone
                                ? screenHeight * 0.014
                                : screenHeight * 0.02,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: sliderWidth,
                              height: 8,
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  // Background thin line
                                  Container(
                                    width: sliderWidth,
                                    height: 0.5,
                                    decoration: BoxDecoration(
                                      color: sliderColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  // Active half — animates position
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    left: _currentIndex == 0
                                        ? 0
                                        : sliderWidth / 2,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: sliderWidth / 2,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: sliderColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Drawer overlay
              if (isDrawerOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => isDrawerOpen = false),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ),

              // Drawer
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: 0,
                bottom: 0,
                left: isDrawerOpen ? 0 : -drawerWidth - 24,
                child: Container(
                  width: drawerWidth,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(-4, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: drawerHorizontalPadding,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: isCompactPhone
                                  ? 36
                                  : isTablet
                                  ? 56
                                  : screenHeight * 0.12,
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Image.asset(
                                'assets/images/logofudikoo.png',
                                width: drawerLogoWidth,
                              ),
                            ),
                            SizedBox(height: drawerSectionGap),
                            AppText(
                              text: "Settings",
                              size: 15,
                              fontWeight: FontWeight.w600,
                              color: appTextColor2,
                            ),
                            SizedBox(height: drawerItemGap),
                            Divider(
                              thickness: 1,
                              color: Colors.grey,
                              height: 1,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: drawerInnerPadding,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "Change Password",
                                    lockIcon,
                                    //  ChangePassword(),
                                    UpdatePassword(),
                                    drawerIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "Notifications",
                                    bellIcon,
                                    NotificationScreen(),
                                    drawerIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "Languages",
                                    languageIcon,
                                    Languages(),
                                    drawerIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "Rewards",
                                    rewardsIcon,
                                    Reward(),
                                    drawerIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "Invite a Friend",
                                    inviteIcon,
                                    EarnPoints(),
                                    drawerIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: drawerSectionGap),
                            AppText(
                              text: "Information",
                              size: 15,
                              fontWeight: FontWeight.w600,
                              color: appTextColor2,
                            ),
                            SizedBox(height: drawerItemGap),
                            Divider(
                              thickness: 1,
                              color: Colors.grey,
                              height: 1,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: drawerInnerPadding,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "About the App",
                                    infoIcon,
                                    AboutPage(),
                                    drawerInfoIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "Badge Earnings",
                                    helpIcon,
                                    BadgeInfo(),
                                    drawerLargeIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "About Badges",
                                    "assets/images/verificationgrey.png",
                                    AboutBadgePage(),
                                    drawerLargeIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "Complaints",
                                    complainIcon,
                                    ComplaintPage(),
                                    drawerLargeIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "Rate the App",
                                    rateAppIcon,
                                    FeedBack(),
                                    drawerIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "Support",
                                    customerServiceIcon,
                                    ContactPage(),
                                    drawerIconSize,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: drawerSectionGap),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: drawerInnerPadding,
                              ),
                              child: Column(
                                children: [
                                  Divider(
                                    thickness: 1,
                                    color: Colors.red,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  _drawerItem(
                                    "Log Out",
                                    logoutIcon,
                                    Login(),
                                    drawerLogoutIconSize,
                                    Colors.red,
                                  ),
                                  SizedBox(height: drawerItemGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.red,
                                    height: 1,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: isCompactPhone ? 18 : screenHeight * 0.03,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _serviceContent({required double gap}) {
  //   final services = <Widget>[
  //     InkWell(
  //       onTap: () => slideRightWidget(
  //         newPage: MainRestaurantNavPage(
  //           city: _currentCity,
  //           lat: _currentLat,
  //           lng: _currentLng,
  //         ),
  //         context: context,
  //       ),
  //       child: RestaurantBox(),
  //     ),
  //     InkWell(
  //       onTap: () => slideRightWidget(
  //         newPage: MainBanquetNavPage(
  //           city: _currentCity,
  //           lat: _currentLat,
  //           lng: _currentLng,
  //         ),
  //         context: context,
  //       ),
  //       child: BanquetBox(),
  //     ),
  //     InkWell(
  //       onTap: () => slideRightWidget(
  //         newPage: MainCateringNavPage(
  //           city: _currentCity,
  //           lat: _currentLat,
  //           lng: _currentLng,
  //         ),
  //         context: context,
  //       ),
  //       child: CateringBox(),
  //     ),
  //     InkWell(
  //       onTap: () => slideRightWidget(newPage: TakeAway(), context: context),
  //       child: TakeAwayBox(),
  //     ),
  //   ];

  //   return Column(
  //     children: [
  //       for (var index = 0; index < services.length; index++) ...[
  //         Expanded(child: services[index]),
  //         if (index != services.length - 1) SizedBox(height: gap),
  //       ],
  //     ],
  //   );
  // }

Widget _serviceContent({required double gap}) {
  final orientation = MediaQuery.orientationOf(context);

  final services = <Widget>[
    InkWell(
      onTap: () => slideRightWidget(
        newPage: MainRestaurantNavPage(
          city: _currentCity,
          lat: _currentLat,
          lng: _currentLng,
        ),
        context: context,
      ),
      child: const RestaurantBox(),
    ),
    InkWell(
      onTap: () => slideRightWidget(
        newPage: MainBanquetNavPage(
          city: _currentCity,
          lat: _currentLat,
          lng: _currentLng,
        ),
        context: context,
      ),
      child: const BanquetBox(),
    ),
    InkWell(
      onTap: () => slideRightWidget(
        newPage: MainCateringNavPage(
          city: _currentCity,
          lat: _currentLat,
          lng: _currentLng,
        ),
        context: context,
      ),
      child: const CateringBox(),
    ),
    InkWell(
      onTap: () => slideRightWidget(
        newPage: const TakeAway(),
        context: context,
      ),
      child: const TakeAwayBox(),
    ),
  ];

  // PORTRAIT (unchanged)
  if (orientation == Orientation.portrait) {
    return Column(
      children: [
        Expanded(child: services[0]),
        SizedBox(height: gap),
        Expanded(child: services[1]),
        SizedBox(height: gap),
        Expanded(child: services[2]),
        SizedBox(height: gap),
        Expanded(child: services[3]),
      ],
    );
  }

  // LANDSCAPE
  return LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - gap) / 2;
      final cardHeight = (constraints.maxHeight - gap) / 2;

      Widget buildCard(Widget child) {
        return SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: child,
        );
      }

      return Column(
        children: [
          Row(
            children: [
              buildCard(services[0]),
              SizedBox(width: gap),
              buildCard(services[1]),
            ],
          ),
          SizedBox(height: gap),
          Row(
            children: [
              buildCard(services[2]),
              SizedBox(width: gap),
              buildCard(services[3]),
            ],
          ),
        ],
      );
    },
  );
}

  Widget _offerContent({required bool isTablet, required bool compactHeight}) {
    if (_isAdsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_partnerAds.isEmpty) {
      return Center(
        child: AppText(
          text: "No offers available",
          size: 13,
          fontWeight: FontWeight.w500,
          color: appTextColor2,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final offerCount = _partnerAds.length;
        final activeOfferIndex = _currentOfferIndex
            .clamp(0, offerCount - 1)
            .toInt();
        final dense =
            compactHeight ||
            constraints.maxHeight < 520 ||
            constraints.maxWidth < 360;
        final indicatorSize = isTablet
            ? 8.0
            : dense
            ? 6.0
            : 7.0;
        final activeIndicatorHeight = isTablet
            ? 24.0
            : dense
            ? 18.0
            : 21.0;
        final indicatorGap = dense ? 5.0 : 7.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: offerCount,
                onPageChanged: (index) {
                  if (_currentOfferIndex == index) return;
                  setState(() => _currentOfferIndex = index);
                },
                itemBuilder: (context, index) {
                  return _offerCard(dense: dense, ad: _partnerAds[index]);
                },
              ),
            ),
            SizedBox(
              width: isTablet ? 20.0 : 16.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < offerCount; index++) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: indicatorSize,
                      height: activeOfferIndex == index
                          ? activeIndicatorHeight
                          : indicatorSize,
                      decoration: BoxDecoration(
                        color: activeOfferIndex == index
                            ? appButtonColor
                            : appTextColor2.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(indicatorSize),
                      ),
                    ),
                    if (index != offerCount - 1) SizedBox(height: indicatorGap),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _offerCard({required bool dense, required PartnerAdModel ad}) {
    final labelSize = dense ? 11.5 : 13.0;
    final imagePadding = dense ? 6.0 : 10.0;

    final createdAt = DateTime.tryParse(ad.createdAt);
    final timeAgoText = createdAt != null ? timeago.format(createdAt) : '';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(imagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (timeAgoText.isNotEmpty) ...[
              AppText(
                text: timeAgoText,
                size: labelSize,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              SizedBox(height: dense ? 6 : 10),
            ],
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  ad.image,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/offerimage.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    String text,
    dynamic icon, // can be String (image path) or IconData
    Widget? routeWidget, [
    double? size,
    Color? color,
  ]) {
    final sizeOfScreen = MediaQuery.sizeOf(context);
    final width = sizeOfScreen.width;
    final height = sizeOfScreen.height;
    final isMobileDevice = Breakpoints.isMobileDevice(sizeOfScreen);
    final isCompactPhone = isMobileDevice && (width < 390 || height < 720);
    final isTablet = Breakpoints.isTabletDevice(sizeOfScreen);
    final iconSize =
        size ??
        (isTablet
            ? 22.0
            : isCompactPhone
            ? 18.0
            : 20.w);
    final itemGap = isTablet
        ? 12.0
        : isCompactPhone
        ? 8.0
        : 10.w;
    final textSize = isTablet
        ? 14.0
        : isCompactPhone
        ? 12.5
        : 13.sp;

    return GestureDetector(
      onTap: () {
        setState(() {
          isDrawerOpen = false;
        });

        Future.delayed(const Duration(milliseconds: 100), () async {
          if (!mounted) return;
          if (routeWidget != null) {
            if (routeWidget is Login) {
              await removeToken();
              if (!mounted) return;
              pushWidgetWhileRemove(newPage: routeWidget, context: context);
            } else {
              slideRightWidget(newPage: routeWidget, context: context);
            }
          }
        });
      },
      child: Row(
        children: [
          icon is String
              ? Image.asset(
                  icon,
                  width: iconSize,
                  height: iconSize,
                  color: color ?? const Color.fromARGB(255, 15, 15, 15),
                )
              : Icon(
                  icon,
                  size: iconSize,
                  color: color ?? const Color.fromARGB(255, 0, 0, 0),
                ),
          SizedBox(width: itemGap),
          Expanded(
            child: AppText(
              text: text,
              size: textSize,
              fontWeight: FontWeight.w500,
              color: color ?? appTextColor2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBar() {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    final isMobileDevice = Breakpoints.isMobileDevice(size);
    final isCompactPhone = isMobileDevice && (width < 390 || height < 720);
    final isTablet = Breakpoints.isTabletDevice(size);
    final locationWidth = isTablet
        ? width * 0.32
        : isCompactPhone
        ? width * 0.42
        : width * 0.45;
    final menuSize = isTablet
        ? 34.0
        : isCompactPhone
        ? 26.0
        : 30.0;
    final topPadding = isCompactPhone ? 6.0 : 10.0;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => isDrawerOpen = !isDrawerOpen),
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Icon(Icons.menu, size: menuSize, color: menuIconColor),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: _showLocationPicker, // ← tap to change location
            child: Container(
              width: locationWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x0D000000), // 5% opacity black
                    offset: const Offset(0, 0),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactPhone ? 12 : 20,
                  vertical: isCompactPhone ? 8 : 10,
                ),
                child: Column(
                  children: [
                    AppText(
                      text: "Near You",
                      size: isCompactPhone ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: menuIconColor.withValues(alpha: 0.8),
                    ),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: [
                    //       Image.asset(
                    //         mappingIcon,
                    //         width: isCompactPhone ? 12 : 14,
                    //         height: isCompactPhone ? 12 : 14,
                    //         color: menuIconColor.withValues(alpha: 0.8),
                    //       ),
                    //       const SizedBox(width: 4),
                    //       Flexible(
                    //         child: AppText(
                    //           isCentered: true,
                    //           text: _currentCity,
                    //           size: isCompactPhone ? 12 : 14,
                    //           fontWeight: FontWeight.w400,
                    //           color: menuIconColor.withValues(alpha: 0.8),
                    //         ),
                    //       ),
                    //       // Icon(
                    //       //   Icons.keyboard_arrow_down,
                    //       //   size: 15.w,
                    //       //   color: appTextColor3,
                    //       // ),
                    //     ],
                    //   ),
                    // ),
                    SizedBox(
                      width: double.infinity,
                      child: _isLocationLoading
                          ? SizedBox(
                              height: isCompactPhone ? 14 : 16,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: isCompactPhone ? 12 : 14,
                                    height: isCompactPhone ? 12 : 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: menuIconColor.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  AppText(
                                    text: "Locating...",
                                    size: isCompactPhone ? 12 : 14,
                                    fontWeight: FontWeight.w400,
                                    color: menuIconColor.withValues(alpha: 0.8),
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  mappingIcon,
                                  width: isCompactPhone ? 12 : 14,
                                  height: isCompactPhone ? 12 : 14,
                                  color: menuIconColor.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: AppText(
                                    isCentered: true,
                                    text: _currentCity,
                                    size: isCompactPhone ? 12 : 14,
                                    fontWeight: FontWeight.w400,
                                    color: menuIconColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Notification icon on right
        // Align(
        //   alignment: Alignment.centerRight,
        //   child: GestureDetector(
        //     onTap: () => Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (_) => NotificationScreen()),
        //     ),
        //     child: Padding(
        //       padding: EdgeInsets.only(top: 10.h),
        //       child: Icon(
        //         Icons.notifications_outlined,
        //         size: 30.w,
        //         color: appTextColor3,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Future<void> _showLocationPicker() async {
    final MapService mapService = MapService();
    List<String> places = [];
    List<MapPlacesResponse> locations = [];
    bool isSearchLoading = false;
    final TextEditingController searchController = TextEditingController();
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final isTablet = Breakpoints.isTabletDevice(screenSize);
    final tabletContentWidth = screenWidth * 0.88;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: isTablet
          ? BoxConstraints(
              minWidth: tabletContentWidth,
              maxWidth: tabletContentWidth,
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final viewInsets = MediaQuery.viewInsetsOf(context);
                final maxSheetHeight =
                    (MediaQuery.sizeOf(context).height - viewInsets.bottom)
                        .clamp(0.0, MediaQuery.sizeOf(context).height * 0.86)
                        .toDouble();
                final resultMaxHeight = (maxSheetHeight * 0.42)
                    .clamp(120.0, 280.0)
                    .toDouble();
                final content = ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxSheetHeight),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: viewInsets.bottom,
                      left: 20.w,
                      right: 20.w,
                      top: 20.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        AppText(
                          text: "Select Location",
                          size: 18,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                        SizedBox(height: 16.h),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _fetchLocation();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: appButtonColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.my_location,
                                  color: appButtonColor,
                                  size: 20.w,
                                ),
                                SizedBox(width: 10.w),
                                AppText(
                                  text: "Use current location",
                                  size: 14,
                                  fontWeight: FontWeight.w500,
                                  color: appButtonColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: "Search location...",
                            prefixIcon: Icon(
                              Icons.search,
                              color: appTextColor3,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          onChanged: (val) async {
                            if (val.length >= 2) {
                              setModalState(() => isSearchLoading = true);
                              final response = await mapService.listPlaces(val);
                              setModalState(() {
                                places = response
                                    .map((p) => p.mainText ?? '')
                                    .toList();
                                locations = response;
                                isSearchLoading = false;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 10.h),
                        if (isSearchLoading)
                          Padding(
                            padding: EdgeInsets.all(16.h),
                            child: CircularProgressIndicator(),
                          )
                        else
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: resultMaxHeight,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: places.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: Icon(
                                    Icons.location_on,
                                    color: appTextColor3,
                                  ),
                                  title: Text(places[index]),
                                  onTap: () async {
                                    final placeId =
                                        locations[index].placeId ?? '';
                                    try {
                                      final coords = await mapService.getPlace(
                                        placeId,
                                      );
                                      final lat = double.tryParse(
                                        coords.lat.toString(),
                                      );
                                      final lng = double.tryParse(
                                        coords.lng.toString(),
                                      );
                                      if (!mounted) return;
                                      setState(() {
                                        _currentCity = places[index];
                                        _currentLat = lat;
                                        _currentLng = lng;
                                      });
                                      await _saveCachedLocation(
                                        places[index],
                                        lat,
                                        lng,
                                      );
                                      _publishLocation(places[index], lat, lng);
                                    } catch (e) {
                                      if (!mounted) return;
                                      setState(
                                        () => _currentCity = places[index],
                                      );
                                      await _saveCachedLocation(
                                        places[index],
                                        null,
                                        null,
                                      );
                                      _publishLocation(
                                        places[index],
                                        null,
                                        null,
                                      );
                                    }
                                    if (!mounted || !context.mounted) return;
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                );

                return content;
              },
            );
          },
        );
      },
    );
  }
}
