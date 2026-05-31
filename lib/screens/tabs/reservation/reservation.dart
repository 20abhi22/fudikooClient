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
  bool _isCancellingBooking = false;
  BookingModel? selectedBooking;
  Timer? _bookingCancelTimer;
  Timer? _searchDebounce;
  int _searchRequestToken = 0;

  bool _isSearchActive = false;

  String selectedStatus = "Entered the wrong details";
  String selectedFilter = "All Bookings";

  final TextEditingController _couponController = TextEditingController();

  final ReservationService _reservationService = ReservationService();
  final List<BookingModel> _allBookings = [];
  final List<BookingModel> _searchBookings = [];
  bool _isLoadingBookings = true;
  bool _isSearchingBookings = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _couponController.addListener(_onSearchChanged);
    _fetchBookings();
  }

  void _onSearchChanged() {
    final String query = _couponController.text.trim();

    _searchDebounce?.cancel();

    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchBookings.clear();
        _isSearchingBookings = false;
        _loadError = _allBookings.isEmpty ? 'No reservations found' : null;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final int token = ++_searchRequestToken;

      if (!mounted) return;
      setState(() {
        _isSearchingBookings = true;
        _loadError = null;
      });

      final bookings = await _reservationService.searchReservations(query);
      if (!mounted || token != _searchRequestToken) return;

      setState(() {
        _searchBookings
          ..clear()
          ..addAll(bookings);
        _isSearchingBookings = false;
        _loadError = bookings.isEmpty ? 'No matching reservations found' : null;
      });
    });
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

    if (_couponController.text.trim().isNotEmpty) {
      _onSearchChanged();
    }
  }

  void _showBookingCanceledPopup() {
    _bookingCancelTimer?.cancel();

    setState(() {
      isBookingCanceled = true;
    });

    _bookingCancelTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      setState(() {
        isBookingCanceled = false;
      });
    });
  }

  Future<void> _declineSelectedBooking() async {
    final BookingModel? booking = selectedBooking;
    final String reservationId = booking?.uuid.trim().isNotEmpty == true
        ? booking!.uuid
        : booking?.id ?? '';

    if (reservationId.isEmpty || _isCancellingBooking) {
      return;
    }

    setState(() {
      _isCancellingBooking = true;
    });

    final bool isDeclined = await _reservationService.declineReservation(reservationId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isCancellingBooking = false;
    });

    if (!isDeclined) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to cancel this reservation.')),
      );
      return;
    }

    setState(() {
      isDeletePressed = false;
      isSearchDeletePressed = false;
      isConfirmedPressed = false;
      selectedBooking = null;
    });

    await _fetchBookings();
    _showBookingCanceledPopup();
  }

  List<BookingModel> get _filteredBookings {
    final List<BookingModel> source = _couponController.text.trim().isNotEmpty
        ? List.from(_searchBookings)
        : List.from(_allBookings);

    List<BookingModel> result = selectedFilter == "All Bookings"
      ? source
      : selectedFilter == "Canceled"
        ? source
          .where(
            (b) => b.status == "Canceled" || b.status == "Cancelled",
          )
          .toList()
        : source.where((b) => b.status == selectedFilter).toList();
    result.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return result;
  }

  @override
  void dispose() {
    _couponController.removeListener(_onSearchChanged);
    _couponController.dispose();
    _searchDebounce?.cancel();
    _bookingCancelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: appTextColor,
              onRefresh: _fetchBookings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildContent(),
              ),
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
                child: Container(color: Colors.black38, child: _confirmedBox()),
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
          child: _couponInputField(),
        ),

        SizedBox(height: 20.h),

        // ── Filter dropdown ──
        SizedBox(
          width: 150.w,
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
              
              height: 30.h,
              hint: selectedFilter,
              imageIconPath: filterIcon,
              imageIconSize: 15.sp,
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
                                _buildFilterOption("Completed"),
                                Divider(color: Colors.grey[200]),
                                _buildFilterOption("Canceled"),
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
          child: _isLoadingBookings || _isSearchingBookings
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

  // ── Coupon number input (shown after tapping Search Restaurant) ──
  Widget _couponInputField() {
    if (!_isSearchActive) {
      // ── "Search Restaurant" button ──
      return GestureDetector(
        onTap: () => setState(() => _isSearchActive = true),
        child: Container(
          height: 50.h,
          padding: EdgeInsets.symmetric(vertical: 19.h, horizontal: 20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
           boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.05), // #000000 5%
    offset: const Offset(0, 0),            // X: 0, Y: 0
    blurRadius: 10,                        // Blur
    spreadRadius: 5,                       // Spread
  ),
],
          ),
          child: Center(
            child: AppText(
              text:"Search Restaurant",
              size: 14,
                fontWeight: FontWeight.w400,
                color: menuIconColor.withOpacity(.7),
              
            ),
          ),
        ),
      );
    }

    // ── Coupon input (shown after tap) ──
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.05), // #000000 5%
    offset: const Offset(0, 0),            // X: 0, Y: 0
    blurRadius: 10,                        // Blur
    spreadRadius: 5,                       // Spread
  ),
],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _couponController.clear(); // clear search results
              setState(() => _isSearchActive = false); // go back to button
            },
            child: Padding(
              padding: EdgeInsets.only(left: 14.w),
              child: Icon(Icons.close, size: 20, color: appTextColor3),
            ),
          ),
          Expanded(
            child: AppTextFeild(
              boxShadow: [
                BoxShadow(
    color: Colors.black.withOpacity(0.00), // #000000 5%
    offset: const Offset(0, 0),            // X: 0, Y: 0
    blurRadius: 0,                        // Blur
    spreadRadius: 0,                       // Spread
  ),
              ],
              controller: _couponController,
              text: 'Enter the Coupon Number',
              isTextCenter: true,
              onChanged: (_) {},
              size: 13,
              textColor: menuIconColor.withOpacity(.7),
              inputContentPadding:
                  EdgeInsets.symmetric(vertical: 19.h, horizontal: 20.w),
              backgroundColor: Colors.transparent,
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
          padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 30.h),
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
                      // isLoading: _isCancellingBooking,
                      onPressed: _declineSelectedBooking,
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
                left: 40.w,
                right: 40.w,
                top: 30.h,
                bottom: 30.h,
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
                        },
                        child: Icon(Icons.close, size: 30, color: appTextColor),
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
                left: 40.w,
                right: 40.w,
                top: 30.h,
                bottom: 30.h,
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
                    text:
                        "Cancelling a confirmed order may negatively impact your reliability rating",
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
                              onPressed: _declineSelectedBooking,
                            borderRadius: 5.r,
                            bgColor1: Colors.green,
                            bgColor2: Colors.green,
                            size: 12,
                              isLoading: _isCancellingBooking,
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: SizedBox(
                          height: 35.h,
                          child: AppButton(
                            text: "No",
                            onPressed: () =>
                                setState(() => isConfirmedPressed = false),
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
                      AppText(
                        text: "Requested party",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => isCateringRequestPressed = false),
                        child: Icon(
                          Icons.close,
                          color: appTextColor3,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      text: "P17854",
                      size: 20,
                      fontWeight: FontWeight.w700,
                      color: appTextColor3,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Catering request details here",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
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
                      AppText(
                        text: "Requested party",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => isPartyRequestPressed = false),
                        child: Icon(
                          Icons.close,
                          color: appTextColor3,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      text: "P17854",
                      size: 20,
                      fontWeight: FontWeight.w700,
                      color: appTextColor3,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Party request details here",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
