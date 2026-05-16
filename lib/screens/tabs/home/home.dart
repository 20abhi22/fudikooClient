import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appsearchbar.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant_filter_model.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/screens/tabs/components/restaurantCard.dart';
import 'package:fudikoclient/screens/tabs/home/addnumberofpeople.dart';
import 'package:fudikoclient/screens/tabs/home/filterbottommodal.dart';
import 'package:fudikoclient/screens/tabs/home/rating.dart';
import 'package:fudikoclient/screens/tabs/home/timebottommodal.dart';
import 'package:fudikoclient/screens/tabs/profile/restaurantProfile.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/service/restaurant/restaurant-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Home extends StatefulWidget {
  final String currentCity;
  final double? currentLat;
  final double? currentLng;

  const Home({
    super.key,
    this.currentCity = "Locating...",
    this.currentLat,
    this.currentLng,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // bool isClicked = false;
  // bool isOpen = false;
  // bool isBookingModalOpen = false;
  // RestaurantService restaurantService = RestaurantService();
  // late List<RestaurantModel> restaurantsList = [];

  // //for filtering
  // int? selectedDiscountIndex;
  // int? selectedTypeIndex;
  // double selectedDistance = 0;
  // List<RestaurantModel> filteredList = [];

  late String _currentCity;
  double? _currentLat;
  double? _currentLng;

  bool isClicked = false;
  bool isOpen = false;
  bool isBookingModalOpen = false;
  bool isLoading = false; // ← move here
  String errorMessage = ''; // ← move here
  RestaurantService restaurantService = RestaurantService();
  List<RestaurantModel> restaurantsList = [];
  List<RestaurantModel> filteredList = [];
  int? selectedDiscountIndex;
  int? selectedTypeIndex;
  double selectedDistance = 0;
  DateTime? selectedDateTime;
  bool _isFilterLoading = false; // ← add with other state vars

  @override
  void initState() {
    super.initState();
    _currentCity = widget.currentCity;
    _currentLat = widget.currentLat;
    _currentLng = widget.currentLng;

    getAllRestaurtantList();
  }

  // Future<void> getAllRestaurtantList() async {
  //   print(await getToken());
  //   RestaurantListResponse response = await restaurantService
  //       .getRestaurantList();
  //   setState(() {
  //     restaurantsList = response.restaurant;
  //   });
  //   print(restaurantsList);
  // }

  //for applying filter
  Future<void> applyFilters(
    int? discountIndex,
    int? typeIndex,
    double distance,
  ) async {
    setState(() {
      selectedDiscountIndex = discountIndex;
      selectedTypeIndex = typeIndex;
      selectedDistance = distance;
      _isFilterLoading = true;
      errorMessage = '';
    });

    final types = ["Restaurant", "Cafe", "Cool Bar", "Bar", "Buffet"];
    final bool hasValidTypeIndex =
        typeIndex != null && typeIndex >= 0 && typeIndex < types.length;
    final String? selectedType = hasValidTypeIndex ? types[typeIndex] : null;

    final bool hasLocation = await _ensureFilterLocation();
    if (!hasLocation || _currentLat == null || _currentLng == null) {
      if (!mounted) return;
      setState(() {
        _isFilterLoading = false;
        errorMessage = 'Location is required to apply backend filters';
        filteredList = [];
      });
      return;
    }

    final request = RestaurantFilterRequest(
      lat: _currentLat!,
      lng: _currentLng!,
      searchRadiusKm: distance,
      type: selectedType,
    );

    try {
      final response = await restaurantService.filterRestaurants(request);
      if (!mounted) return;
      setState(() {
        filteredList = _applyDistanceFilter(response.restaurant, distance);
        _isFilterLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFilterLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  List<RestaurantModel> _applyDistanceFilter(
    List<RestaurantModel> restaurants,
    double distanceKm,
  ) {
    final List<RestaurantModel> filteredRestaurants = distanceKm <= 0
        ? List.of(restaurants)
        : restaurants.where((restaurant) {
            final double? restaurantDistance = restaurant.distance;
            return restaurantDistance != null &&
                restaurantDistance <= distanceKm;
          }).toList();

    filteredRestaurants.sort((a, b) {
      final double aDistance = a.distance ?? double.infinity;
      final double bDistance = b.distance ?? double.infinity;
      return aDistance.compareTo(bDistance);
    });

    return filteredRestaurants;
  }

  Future<bool> _ensureFilterLocation() async {
    if (_currentLat != null && _currentLng != null) {
      return true;
    }

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return false;
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });

      return true;
    } catch (_) {
      return false;
    }
  }
  // Future<void> getAllRestaurtantList() async {
  //   bool isLoading;
  //   setState(() => isLoading = true);
  //   try {
  //     RestaurantListResponse response = await restaurantService
  //         .getRestaurantList();
  //     setState(() {
  //       restaurantsList = response.restaurant;
  //       filteredList = response.restaurant;
  //       isLoading = false;
  //     });
  //     print('Restaurants count: ${restaurantsList.length}');
  //     print(
  //       'First restaurant: ${restaurantsList.isNotEmpty ? restaurantsList[0].name : "empty list"}',
  //     );
  //   } catch (e) {
  //     setState(() {
  //       isLoading = false;
  //       var errorMessage = e.toString();
  //     });
  //     print('Error fetching restaurants: $e');
  //   }
  // }

  Future<void> getAllRestaurtantList() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      RestaurantListResponse response = await restaurantService
          .getRestaurantList();
      if (!mounted) return;
      setState(() {
        restaurantsList = response.restaurant;
        filteredList = _applyDistanceFilter(
          response.restaurant,
          selectedDistance,
        );
        isLoading = false;
        errorMessage = '';
      });
      print('Restaurants count: ${restaurantsList.length}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      print('Error fetching restaurants: $e');
    }
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
        setState(() {
          _currentCity = p.locality ?? p.subLocality ?? p.name ?? "Unknown";
        });
      }
    } catch (e) {
      setState(() => _currentCity = "Unknown");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double filterHeaderHeight = 72.h;

    return Scaffold(
      backgroundColor: const Color(0xfffdf8f5),
      body: Column(
        children: [
          // ── Search bar stays fixed at the very top ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 25.h),
            child: AppSearchBar(
              city: _currentCity,
              onLocationTap: _showLocationPicker,
            ),
          ),

          // ── Everything below scrolls; filter row sticks ──
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Discount cards — scrolls away
                SliverToBoxAdapter(child: _discountBuilder()),

                // Map — scrolls away
                SliverToBoxAdapter(child: _mapBuilder()),

                // Filter row — STICKY
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterHeaderDelegate(
                    child: Container(
                      color: const Color(0xfffdf8f5), // match scaffold bg
                      child: SizedBox(
                        height: filterHeaderHeight,
                        child: _dropDownBuilder(),
                      ),
                    ),
                    height: filterHeaderHeight,
                  ),
                ),

                // Restaurant list
                if (isLoading || _isFilterLoading)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220.h,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (errorMessage.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220.h,
                      child: Center(
                        child: AppText(
                          text: 'Error: $errorMessage',
                          size: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  )
                else if (filteredList.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 260.h,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10.h),
                            AppText(
                              text: "No restaurants found",
                              size: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: () => setState(() {
                                filteredList = restaurantsList;
                                selectedDiscountIndex = null;
                                selectedTypeIndex = null;
                                selectedDistance = 0;
                              }),
                              child: AppText(
                                text: "Clear filters",
                                size: 14,
                                fontWeight: FontWeight.w500,
                                color: appTextColor3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final restaurant = filteredList[index];
                      return InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantProfile(
                                uuid: restaurant.uuid,
                                deliveryServiceArea: restaurant.deliveryServiceArea,
                                 isFavourite: restaurant.isFavorite, 
                              ),
                            ),
                          );
                          if (result is bool) {
                            if (!mounted) return;
                            setState(() {
                              restaurantsList = restaurantsList
                                  .map((r) => r.uuid == restaurant.uuid ? r.copyWith(isFavorite: result) : r)
                                  .toList();
                              filteredList = filteredList
                                  .map((r) => r.uuid == restaurant.uuid ? r.copyWith(isFavorite: result) : r)
                                  .toList();
                            });
                          }
                        },
                        child: RestaurantCard(
                          uuid: restaurant.uuid,
                          name: restaurant.name,
                          type: restaurant.type,
                          address: restaurant.address,
                          phone: restaurant.phone,
                          lat: restaurant.lat,
                          lng: restaurant.lng,
                          description: restaurant.description,
                          availableDishes: restaurant.availableDishes,
                          takeAwayService: restaurant.takeAwayService,
                          deliveryService: restaurant.deliveryService,
                          deliveryServiceArea: restaurant.deliveryServiceArea,
                          restaurantType: restaurant.restaurantType,
                          status: restaurant.status,
                          isFavourite: restaurant.isFavorite,
                          image: restaurant.image, 
                          offers: restaurant.offers,
                          onRatingOnClick: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RatingPage(
  restaurantId: restaurant.uuid,
  restaurantName: restaurant.name,
)),
                          ),
                          onBoxClicked: (String? offerId) {
                            setState(
                              () => isBookingModalOpen = !isBookingModalOpen,
                            );
                            if (isBookingModalOpen) {
                              showModalBottomSheet(
                                backgroundColor: Colors.white,
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(25),
                                  ),
                                ),
                                builder: (_) =>
                                    NumberOfPeopleModal(uuid: restaurant.uuid, offerId: offerId),
                              );
                            }
                          },
                        ),
                      );
                    }, childCount: filteredList.length),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropDownBuilder() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Filter button
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                backgroundColor: Colors.white,
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (context) => FilterBottomModal(
                  onApply: applyFilters,
                  initialDiscountIndex: selectedDiscountIndex,
                  initialTypeIndex: selectedTypeIndex,
                  initialDistance: selectedDistance,
                ),
              );
            },
            child: Container(
              // height: 29.h,
              // width: 92.w,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withOpacity(0.10), // 10%
                    offset: const Offset(0, 0), // X:0 Y:0
                    blurRadius: 10, // Blur:10
                    spreadRadius: 2, // Spread:2
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    filterIcon,
                    width: 15.w,
                    height: 15.w,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Filter",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16.w,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 10.w),

          // Date/Time button
          Flexible(
            fit: FlexFit.loose,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  backgroundColor: Colors.white,
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  builder: (context) => TimeBottomModal(
                    onApply: (dateTime) {
                      setState(() => selectedDateTime = dateTime);
                    },
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withOpacity(0.10), // 10%
                      offset: const Offset(0, 0), // X:0 Y:0
                      blurRadius: 10, // Blur:10
                      spreadRadius: 2, // Spread:2
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          filtercalenderIcon,
                          width: 15.w,
                          height: 15.w,
                          color: Colors.black87,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            selectedDateTime != null
                                ? "${selectedDateTime!.day}/${selectedDateTime!.month}"
                                      " at ${selectedDateTime!.hour}:"
                                      "${selectedDateTime!.minute.toString().padLeft(2, '0')}"
                                : "Today at 12:00PM",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87.withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16.w,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapBuilder() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Container(
        width: double.infinity,
        height: 90.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.asset('assets/images/map.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _discountBuilder() {
    final colors = [
      {'color2': Color(0xFF6CCB3F), 'color1': Color(0XFF36651F)},
      {'color2': Color(0xFF3FB2CB), 'color1': Color(0xFF1F5965)},
      {'color2': Color(0xFF9E3FCB), 'color1': Color(0xFF4F1F65)},
      {'color2': Color(0xFFCBAC3F), 'color1': Color(0xFF65561F)},
    ];
    final discountDetails = [
      {
        'offer_range': "10%-20%",
        'discount_tag': "assets/images/discount_tag1.png",
      },
      {
        'offer_range': "20%-30%",
        'discount_tag': "assets/images/discount_tag2.png",
      },
      {
        'offer_range': "30%-40%",
        'discount_tag': "assets/images/discount_tag3.png",
      },
      {
        'offer_range': "40%-50%",
        'discount_tag': "assets/images/discount_tag4.png",
      },
    ];

    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        itemCount: colors.length,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final color1 = colors[index]['color1']!;
          final color2 = colors[index]['color2']!;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Container(
              height: 180.h,
              width: 120.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [color1, color2],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/boxbg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),
                      AppText(
                        text: discountDetails[index]['offer_range']!,
                        size: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        isboxShadow: [
                          BoxShadow(
                            color: const Color(0x4D000000),
                            offset: const Offset(0, 3),
                            blurRadius: 5,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        text: "Discount",
                        size: 18.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      SizedBox(height: 5.h),

                      Image.asset(
                        discountDetails[index]['discount_tag']!,
                        height: 70.h,
                        width: 70.w,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
                              setState(() {
                                _currentCity = places[index];
                                _currentLat = double.tryParse(
                                  coords.lat.toString(),
                                );
                                _currentLng = double.tryParse(
                                  coords.lng.toString(),
                                );
                              });
                            } catch (e) {
                              setState(() => _currentCity = places[index]);
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

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _FilterHeaderDelegate({required this.child, required this.height});

  // ❌ REMOVE THIS LINE — it's overriding your dynamic height
  // static const double _height = 72;

  @override
  double get minExtent => height; // ← uses instance field now

  @override
  double get maxExtent => height; // ← uses instance field now

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_FilterHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
