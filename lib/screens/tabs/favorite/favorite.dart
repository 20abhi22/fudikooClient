import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/favorite/favoraite_model.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/screens/tabs/components/restaurantCard.dart';
import 'package:fudikoclient/screens/tabs/home/addnumberofpeople.dart';
import 'package:fudikoclient/screens/tabs/home/rating.dart';
import 'package:fudikoclient/service/favourite/favourite_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/screens/tabs/profile/restaurantProfile.dart';

class Favorite extends StatefulWidget {
  final double? currentLat;
  final double? currentLng;

  const Favorite({super.key, this.currentLat, this.currentLng});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  FavouriteRestaurantService favouriteRestaurantService =
      FavouriteRestaurantService();
  List<FavouriteRestaurantModel> restaurantsList = [];
  List<FavouriteRestaurantModel> _allRestaurants = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool isBookingModalOpen = false;
  bool _isSearchActive = false;
  bool _isLoadingRestaurants = true;

  @override
  void initState() {
    super.initState();
    loadFavouriteRestaurants();
  }

  Future<void> loadFavouriteRestaurants() async {
    if (mounted) {
      setState(() => _isLoadingRestaurants = true);
    }

    FavouriteRestaurantModelResponse response = await favouriteRestaurantService
        .getFavouriteRestaurants(
          lat: widget.currentLat,
          lng: widget.currentLng,
        );

    if (!mounted) return;

    if (response.status) {
      setState(() {
        restaurantsList = response.restaurant;
        _allRestaurants = List.from(response.restaurant);
        _isLoadingRestaurants = false;
      });
    } else {
      setState(() {
        _isLoadingRestaurants = false;
      });
      debugPrint('Error loading favourite restaurants');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final q = query.trim();
      if (q.isEmpty) {
        if (!mounted) return;
        setState(() => restaurantsList = List.from(_allRestaurants));
        return;
      }

      try {
        final resp = await favouriteRestaurantService
            .searchFavouriteRestaurants(
              q,
              lat: widget.currentLat,
              lng: widget.currentLng,
            );
        if (resp.status) {
          if (!mounted) return;
          setState(() => restaurantsList = resp.restaurant);
        } else {
          // fallback to client-side filter
          final filtered = _allRestaurants.where((r) {
            final name = r.name.toLowerCase();
            return name.contains(q.toLowerCase());
          }).toList();
          if (!mounted) return;
          setState(() => restaurantsList = filtered);
        }
      } catch (e) {
        final filtered = _allRestaurants.where((r) {
          final name = r.name.toLowerCase();
          return name.contains(q.toLowerCase());
        }).toList();
        if (!mounted) return;
        setState(() => restaurantsList = filtered);
      }
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _isSearchActive = false;
      restaurantsList = List.from(_allRestaurants);
    });
  }

  Widget _searchInputField(_FavoriteMetrics metrics) {
    if (!_isSearchActive) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
        child: GestureDetector(
          onTap: () => setState(() => _isSearchActive = true),
          child: Container(
            height: metrics.searchHeight,
            padding: EdgeInsets.symmetric(
              horizontal: metrics.searchHorizontalPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(metrics.searchRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: metrics.searchShadowAlpha,
                  ),
                  offset: Offset(0, metrics.searchShadowOffsetY),
                  blurRadius: metrics.searchShadowBlur,
                  spreadRadius: metrics.searchShadowSpread,
                ),
              ],
            ),
            child: Center(
              child: AppText(
                text: "Search Restaurant",
                size: metrics.searchTextSize,
                fontWeight: FontWeight.w400,
                color: menuIconColor.withValues(alpha: .7),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      child: Container(
        height: metrics.searchHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(metrics.searchRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: metrics.searchShadowAlpha),
              offset: Offset(0, metrics.searchShadowOffsetY),
              blurRadius: metrics.searchShadowBlur,
              spreadRadius: metrics.searchShadowSpread,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _clearSearch,
              child: Padding(
                padding: EdgeInsets.only(left: metrics.closeIconLeftPadding),
                child: Icon(
                  Icons.close,
                  size: metrics.closeIconSize,
                  color: appTextColor3,
                ),
              ),
            ),
            Expanded(
              child: AppTextFeild(
                controller: _searchController,
                text: 'Search Restaurant',
                isTextCenter: true,
                onChanged: _onSearchChanged,
                size: metrics.searchInputTextSize,
                textColor: menuIconColor.withValues(alpha: .7),
                inputContentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: metrics.searchHorizontalPadding,
                ),
                backgroundColor: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.00),
                    offset: const Offset(0, 0),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _FavoriteMetrics.fromContext(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: appButtonColor,
          onRefresh: loadFavouriteRestaurants,
          child: ListView.builder(
            padding: EdgeInsets.only(top: metrics.topPadding),
            itemCount: _isLoadingRestaurants ? 2 : restaurantsList.length + 2,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Center(
                  child: SizedBox(
                    width: metrics.contentWidth,
                    child: _searchInputField(metrics),
                  ),
                );
              }

              if (index == 1) {
                if (_isLoadingRestaurants) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: metrics.loadingVerticalPadding,
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (restaurantsList.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.horizontalPadding,
                      vertical: metrics.emptyVerticalPadding,
                    ),
                    child: Center(
                      child: AppText(
                        text: 'No favourite restaurants found',
                        size: metrics.emptyTextSize,
                        fontWeight: FontWeight.w500,
                        color: appTextColor3,
                        isCentered: true,
                      ),
                    ),
                  );
                }

                return SizedBox(height: metrics.afterSearchGap);
              }

              if (_isLoadingRestaurants) {
                return const SizedBox.shrink();
              }

              final restaurant = restaurantsList[index - 2];

              return Center(
                child: SizedBox(
                  width: metrics.contentWidth,
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantProfile(
                            uuid: restaurant.uuid,
                            deliveryServiceArea: restaurant.deliveryServiceArea,
                            averageReview: restaurant.averageReview,
                            distance: restaurant.distance,
                            isFavourite: true,
                          ),
                        ),
                      );
                      if (result is bool && result == false) {
                        if (!mounted) return;
                        setState(() {
                          restaurantsList.removeAt(index - 2);
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
                      averageReview: restaurant.averageReview,
                      distance: restaurant.distance,
                      restaurantType: restaurant.restaurantType,
                      status: restaurant.status,
                      isFavourite: true,
                      isFavoriteBox: false,
                      offers: restaurant.offers,
                      image: restaurant.image,
                      onRatingOnClick: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RatingPage(
                            restaurantId: restaurant.uuid,
                            restaurantName: restaurant.name,
                            restaurantAddress: restaurant.address,
                          ),
                        ),
                      ),
                      onBoxClicked: (String? offerId, OfferModel? offer) {
                        final selectedOffers = restaurant.offers
                            .where((offer) => offer.uuid == offerId)
                            .toList();
                        setState(
                          () => isBookingModalOpen = !isBookingModalOpen,
                        );
                        if (isBookingModalOpen) {
                          // showModalBottomSheet(
                          //   backgroundColor: Colors.white,
                          //   context: context,
                          //   isScrollControlled: true,
                          //   shape: const RoundedRectangleBorder(
                          //     borderRadius: BorderRadius.vertical(
                          //       top: Radius.circular(25),
                          //     ),
                          //   ),
                          //   builder: (_) => NumberOfPeopleModal(
                          //     uuid: restaurant.uuid,
                          //     offerId: offerId,
                          //     offer:
                          //         offer ??
                          //         (selectedOffers.isEmpty
                          //             ? null
                          //             : selectedOffers.first),
                          //   ),
                          // );
                          showModalBottomSheet(
  backgroundColor: Colors.white,
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: Breakpoints.isTabletContext(context)
      ? const BoxConstraints(maxWidth: 500)
      : null,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(25),
    ),
  ),
  builder: (_) => SingleChildScrollView(
    child: NumberOfPeopleModal(
      uuid: restaurant.uuid,
      offerId: offerId,
      offer: offer ??
          (selectedOffers.isEmpty ? null : selectedOffers.first),
    ),
  ),
);
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

class _FavoriteMetrics {
  const _FavoriteMetrics({
    required this.contentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.afterSearchGap,
    required this.searchHeight,
    required this.searchHorizontalPadding,
    required this.searchRadius,
    required this.searchShadowAlpha,
    required this.searchShadowBlur,
    required this.searchShadowOffsetY,
    required this.searchShadowSpread,
    required this.searchTextSize,
    required this.searchInputTextSize,
    required this.closeIconLeftPadding,
    required this.closeIconSize,
    required this.loadingVerticalPadding,
    required this.emptyVerticalPadding,
    required this.emptyTextSize,
  });

  final double contentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double afterSearchGap;
  final double searchHeight;
  final double searchHorizontalPadding;
  final double searchRadius;
  final double searchShadowAlpha;
  final double searchShadowBlur;
  final double searchShadowOffsetY;
  final double searchShadowSpread;
  final double searchTextSize;
  final double searchInputTextSize;
  final double closeIconLeftPadding;
  final double closeIconSize;
  final double loadingVerticalPadding;
  final double emptyVerticalPadding;
  final double emptyTextSize;

  factory _FavoriteMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // final isTablet = Breakpoints.isTablet(size.width);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final contentWidth = (size.width * 0.82).clamp(680.0, 980.0).toDouble();
      final scale = (contentWidth / 760).clamp(1.0, 1.12).toDouble();
      double s(double value) => value * scale;

      return _FavoriteMetrics(
        contentWidth: contentWidth,
        horizontalPadding: s(28),
        topPadding: s(28),
        afterSearchGap: s(24),
        searchHeight: s(64),
        searchHorizontalPadding: s(24),
        searchRadius: s(18),
        searchShadowAlpha: 0.2,
        searchShadowBlur: s(10),
        searchShadowOffsetY: s(5),
        searchShadowSpread: 0,
        searchTextSize: s(17),
        searchInputTextSize: s(16),
        closeIconLeftPadding: s(18),
        closeIconSize: s(24),
        loadingVerticalPadding: s(150),
        emptyVerticalPadding: s(120),
        emptyTextSize: s(17),
      );
    }

    if (isWideShortPhone) {
      return _FavoriteMetrics(
        contentWidth: math.min(size.width, 760.0),
        horizontalPadding: 28,
        topPadding: 20,
        afterSearchGap: 18,
        searchHeight: 52,
        searchHorizontalPadding: 22,
        searchRadius: 16,
        searchShadowAlpha: 0.14,
        searchShadowBlur: 10,
        searchShadowOffsetY: 4,
        searchShadowSpread: 0,
        searchTextSize: 14,
        searchInputTextSize: 14,
        closeIconLeftPadding: 14,
        closeIconSize: 20,
        loadingVerticalPadding: 92,
        emptyVerticalPadding: 76,
        emptyTextSize: 14,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _FavoriteMetrics(
        contentWidth: math.min(size.width, 760.0),
        horizontalPadding: s(16),
        topPadding: s(16),
        afterSearchGap: s(16),
        searchHeight: s(44),
        searchHorizontalPadding: s(16),
        searchRadius: s(13),
        searchShadowAlpha: 0.05,
        searchShadowBlur: s(8),
        searchShadowOffsetY: 0,
        searchShadowSpread: s(3),
        searchTextSize: s(12.5),
        searchInputTextSize: s(12.5),
        closeIconLeftPadding: s(11),
        closeIconSize: s(18),
        loadingVerticalPadding: s(90),
        emptyVerticalPadding: s(70),
        emptyTextSize: s(13),
      );
    }

    return _FavoriteMetrics(
      contentWidth: math.min(size.width, 760.0),
      horizontalPadding: 20.w,
      topPadding: 20.h,
      afterSearchGap: 20,
      searchHeight: 50.h,
      searchHorizontalPadding: 20.w,
      searchRadius: 16.r,
      searchShadowAlpha: 0.05,
      searchShadowBlur: 10,
      searchShadowOffsetY: 0,
      searchShadowSpread: 5,
      searchTextSize: 14,
      searchInputTextSize: 14,
      closeIconLeftPadding: 12.w,
      closeIconSize: 20,
      loadingVerticalPadding: 120.h,
      emptyVerticalPadding: 90.h,
      emptyTextSize: 15,
    );
  }
}
