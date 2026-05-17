
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
import 'package:fudikoclient/screens/tabs/reservation/reservationBox.dart';
import 'package:fudikoclient/screens/tabs/reservation/searchBox.dart';
import 'package:fudikoclient/service/reservation/reservation-service.dart';
import 'package:fudikoclient/utils/constants.dart';

class Reservation extends StatefulWidget {
  const Reservation({super.key});

  @override
  State<Reservation> createState() => _ReservationState();
}

class _ReservationState extends State<Reservation> {
  bool isDeletePressed = false;
  bool isConfirmedPressed = false;
  bool isBookingCanceled = false;
  bool isSearchDeletePressed = false;
  bool isPartyRequestPressed = false;
  bool isCateringRequestPressed = false;
  BookingModel? selectedBooking;
  Timer? _bookingCancelTimer;

  // Controls whether we show coupon input or the "Search Restaurant" button
  bool isCouponSearchMode = false;

  String selectedStatus = "Entered the wrong details";
  String selectedFilter = "All Bookings";

  final TextEditingController _couponController = TextEditingController();

  final ReservationService _reservationService = ReservationService();
  final List<BookingModel> _allBookings = [];
  bool _isLoadingBookings = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoadingBookings = true;
      _loadError = null;
    });

    final bookings = await _reservationService.fetchReservations();
    if (!mounted) return;

    setState(() {
      _allBookings
        ..clear()
        ..addAll(bookings);
      _isLoadingBookings = false;
      _loadError = bookings.isEmpty ? 'No reservations found' : null;
    });
  }

