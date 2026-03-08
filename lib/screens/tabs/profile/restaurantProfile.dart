import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/restaurant/restaurant_profile_model.dart';
import 'package:fudikoclient/screens/tabs/home/rating.dart';
import 'package:fudikoclient/screens/tabs/profile/menu.dart';
import 'package:fudikoclient/service/restaurant/restaurant_profile_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class RestaurantProfile extends StatefulWidget {
  final String uuid;
  const RestaurantProfile({super.key, required this.uuid});

  @override
  State<RestaurantProfile> createState() => _RestaurantProfileState();
}

class _RestaurantProfileState extends State<RestaurantProfile> {
  //bool isRatingOnClick = false;
  bool isMenuOpen = false;
  Restaurant? restaurant;
  bool isLoading = true;
  Future<void> fetchRestaurantDetails() async {
    final service = RestaurantDetailsService();

    final response = await service.getRestaurantDetails(widget.uuid);

    if (response.status && response.restaurant != null) {
      setState(() {
        restaurant = response.restaurant;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRestaurantDetails();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : isMenuOpen
            ? Menu()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Image.asset(
                          'assets/images/restaurantBanner.png',
                          height: 160.h,
                          width: double.infinity.w,
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
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 30.w,
                          ),
                        ),

                        Positioned(
                          bottom: 20.h,
                          right: 20.w,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _badge(Icons.location_on, '12 km'),
                              SizedBox(height: 8.h),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RatingPage(),
                                    ),
                                  );
                                },
                                child: _badge(Icons.star, '4.8'),
                              ),
                            ],
                          ),
                        ),

                        Positioned(
                          left: 20.w,
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
                              ),
                              //R type---------------------------
                              AppText(
                                text: restaurant?.type ?? "",
                                size: 25,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4.w),
                                  //R addresss---------------------------
                             
                                  AppText(
                                    text: restaurant?.address ?? "",
                                    size: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
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
                                                borderRadius:
                                                    BorderRadius.circular(6.r),
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
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 150.h,
                      child: ListView.builder(
                        itemCount: 6,
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w),
                            child: Image.asset(
                              'assets/images/restaurantPic.png',
                              height: 150.h,
                              fit: BoxFit.cover,
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
                               text: restaurant?.description??"",
                                 size: 12,
                                fontWeight: FontWeight.w400,
                                color: appTextColor2,
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
                                text: restaurant?.restaurantType??"",
                                size: 12,
                                fontWeight: FontWeight.w400,
                                color: appTextColor2,
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
                                text:
                                restaurant?.address??""    ,
                                      size: 12,
                                fontWeight: FontWeight.w400,
                                color: appTextColor2,
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
                                text: restaurant?.phone??"",
                                size: 12,
                                fontWeight: FontWeight.w400,
                                color: appTextColor2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150.w,
                      height: 40.h,
                      child: AppButton(
                        text: "View Menu",
                        size: 12,
                        borderRadius: 10.r,
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
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Color(0xfff87b0d),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          SizedBox(width: 4.w),
          Text(text, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
