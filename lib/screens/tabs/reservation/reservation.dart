import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/cancel_circle_x.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
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

  bool get _isAnyOverlayOpen =>
      isDeletePressed ||
      isSearchDeletePressed ||
      isPartyRequestPressed ||
      isCateringRequestPressed ||
      isConfirmedPressed ||
      isBookingCanceled;

  void _closeAllOverlays() {
    setState(() {
      isDeletePressed = false;
      isSearchDeletePressed = false;
      isPartyRequestPressed = false;
      isCateringRequestPressed = false;
      isConfirmedPressed = false;
      isBookingCanceled = false;
      selectedBooking = null;
    });
  }

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

    _bookingCancelTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      setState(() {
        isBookingCanceled = false;
      });

      await _fetchBookings();
    });
  }

  Future<void> _closeBookingCanceledPopup() async {
    _bookingCancelTimer?.cancel();

    if (!mounted) return;

    setState(() {
      isBookingCanceled = false;
    });

    await _fetchBookings();
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

    final bool isDeclined = await _reservationService.declineReservation(
      reservationId,
    );

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
              .where((b) => b.status == "Canceled" || b.status == "Cancelled")
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
    return PopScope(
      canPop: !_isAnyOverlayOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isAnyOverlayOpen) {
          _closeAllOverlays();
        }
      },
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
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
        ),
      ),
    );
  }

  Widget _buildContent() {
    final metrics = _ReservationMetrics.fromContext(context);

    return Center(
      child: SizedBox(
        width: metrics.contentWidth,
        child: Column(
          children: [
            SizedBox(height: metrics.topGap),

            // ── Search bar: toggles between button and coupon input ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.horizontalPadding,
              ),
              child: _couponInputField(metrics),
            ),

            SizedBox(height: metrics.sectionGap),

            // ── Filter dropdown ──
            SizedBox(
              width: metrics.filterWidth,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(metrics.filterRadius),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1A000000),
                      offset: const Offset(0, 0),
                      blurRadius: metrics.filterShadowBlur,
                      spreadRadius: metrics.filterShadowSpread,
                    ),
                  ],
                ),
                child: AppFilterDropDown(
                  height: metrics.filterHeight,
                  hint: selectedFilter,
                  imageIconPath: filterIcon,
                  imageIconSize: metrics.filterIconSize,
                  toggleDropdown: () {
                    showModalBottomSheet(
                      backgroundColor: Colors.white,
                      context: context,
                      isScrollControlled: true,
                      constraints: metrics.sheetWidth == null
                          ? null
                          : BoxConstraints(
                              maxWidth: metrics.sheetWidth!,
                              // maxWidth: metrics.sheetWidth!,
                            ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                      maxWidth: metrics.sheetWidth ?? 420,
                                    ),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: EdgeInsets.all(metrics.sheetPadding),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: metrics.sheetHandleWidth,
                                        height: metrics.sheetHandleHeight,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      SizedBox(height: metrics.sheetGap),
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.all(
                                          metrics.sheetInnerPadding,
                                        ),
                                        child: Column(
                                          children: [
                                            _buildFilterOption("All Bookings", metrics),
                                            Divider(color: Colors.grey[200]),
                                            _buildFilterOption("Confirmed", metrics),
                                            Divider(color: Colors.grey[200]),
                                            _buildFilterOption("Completed", metrics),
                                            Divider(color: Colors.grey[200]),
                                            _buildFilterOption("Canceled", metrics),
                                            Divider(color: Colors.grey[200]),
                                            _buildFilterOption("Rejected", metrics),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: metrics.sectionGap),

            // ── Booking list ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.horizontalPadding,
              ),
              child: _isLoadingBookings || _isSearchingBookings
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: metrics.emptyVerticalPadding,
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : _filteredBookings.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: metrics.emptyVerticalPadding,
                      ),
                      child: Center(
                        child: AppText(
                          text: _loadError ?? "No bookings found",
                          size: metrics.emptyTextSize,
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
                            () =>
                                isPartyRequestPressed = !isPartyRequestPressed,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Coupon number input (shown after tapping Search Restaurant) ──
  Widget _couponInputField(_ReservationMetrics metrics) {
    if (!_isSearchActive) {
      // ── "Search Restaurant" button ──
      return GestureDetector(
        onTap: () => setState(() => _isSearchActive = true),
        child: Container(
          height: metrics.searchHeight,
          padding: EdgeInsets.symmetric(
            vertical: metrics.searchVerticalPadding,
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
      );
    }

    // ── Coupon input (shown after tap) ──
    return Container(
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
        children: [
          GestureDetector(
            onTap: () {
              _couponController.clear(); // clear search results
              setState(() => _isSearchActive = false); // go back to button
            },
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.00),
                  offset: const Offset(0, 0), // X: 0, Y: 0
                  blurRadius: 0, // Blur
                  spreadRadius: 0, // Spread
                ),
              ],
              controller: _couponController,
              text: 'Enter the Coupon Number',
              isTextCenter: true,
              onChanged: (_) {},
              size: metrics.searchInputTextSize,
              textColor: menuIconColor.withValues(alpha: .7),
              inputContentPadding: EdgeInsets.symmetric(
                vertical: metrics.searchVerticalPadding,
                horizontal: metrics.searchHorizontalPadding,
              ),
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter option tile ────────────────────────────────────
  Widget _buildFilterOption(String label, _ReservationMetrics metrics) {
    final bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = label);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: metrics.filterOptionVerticalPadding,
          horizontal: metrics.filterOptionHorizontalPadding,
        ),
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
          size: metrics.filterOptionTextSize,
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
              color: Colors.black.withValues(alpha: 0.1),
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
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
        
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.9,),
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
      ),
    );
  }

  Widget _bookingCanceledBox() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.black.withValues(alpha: 0.5),
        ),
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
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
                          onTap: _closeBookingCanceledPopup,
                          child: Icon(Icons.close, size: 30, color: appTextColor),
                        ),
                      ],
                    ),
                    CancelCircleX(size: 86.w),
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
          color: Colors.black.withValues(alpha: 0.5),
        ),
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: ConstrainedBox(
               constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.9,),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
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
      ),
    );
  }
}

