import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fudikoclient/components/appsearchbar.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/features/map/providers/map_providers.dart';
import 'package:fudikoclient/features/map/services/map_controller_service.dart';
import 'package:fudikoclient/features/map/services/marker_bitmap_service.dart';
import 'package:fudikoclient/features/map/widgets/persistent_google_map.dart';
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
import 'dart:ui' show lerpDouble;
import 'dart:ui' as ui;

class Home extends ConsumerStatefulWidget {
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
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  late String _currentCity;
  double? _currentLat;
  double? _currentLng;
  bool _hasMapPermission = false;

Timer? _zoomDebounce;

  bool isClicked = false;
  bool isOpen = false;
  bool isBookingModalOpen = false;
  bool isLoading = false;
  String errorMessage = '';
  RestaurantService restaurantService = RestaurantService();
  List<RestaurantModel> restaurantsList = [];
  List<RestaurantModel> filteredList = [];
  int? selectedDiscountIndex;
  int? selectedTypeIndex;
  double selectedDistance = 0;
  DateTime? selectedDateTime;
  late final MapControllerService _mapControllerService;
  final MarkerBitmapService _markerBitmapService = const MarkerBitmapService();
  String _lastMarkerSignature = '';
  bool _isFilterLoading = false;

  double _mapExpandProgress = 0.0; // 0 = collapsed, 1 = fully expanded
    final GlobalKey _mapPreviewKey = GlobalKey(); // ← add here

  // Separate controller for the collapsed preview so it doesn't
  // conflict with the expanded map controller.
  late final MapControllerService _collapsedMapControllerService;

  @override
  void initState() {
    super.initState();
    _mapControllerService = MapControllerService();
    _collapsedMapControllerService = MapControllerService();
    _currentCity = widget.currentCity;
    _currentLat = widget.currentLat;
    _currentLng = widget.currentLng;
    // _checkLocationPermission();
_checkLocationPermission().then((_) => _buildUserLocationIcon()); // ← add this
    getAllRestaurtantList();

      // _fetchLocation();
  }

  @override
  void dispose() {
    _mapControllerService.dispose();
    _collapsedMapControllerService.dispose();
    _zoomDebounce?.cancel();
    super.dispose();
  }


Future<void> _buildUserLocationIcon() async {
  const double size = 120; // large canvas to fit the accuracy ring
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Accuracy ring (large semi-transparent circle)
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2,
    Paint()..color = const Color(0x22B97A3E), // very transparent orange
  );

  // Thin border ring
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 1,
    Paint()
      ..color = const Color(0x44B97A3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );

