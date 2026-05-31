import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/favorite/favoraite_model.dart';
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

  Widget _searchInputField() {
    final searchPadding = EdgeInsets.symmetric(horizontal: 20.w);
    final searchHeight = 50.h;

    if (!_isSearchActive) {
      return Padding(
        padding: searchPadding,
        child: GestureDetector(
          onTap: () => setState(() => _isSearchActive = true),
          child: Container(
            height: searchHeight,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), // #000000 5%
                  offset: const Offset(0, 0), // X: 0, Y: 0
                  blurRadius: 10, // Blur: 10
                  spreadRadius: 5, // Spread: 5
                ),
              ],
            ),
            child: Center(
              child: AppText(
                text: "Search Restaurant",
                size: 14,
                fontWeight: FontWeight.w400,
                color: menuIconColor.withOpacity(.7),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: searchPadding,
      child: Container(
        height: searchHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // #000000 5%
              offset: const Offset(0, 0), // X: 0, Y: 0
              blurRadius: 10, // Blur
              spreadRadius: 5, // Spread
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _clearSearch,
              child: Padding(
                padding: EdgeInsets.only(left: 12.w),
                child: Icon(Icons.close, size: 20, color: appTextColor3),
              ),
            ),
            Expanded(
              child: AppTextFeild(
                controller: _searchController,
                text: 'Search Restaurant',
                isTextCenter: true,
                onChanged: _onSearchChanged,
                size: 14,
                textColor: menuIconColor.withOpacity(.7),
                inputContentPadding: EdgeInsets.symmetric(
                  vertical: 0.h,
                  horizontal: 20.w,
                ),
                backgroundColor: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.00), // #000000 5%
                    offset: const Offset(0, 0), // X: 0, Y: 0
                    blurRadius: 0, // Blur: 10
                    spreadRadius: 0, // Spread: 5
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
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: appButtonColor,
          onRefresh: loadFavouriteRestaurants,
          child: ListView.builder(
            padding: EdgeInsets.only(left: 0.w, right: 0.w, top: 20.h),
            itemCount: _isLoadingRestaurants ? 2 : restaurantsList.length + 2,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == 0) return _searchInputField();
              if (index == 1) {
                if (_isLoadingRestaurants) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 120.h),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                return const SizedBox(height: 20);
              }

              if (_isLoadingRestaurants) {
                return const SizedBox.shrink();
              }

              final restaurant = restaurantsList[index - 2];

              return InkWell(
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
                  onBoxClicked: (String? offerId) {
                    final selectedOffers = restaurant.offers
                        .where((offer) => offer.uuid == offerId)
                        .toList();
                    setState(() => isBookingModalOpen = !isBookingModalOpen);
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
                          offer: selectedOffers.isEmpty
                              ? null
                              : selectedOffers.first,
                        ),
                      );
                    }
                  },
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