class _ReservationMetrics {
  const _ReservationMetrics({
    required this.contentWidth,
    required this.horizontalPadding,
    required this.topGap,
    required this.sectionGap,
    required this.searchHeight,
    required this.searchHorizontalPadding,
    required this.searchVerticalPadding,
    required this.searchRadius,
    required this.searchShadowAlpha,
    required this.searchShadowBlur,
    required this.searchShadowOffsetY,
    required this.searchShadowSpread,
    required this.searchTextSize,
    required this.searchInputTextSize,
    required this.closeIconLeftPadding,
    required this.closeIconSize,
    required this.filterWidth,
    required this.filterHeight,
    required this.filterRadius,
    required this.filterIconSize,
    required this.filterShadowBlur,
    required this.filterShadowSpread,
    required this.emptyVerticalPadding,
    required this.emptyTextSize,
    required this.sheetWidth,
    required this.sheetPadding,
    required this.sheetHandleWidth,
    required this.sheetHandleHeight,
    required this.sheetGap,
    required this.sheetInnerPadding,
    required this.filterOptionVerticalPadding,
    required this.filterOptionHorizontalPadding,
    required this.filterOptionTextSize,
  });

  final double contentWidth;
  final double horizontalPadding;
  final double topGap;
  final double sectionGap;
  final double searchHeight;
  final double searchHorizontalPadding;
  final double searchVerticalPadding;
  final double searchRadius;
  final double searchShadowAlpha;
  final double searchShadowBlur;
  final double searchShadowOffsetY;
  final double searchShadowSpread;
  final double searchTextSize;
  final double searchInputTextSize;
  final double closeIconLeftPadding;
  final double closeIconSize;
  final double filterWidth;
  final double filterHeight;
  final double filterRadius;
  final double filterIconSize;
  final double filterShadowBlur;
  final double filterShadowSpread;
  final double emptyVerticalPadding;
  final double emptyTextSize;
  final double? sheetWidth;
  final double sheetPadding;
  final double sheetHandleWidth;
  final double sheetHandleHeight;
  final double sheetGap;
  final double sheetInnerPadding;
  final double filterOptionVerticalPadding;
  final double filterOptionHorizontalPadding;
  final double filterOptionTextSize;

  factory _ReservationMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final contentWidth = (size.width * 0.82).clamp(680.0, 980.0).toDouble();
      final scale = (contentWidth / 760).clamp(1.0, 1.12).toDouble();
      double s(double value) => value * scale;

