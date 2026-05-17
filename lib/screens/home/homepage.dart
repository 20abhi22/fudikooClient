import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/screens/catering_tabs/main_catering_nav.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fudikoclient/screens/aboutapp/about.dart';
import 'package:fudikoclient/screens/auth/changepassword.dart';
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
import 'package:fudikoclient/screens/notification/notification_setting.dart';
import 'package:fudikoclient/screens/reward/reward.dart';
import 'package:fudikoclient/screens/tabs/main_restaurant_nav.dart';
import 'package:fudikoclient/screens/takeaway_tabs/takeaway.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool isDrawerOpen = false;
  String _currentCity = "Locating...";
  double? _currentLat;
  double? _currentLng;
  late SharedPreferences _prefs;
  
  // Cache keys
  static const String _cacheKeyCity = 'cached_city';
  static const String _cacheKeyLat = 'cached_lat';
  static const String _cacheKeyLng = 'cached_lng';
  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedLocation();
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
    } else {
      // No cache, fetch fresh location
      await _fetchLocation();
    }
  }

  Future<void> _saveCachedLocation(String city, double? lat, double? lng) async {
    await _prefs.setString(_cacheKeyCity, city);
    if (lat != null) await _prefs.setDouble(_cacheKeyLat, lat);
    if (lng != null) await _prefs.setDouble(_cacheKeyLng, lng);
  }

  Future<void> _fetchLocation() async {
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
        // Cache the location
        await _saveCachedLocation(city, _currentLat, _currentLng);
      }
    } catch (e) {
      setState(() => _currentCity = "Unknown");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double horizontalPadding = screenWidth * 0.075; // ~30 on 400px screen
    final double sliderWidth = screenWidth * 0.5;

    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: screenHeight * 0.025,
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
                            return SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: horizontalPadding,
                                  right: horizontalPadding,
                                  top: screenHeight * 0.03,
                                ),
                                child: Column(
                                  children: [
                                    if (index == 0) ...[
                                      // GestureDetector(
                                      //   onTap: () => slideRightWidget(
                                      //     newPage: MainRestaurantNavPage(),
                                      //     context: context,
                                      //   ),
                                      //   child: RestaurantBox(),
                                      // ),
                                      InkWell(
                                        onTap: () => slideRightWidget(
                                          newPage: MainRestaurantNavPage(
                                            city: _currentCity,
                                            lat: _currentLat,
                                            lng: _currentLng,
                                          ),
                                          context: context,
                                        ),
                                        child: RestaurantBox(),
                                      ),
                                      SizedBox(height: screenHeight * 0.012),
                                      InkWell(
                                        onTap: () => slideRightWidget(
                                          newPage: MainBanquetNavPage(
                                            city: _currentCity,
                                            lat: _currentLat,
                                            lng: _currentLng,
                                          ),
                                          context: context,
                                        ),
                                        child: BanquetBox(),
                                      ),
                                      SizedBox(height: screenHeight * 0.012),
                                      // CateringBox(),
                                      InkWell(
                                        onTap: () => slideRightWidget(
                                          newPage: MainCateringNavPage(
                                            city: _currentCity,
                                            lat: _currentLat,
                                            lng: _currentLng,
                                          ),
                                          context: context,
                                        ),
                                        child: CateringBox(),
                                      ),
                                      SizedBox(height: screenHeight * 0.012),
                                      InkWell(
                                        onTap: () => slideRightWidget(
                                          // newPage: MainCateringNavPage(
                                          //   city: _currentCity,
                                          //   lat: _currentLat,
                                          //   lng: _currentLng,
                                          // ),
                                          newPage: TakeAway(),
                                          context: context,
                                        ),
                                        child: TakeAwayBox(),
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                    ] else ...[
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: 5,
                                        itemBuilder: (context, i) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  AppText(
                                                    text: "10 minutes ago",
                                                    size: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: appTextColor2,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.012,
                                              ),
                                              Image.asset(
                                                'assets/images/offerimage.png',
                                                height: screenHeight * 0.35,
                                                width: double.infinity,
                                                fit: BoxFit.contain,
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.012,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // WORKING SLIDER
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
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
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),

            // Drawer
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: 0,
              bottom: 0,
              left: isDrawerOpen ? 0 : -screenWidth * 0.75,
              child: Container(
                width: screenWidth * 0.6,
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
                      horizontal: screenWidth * 0.05,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: screenHeight * 0.12),
                          Align(
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/images/logofudikoo.png',
                              width: screenWidth * 0.35,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.06),
                          AppText(
                            text: "Settings",
                            size: 15,
                            fontWeight: FontWeight.w600,
                            color: appTextColor2,
                          ),
                          SizedBox(height: screenHeight * 0.012),
                          Divider(thickness: 1, color: Colors.grey, height: 1),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "Change Password",
                                  lockIcon,
                                  ChangePassword(),
                                  21.w,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "Notifications",
                                  bellIcon,
                                  NotificationScreen(),
                                  21.w,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "Languages",
                                  languageIcon,
                                  Languages(),
                                  21.w,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "Rewards",
                                  rewardsIcon,
                                  Reward(),
                                  21.w,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "Invite a Friend",
                                  inviteIcon,
                                  EarnPoints(),
                                  21.w,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.06),
                          AppText(
                            text: "Information",
                            size: 15,
                            fontWeight: FontWeight.w600,
                            color: appTextColor2,
                          ),
                          SizedBox(height: screenHeight * 0.012),
                          Divider(thickness: 1, color: Colors.grey, height: 1),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "About the App",
                                  infoIcon,
                                  AboutPage(),
                                  22.w,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "Badge Earnings",
                                  helpIcon,
                                  BadgeInfo(),
                                  26.w,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "Complaints",
                                  complainIcon,
                                  ComplaintPage(),
                                  26.w,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "Rate the App",
                                  rateAppIcon,
                                  FeedBack(),
                                  21.w,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "Support",
                                  customerServiceIcon,
                                  ContactPage(),
                                  21.w,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.06),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                            ),
                            child: Column(
                              children: [
                                Divider(
                                  thickness: 1,
                                  color: Colors.red,
                                  height: 1,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                _drawerItem(
                                  "Log Out",
                                  logoutIcon,
                                  Login(),
                                  20.w,
                                  Colors.red,
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Divider(
                                  thickness: 1,
                                  color: Colors.red,
                                  height: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
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
    );
  }

  Widget _drawerItem(
    String text,
    dynamic icon, // can be String (image path) or IconData
    Widget? routeWidget, [
    double? size,
    Color? color,
  ]) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isDrawerOpen = false;
        });

        Future.delayed(Duration(milliseconds: 100), () {
          if (routeWidget != null) {
            if (routeWidget is Login) {
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
              ? Image.asset(icon, width: size ?? 20.w, height: size ?? 20.w)
              : Icon(icon, size: size ?? 20.w, color: color ?? appTextColor2),
          SizedBox(width: 10.w),
          AppText(
            text: text,
            size: 13.sp,
            fontWeight: FontWeight.w500,
            color: color ?? appTextColor2,
          ),
        ],
      ),
    );
  }



  Widget _navBar() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => isDrawerOpen = !isDrawerOpen),
          child: Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Icon(Icons.menu, size: 30.w, color: menuIconColor),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: _showLocationPicker, // ← tap to change location
            child: Container(
              width: 180.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
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
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Column(
                  children: [
                    AppText(
                      text: "Near You",
                      size: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: menuIconColor.withOpacity(.8),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            mappingIcon,
                            width: 14.sp,
                            height: 14.sp,
                            color: menuIconColor.withOpacity(.8),
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: AppText(
                              text: _currentCity,
                              size: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: menuIconColor.withOpacity(.8),
                            ),
                          ),
                          // Icon(
                          //   Icons.keyboard_arrow_down,
                          //   size: 15.w,
                          //   color: appTextColor3,
                          // ),
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 20.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
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

                  // Use current location button
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
                        color: appButtonColor.withOpacity(0.1),
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

                  // Search field
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search location...",
                      prefixIcon: Icon(Icons.search, color: appTextColor3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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

                  // Results list
                  if (isSearchLoading)
                    Padding(
                      padding: EdgeInsets.all(16.h),
                      child: CircularProgressIndicator(),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: appTextColor3,
                          ),
                          title: Text(places[index]),
                          onTap: () async {
                            final placeId = locations[index].placeId ?? '';
                            try {
                              final coords = await mapService.getPlace(placeId);
                              final lat = double.tryParse(coords.lat.toString());
                              final lng = double.tryParse(coords.lng.toString());
                              setState(() {
                                _currentCity = places[index];
                                _currentLat = lat;
                                _currentLng = lng;
                              });
                              // Cache the selected location
                              await _saveCachedLocation(places[index], lat, lng);
                            } catch (e) {
                              setState(() => _currentCity = places[index]);
                              // Cache even if coords not found
                              await _saveCachedLocation(places[index], null, null);
                            }
                            if (!mounted) return;
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

