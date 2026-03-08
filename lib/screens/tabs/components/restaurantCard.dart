import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/service/restaurant/restaurant-service.dart';
import 'package:fudikoclient/utils/constants.dart';

class RestaurantCard extends StatefulWidget {
  final VoidCallback? onRatingOnClick;
  final VoidCallback? onBoxClicked;
  final String uuid;
  final String name;
  final String type;
  final String address;
  final String phone;
  final String lat;
  final String lng;
  final String description;
  final String availableDishes;
  final int takeAwayService;
  final int deliveryService;
  final String deliveryServiceArea;
  final String restaurantType;
  final String status;
  final bool? isFavourite;
  final bool isFavoriteBox;

  const RestaurantCard({
    super.key,
    this.onRatingOnClick,
    this.onBoxClicked,
    required this.uuid,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.description,
    required this.availableDishes,
    required this.takeAwayService,
    required this.deliveryService,
    required this.deliveryServiceArea,
    required this.restaurantType,
    required this.status,
    this.isFavourite,
    this.isFavoriteBox = false,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  bool isLiked = false;
  RestaurantService restaurantService = RestaurantService();
  @override
  void initState() {
    super.initState();
    isLiked = widget.isFavourite ?? false;
  }

  Future<void> onLikeOnTap() async {
    RestaurantLikedDislikedModel data = RestaurantLikedDislikedModel(
      uuid: widget.uuid,
    );
    RestaurantLikedDislikedResponseModel response = await restaurantService
        .changeStatus(data);
    if (response.status) {
      setState(() {
        isLiked = !isLiked;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isLiked ? Colors.green : Colors.red,
          content: Text(
            isLiked ? 'Add to favourites' : 'Removed from favourites',
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text('Something went wrong'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(20.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/restaurantBanner.png',
                      height: 180.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 180.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Color(0xfff87b0d),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 14.w, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text(
                        '${widget.deliveryServiceArea} km',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              widget.isFavoriteBox
                  ? SizedBox.shrink()
                  : Positioned(
                      top: 20,
                      right: 20,
                      child: InkWell(
                        onTap: onLikeOnTap,
                        child: Icon(
                          Icons.favorite,
                          color: isLiked ? Color(0XFFf87b0d) : Colors.grey[200],
                          size: 25.w,
                        ),
                      ),
                    ),
              Positioned(
                bottom: 10,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: "${widget.name} ",
                      size: 30,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    AppText(
                      text: "${widget.type} ",
                      size: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: widget.onBoxClicked,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(15.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: appTextColor3,
                                  size: 18.w,
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: AppText(
                                    text: widget.address,
                                    color: appTextColor3,
                                    size: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w), // Add some spacing
                          Flexible(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0XFFf87b0d),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: GestureDetector(
                                onTap: widget.onRatingOnClick,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14.w,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '4.8',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 18.w,
                            color: appTextColor3,
                          ),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              widget.availableDishes
                                  .split(',')
                                  .map((e) => e.trim())
                                  .join(' - '),
                              style: TextStyle(
                                color: appTextColor3,
                                fontSize: 14.sp,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 135.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(
                      left: 15.w,
                      right: 15.w,
                      bottom: 15.h,
                    ),
                    children: List.generate(5, (index) {
                      final discounts = [
                        '-40%',
                        '-40%',
                        '-30%',
                        '-25%',
                        '-40%',
                      ];
                      final texts = [
                        'for entire menu',
                        'for entire menu',
                        'for entire menu',
                        'for entire drinks',
                        'for entire menu',
                      ];
                      final times = [
                        '12:00PM',
                        '12:30PM',
                        '01:00PM',
                        '05:00PM',
                        '12:00PM',
                      ];
                      final dates = [
                        'TODAY',
                        'TODAY',
                        'TODAY',
                        'TODAY',
                        'MAY 1',
                      ];

                      return Padding(
                        padding: EdgeInsets.only(right: 5.w),
                        child: Container(
                          width: 85.w,
                          decoration: BoxDecoration(
                            color: Color(0XFF417629),
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
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          discounts[index],
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        AppText(
                                          text: texts[index],
                                          size: 10.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w400,
                                          isCentered: true,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: List.generate(
                                        15,
                                        (i) => Expanded(
                                          child: Container(
                                            height: 1.h,
                                            color: i % 2 == 0
                                                ? Colors.white
                                                : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),

                                    Column(
                                      children: [
                                        SizedBox(height: 2.h),
                                        Text(
                                          dates[index],
                                          style: TextStyle(
                                            fontSize: 6.sp,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 6.h),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6.r,
                                            ),
                                          ),
                                          child: Text(
                                            times[index],
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
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
                    }),
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