void _showBookingCanceledPopup() {
  _bookingCancelTimer?.cancel();

  setState(() {
    isBookingCanceled = true;
  });

  _bookingCancelTimer = Timer(
    const Duration(seconds: 3),
    () {
      if (!mounted) return;

      setState(() {
        isBookingCanceled = false;
      });
    },
  );
}

  List<BookingModel> get _filteredBookings {
    List<BookingModel> result = selectedFilter == "All Bookings"
        ? List.from(_allBookings)
        : _allBookings.where((b) => b.status == selectedFilter).toList();
    result.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return result;
  }

  @override
  void dispose() {
    _couponController.dispose();
     _bookingCancelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: _buildContent(),
          ),
          if (isDeletePressed || isSearchDeletePressed)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: _deleteSearchBox(),
              ),
            ),
          if (isPartyRequestPressed)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: _viewPartyRequestWidget(),
              ),
            ),
          if (isCateringRequestPressed)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: _viewCateringRequestWidget(),
              ),
            ),
          if (isConfirmedPressed)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: _confirmedBox(),
              ),
            ),
          if (isBookingCanceled)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: _bookingCanceledBox(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        SizedBox(height: 20.h),

        // ── Search bar: toggles between button and coupon input ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: isCouponSearchMode
              ? _couponInputField()   // shows coupon text field with close icon
              : _searchRestaurantButton(), // shows tappable "Search Restaurant"
        ),

        SizedBox(height: 20.h),

        // ── Filter dropdown ──
        SizedBox(width: 150.w,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1A000000),
                  offset: const Offset(0, 0),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: AppFilterDropDown(
              hint: selectedFilter,
              imageIconPath: filterIcon,
              imageIconSize: 15.sp,
              toggleDropdown: () {
                showModalBottomSheet(
                  backgroundColor: Colors.white,
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: EdgeInsets.all(30.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              children: [
                                _buildFilterOption("All Bookings"),
                                Divider(color: Colors.grey[200]),
                                _buildFilterOption("Confirmed"),
                                Divider(color: Colors.grey[200]),
                                _buildFilterOption("Rejected"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),

        SizedBox(height: 20.h),

        // ── Booking list ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: _isLoadingBookings
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 60.h),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : _filteredBookings.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 60.h),
                  child: Center(
                    child: AppText(
                      text: _loadError ?? "No bookings found",
                      size: 15,
                      fontWeight: FontWeight.w500,
                      color: appTextColor3,
                      isCentered: true,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredBookings.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final booking = _filteredBookings[index];
                    return SearchBox(
  booking: booking,
  onCancelTap: () {
    selectedBooking = booking;

    if (booking.status == "Confirmed") {
      setState(() {
        isConfirmedPressed = true;
      });
    } else {
      setState(() {
        isSearchDeletePressed = true;
      });
    }
  },
  onRequestTap: () => setState(
    () => isPartyRequestPressed = !isPartyRequestPressed,
  ),
);
                  },
                ),
        ),
      ],
    );
  }

  // ── "Search Restaurant" pill button (default state) ──────
  Widget _searchRestaurantButton() {
    return GestureDetector(
      onTap: () {
        setState(() => isCouponSearchMode = true);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AppText(
            text:"Search Restaurant",
            size: 14,
            fontWeight: FontWeight.w400,
            color: menuIconColor.withOpacity(.8),
          ),
        ),
      ),
    );
  }

  // ── Coupon number input (shown after tapping Search Restaurant) ──
  Widget _couponInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Close button — tapping it goes back to "Search Restaurant"
          GestureDetector(
            onTap: () {
              _couponController.clear();
              setState(() => isCouponSearchMode = false);
            },
            child: Padding(
              padding: EdgeInsets.only(left: 14.w),
              child: Icon(Icons.close, size: 20, color: appTextColor3),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _couponController,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: appTextColor3,
              ),
              decoration: InputDecoration(
                hintText: "Enter the Coupon Number",
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: appTextColor3,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 18.h,
                  horizontal: 20.w,
                ),
              ),
            ),
          ),
          
        ],
      ),
    );
  }

  // ── Filter option tile ────────────────────────────────────
  Widget _buildFilterOption(String label) {
    final bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = label);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: AppText(
          text: label,
          size: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }

  // ── Status buttons ────────────────────────────────────────
  Widget buildStatusButton(String text) {
    final bool isSelected = selectedStatus == text;
    return GestureDetector(
      onTap: () => setState(() => selectedStatus = text),
      child: Container(
        height: 35.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
                )
              : null,
          color: isSelected ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  // ── Overlays ──────────────────────────────────────────────
  Widget _deleteSearchBox() {
  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 25.w,
          vertical: 30.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              text: "Are you sure you want to Cancel this Booking?",
              size: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              isCentered: true,
            ),

            SizedBox(height: 25.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80.w,
                  height: 28.h,
                  child: AppButton(
                    text: "Yes",
                    bgColor1: Color(0xFF73B256),
                    bgColor2: Color(0xFF73B256),
                    size: 12,
                    borderRadius: 6.r,
                    isShadow: true,
                    onPressed: () {
                  setState(() {
                    isSearchDeletePressed = false;
                  });
                
                  _showBookingCanceledPopup();
                },
                  ),
                ),

                SizedBox(width: 15.w),

                SizedBox(
                  width: 80.w,
                  height: 28.h,
                  child: AppButton(
                    isShadow: true,
                    text: "No",
                    bgColor1: Color(0xFFCE3F3F),
                    bgColor2: Color(0xFFCE3F3F),
                    size: 12,
                    borderRadius: 6.r,
                    onPressed: () {
                      setState(() {
                        isSearchDeletePressed = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _bookingCanceledBox() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.black.withOpacity(0.5),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 40.w, right: 40.w, top: 30.h, bottom: 30.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
onTap: () {
  _bookingCancelTimer?.cancel();

  setState(() {
    isBookingCanceled = false;
  });
},                        child: Icon(Icons.close, size: 30, color: appTextColor),
                      ),
                    ],
                  ),
                  Image.asset(
                    cancelImageIcon,
                    height: 60.h,
                    width: 60.w,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Booking Canceled!",
                    size: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCE3F3F),
                    isCentered: true,
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirmedBox() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.black.withOpacity(0.5),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 40.w, right: 40.w, top: 30.h, bottom: 30.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    text: "Are you sure you want to Cancel this Booking?",
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    isCentered: true,
                  ),
                  SizedBox(height: 10.h),
                  AppText(
                    text: "Cancelling a confirmed order may negatively impact your reliability rating",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    isCentered: true,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 35.h,
                          child: AppButton(
                            text: "Yes",
                           onPressed: () {
  setState(() {
    isDeletePressed = false;
    isConfirmedPressed = false;
  });

  _showBookingCanceledPopup();
},
                            borderRadius: 5.r,
                            bgColor1: Colors.green,
                            bgColor2: Colors.green,
                            size: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: SizedBox(
                          height: 35.h,
                          child: AppButton(
                            text: "No",
                            onPressed: () => setState(() => isConfirmedPressed = false),
                            size: 12,
                            borderRadius: 5.r,
                            bgColor1: Colors.red,
                            bgColor2: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _viewCateringRequestWidget() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(text: "Requested party", size: 15, fontWeight: FontWeight.w500, color: appTextColor2),
                      GestureDetector(
                        onTap: () => setState(() => isCateringRequestPressed = false),
                        child: Icon(Icons.close, color: appTextColor3, size: 25),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(text: "P17854", size: 20, fontWeight: FontWeight.w700, color: appTextColor3),
                  ),
                  SizedBox(height: 20.h),
                  AppText(text: "Catering request details here", size: 15, fontWeight: FontWeight.w400, color: appTextColor2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewPartyRequestWidget() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(text: "Requested party", size: 15, fontWeight: FontWeight.w500, color: appTextColor2),
                      GestureDetector(
                        onTap: () => setState(() => isPartyRequestPressed = false),
                        child: Icon(Icons.close, color: appTextColor3, size: 25),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(text: "P17854", size: 20, fontWeight: FontWeight.w700, color: appTextColor3),
                  ),
                  SizedBox(height: 20.h),
                  AppText(text: "Party request details here", size: 15, fontWeight: FontWeight.w400, color: appTextColor2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



























// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fudikoclient/components/appbutton.dart';
// import 'package:fudikoclient/components/appfilterdropdown.dart';
// import 'package:fudikoclient/components/apptext.dart';
// import 'package:fudikoclient/components/apptextfeild.dart';
// import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
// import 'package:fudikoclient/screens/tabs/reservation/reservationBox.dart';
// import 'package:fudikoclient/screens/tabs/reservation/searchBox.dart';
// import 'package:fudikoclient/utils/constants.dart';

// class Reservation extends StatefulWidget {
//   const Reservation({super.key});

//   @override
//   State<Reservation> createState() => _ReservationState();
// }

// class _ReservationState extends State<Reservation> {
//   bool isDeletePressed = false;
//   bool isConfirmedPressed = false;
//   bool isBookingCanceled = false;
//   bool isPartySearchPressed = false;
//   bool isCateringSearchPressed = false;
//   bool isSearchDeletePressed = false;
//   bool isPartyRequestPressed = false;
//   bool isCateringRequestPressed = false;
//   String selectedStatus = "Entered the wrong details";
//   String mainSelectedStatus = "Party";



//   String selectedFilter = "All Bookings";

//   //----------------temp data------------------
//   // ── Sample data ──────────────────────────────────────────
//   final List<BookingModel> _allBookings = [
//     BookingModel(
//       couponId: "P17854",
//       restaurantName: "Bollywood Restaurant",
//       pricePerPerson: 950,
//       discount: 5,
//       message: "If you have more than 50 people, we can offer 850 per head.",
//       eventDate: DateTime(2025, 4, 12, 14, 30),
//       bookingDate: DateTime(2025, 4, 11, 12, 30),
//       persons: 12,
//       status: "Confirmed",
//     ),
//     BookingModel(
//       couponId: "P17855",
//       restaurantName: "Spice Garden",
//       pricePerPerson: 800,
//       discount: 10,
//       message: "Complimentary welcome drinks for groups above 30.",
//       eventDate: DateTime(2025, 4, 20, 19, 0),
//       bookingDate: DateTime(2025, 4, 15, 10, 0),
//       persons: 40,
//       status: "Rejected",
//     ),
//     BookingModel(
//       couponId: "P17856",
//       restaurantName: "The Grand Feast",
//       pricePerPerson: 1200,
//       discount: 3,
//       message: "Special dessert platter for groups above 20.",
//       eventDate: DateTime(2025, 5, 1, 13, 0),
//       bookingDate: DateTime(2025, 4, 18, 9, 0),
//       persons: 25,
//       status: "Confirmed",
//     ),
//   ];

//   // ── Filtered + sorted list getter ────────────────────────
//   List<BookingModel> get _filteredBookings {
//     List<BookingModel> result = selectedFilter == "All Bookings"
//         ? List.from(_allBookings)
//         : _allBookings.where((b) => b.status == selectedFilter).toList();

//     // Sort latest bookingDate first
//     result.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
//     return result;
//   }

//   //----------------temp data------------------


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: appSecondaryBackgroundColor,
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             // child: mainSelectedStatus == "Party" ? isPartySearchPressed ? _viewSearchWidget() : _buildMain()
//             //       : isCateringSearchPressed ? _viewCateringSearchWidget() : _buildCateringMain(),
//             child: isPartySearchPressed ? _viewSearchWidget() : _buildMain(),
//           ),
//           // Padding(
//           //   padding:  EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
//           //   child:
//           //   Row(
//           //     children: [
//           //       Expanded(child: buildMainStatusButton("Party")),
//           //       SizedBox(width: 10.w),
//           //       Expanded(child: buildMainStatusButton("Catering")),
//           //     ],
//           //   ),
//           // ),
//           if (isDeletePressed)
//             Positioned.fill(
//               child: Container(color: Colors.black38, child: _deleteBox()),
//             ),
//           if (isPartyRequestPressed)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black38,
//                 child: _viewPartyRequestWidget(),
//               ),
//             ),
//           if (isCateringRequestPressed)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black38,
//                 child: _viewCateringRequestWidget(),
//               ),
//             ),
//           if (isSearchDeletePressed)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black38,
//                 child: _deleteSearchBox(),
//               ),
//             ),
//           if (isConfirmedPressed)
//             Positioned.fill(
//               child: Container(color: Colors.black38, child: _confirmedBox()),
//             ),
//           if (isBookingCanceled)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black38,
//                 child: _bookingCanceledBox(),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // Widget _viewCateringSearchWidget(){
//   //   return Column(
//   //     children: [
//   //       GestureDetector(
//   //         onTap: () {
//   //           setState(() {
//   //             isCateringSearchPressed = !isCateringSearchPressed;
//   //           });
//   //         },
//   //         child: Padding(
//   //           padding:  EdgeInsets.only(left: 20.w, right: 20.w, top: 80.h),
//   //           child: AppTextFeild(
//   //             text: "Enter the Coupon Number",
//   //             textColor: appTextColor3,
//   //             isTextCenter: true,
//   //             icon: Icons.close,
//   //             iconColor: appTextColor3,
//   //             size: 13.sp,
//   //           ),
//   //         ),
//   //       ),
//   //       SizedBox(height: 20.h),
//   //       SizedBox(
//   //         width: 200,
//   //         child: AppFilterDropDown(
//   //           hint: "filter",
//   //           icon: Icons.tune_outlined,
//   //           toggleDropdown: () {
//   //             showModalBottomSheet(
//   //               backgroundColor: Colors.white,
//   //               context: context,
//   //               isScrollControlled: true,
//   //               shape: const RoundedRectangleBorder(
//   //                 borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//   //               ),
//   //               builder: (context) {
//   //                 return Padding(
//   //                   padding:  EdgeInsets.all(30.w),
//   //                   child: Column(
//   //                     mainAxisSize: MainAxisSize.min,
//   //                     children: [
//   //                       Container(
//   //                         width: 40,
//   //                         height: 5,
//   //                         decoration: BoxDecoration(
//   //                           color: Colors.grey[300],
//   //                           borderRadius: BorderRadius.circular(10),
//   //                         ),
//   //                       ),
//   //                       SizedBox(height: 16.h),
//   //                       Container(
//   //                         width: MediaQuery.of(context).size.width,
//   //                         decoration: BoxDecoration(
//   //                           color: Colors.white,
//   //                           borderRadius: BorderRadius.circular(20),
//   //                         ),
//   //                         padding:  EdgeInsets.all(16.w),
//   //                         child: Column(
//   //                           children: [
//   //                             Divider(color: Colors.grey[200]),
//   //                             SizedBox(height: 10.h),
//   //                             AppText(
//   //                               text: "item1",
//   //                               size: 15,
//   //                               fontWeight: FontWeight.w500,
//   //                               color: Colors.black,
//   //                             ),
//   //                             SizedBox(height: 10.h),
//   //                             Divider(color: Colors.grey[200]),
//   //                             SizedBox(height: 10.h),
//   //                             AppText(
//   //                               text: "item2",
//   //                               size: 15,
//   //                               fontWeight: FontWeight.w500,
//   //                               color: Colors.black,
//   //                             ),
//   //                             SizedBox(height: 10.h),
//   //                             Divider(color: Colors.grey[200]),
//   //                             SizedBox(height: 10.h),
//   //                             AppText(
//   //                               text: "item3",
//   //                               size: 15,
//   //                               fontWeight: FontWeight.w500,
//   //                               color: Colors.black,
//   //                             ),
//   //                             SizedBox(height: 10.h),
//   //                             Divider(color: Colors.grey[200]),
//   //                           ],
//   //                         ),
//   //                       ),
//   //                     ],
//   //                   ),
//   //                 );
//   //               },
//   //             );
//   //           },
//   //         ),
//   //       ),
//   //       SizedBox(height: 20.h),
//   //       Padding(
//   //         padding:  EdgeInsets.symmetric(horizontal: 20.w),
//   //         child: ListView.builder(
//   //           itemCount: 3,
//   //           shrinkWrap: true,
//   //           physics: const NeverScrollableScrollPhysics(),
//   //           itemBuilder: (context, index) {
//   //             return SearchBox(
//   //               onCancelTap: () {
//   //                 setState(() {
//   //                   isSearchDeletePressed = !isSearchDeletePressed;
//   //                 });
//   //               },
//   //               onRequestTap: () {
//   //                 setState(() {
//   //                   isCateringRequestPressed = !isCateringRequestPressed;
//   //                 });
//   //               },
//   //             );
//   //           },
//   //         ),
//   //       ),
//   //     ],
//   //   );
//   // }

//   // Widget _buildCateringMain(){
//   //   return Column(
//   //     children: [
//   //       GestureDetector(
//   //         onTap: () {
//   //           setState(() {
//   //             isCateringSearchPressed = !isCateringSearchPressed;
//   //           });
//   //         },
//   //         child: Padding(
//   //           padding:  EdgeInsets.only(left: 30.w, right: 30.w, top: 80.h),
//   //           child: Container(
//   //             padding:  EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
//   //             decoration: BoxDecoration(
//   //               color: Colors.white,
//   //               borderRadius: BorderRadius.circular(20),
//   //               boxShadow: [
//   //                 BoxShadow(
//   //                   color: Colors.black.withOpacity(0.2),
//   //                   blurRadius: 10,
//   //                   offset: const Offset(0, 4),
//   //                 ),
//   //               ],
//   //             ),
//   //             child: Center(
//   //               child: Text(
//   //                 "Search Restaurant",
//   //                 style: TextStyle(
//   //                   fontSize: 16,
//   //                   fontWeight: FontWeight.w400,
//   //                   color: appTextColor3,
//   //                 ),
//   //               ),
//   //             ),
//   //           ),
//   //         ),
//   //       ),
//   //       SizedBox(height: 20.h),
//   //       SizedBox(
//   //         width: 200,
//   //         child: AppFilterDropDown(
//   //           hint: "filter",
//   //           icon: Icons.tune_outlined,
//   //           toggleDropdown: () {
//   //             showModalBottomSheet(
//   //               backgroundColor: Colors.white,
//   //               context: context,
//   //               isScrollControlled: true,
//   //               shape: const RoundedRectangleBorder(
//   //                 borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//   //               ),
//   //               builder: (context) {
//   //                 return Padding(
//   //                   padding:  EdgeInsets.all(30.w),
//   //                   child: Column(
//   //                     mainAxisSize: MainAxisSize.min,
//   //                     children: [
//   //                       Container(
//   //                         width: 40,
//   //                         height: 5,
//   //                         decoration: BoxDecoration(
//   //                           color: Colors.grey[300],
//   //                           borderRadius: BorderRadius.circular(10),
//   //                         ),
//   //                       ),
//   //                       SizedBox(height: 16.h),
//   //                       Container(
//   //                         width: MediaQuery.of(context).size.width,
//   //                         decoration: BoxDecoration(
//   //                           color: Colors.white,
//   //                           borderRadius: BorderRadius.circular(20),
//   //                         ),
//   //                         padding:  EdgeInsets.all(16.w),
//   //                         child: Column(
//   //                           children: [
//   //                             Divider(color: Colors.grey[200]),
//   //                             SizedBox(height: 10.h),
//   //                             AppText(
//   //                               text: "item1",
//   //                               size: 15,
//   //                               fontWeight: FontWeight.w500,
//   //                               color: Colors.black,
//   //                             ),
//   //                             SizedBox(height: 10.h),
//   //                             Divider(color: Colors.grey[200]),
//   //                             SizedBox(height: 10.h),
//   //                             AppText(
//   //                               text: "item2",
//   //                               size: 15,
//   //                               fontWeight: FontWeight.w500,
//   //                               color: Colors.black,
//   //                             ),
//   //                             SizedBox(height: 10.h),
//   //                             Divider(color: Colors.grey[200]),
//   //                             SizedBox(height: 10.h),
//   //                             AppText(
//   //                               text: "item3",
//   //                               size: 15,
//   //                               fontWeight: FontWeight.w500,
//   //                               color: Colors.black,
//   //                             ),
//   //                             SizedBox(height: 10.h),
//   //                             Divider(color: Colors.grey[200]),
//   //                           ],
//   //                         ),
//   //                       ),
//   //                     ],
//   //                   ),
//   //                 );
//   //               },
//   //             );
//   //           },
//   //         ),
//   //       ),
//   //       SizedBox(height: 20.h),
//   //       Padding(
//   //         padding:  EdgeInsets.symmetric(horizontal: 20.w),
//   //         child: ListView.builder(
//   //           itemCount: 1,
//   //           shrinkWrap: true,
//   //           physics: const NeverScrollableScrollPhysics(),
//   //           itemBuilder: (context, index) {
//   //             return ReservationBox(
//   //               onCancelTap: () {
//   //                 setState(() {
//   //                   isDeletePressed = !isDeletePressed;
//   //                 });
//   //               },
//   //             );
//   //           },
//   //         ),
//   //       ),
//   //     ],
//   //   );
//   // }

//   Widget _buildMain() {
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: () {
//             setState(() {
//               isPartySearchPressed = !isPartySearchPressed;
//             });
//           },
//           child: Padding(
//             padding:  EdgeInsets.only(left: 20.w, right: 20.w, top: 20.h),
//             child: Container(
//               padding:  EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Text(
//                   "Search Restaurant",
//                   style: TextStyle(
//                     fontSize: 13.sp,
//                     fontWeight: FontWeight.w400,
//                     color: appTextColor3,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         SizedBox(height: 20.h),
//         SizedBox(
//           width: 200,
//           child: AppFilterDropDown(
//             hint: "filter",
//             icon: Icons.tune_outlined,
//             toggleDropdown: () {
//               showModalBottomSheet(
//                 backgroundColor: Colors.white,
//                 context: context,
//                 isScrollControlled: true,
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//                 ),
//                 builder: (context) {
//                   return Padding(
//                     padding:  EdgeInsets.all(30.w),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           width: 40,
//                           height: 5,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         SizedBox(height: 16.h),
//                         Container(
//                           width: MediaQuery.of(context).size.width,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           padding:  EdgeInsets.all(16.w),
//                           child: Column(
//                             children: [
//                               Divider(color: Colors.grey[200]),
//                               SizedBox(height: 10.h),
//                               AppText(
//                                 text: "item1",
//                                 size: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black,
//                               ),
//                               SizedBox(height: 10.h),
//                               Divider(color: Colors.grey[200]),
//                               SizedBox(height: 10.h),
//                               AppText(
//                                 text: "item2",
//                                 size: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black,
//                               ),
//                               SizedBox(height: 10.h),
//                               Divider(color: Colors.grey[200]),
//                               SizedBox(height: 10.h),
//                               AppText(
//                                 text: "item3",
//                                 size: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black,
//                               ),
//                               SizedBox(height: 10.h),
//                               Divider(color: Colors.grey[200]),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//         SizedBox(height: 20.h),
//         Padding(
//           padding:  EdgeInsets.symmetric(horizontal: 20.w),
//           child: ListView.builder(
//             itemCount: 3,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemBuilder: (context, index) {
//               return ReservationBox(
//                 onCancelTap: () {
//                   setState(() {
//                     isDeletePressed = !isDeletePressed;
//                   });
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _viewSearchWidget() {
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: () {
//             setState(() {
//               isPartySearchPressed = !isPartySearchPressed;
//             });
//           },
//           child: Padding(
//             padding:  EdgeInsets.only(left: 20.w, right: 20.w, top: 80.h),
//             child: AppTextFeild(
//               text: "Enter the Coupon Number",
//               textColor: appTextColor3,
//               isTextCenter: true,
//               icon: Icons.close,
//               iconColor: appTextColor3,
//               size: 13.sp,
//             ),
//           ),
//         ),
//         SizedBox(height: 20.h),
//         SizedBox(
//           width: 200,
//           child: AppFilterDropDown(
//             hint: "filter",
//             icon: Icons.tune_outlined,
//             toggleDropdown: () {
//               showModalBottomSheet(
//                 backgroundColor: Colors.white,
//                 context: context,
//                 isScrollControlled: true,
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//                 ),
//                 builder: (context) {
//                   return Padding(
//                     padding:  EdgeInsets.all(30.w),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           width: 40,
//                           height: 5,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         SizedBox(height: 16.h),
//                         Container(
//                           width: MediaQuery.of(context).size.width,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           padding:  EdgeInsets.all(16.w),
//                           child: Column(
//                             children: [
//                               Divider(color: Colors.grey[200]),
//                               SizedBox(height: 10.h),
//                               AppText(
//                                 text: "item1",
//                                 size: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black,
//                               ),
//                               SizedBox(height: 10.h),
//                               Divider(color: Colors.grey[200]),
//                               SizedBox(height: 10.h),
//                               AppText(
//                                 text: "item2",
//                                 size: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black,
//                               ),
//                               SizedBox(height: 10.h),
//                               Divider(color: Colors.grey[200]),
//                               SizedBox(height: 10.h),
//                               AppText(
//                                 text: "item3",
//                                 size: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black,
//                               ),
//                               SizedBox(height: 10.h),
//                               Divider(color: Colors.grey[200]),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//         SizedBox(height: 20.h),
//         Padding(
//               padding:  EdgeInsets.symmetric(horizontal: 20.w),
//           child: ListView.builder(
//             itemCount: 3,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemBuilder: (context, index) {
//               final booking = _filteredBookings[index];
//               return SearchBox(
//                 onCancelTap: () {
//                   setState(() {
//                     isSearchDeletePressed = !isSearchDeletePressed;
//                   });
//                 },
//                 onRequestTap: () {
//                   setState(() {
//                     isPartyRequestPressed = !isPartyRequestPressed;
//                   });
//                 }, booking: booking,
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _deleteSearchBox() {
//     return Stack(
//       children: [
//         Container(
//           height: MediaQuery.of(context).size.height,
//           width: MediaQuery.of(context).size.width,
//           decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
//         ),
//         Center(
//           child: Padding(
//             padding:  EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding:  EdgeInsets.only(
//                 left: 40.w,
//                 right: 40.w,
//                 top: 30.h,
//                 bottom: 30.h,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10.r,
//                     offset: Offset(0, 4.r),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     children: [
//                       AppText(
//                         text: "Reason for Cancel",
//                         size: 13,
//                         fontWeight: FontWeight.w500,
//                         color: appTextColor3,
//                         isCentered: true,
//                       ),
//                       Spacer(),
//                       Icon(Icons.close, size: 25, color: appTextColor3),
//                     ],
//                   ),

//                   SizedBox(height: 20.h),
//                   SizedBox(
//                     height: 40.h,
//                     child: buildStatusButton("I changed my mind"),
//                   ),
//                   SizedBox(height: 10.h),
//                   SizedBox(
//                     height: 40.h,
//                     child: buildStatusButton("I need to reschedule the event"),
//                   ),
//                   SizedBox(height: 10.h),
//                   SizedBox(
//                     height: 40.h,
//                     child: buildStatusButton("Entered the wrong details"),
//                   ),
//                   SizedBox(height: 10.h),
//                   SizedBox(
//                     height: 40.h,
//                     child: buildStatusButton("I booked by mistake"),
//                   ),
//                   SizedBox(height: 10.h),
//                   SizedBox(
//                     height: 40.h,
//                     child: buildStatusButton("Other Reasons"),
//                   ),
//                   SizedBox(height: 40.h),
//                   AppText(
//                     text:
//                         "Canceling a confirmed booking may negatively impact your reliability rating.",
//                     size: 13,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black,
//                     isCentered: true,
//                   ),
//                   SizedBox(height: 10.h),
//                   AppText(
//                     text:
//                         "However, if you accept another response instead, the previous booking will be automatically replaced without affecting your rating.",
//                     size: 13,
//                     fontWeight: FontWeight.w400,
//                     color: appTextColor2,
//                     isCentered: true,
//                   ),
//                   SizedBox(height: 20.h),
//                   AppText(
//                     text: "Accept another response",
//                     size: 15,
//                     fontWeight: FontWeight.w400,
//                     color: appLinkColor2,
//                     isCentered: true,
//                   ),
//                   SizedBox(height: 20.h ),
//                   SizedBox(
//                     width: 150,
//                     height: 40,
//                     child: AppButton(
//                       text: "Cancel",
//                       bgColor1: Colors.red,
//                       bgColor2: Colors.red,
//                       size: 15,
//                       borderRadius: 10,
//                       onPressed: () {
//                         setState(() {
//                           isSearchDeletePressed = !isSearchDeletePressed;
//                           isBookingCanceled = !isBookingCanceled;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget buildStatusButton(String text) {
//     final bool isSelected = selectedStatus == text;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedStatus = text;
//         });
//       },
//       child: Container(
//         height: 35.h,
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           gradient: isSelected
//               ? const LinearGradient(
//                   colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
//                 )
//               : null,
//           color: isSelected ? null : Colors.grey[200],
//           borderRadius: BorderRadius.circular(10),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               offset: const Offset(2, 2),
//             ),
//           ],
//         ),
//         child: Text(
//           text,
//           style: TextStyle(
//             fontSize: 13.sp,
//             fontWeight: FontWeight.w500,
//             color: isSelected ? Colors.white : Colors.black,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildMainStatusButton(String text) {
//     final bool isSelected = mainSelectedStatus == text;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           mainSelectedStatus = text;
//         });
//       },
//       child: Container(
//         height: 35.h,
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           gradient: isSelected
//               ? const LinearGradient(
//                   colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
//                 )
//               : null,
//           color: isSelected ? null : Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 5,
//               offset: const Offset(2, 2),
//             ),
//           ],
//         ),
//         child: Text(
//           text,
//           style: TextStyle(
//             fontSize: 13.sp,
//             fontWeight: FontWeight.w500,
//             color: isSelected ? Colors.white : appTextColor3,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _bookingCanceledBox() {
//     return Stack(
//       children: [
//         Container(
//           height: MediaQuery.of(context).size.height,
//           width: MediaQuery.of(context).size.width,
//           decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
//           ),
//         Center(
//           child: Padding(
//             padding:  EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding:  EdgeInsets.only(
//                 left: 40.w,
//                 right: 40.w,
//                 top: 30.h,
//                 bottom: 30.h,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10.r,
//                     offset: Offset(0, 4.r),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             if (isDeletePressed) {
//                               isDeletePressed = !isDeletePressed;
//                             }
//                             isBookingCanceled = !isBookingCanceled;
//                           });
//                         },
//                         child: Icon(Icons.close, size: 30, color: appTextColor),
//                       ),
//                     ],
//                   ),
//                   Image.asset(
//                     'assets/images/cancel.png',
//                     height: 60.h,
//                     width: 60.w,
//                     fit: BoxFit.contain,
//                   ),
//                   SizedBox(height: 20.h),
//                   AppText(
//                     text: "Booking Canceled!",
//                     size: 20,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.red,
//                     isCentered: true,
//                   ),
//                   SizedBox(height: 20.h),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _confirmedBox() {
//     return Stack(
//       children: [
//         Container(
//           height: MediaQuery.of(context).size.height,
//           width: MediaQuery.of(context).size.width,
//           decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
//         ),
//         Center(
//           child: Padding(
//             padding:  EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding:  EdgeInsets.only(
//                 left: 40.w,
//                 right: 40.w,
//                 top: 30.h,
//                 bottom: 30.h,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10.r,
//                     offset: Offset(0, 4.r),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   AppText(
//                     text: "Are you sure you want to Cancel this Booking?",
//                     size: 15,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black,
//                     isCentered: true,
//                   ),
//                   SizedBox(height: 10.h),
//                   AppText(
//                     text:
//                         "Cancelling a confirmed order may negatively impact your reliability rating",
//                     size: 15,
//                     fontWeight: FontWeight.w400,
//                     color: Colors.black,
//                     isCentered: true,
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: SizedBox(
//                           height: 35.h,
//                           child: AppButton(
//                             text: "Yes",
//                             onPressed: () {
//                               setState(() {
//                                 isDeletePressed = !isDeletePressed;
//                                 isConfirmedPressed = !isConfirmedPressed;
//                                 isBookingCanceled = !isBookingCanceled;
//                               });
//                             },
//                               borderRadius: 5.r,
//                             bgColor1: Colors.green,
//                             bgColor2: Colors.green,
//                             size: 12,
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 20.w),
//                       Expanded(
//                         child: SizedBox(
//                           height: 35.h,
//                           child: AppButton(
//                             text: "No",
//                             onPressed: () {
//                               setState(() {
//                                 isDeletePressed = !isDeletePressed;
//                               });
//                             },
//                                 size: 12,
//                             borderRadius: 5.r,
//                             bgColor1: Colors.red,
//                             bgColor2: Colors.red,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _deleteBox() {
//     return Stack(
//       children: [
//         Container(
//           height: MediaQuery.of(context).size.height,
//           width: MediaQuery.of(context).size.width,
//           decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
//         ),
//         Center(
//           child: Padding(
//             padding:  EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding:  EdgeInsets.only(
//                 left: 40.w,
//                 right: 40.w,
//                 top: 30.h,
//                 bottom: 30.h,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10.r,
//                     offset: Offset(0, 4.r),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   AppText(
//                     text: "Are you sure you want to Cancel this Booking?",
//                     size: 13,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black,
//                     isCentered: true,
//                     lineSpacing: 1.2,
//                   ),
//                   SizedBox(height: 10.h ),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: SizedBox(
//                           height: 35.h,
//                           child: AppButton(
//                             text: "Yes",
//                             onPressed: () {
//                               setState(() {
//                                 isDeletePressed = !isDeletePressed;
//                                 isConfirmedPressed = !isConfirmedPressed;
//                               });
//                             },
//                             borderRadius: 5.r,
//                             bgColor1: Colors.green,
//                             bgColor2: Colors.green,
//                             size: 12,
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 20.w),
//                       Expanded(
//                         child: SizedBox(
//                           height: 35.h,
//                           child: AppButton(
//                             text: "No",
//                             onPressed: () {
//                               setState(() {
//                                 isDeletePressed = !isDeletePressed;
//                               });
//                             },
//                               size: 12,
//                             borderRadius: 5.r,
//                             bgColor1: Colors.red,
//                             bgColor2: Colors.red,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _viewCateringRequestWidget(){
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding:  EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding:  EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       AppText(
//                         text: "Requested party",
//                         size: 15,
//                         fontWeight: FontWeight.w500,
//                         color: appTextColor2,
//                       ),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             isCateringRequestPressed = !isCateringRequestPressed;
//                           });
//                         },
//                         child: Icon(
//                           Icons.close,
//                           color: appTextColor3,
//                           size: 25,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: AppText(
//                       text: "P17854",
//                       size: 20,
//                       fontWeight: FontWeight.w700,
//                       color: appTextColor3,
//                     ),
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.dashboard, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Your Menu",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text:
//                                   "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.handshake, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Other Services",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "7 Service boys needed.",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.people, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w  ),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Number of Persons",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "12 Person ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(
//                         Icons.calendar_today_sharp,
//                         size: 20,
//                         color: appTextColor2,
//                       ),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Date and Time ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "April 12 - 2:30 pm",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.wallet, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Expected amount per person",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "1000 Per person",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.analytics, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Enquiry Radius ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "Moscow City - 20km Radius",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }



//   Widget _viewPartyRequestWidget() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding:  EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding:  EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       AppText(
//                         text: "Requested party",
//                         size: 15,
//                         fontWeight: FontWeight.w500,
//                         color: appTextColor2,
//                       ),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             isPartyRequestPressed = !isPartyRequestPressed;
//                           });
//                         },
//                         child: Icon(
//                           Icons.close,
//                           color: appTextColor3,
//                           size: 25,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: AppText(
//                       text: "P17854",
//                       size: 20,
//                       fontWeight: FontWeight.w700,
//                       color: appTextColor3,
//                     ),
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.dashboard, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Your Menu",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text:
//                                   "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.people, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Number of Persons",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "12 Person ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(
//                         Icons.calendar_today_sharp,
//                         size: 20,
//                         color: appTextColor2,
//                       ),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Date and Time ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h  ),
//                             AppText(
//                               text: "April 12 - 2:30 pm",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.wallet, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Expected amount per person",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "1000 Per person",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.analytics, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Enquiry Radius ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "Moscow City - 20km Radius",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
