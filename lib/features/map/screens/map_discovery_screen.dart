import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/screens/tabs/components/restaurantCard.dart';
import 'package:fudikoclient/screens/tabs/home/addnumberofpeople.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fudikoclient/features/map/models/marker_spec.dart';
import 'package:fudikoclient/features/map/providers/map_providers.dart';
import 'package:fudikoclient/features/map/services/map_controller_service.dart';
import 'package:fudikoclient/features/map/services/marker_bitmap_service.dart';
import 'package:fudikoclient/features/map/widgets/map_search_bar.dart';
import 'package:fudikoclient/features/map/widgets/persistent_google_map.dart';

class MapDiscoveryScreen extends ConsumerStatefulWidget {
  const MapDiscoveryScreen({
    super.key,
    required this.currentCity,
    this.currentLat,
    this.currentLng,
  });

  final String currentCity;
  final double? currentLat;
  final double? currentLng;

  @override
  ConsumerState<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends ConsumerState<MapDiscoveryScreen> {
  late final MapControllerService _controllerService;
  final MarkerBitmapService _markerBitmapService = const MarkerBitmapService();
  var _lastMarkerSignature = '';
  // map_providers.dart
// final selectedRestaurantProvider = StateProvider<RestaurantModel?>((ref) => null);

  CameraPosition get _initialCameraPosition {
    return CameraPosition(
      target: LatLng(
        widget.currentLat ?? 10.8505,
        widget.currentLng ?? 76.2711,
      ),
      zoom: widget.currentLat == null ? 7.4 : 14.2,
    );
  }

  @override
  void initState() {
    super.initState();
    _controllerService = MapControllerService();
  }

  @override
  void dispose() {
    unawaited(_controllerService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<MarkerSpec>>(markerSpecsProvider, (_, specs) {
      unawaited(_refreshMarkers(specs));
    });

    ref.listen<AsyncValue<List<RestaurantModel>>>(nearbyRestaurantsProvider, (
      previous,
      next,
    ) {
      next.whenData((restaurants) {
        if (restaurants.isNotEmpty && previous?.valueOrNull == null) {
          unawaited(
            _controllerService.fitRestaurants(
             restaurants.map((r) => LatLng(double.tryParse(r.lat) ?? 0, double.tryParse(r.lng) ?? 0)),
            ),
          );
        }
      });
    });

    final isExpanded = ref.watch(mapExpandedProvider);
    final selectedRestaurant = ref.watch(selectedRestaurantProvider);
    final restaurants = ref.watch(nearbyRestaurantsProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final collapsedTop = 108.h;
    final collapsedHeight = 172.h;
    final collapsedRadius = 24.r;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      body: Stack(
        children: [
          // Keep one GoogleMap alive and animate only its Stack geometry.
          // The native map view is expensive to recreate during this transition.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            top: isExpanded ? 0 : collapsedTop,
            left: isExpanded ? 0 : 18.w,
            right: isExpanded ? 0 : 18.w,
            height: isExpanded ? screenHeight : collapsedHeight,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: isExpanded ? 0 : collapsedRadius),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, radius, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _expandMap,
                child: PersistentGoogleMap(
                  key: const ValueKey('persistent-google-map'),
                  initialCameraPosition: _initialCameraPosition,
                  controllerService: _controllerService,
                  onMapTap: _expandMap,
                  gesturesEnabled: isExpanded,
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            top: isExpanded ? 0 : collapsedTop,
            left: isExpanded ? 0 : 18.w,
            right: isExpanded ? 0 : 18.w,
            height: isExpanded ? 0 : collapsedHeight,
            child: IgnorePointer(
              ignoring: false,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _expandMap,
                child: AnimatedOpacity(
                  opacity: isExpanded ? 0 : 1,
                  duration: const Duration(milliseconds: 240),
                  child: Container(
                    alignment: Alignment.bottomLeft,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(.42),
                        ],
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'View offers on map',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 430),
            curve: Curves.easeOutCubic,
            top: isExpanded
                ? screenHeight
                : collapsedTop + collapsedHeight + 18.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: isExpanded,
              child: AnimatedOpacity(
                opacity: isExpanded ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: restaurants.when(
                  data: _RestaurantHomeList.new,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorState(message: error.toString()),
                ),
              ),
            ),
          ),
          MapSearchBar(
            city: widget.currentCity,
            isExpanded: isExpanded,
            onFilterTap: () {},
          ),
          if (isExpanded)
            Positioned(
              left: 16.w,
              top: MediaQuery.paddingOf(context).top + 76.h,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 8,
                shadowColor: const Color(0x26000000),
                child: IconButton(
                  onPressed: _collapseMap,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          // Replace the old RestaurantBottomSheet reconstruction block:
if (isExpanded && selectedRestaurant != null)
  Positioned(
    left: 0, right: 0, bottom: 0,
    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SingleChildScrollView(
        child: RestaurantCard(
          uuid: selectedRestaurant.uuid,
          name: selectedRestaurant.name,
          type: selectedRestaurant.type,
          address: selectedRestaurant.address,
          phone: selectedRestaurant.phone,
          lat: selectedRestaurant.lat,
          lng: selectedRestaurant.lng,
          description: selectedRestaurant.description,
          availableDishes: selectedRestaurant.availableDishes,
          takeAwayService: selectedRestaurant.takeAwayService,
          deliveryService: selectedRestaurant.deliveryService,
          deliveryServiceArea: selectedRestaurant.deliveryServiceArea,
          restaurantType: selectedRestaurant.restaurantType,
          status: selectedRestaurant.status,
          isFavourite: selectedRestaurant.isFavorite,
          image: selectedRestaurant.image,
          offers: selectedRestaurant.offers,
          isFavoriteBox: false,
          onRatingOnClick: () {},
          onBoxClicked: (String? offerId) {
            showModalBottomSheet(
              backgroundColor: Colors.white,
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              builder: (_) => NumberOfPeopleModal(
                uuid: selectedRestaurant.uuid,
                offerId: offerId,
              ),
            );
          },
        ),
      ),
    ),
  ),

// Replace the preview carousel (no longer uses map_feature.Restaurant):
if (isExpanded && selectedRestaurant == null)
  Positioned(
    left: 0, right: 0, bottom: 20.h,
    child: restaurants.maybeWhen(
      data: (items) => SizedBox(
        height: 82.h,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final r = items[index];
            return GestureDetector(
              onTap: () => _selectRestaurant(r),
              child: Container(
                margin: EdgeInsets.only(right: 10.w),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: r.image != null
                          ? Image.network(r.image!, width: 44.w, height: 44.w, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/restaurantBanner.png',
                                width: 44.w, height: 44.w, fit: BoxFit.cover))
                          : Image.asset('assets/images/restaurantBanner.png',
                              width: 44.w, height: 44.w, fit: BoxFit.cover),
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(r.name,
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
                        if (r.offers.isNotEmpty)
                          Text(
                            '-${r.offers.reduce((a, b) => a.discountPercentage >= b.discountPercentage ? a : b).discountPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(color: const Color(0xFFF87B0D), fontSize: 12.sp, fontWeight: FontWeight.w700),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      orElse: SizedBox.shrink,
    ),
  ),
        ],
      ),
    );
  }

  Future<void> _expandMap() async {
    if (ref.read(mapExpandedProvider)) return;
    ref.read(mapExpandedProvider.notifier).state = true;
    final restaurants = ref.read(nearbyRestaurantsProvider).valueOrNull ?? [];
    if (restaurants.isNotEmpty) {
      await _controllerService.expandAround(
  LatLng(double.tryParse(restaurants.first.lat) ?? 0, double.tryParse(restaurants.first.lng) ?? 0),
);
await _controllerService.fitRestaurants(
  restaurants.map((r) => LatLng(double.tryParse(r.lat) ?? 0, double.tryParse(r.lng) ?? 0)),
);
    }
  }

  void _collapseMap() {
    ref.read(selectedRestaurantProvider.notifier).state = null;
    ref.read(mapExpandedProvider.notifier).state = false;
  }

// Replace _selectRestaurant
Future<void> _selectRestaurant(RestaurantModel restaurant) async {
  ref.read(mapExpandedProvider.notifier).state = true;
  ref.read(selectedRestaurantProvider.notifier).state = restaurant;
  await _controllerService.focusRestaurant(
    LatLng(double.tryParse(restaurant.lat) ?? 0, double.tryParse(restaurant.lng) ?? 0),
  );
}
  Future<void> _refreshMarkers(List<MarkerSpec> specs) async {
  final signature = specs
      .map((spec) =>
          '${spec.restaurantId}:${spec.discountLabel}:${spec.isSelected}:${spec.isDimmed}')
      .join('|');
  if (signature == _lastMarkerSignature || !mounted) return;
  _lastMarkerSignature = signature;

  final restaurants = ref.read(nearbyRestaurantsProvider).valueOrNull ?? [];
  final markers = <Marker>{};

  for (final spec in specs) {
    final icon = await _markerBitmapService.buildOfferMarker(
      context,
      label: spec.discountLabel,
      isSelected: spec.isSelected,
      isDimmed: spec.isDimmed,
    );
    markers.add(
      Marker(
        markerId: MarkerId(spec.restaurantId),
        position: spec.position,
        icon: icon,
        anchor: const Offset(.5, .94),
        zIndexInt: spec.isSelected ? 2 : 1,
        onTap: () {                          // ← replace the onTap block here
          final match = restaurants.firstWhere(
            (r) => r.uuid == spec.restaurantId,
            orElse: () => restaurants.first,
          );
          unawaited(_selectRestaurant(match));
        },
      ),
    );
  }

  if (!mounted) return;
  ref.read(mapMarkersProvider.notifier).state = markers;
}
}

class _RestaurantHomeList extends StatelessWidget {
  const _RestaurantHomeList(this.restaurants);

  final List<RestaurantModel> restaurants;  // ← was List<Restaurant>

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 24.h),
      children: [
        SizedBox(
          height: 74.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _discounts.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, index) => _DiscountChip(label: _discounts[index]),
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          'Nearby restaurants',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 12.h),
        ...restaurants.map(
          (restaurant) => Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: _RestaurantListTile(restaurant: restaurant),
          ),
        ),
      ],
    );
  }
}

class _DiscountChip extends StatelessWidget {
  const _DiscountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF172018),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Discount',
            style: TextStyle(color: Colors.white70, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}

class _RestaurantListTile extends StatelessWidget {
  const _RestaurantListTile({required this.restaurant});

  final RestaurantModel restaurant;  // ← was Restaurant

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: restaurant.image != null
                ? Image.network(
                    restaurant.image!,
                    width: 78.w, height: 78.w, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/restaurantBanner.png',
                      width: 78.w, height: 78.w, fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'assets/images/restaurantBanner.png',
                    width: 78.w, height: 78.w, fit: BoxFit.cover,
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5.h),
                Text(
                  restaurant.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: const Color(0xFF666666), fontSize: 12.sp),
                ),
                SizedBox(height: 8.h),
                // No rating field on RestaurantModel — show best offer instead
                if (restaurant.offers.isNotEmpty)
                  Text(
                    '-${restaurant.offers
                        .reduce((a, b) => a.discountPercentage >= b.discountPercentage ? a : b)
                        .discountPercentage
                        .toStringAsFixed(0)}% off',
                    style: TextStyle(
                      color: const Color(0xFFF87B0D),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

const _discounts = ['10%-20%', '20%-30%', '30%-40%', '40%-50%'];
