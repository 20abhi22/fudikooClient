import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/appsearchbar.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/screens/tabs/components/restaurantCard.dart';
import 'package:fudikoclient/screens/tabs/home/addnumberofpeople.dart';
import 'package:fudikoclient/screens/tabs/home/filterbottommodal.dart';
import 'package:fudikoclient/screens/tabs/home/rating.dart';
import 'package:fudikoclient/screens/tabs/home/timebottommodal.dart';
import 'package:fudikoclient/screens/tabs/profile/restaurantProfile.dart';
import 'package:fudikoclient/service/restaurant/restaurant-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';

class Home extends StatefulWidget {
  const Home({super.key});

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
  // bool _mounted = true;

  @override
  void initState() {
    getAllRestaurtantList();

    super.initState();
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
  void applyFilters(int? discountIndex, int? typeIndex, double distance) {
    setState(() {
      selectedDiscountIndex = discountIndex;
      selectedTypeIndex = typeIndex;
      selectedDistance = distance;

      filteredList = restaurantsList.where((r) {
        // filter by type
        if (typeIndex != null) {
          final types = ["Restaurant", "Cafe", "Cool Bar", "Bar", "Buffet"];
          if (!r.type.toLowerCase().contains(types[typeIndex].toLowerCase())) {
            return false;
          }
        }
        return true;
      }).toList();
    });
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
        filteredList = response.restaurant;
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

  @override
  Widget build(BuildContext context) {
    // bool isLoading = false;
    // String errorMessage = '';
    return Scaffold(
      backgroundColor: Color(0xfffdf8f5),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 25.h),
                child: AppSearchBar(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _discountBuilder(),
                      _mapBuilder(),
                      _dropDownBuilder(),

                      // ListView.builder(
                      //   // itemCount: restaurantsList.length,
                      //   itemCount: filteredList.length,
                      //   shrinkWrap: true,
                      //   physics: const NeverScrollableScrollPhysics(),
                      //   itemBuilder: (context, index) {
                      //     // isLoading
                      //     //     ? Center(child: CircularProgressIndicator())
                      //     //     : errorMessage != null
                      //     //     ? Center(child: Text('Error: $errorMessage'))
                      //     //     : restaurantsList.isEmpty
                      //     //     ? Center(child: Text('No restaurants found'))
                      //     //     : ListView.builder(
                      //     //         itemCount: restaurantsList.length,
                      //     //         shrinkWrap: true,
                      //     //         physics: const NeverScrollableScrollPhysics(),
                      //     //         itemBuilder: (context, index) {
                      //     //final restaurant = restaurantsList[index];
                      //     final restaurant = filteredList[index];

                      //     return GestureDetector(
                      //       onTap: () {
                      //         setState(() {
                      //           isClicked = true;
                      //         });
                      //       },
                      //       child: InkWell(
                      //         onTap: () {
                      //           Navigator.push(
                      //             context,
                      //             MaterialPageRoute(
                      //               builder: (context) => RestaurantProfile(
                      //                 uuid: restaurant.uuid,
                      //               ),
                      //             ),
                      //           );
                      //         },
                      //         child: RestaurantCard(
                      //           uuid: restaurant.uuid,
                      //           name: restaurant.name,
                      //           type: restaurant.type,
                      //           address: restaurant.address,
                      //           phone: restaurant.phone,
                      //           lat: restaurant.lat,
                      //           lng: restaurant.lng,
                      //           description: restaurant.description,
                      //           availableDishes: restaurant.availableDishes,
                      //           takeAwayService: restaurant.takeAwayService,
                      //           deliveryService: restaurant.deliveryService,
                      //           deliveryServiceArea:
                      //               restaurant.deliveryServiceArea,
                      //           restaurantType: restaurant.restaurantType,
                      //           status: restaurant.status,
                      //           isFavourite: restaurant.isFavorite,
                      //           onRatingOnClick: () {
                      //             Navigator.push(
                      //               context,
                      //               MaterialPageRoute(
                      //                 builder: (context) => RatingPage(),
                      //               ),
                      //             );
                      //           },
                      //           onBoxClicked: () {
                      //             setState(() {
                      //               isBookingModalOpen = !isBookingModalOpen;
                      //             });
                      //             if (isBookingModalOpen) {
                      //               showModalBottomSheet(
                      //                 backgroundColor: Colors.white,
                      //                 context: context,
                      //                 isScrollControlled: true,
                      //                 shape: const RoundedRectangleBorder(
                      //                   borderRadius: BorderRadius.vertical(
                      //                     top: Radius.circular(25),
                      //                   ),
                      //                 ),
                      //                 builder: (context) {
                      //                   return NumberOfPeopleModal(
                      //                     uuid: restaurant.uuid,
                      //                   );
                      //                 },
                      //               );
                      //             }
                      //           },
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                      isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 50),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : errorMessage.isNotEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 50),
                                child: AppText(
                                  text: 'Error: $errorMessage',
                                  size: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.red,
                                ),
                              ),
                            )
                          : filteredList.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 50),
                                child: Column(
                                  children: [
                                    Icon(
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
                            )
                          : ListView.builder(
                              itemCount: filteredList.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final restaurant = filteredList[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isClicked = true;
                                    });
                                  },
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RestaurantProfile(
                                                uuid: restaurant.uuid,
                                              ),
                                        ),
                                      );
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
                                      availableDishes:
                                          restaurant.availableDishes,
                                      takeAwayService:
                                          restaurant.takeAwayService,
                                      deliveryService:
                                          restaurant.deliveryService,
                                      deliveryServiceArea:
                                          restaurant.deliveryServiceArea,
                                      restaurantType: restaurant.restaurantType,
                                      status: restaurant.status,
                                      isFavourite: restaurant.isFavorite,
                                      onRatingOnClick: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RatingPage(),
                                          ),
                                        );
                                      },
                                      onBoxClicked: () {
                                        setState(() {
                                          isBookingModalOpen =
                                              !isBookingModalOpen;
                                        });
                                        if (isBookingModalOpen) {
                                          showModalBottomSheet(
                                            backgroundColor: Colors.white,
                                            context: context,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(25),
                                                  ),
                                            ),
                                            builder: (context) {
                                              return NumberOfPeopleModal(
                                                uuid: restaurant.uuid,
                                              );
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropDownBuilder() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          SizedBox(
            width: 120.w,
            child: AppFilterDropDown(
              hint: "Filter",
              icon: Icons.tune_outlined,
              toggleDropdown: () {
                showModalBottomSheet(
                  backgroundColor: Colors.white,
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  builder: (context) {
                    return FilterBottomModal(onApply: applyFilters);
                  },
                );
              },
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: AppFilterDropDown(
              hint: selectedDateTime != null
                  ? "${selectedDateTime!.day}/${selectedDateTime!.month} at ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}"
                  : "Today at 12:00PM",
              icon: Icons.event_available,
              toggleDropdown: () {
                showModalBottomSheet(
                  backgroundColor: Colors.white,
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  builder: (context) {
                    return TimeBottomModal(
                      onApply: (dateTime) {
                        setState(() {
                          selectedDateTime = dateTime;
                        });
                      },
                    );
                  },
                );
              },
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
      {'color2': Color(0xFF9038b8), 'color1': Color(0XFF502066)},
      {'color2': Color(0xFF61b439), 'color1': Color(0xFF33601f)},
      {'color2': Color(0xFF369cb3), 'color1': Color(0xFF1f5663)},
      {'color2': Color(0xFFb79d38), 'color1': Color(0xFF64541e)},
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
                        text: "20%-30%",
                        size: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        text: "Discount",
                        size: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      SizedBox(height: 5.h),
                      Image.asset(
                        'assets/images/discounttag.png',
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
}