      return _ReservationMetrics(
        contentWidth: contentWidth,
        horizontalPadding: s(28),
        topGap: s(28),
        sectionGap: s(26),
        searchHeight: s(64),
        searchHorizontalPadding: s(24),
        searchVerticalPadding: s(14),
        searchRadius: s(18),
        searchShadowAlpha: 0.2,
        searchShadowBlur: s(10),
        searchShadowOffsetY: s(5),
        searchShadowSpread: 0,
        searchTextSize: s(17),
        searchInputTextSize: s(16),
        closeIconLeftPadding: s(18),
        closeIconSize: s(24),
        filterWidth: s(190),
        filterHeight: s(42),
        filterRadius: s(12),
        filterIconSize: s(18),
        filterShadowBlur: s(12),
        filterShadowSpread: s(2),
        emptyVerticalPadding: s(76),
        emptyTextSize: s(17),
        // sheetWidth: contentWidth,
        sheetWidth: math.min(contentWidth * 0.5, 400),
        sheetPadding: s(34),
        sheetHandleWidth: s(48),
        sheetHandleHeight: s(5),
        sheetGap: s(20),
        sheetInnerPadding: s(20),
        filterOptionVerticalPadding: s(15),
        filterOptionHorizontalPadding: s(10),
        filterOptionTextSize: s(17),
      );
    }

    if (isWideShortPhone) {
      return const _ReservationMetrics(
        contentWidth: double.infinity,
        horizontalPadding: 28,
        topGap: 20,
        sectionGap: 18,
        searchHeight: 52,
        searchHorizontalPadding: 22,
        searchVerticalPadding: 14,
        searchRadius: 16,
        searchShadowAlpha: 0.14,
        searchShadowBlur: 10,
        searchShadowOffsetY: 4,
        searchShadowSpread: 0,
        searchTextSize: 14,
        searchInputTextSize: 13,
        closeIconLeftPadding: 14,
        closeIconSize: 20,
        filterWidth: 146,
        filterHeight: 32,
        filterRadius: 10,
        filterIconSize: 15,
        filterShadowBlur: 9,
        filterShadowSpread: 1,
        emptyVerticalPadding: 50,
        emptyTextSize: 14,
        sheetWidth: 480,
        sheetPadding: 28,
        sheetHandleWidth: 42,
        sheetHandleHeight: 4,
        sheetGap: 14,
        sheetInnerPadding: 15,
        filterOptionVerticalPadding: 11,
        filterOptionHorizontalPadding: 8,
        filterOptionTextSize: 14,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _ReservationMetrics(
        contentWidth: double.infinity,
        horizontalPadding: s(16),
        topGap: s(16),
        sectionGap: s(16),
        searchHeight: s(44),
        searchHorizontalPadding: s(16),
        searchVerticalPadding: s(15),
        searchRadius: s(13),
        searchShadowAlpha: 0.05,
        searchShadowBlur: s(10),
        searchShadowOffsetY: 0,
        searchShadowSpread: s(5),
        searchTextSize: s(12.5),
        searchInputTextSize: s(12),
        closeIconLeftPadding: s(11),
        closeIconSize: s(18),
        filterWidth: s(132),
        filterHeight: s(28),
        filterRadius: s(9),
        filterIconSize: s(13),
        filterShadowBlur: s(8),
        filterShadowSpread: s(1.5),
        emptyVerticalPadding: s(44),
        emptyTextSize: s(13),
        sheetWidth: null,
        sheetPadding: s(22),
        sheetHandleWidth: s(36),
        sheetHandleHeight: s(4),
        sheetGap: s(12),
        sheetInnerPadding: s(12),
        filterOptionVerticalPadding: s(10),
        filterOptionHorizontalPadding: s(7),
        filterOptionTextSize: s(13),
      );
    }

    return _ReservationMetrics(
      contentWidth: double.infinity,
      horizontalPadding: 20.w,
      topGap: 20.h,
      sectionGap: 20.h,
      searchHeight: 50.h,
      searchHorizontalPadding: 20.w,
      searchVerticalPadding: 19.h,
      searchRadius: 16.r,
      searchShadowAlpha: 0.05,
      searchShadowBlur: 10,
      searchShadowOffsetY: 0,
      searchShadowSpread: 5,
      searchTextSize: 14,
      searchInputTextSize: 13,
      closeIconLeftPadding: 14.w,
      closeIconSize: 20,
      filterWidth: 150.w,
      filterHeight: 30.h,
      filterRadius: 10.r,
      filterIconSize: 15.sp,
      filterShadowBlur: 10,
      filterShadowSpread: 2,
      emptyVerticalPadding: 60.h,
      emptyTextSize: 15,
      sheetWidth: null,
      sheetPadding: 30.w,
      sheetHandleWidth: 40,
      sheetHandleHeight: 5,
      sheetGap: 16.h,
      sheetInnerPadding: 16.w,
      filterOptionVerticalPadding: 12.h,
      filterOptionHorizontalPadding: 8.w,
      filterOptionTextSize: 15,
    );
  }
}