  // White ring around dot
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    10,
    Paint()..color = Colors.white,
  );

  // Orange dot center
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    7,
    Paint()..color = const Color(0xFFB97A3E),
  );

  final image = await recorder
      .endRecording()
      .toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final icon = BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    width: 120,
    height: 120,
  );

  ref.read(userLocationIconProvider.notifier).state = icon;
}

  Future<void> getAllRestaurtantList() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final RestaurantListResponse response = await restaurantService
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
      _buildCollapsedMarkers();
      await _refreshMapMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _checkLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (!mounted) return;

  setState(() {
    _hasMapPermission =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  });
}

  /// Builds simple default Google Maps pins for the collapsed preview.
  /// These are cheap: no async bitmap rendering needed.
  void _buildCollapsedMarkers() {
  if (!mounted) return;
  ref.read(collapsedMarkersProvider.notifier).state = const <Marker>{};
}
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
      _buildCollapsedMarkers();
      await _refreshMapMarkers();
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
    final List<RestaurantModel> result = distanceKm <= 0
        ? List.of(restaurants)
        : restaurants.where((r) {
            final double? d = r.distance;
            return d != null && d <= distanceKm;
          }).toList();

    result.sort((a, b) {
      final double aD = a.distance ?? double.infinity;
      final double bD = b.distance ?? double.infinity;
      return aD.compareTo(bD);
    });
    return result;
  }

  Future<bool> _ensureFilterLocation() async {
    if (_currentLat != null && _currentLng != null) return true;
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
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
      ref.read(userLocationProvider.notifier).state = LatLng(position.latitude, position.longitude); // ← here
      return true;
    } catch (_) {
      return false;
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
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });
      ref.read(userLocationProvider.notifier).state = LatLng(position.latitude, position.longitude); // ← here
      final List<Placemark> placemarks = await placemarkFromCoordinates(
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

//   Future<void> _expandMap() async {
//   if (ref.read(mapExpandedProvider)) return;

//   _mapControllerService.reset();

//   ref.read(mapExpandedProvider.notifier).state = true;

//   await _refreshMapMarkers();

//   // Small delay so map first opens at user location
//   await Future.delayed(const Duration(milliseconds: 800));

//   final restaurants = _mapRestaurants;

//   if (restaurants.isNotEmpty) {
//     await _mapControllerService.fitRestaurants(
//       restaurants.map((r) => r.position),
//     );
//   }
// }
Future<void> _expandMap() async {
  if (ref.read(mapExpandedProvider)) return;
  ref.read(mapExpandedProvider.notifier).state = true;
  await _refreshMapMarkers();

  if (!mounted) return;
  await Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => _ExpandedMapPage(
        initialCameraPosition: _initialCameraPosition,
        controllerService: _mapControllerService,
        hasMapPermission: _hasMapPermission,
        onClose: () => Navigator.pop(context),
        currentCity: _currentCity,
        currentLat: _currentLat,
        currentLng: _currentLng,
        selectedDateTime: selectedDateTime,
        selectedDiscountIndex: selectedDiscountIndex,
        selectedTypeIndex: selectedTypeIndex,
        selectedDistance: selectedDistance,
        onApplyFilters: applyFilters,
        onApplyDateTime: (dt) => setState(() => selectedDateTime = dt),
        onLocationChanged: (city, lat, lng) {
          setState(() {
            _currentCity = city;
            _currentLat = lat;
            _currentLng = lng;
          });
        },
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 1.0), // fade in after hero lands
          ),
          child: child,
        );
      },
    ),
  );

  _collapseMap();
}
Future<void> _refreshMapMarkersWithZoom(double zoom) async {
  if (!ref.read(mapExpandedProvider) || !mounted) return;

  final selectedRestaurant = ref.read(selectedRestaurantProvider);
  final double scale = ((zoom - 10) / 8).clamp(0.3, 1.4);
  final markers = <Marker>{};

  for (final restaurant in filteredList) {
    if (restaurant.lat.isEmpty || restaurant.lng.isEmpty) continue;
    if (restaurant.offers.isEmpty) continue;

    final bestOffer = restaurant.offers.reduce(
      (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
    );
    final position = LatLng(
      double.tryParse(restaurant.lat) ?? 0,
      double.tryParse(restaurant.lng) ?? 0,
    );
    final isSelected = selectedRestaurant?.uuid == restaurant.uuid;
    final isDimmed = selectedRestaurant != null && !isSelected;

    final icon = await _markerBitmapService.buildOfferMarker(
      context,
      label: '-${bestOffer.discountPercentage.toStringAsFixed(0)}%',
      isSelected: isSelected,
      isDimmed: isDimmed,
      scale: scale,
    );

    markers.add(
      Marker(
        markerId: MarkerId(restaurant.uuid),
        position: position,
        icon: icon,
        anchor: const Offset(.5, .94),
        zIndexInt: isSelected ? 2 : 1,
        onTap: () => _selectMapRestaurant(restaurant),
      ),
    );
  }

  if (!mounted) return;
  ref.read(mapMarkersProvider.notifier).state = markers;
}




void _collapseMap() {
  ref.read(selectedRestaurantProvider.notifier).state = null;
  ref.read(mapExpandedProvider.notifier).state = false;
  ref.read(mapMarkersProvider.notifier).state = const <Marker>{};
  _lastMarkerSignature = '';
}

  // List<map_feature.Restaurant> get _mapRestaurants {
  //   return filteredList
  //       .where((r) => r.lat.isNotEmpty && r.lng.isNotEmpty)
  //       .map(map_feature.Restaurant.fromLegacy)
  //       .toList(growable: false);
  // }

  Future<void> _refreshMapMarkers() async {
  if (!ref.read(mapExpandedProvider) || !mounted) return;

  final zoom = ref.read(mapZoomProvider);
  final double scale = ((zoom - 10) / 8).clamp(0.3, 1.4);
  final selectedRestaurant = ref.read(selectedRestaurantProvider);

  final signature = filteredList
      .where((r) => r.offers.isNotEmpty)
      .map((r) {
        final best = r.offers.reduce(
          (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
        );
        return '${r.uuid}:${best.discountPercentage}:${selectedRestaurant?.uuid}';
      })
      .join('|');

  if (signature == _lastMarkerSignature) return;
  _lastMarkerSignature = signature;

  final markers = <Marker>{};
  for (final restaurant in filteredList) {
    if (restaurant.lat.isEmpty || restaurant.lng.isEmpty) continue;
    if (restaurant.offers.isEmpty) continue;

    final bestOffer = restaurant.offers.reduce(
      (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
    );
    final position = LatLng(
      double.tryParse(restaurant.lat) ?? 0,
      double.tryParse(restaurant.lng) ?? 0,
    );
    final isSelected = selectedRestaurant?.uuid == restaurant.uuid;
    final isDimmed = selectedRestaurant != null && !isSelected;

    final icon = await _markerBitmapService.buildOfferMarker(
      context,
      label: '-${bestOffer.discountPercentage.toStringAsFixed(0)}%',
      isSelected: isSelected,
      isDimmed: isDimmed,
      scale: scale,
    );

    markers.add(
      Marker(
        markerId: MarkerId(restaurant.uuid),
        position: position,
        icon: icon,
        anchor: const Offset(.5, .94),
        zIndexInt: isSelected ? 2 : 1,
        onTap: () => _selectMapRestaurant(restaurant),
      ),
    );
  }

  if (!mounted) return;
  ref.read(mapMarkersProvider.notifier).state = markers;
}


Future<void> _selectMapRestaurant(RestaurantModel restaurant) async {
  ref.read(selectedRestaurantProvider.notifier).state = restaurant;
  _lastMarkerSignature = '';
  await _refreshMapMarkers();
  await _mapControllerService.focusRestaurant(
    LatLng(
      double.tryParse(restaurant.lat) ?? 0,
      double.tryParse(restaurant.lng) ?? 0,
    ),
  );
}
  @override
  Widget build(BuildContext context) {
     ref.listen(mapZoomProvider, (previous, next) {
    if (previous == next) return;
    _zoomDebounce?.cancel();
    _zoomDebounce = Timer(const Duration(milliseconds: 300), () {
      _lastMarkerSignature = '';
      _refreshMapMarkersWithZoom(next);
    });
  });
 final double filterHeaderHeight = 72.h;
  final bool isMapExpanded = ref.watch(mapExpandedProvider);
final RestaurantModel? selectedMapRestaurant = ref.watch(selectedRestaurantProvider);
  final collapsedMarkers = ref.watch(collapsedMarkersProvider);

    return Scaffold(
      backgroundColor: const Color(0xfffdf8f5),
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar stays fixed at top.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 25.h),
                child: AppSearchBar(
                  city: _currentCity,
                  onLocationTap: _showLocationPicker,
                ),
              ),

              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Discount cards
                    SliverToBoxAdapter(child: _discountBuilder()),

                    SliverToBoxAdapter(
                      child: _collapsedMapPreview(collapsedMarkers),
                    ),

                    // Filter row: sticky
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _FilterHeaderDelegate(
                        child: Container(
                          color: const Color(0xfffdf8f5),
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
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
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
                                  onTap: () {
                                    setState(() {
                                      filteredList = restaurantsList;
                                      selectedDiscountIndex = null;
                                      selectedTypeIndex = null;
                                      selectedDistance = 0;
                                    });
                                    _buildCollapsedMarkers();
                                  },
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
                                    deliveryServiceArea:
                                        restaurant.deliveryServiceArea,
                                    isFavourite: restaurant.isFavorite,
                                  ),
                                ),
                              );
                              if (result is bool) {
                                if (!mounted) return;
                                setState(() {
                                  restaurantsList = restaurantsList
                                      .map(
                                        (r) => r.uuid == restaurant.uuid
                                            ? r.copyWith(isFavorite: result)
                                            : r,
                                      )
                                      .toList();
                                  filteredList = filteredList
                                      .map(
                                        (r) => r.uuid == restaurant.uuid
                                            ? r.copyWith(isFavorite: result)
                                            : r,
                                      )
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
                              deliveryServiceArea:
                                  restaurant.deliveryServiceArea,
                              restaurantType: restaurant.restaurantType,
                              status: restaurant.status,
                              isFavourite: restaurant.isFavorite,
                              image: restaurant.image,
                              offers: restaurant.offers,
                              onRatingOnClick: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RatingPage(
                                    restaurantId: restaurant.uuid,
                                    restaurantName: restaurant.name,
                                  ),
                                ),
                              ),
                              onBoxClicked: (String? offerId) {
                                setState(
                                  () =>
                                      isBookingModalOpen = !isBookingModalOpen,
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
                                    builder: (_) => NumberOfPeopleModal(
                                      uuid: restaurant.uuid,
                                      offerId: offerId,
                                    ),
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

          // if (isMapExpanded) _expandedMapOverlay(),

          // if (isMapExpanded)
          //   Positioned(
          //     left: 16.w,
          //     top: MediaQuery.paddingOf(context).top + 16.h,
          //     child: Material(
          //       color: Colors.white,
          //       shape: const CircleBorder(),
          //       elevation: 8,
          //       shadowColor: const Color(0x26000000),
          //       child: IconButton(
          //         onPressed: _collapseMap,
          //         icon: const Icon(Icons.close_rounded),
          //       ),
          //     ),
          //   ),

          // if (isMapExpanded && selectedMapRestaurant != null)
          //   RestaurantBottomSheet(restaurant: selectedMapRestaurant),
        ],
      ),
    );
  }

  CameraPosition get _initialCameraPosition {
    return CameraPosition(
      target: LatLng(_currentLat ?? 10.8505, _currentLng ?? 76.2711),
      zoom: _currentLat == null ? 7.4 : 15.5,
    );
  }

  // Replace _collapsedMapPreview with this:
Widget _collapsedMapPreview(Set<Marker> collapsedMarkers) {
  return Padding(
    key: _mapPreviewKey,
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
    child: Hero(
      tag: 'map-expand',
      flightShuttleBuilder: (_, animation, __, fromContext, ___) {
        // During flight: animate the border radius from rounded → 0
        return AnimatedBuilder(
          animation: animation,
          builder: (_, __) {
            final radius = Tween<double>(begin: 20, end: 0)
                .evaluate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ));
            return Material(
              color: Colors.black,
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: Clip.antiAlias,
              child: Container(color: Colors.black87),
            );
          },
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: SizedBox(
          height: 90.h,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PersistentGoogleMap(
                key: const ValueKey('home-collapsed-google-map'),
                initialCameraPosition: _initialCameraPosition,
                controllerService: _collapsedMapControllerService,
                onMapTap: _expandMap,
                gesturesEnabled: false,
                overrideMarkers: collapsedMarkers,
                showMyLocation: _hasMapPermission,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(.40),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'View offers on map',
                        style: TextStyle(
                          color: const Color(0xFF172018),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _expandMap,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

 Widget _expandedMapOverlay() {
  // Grab the card's position on screen
  Rect cardRect = Rect.fromLTWH(
    20.w, 0, MediaQuery.sizeOf(context).width - 40.w, 90.h,
  );
  final RenderObject? ro = _mapPreviewKey.currentContext?.findRenderObject();
  if (ro is RenderBox && ro.hasSize) {
    final Offset topLeft = ro.localToGlobal(Offset.zero);
    cardRect = topLeft & ro.size;
  }

  final Size screen = MediaQuery.sizeOf(context);
  final Rect fullRect = Rect.fromLTWH(0, 0, screen.width, screen.height);

  return Positioned.fill(
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
      onEnd: () {
        if (mounted) setState(() => _mapExpandProgress = 1.0);
      },
      builder: (context, value, child) {
        // Sync progress for fading the collapsed preview
        if ((_mapExpandProgress - value).abs() > 0.01) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _mapExpandProgress = value);
          });
        }

        // Interpolate from card rect → full screen
        final Rect animRect = Rect.lerp(cardRect, fullRect, value)!;
        // Border radius 20 → 0
        final double radius = lerpDouble(20.r, 0, value)!;

        return Stack(
          children: [
            Positioned(
              left: animRect.left,
              top: animRect.top,
              width: animRect.width,
              height: animRect.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Opacity(
                  opacity: value.clamp(0.3, 1.0), // start slightly visible
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      child: PersistentGoogleMap(
        key: const ValueKey('home-expanded-google-map'),
        initialCameraPosition: _initialCameraPosition,
        controllerService: _mapControllerService,
        onMapTap: _expandMap,
        showMyLocation: _hasMapPermission,
      ),
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
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withOpacity(0.10),
                    offset: const Offset(0, 0),
                    blurRadius: 10,
                    spreadRadius: 2,
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
                      color: const Color(0xFF000000).withOpacity(0.10),
                      offset: const Offset(0, 0),
                      blurRadius: 10,
                      spreadRadius: 2,
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

  Widget _discountBuilder() {
    final colors = [
      {'color2': const Color(0xFF6CCB3F), 'color1': const Color(0XFF36651F)},
      {'color2': const Color(0xFF3FB2CB), 'color1': const Color(0xFF1F5965)},
      {'color2': const Color(0xFF9E3FCB), 'color1': const Color(0xFF4F1F65)},
      {'color2': const Color(0xFFCBAC3F), 'color1': const Color(0xFF65561F)},
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
                        isboxShadow: const [
                          BoxShadow(
                            color: Color(0x4D000000),
                            offset: Offset(0, 3),
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
                  if (isSearchLoading)
                    Padding(
                      padding: EdgeInsets.all(16.h),
                      child: const CircularProgressIndicator(),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                            final selectedPlace = places[index];
                            try {
                              final coords = await mapService.getPlace(placeId);
                              if (!mounted) return;
                              setState(() {
                                _currentCity = selectedPlace;
                                _currentLat = double.tryParse(
                                  coords.lat.toString(),
                                );
                                _currentLng = double.tryParse(
                                  coords.lng.toString(),
                                );
                              });
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _currentCity = selectedPlace);
                            }
                            if (!context.mounted) return;
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

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

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
// ─── Replace _ExpandedMapPage class ──────────────────────────────────────────
class _ExpandedMapPage extends ConsumerStatefulWidget {
  final CameraPosition initialCameraPosition;
  final MapControllerService controllerService;
  final bool hasMapPermission;
  final VoidCallback onClose;
  final String currentCity;
  final double? currentLat;
  final double? currentLng;
  final DateTime? selectedDateTime;
  final int? selectedDiscountIndex;
  final int? selectedTypeIndex;
  final double selectedDistance;
  final Future<void> Function(int?, int?, double) onApplyFilters;
  final void Function(DateTime) onApplyDateTime;
  // Callback so Home stays in sync when user picks a new location on the map
  final void Function(String city, double? lat, double? lng) onLocationChanged;

  const _ExpandedMapPage({
    required this.initialCameraPosition,
    required this.controllerService,
    required this.hasMapPermission,
    required this.onClose,
    required this.currentCity,
    required this.currentLat,
    required this.currentLng,
    required this.selectedDateTime,
    required this.selectedDiscountIndex,
    required this.selectedTypeIndex,
    required this.selectedDistance,
    required this.onApplyFilters,
    required this.onApplyDateTime,
    required this.onLocationChanged,
  });

  @override
  ConsumerState<_ExpandedMapPage> createState() => _ExpandedMapPageState();
}

class _ExpandedMapPageState extends ConsumerState<_ExpandedMapPage> {
  late String _city;
  late double? _lat;
  late double? _lng;

  @override
  void initState() {
    super.initState();
    _city = widget.currentCity;
    _lat  = widget.currentLat;
    _lng  = widget.currentLng;
  }

  // Same location-picker logic as Home, but runs inside the map page
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
                  // Use current GPS location
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _fetchAndApplyCurrentLocation();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: appButtonColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.my_location, color: appButtonColor, size: 20.w),
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
                          places = response.map((p) => p.mainText ?? '').toList();
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
                      child: const CircularProgressIndicator(),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(Icons.location_on, color: appTextColor3),
                          title: Text(places[index]),
                          onTap: () async {
                            final placeId = locations[index].placeId ?? '';
                            final selectedPlace = places[index];
                            try {
                              final coords = await mapService.getPlace(placeId);
                              final lat = double.tryParse(coords.lat.toString());
                              final lng = double.tryParse(coords.lng.toString());
                              if (!mounted) return;
                              // Update local state (search bar city label)
                              setState(() {
                                _city = selectedPlace;
                                _lat  = lat;
                                _lng  = lng;
                              });
                              // Move the map camera to the new location
                              if (lat != null && lng != null) {
                                widget.controllerService.animateTo(
                                  LatLng(lat, lng),
                                  zoom: 14,
                                );
                              }
                              // Keep Home in sync
                              widget.onLocationChanged(selectedPlace, lat, lng);
                            } catch (_) {
                              if (!mounted) return;
                              setState(() => _city = selectedPlace);
                              widget.onLocationChanged(selectedPlace, null, null);
                            }
                            if (!context.mounted) return;
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

  Future<void> _fetchAndApplyCurrentLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );
      final city = placemarks.isNotEmpty
          ? (placemarks.first.locality ??
             placemarks.first.subLocality ??
             placemarks.first.name ?? "Unknown")
          : "Unknown";

      if (!mounted) return;
      setState(() {
        _city = city;
        _lat  = position.latitude;
        _lng  = position.longitude;
      });
      ref.read(userLocationProvider.notifier).state = LatLng(position.latitude, position.longitude); // ← here
      widget.controllerService.animateTo(
        LatLng(position.latitude, position.longitude),
        zoom: 15.5,
      );
      widget.onLocationChanged(city, position.latitude, position.longitude);
    } catch (_) {
      if (!mounted) return;
      setState(() => _city = "Unknown");
    }
  }

  @override
  Widget build(BuildContext context) { // ← WidgetRef via ConsumerState
    final selectedMapRestaurant = ref.watch(selectedRestaurantProvider);
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'map-expand',
            child: PersistentGoogleMap(
              key: const ValueKey('home-expanded-google-map'),
              initialCameraPosition: widget.initialCameraPosition,
              controllerService: widget.controllerService,
              onMapTap: () {},
              gesturesEnabled: true,
              showMyLocation: widget.hasMapPermission,
            ),
          ),

          // Search bar — uses local _city so it updates instantly
          Positioned(
                top: topPad + 10.h,
            left: 16.w,
            right: 16.w,
            child: AppSearchBar(
              city: _city,
              onLocationTap: _showLocationPicker, // ← opens picker in-map
            ),
          ),

          // Filter row
          Positioned(
            top: topPad + 10.h + 60.h + 10.h,
              left: 0,
              right: 0,
            child: Center(
              child: _MapFilterRow(
                selectedDateTime: widget.selectedDateTime,
                selectedDiscountIndex: widget.selectedDiscountIndex,
                selectedTypeIndex: widget.selectedTypeIndex,
                selectedDistance: widget.selectedDistance,
                onApplyFilters: widget.onApplyFilters,
                onApplyDateTime: widget.onApplyDateTime,
              ),
            ),
          ),

         if (selectedMapRestaurant != null)
  Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: RestaurantCard(
          uuid: selectedMapRestaurant.uuid,
          name: selectedMapRestaurant.name,
          type: selectedMapRestaurant.type,
          address: selectedMapRestaurant.address,
          phone: selectedMapRestaurant.phone,
          lat: selectedMapRestaurant.lat,
          lng: selectedMapRestaurant.lng,
          description: selectedMapRestaurant.description,
          availableDishes: selectedMapRestaurant.availableDishes,
          takeAwayService: selectedMapRestaurant.takeAwayService,
          deliveryService: selectedMapRestaurant.deliveryService,
          deliveryServiceArea: selectedMapRestaurant.deliveryServiceArea,
          restaurantType: selectedMapRestaurant.restaurantType,
          status: selectedMapRestaurant.status,
          isFavourite: selectedMapRestaurant.isFavorite,
          image: selectedMapRestaurant.image,
          offers: selectedMapRestaurant.offers,
          isFavoriteBox: false,
          onRatingOnClick: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RatingPage(
                restaurantId: selectedMapRestaurant.uuid,
                restaurantName: selectedMapRestaurant.name,
              ),
            ),
          ),
          onBoxClicked: (String? offerId) {
            showModalBottomSheet(
              backgroundColor: Colors.white,
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              builder: (_) => NumberOfPeopleModal(
                uuid: selectedMapRestaurant.uuid,
                offerId: offerId,
              ),
            );
          },
        ),
      ),
    ),
  ),
        ],
      ),
    );
  }
}




// ─── Filter row widget ────────────────────────────────────────────────────────
class _MapFilterRow extends StatelessWidget {
  final DateTime? selectedDateTime;
  final int? selectedDiscountIndex;
  final int? selectedTypeIndex;
  final double selectedDistance;
  final Future<void> Function(int?, int?, double) onApplyFilters;
  final void Function(DateTime) onApplyDateTime;

  const _MapFilterRow({
    required this.selectedDateTime,
    required this.selectedDiscountIndex,
    required this.selectedTypeIndex,
    required this.selectedDistance,
    required this.onApplyFilters,
    required this.onApplyDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      
      
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
              builder: (_) => FilterBottomModal(
                onApply: onApplyFilters,
                initialDiscountIndex: selectedDiscountIndex,
                initialTypeIndex: selectedTypeIndex,
                initialDistance: selectedDistance,
              ),
            );
          },
          child: _filterChip(
            context,
            icon: Image.asset(filterIcon, width: 14.w, height: 14.w, color: Colors.black87),
            label: 'Filter',
          ),
        ),

        SizedBox(width: 8.w),

        // Date / time button
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              backgroundColor: Colors.white,
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              builder: (_) => TimeBottomModal(
                onApply: onApplyDateTime,
              ),
            );
          },
          child: _filterChip(
            context,
            icon: Image.asset(filtercalenderIcon, width: 14.w, height: 14.w, color: Colors.black87),
            label: selectedDateTime != null
                ? "${selectedDateTime!.day}/${selectedDateTime!.month}"
                  " at ${selectedDateTime!.hour}:"
                  "${selectedDateTime!.minute.toString().padLeft(2, '0')}"
                : 'Today at 12:00PM',
          ),
        ),
      ],
    );
  }

  Widget _filterChip(BuildContext context, {required Widget icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.10),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.keyboard_arrow_down, size: 15.w, color: Colors.black54),
        ],
      ),
    );
  }
}