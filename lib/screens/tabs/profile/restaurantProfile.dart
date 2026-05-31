import 'dart:ui';
import 'package:fudikoclient/screens/tabs/home/addnumberofpeople.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/model/restaurant/restaurant_profile_model.dart';
import 'package:fudikoclient/screens/tabs/home/rating.dart';
import 'package:fudikoclient/screens/tabs/profile/menu.dart';
import 'package:fudikoclient/service/restaurant/restaurant-service.dart';
import 'package:fudikoclient/service/restaurant/restaurant_profile_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class RestaurantProfile extends StatefulWidget {
  final String uuid;
  final String? deliveryServiceArea;
  final double? averageReview;
  final double? distance;
  final bool isFavourite;
  const RestaurantProfile({
    super.key,
    required this.uuid,
    this.deliveryServiceArea,
    this.averageReview,
    this.distance,
    this.isFavourite = false, // ← ADDED isFavourite
  });

  @override
  State<RestaurantProfile> createState() => _RestaurantProfileState();
}

class _RestaurantProfileState extends State<RestaurantProfile> {
  //bool isRatingOnClick = false;
  bool _isLiked = false;
  final RestaurantService _restaurantService = RestaurantService();
  bool isMenuOpen = false;
  Restaurant? restaurant;
  bool isLoading = true;
  Future<void> fetchRestaurantDetails() async {
    final service = RestaurantDetailsService();

    final response = await service.getRestaurantDetails(widget.uuid);

    if (response.status && response.restaurant != null) {
      setState(() {
        //  _isLiked = response.restaurant!.isFavourite;
        restaurant = response.restaurant;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _onFavouriteTap() async {
    final data = RestaurantLikedDislikedModel(uuid: widget.uuid);
    final response = await _restaurantService.changeStatus(data);
    if (response.status) {
      setState(() => _isLiked = !_isLiked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _isLiked ? Colors.green : Colors.red,
          content: Text(
            _isLiked ? 'Added to favourites' : 'Removed from favourites',
          ),
        ),
      );
    }
  }

  void _openImagePreview(String imageUrl, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: 'restaurant-gallery-$index',
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/restaurantPic.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12.h,
              right: 16.w,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isFavourite;
    fetchRestaurantDetails();
  }

  @override
  Widget build(BuildContext context) {
    final distanceLabel = widget.distance != null
        ? '${widget.distance!.toStringAsFixed(widget.distance! % 1 == 0 ? 0 : 1)} km'
        : '${widget.deliveryServiceArea ?? restaurant?.deliveryServiceArea ?? 'N/A'} km';
    final reviewLabel =
        (restaurant?.averageReview ?? widget.averageReview)?.toStringAsFixed(
          1,
        ) ??
        'N/A';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _isLiked);
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : isMenuOpen
              ? Menu(restaurantId: widget.uuid)
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          restaurant?.image != null
                              ? Image.network(
                                  restaurant!.image!,
                                  height: 160.h,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/restaurantBanner.png',
                                    height: 160.h,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/restaurantBanner.png',
                                  height: 160.h,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),

                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),

                          Positioned(
                            top: 5.h,
                            right: 30.w,
                            child: InkWell(
                              // ← was just Icon before
                              onTap: _onFavouriteTap,
                              child: Icon(
                                Icons.favorite,
                                color: _isLiked
                                    ? Color(0xFFf87b0d)
                                    : Colors.white,
                                size: 30.w,
                              ),
                            ),
                          ),

                          Positioned(
                            bottom: 20.h,
                            right: 20.w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _badge(pin_to_pinIcon, distanceLabel, 18.w),
                                SizedBox(height: 8.h),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RatingPage(
                                          restaurantId: widget.uuid,
                                          restaurantName: restaurant?.name,
                                          restaurantAddress:
                                              restaurant?.address,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _badge(
                                    reviewStarIcon,
                                    reviewLabel,
                                    18.w,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Positioned(
                            left: 20.w,
                            right: 120.w,
                            bottom: 20.h,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //R name-------------------------
                                AppText(
                                  text: restaurant?.name ?? "",
                                  size: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                //R type---------------------------
                                AppText(
                                  text: restaurant?.type ?? "",
                                  size: 25,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      locationpinIcon,
                                      width: 16,
                                      height: 16,
                                    ),
                                    SizedBox(width: 4.w),

                                    //R addresss---------------------------
                                    Expanded(
                                      child: AppText(
                                        text: restaurant?.address ?? "",
                                        size: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      SizedBox(
                        height: 135.h,
                        child:
                            restaurant?.offers == null ||
                                restaurant!.offers.isEmpty
                            ? Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15.w,
                                  vertical: 10.h,
                                ),
                                child: Center(
                                  child: AppText(
                                    text: 'No offers available',
                                    color: Colors.grey,
                                    size: 13.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.only(
                                  left: 15.w,
                                  right: 15.w,
                                  bottom: 15.h,
                                ),
                                itemCount: restaurant!.offers.length,
                                itemBuilder: (context, index) {
                                  final offer = restaurant!.offers[index];
                                  final discountStr =
                                      '-${offer.discountPercentage.toStringAsFixed(0)}%';
                                  final forText = 'for ${offer.applicableFor}';
                                  final timeStr = offer.startTime;
                                  const days2 = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  final today =
                                      days2[DateTime.now().weekday - 1];
                                  final activeDays = offer.activeDays
                                      .split(',')
                                      .map((d) => d.trim())
                                      .toList();
                                  final dateLabel = activeDays.contains(today)
                                      ? 'TODAY'
                                      : activeDays.first.toUpperCase();
                                  final offerId = offer.uuid.isNotEmpty
                                      ? offer.uuid
                                      : null;

                                  return Padding(
                                    padding: EdgeInsets.only(right: 5.w),
                                    child: Container(
                                      width: 85.w,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF417629),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(5.r),
                                          topRight: Radius.circular(5.r),
                                          bottomLeft: Radius.circular(10.r),
                                          bottomRight: Radius.circular(10.r),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(8.w),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  children: [
                                                    AppText(
                                                      text: discountStr,
                                                      size: 16.sp,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    AppText(
                                                      text: forText,
                                                      isCentered: true,
                                                      size: 10.sp,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: List.generate(
                                                    15,
                                                    (i) => Expanded(
                                                      child: Container(
                                                        height: 1.h,
                                                        color: i % 2 == 0
                                                            ? Colors.white
                                                            : Colors
                                                                  .transparent,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    SizedBox(height: 2.h),
                                                    AppText(
                                                      text: dateLabel,
                                                      size: 6.sp,
                                                      color: Colors.white70,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    SizedBox(height: 6.h),

                                                    SizedBox(
                                                      height: 6.h,
                                                    ), // ← ADD
                                                    GestureDetector(
                                                      // ← ADD
                                                      onTap: () {
                                                        // ← ADD
                                                        showModalBottomSheet(
                                                          // ← ADD
                                                          backgroundColor: Colors
                                                              .white, // ← ADD
                                                          context:
                                                              context, // ← ADD
                                                          isScrollControlled:
                                                              true, // ← ADD
                                                          shape: const RoundedRectangleBorder(
                                                            // ← ADD
                                                            borderRadius:
                                                                BorderRadius.vertical(
                                                                  // ← ADD
                                                                  top: Radius.circular(
                                                                    25,
                                                                  ), // ← ADD
                                                                ), // ← ADD
                                                          ), // ← ADD
                                                          builder: (_) =>
                                                              NumberOfPeopleModal(
                                                                // ← ADD
                                                                uuid: widget
                                                                    .uuid, // ← ADD
                                                                offerId:
                                                                    offerId, // ← ADD
                                                                offer: offer,
                                                              ), // ← ADD
                                                        ); // ← ADD
                                                      }, // ← ADD
                                                      child: Container(
                                                        // ← ADD
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              // ← ADD
                                                              horizontal: 4.w,
                                                              vertical:
                                                                  4.h, // ← ADD
                                                            ), // ← ADD
                                                        decoration: BoxDecoration(
                                                          // ← ADD
                                                          color: Colors
                                                              .white, // ← ADD
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6.r,
                                                              ), // ← ADD
                                                        ), // ← ADD
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 4.w,
                                                                vertical: 4.h,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6.r,
                                                                ),
                                                          ),
                                                          child: AppText(
                                                            text: timeStr,
                                                            size: 10,
                                                            color: Colors
                                                                .green
                                                                .shade700,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ), // ← ADD
                                                      ), // ← ADD
                                                    ), // ← ADD
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            left: -8.w,
                                            top: 20,
                                            bottom: 0,
                                            child: Center(
                                              child: Container(
                                                width: 16.w,
                                                height: 16.w,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: -8.w,
                                            top: 20,
                                            bottom: 0,
                                            child: Center(
                                              child: Container(
                                                width: 16.w,
                                                height: 16.w,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        height: 150.h,
                        child: restaurant?.images.isEmpty ?? true
                            ? Center(
                                child: AppText(
                                  color: Colors.grey,
                                  size: 13,
                                  text: 'No images available',
                                  fontWeight: FontWeight.w400,
                                ),
                              )
                            : ListView.builder(
                                itemCount: restaurant!.images.length,
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: 10.w),
                                    child: GestureDetector(
                                      onTap: () => _openImagePreview(
                                        restaurant!.images[index],
                                        index,
                                      ),
                                      child: Hero(
                                        tag: 'restaurant-gallery-$index',
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                          child: Image.network(
                                            restaurant!.images[index],
                                            height: 150.h,
                                            width: 100.w,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Image.asset(
                                                  'assets/images/restaurantPic.png',
                                                  height: 150.h,
                                                  fit: BoxFit.cover,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      Padding(
                        padding: EdgeInsets.all(20.r),
                        child: Container(
                          padding: EdgeInsets.all(16.r),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10.r,
                                offset: Offset(0, 4.r),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  AppText(
                                    text: "About",
                                    size: 12,
                                    fontWeight: FontWeight.bold,
                                    color: appTextColor2,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Container(
                                      height: 0.5,
                                      color: appTextColor3,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 8.h,
                                  right: 10.w,
                                  left: 10.w,
                                  bottom: 8.h,
                                ),
                                child: AppText(
                                  text: restaurant?.description ?? "",
                                  size: 12,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor2,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  AppText(
                                    text: "Cuisine",
                                    size: 12,
                                    fontWeight: FontWeight.bold,
                                    color: appTextColor2,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Container(
                                      height: 0.5,
                                      color: appTextColor3,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 8.h,
                                  right: 10.w,
                                  left: 10.w,
                                  bottom: 8.h,
                                ),
                                child: AppText(
                                  text: restaurant?.restaurantType ?? "",
                                  size: 12,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor2,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  AppText(
                                    text: "Address",
                                    size: 12,
                                    fontWeight: FontWeight.bold,
                                    color: appTextColor2,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Container(
                                      height: 0.5,
                                      color: appTextColor3,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 8.h,
                                  right: 10.w,
                                  left: 10.w,
                                  bottom: 8.h,
                                ),
                                //addresss----------------------------------
                                child: AppText(
                                  text: restaurant?.address ?? "",
                                  size: 12,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor2,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  AppText(
                                    text: "Contact Info",
                                    size: 12,
                                    fontWeight: FontWeight.bold,
                                    color: appTextColor2,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Container(
                                      height: 0.5,
                                      color: appTextColor3,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 8.h,
                                  right: 10.w,
                                  left: 10.w,
                                  bottom: 8.h,
                                ),
                                //contact-----------------------------
                                child: AppText(
                                  text: restaurant?.phone ?? "",
                                  size: 12,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor2,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 175.w,
                        height: 50.h,
                        child: AppButton(
                          imageIconPath: menuBookIcon,
                          iconSize: 35.w,
                          bgColor1: appButtonColor,
                          bgColor2: Color(0xFF934808),
                          text: " View Menu",
                          size: 17,
                          borderRadius: 15.r,
                          onPressed: () {
                            setState(() {
                              isMenuOpen = !isMenuOpen;
                            });
                          },
                          // icon: Icons.fastfood,
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _badge(String? imageIconPath, String text, double? iconSize) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Color(0xfff87b0d),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          imageIconPath != null
              ? Image.asset(
                  imageIconPath,
                  width: iconSize?.w ?? 10.w,
                  height: iconSize?.h ?? 10.h,
                )
              : Icon(
                  Icons.info,
                  size: iconSize?.sp ?? 10.sp,
                  color: Colors.white,
                ),
          SizedBox(width: 4.w),
          Text(text, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
