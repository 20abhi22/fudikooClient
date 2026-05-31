import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/model/banquet/banquet_reservation_modal.dart';
import 'package:fudikoclient/screens/catering_tabs/reservation/catering_reservation_box.dart';
import 'package:fudikoclient/service/inquery/catering_reservation_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class CateringReservation extends StatefulWidget {
  const CateringReservation({super.key});

  @override
  State<CateringReservation> createState() => _CateringReservationState();
}

class _CateringReservationState extends State<CateringReservation> {
  // ── Overlay visibility flags ─────────────────────────────────────────────
  bool isDeletePressed = false;
  bool isConfirmedPressed = false;
  bool isBookingCanceled = false;
  bool isSearchDeletePressed = false;
  bool isPartyRequestPressed = false;
  bool isCateringRequestPressed = false;

  // ── Selection state ──────────────────────────────────────────────────────
  String selectedStatus = "Entered the wrong details";
  String mainSelectedStatus = "Party";
  String selectedFilter = "All Bookings";

  // ── Loading / error / search state ──────────────────────────────────────
  bool _isLoadingReservations = false;
  bool _isReservationSearchActive = false;
  bool _isSearchingReservations = false;
  bool _isCancellingReservation = false;
  String _reservationError = '';
  String _reservationSearchError = '';
  String _selectedReservationId = '';
  int _reservationSearchRequestId = 0;

  // ── Data lists ───────────────────────────────────────────────────────────
  List<BanquetReservationModal> _reservations = [];
  List<BanquetReservationModal> _searchedReservations = [];

  // ── Controllers & focus nodes ────────────────────────────────────────────
  final TextEditingController _reservationSearchController =
      TextEditingController();
  final TextEditingController _acceptAnotherReasonController =
      TextEditingController();
  final FocusNode _reservationSearchFocusNode = FocusNode();

  // ── Computed getters ─────────────────────────────────────────────────────

  List<BanquetReservationModal> get _filteredBookings {
    final source = _isReservationSearchActive
        ? _searchedReservations
        : _reservations;
    List<BanquetReservationModal> result = selectedFilter == "All Bookings"
        ? List.from(source)
        : source.where((b) => b.status == selectedFilter).toList();
    result.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return result;
  }

  bool get _isActiveListLoading => _isReservationSearchActive
      ? _isSearchingReservations
      : _isLoadingReservations;

  String get _activeListError =>
      _isReservationSearchActive ? _reservationSearchError : _reservationError;

  String get _emptyListText {
    if (_isReservationSearchActive &&
        _reservationSearchController.text.trim().isEmpty) {
      return "Type a coupon number";
    }
    return "No bookings found";
  }

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
      _selectedReservationId = '';
    });
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  @override
  void dispose() {
    _reservationSearchRequestId++;
    _reservationSearchController.dispose();
    _acceptAnotherReasonController.dispose();
    _reservationSearchFocusNode.dispose();
    super.dispose();
  }

  // ── API calls ────────────────────────────────────────────────────────────

  Future<void> _fetchReservations() async {
    setState(() {
      _isLoadingReservations = true;
      _reservationError = '';
    });

    final result = await CateringReservationService().fetchReservations();

    if (!mounted) return;
    setState(() {
      _reservations = result.reservations;
      _isLoadingReservations = false;
      _reservationError = result.status
          ? ''
          : result.message.isEmpty
          ? 'Unable to fetch bookings right now.'
          : result.message;
    });
  }

  Future<void> _cancelSelectedReservation() async {
    if (_isCancellingReservation) return;

    setState(() {
      _isCancellingReservation = true;
      isDeletePressed = false;
      isSearchDeletePressed = false;
      isConfirmedPressed = false;
    });

    final result = await CateringReservationService().cancelReservation(
      _selectedReservationId,
    );

    if (!mounted) return;

    final bool isSuccess = result['status'] == true;
    final String message = (result['message'] ?? '').toString().isEmpty
        ? (isSuccess ? 'Reservation cancelled successfully' : 'Cancel failed')
        : result['message'].toString();

    setState(() {
      _isCancellingReservation = false;
      isSearchDeletePressed = false;
      isDeletePressed = false;
      isConfirmedPressed = false;
      if (isSuccess) {
        isBookingCanceled = true;
        _selectedReservationId = '';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );

    if (isSuccess) {
      await _fetchReservations();
      if (_isReservationSearchActive) {
        await _searchReservations(_reservationSearchController.text);
      }
    }
  }

  Future<void> _searchReservations(String value) async {
    final query = value.trim();
    final requestId = ++_reservationSearchRequestId;

    if (query.isEmpty) {
      setState(() {
        _isSearchingReservations = false;
        _reservationSearchError = '';
        _searchedReservations = [];
      });
      return;
    }

    setState(() {
      _isSearchingReservations = true;
      _reservationSearchError = '';
    });

    final result = await CateringReservationService().searchReservations(query);

    if (!mounted || requestId != _reservationSearchRequestId) return;

    setState(() {
      _searchedReservations = result.reservations;
      _isSearchingReservations = false;
      _reservationSearchError = result.status
          ? ''
          : result.message.isEmpty
          ? 'Unable to search bookings right now.'
          : result.message;
    });
  }

  Future<void> _retryActiveListRequest() {
    if (_isReservationSearchActive) {
      return _searchReservations(_reservationSearchController.text);
    }
    return _fetchReservations();
  }

  // ── Search helpers ───────────────────────────────────────────────────────

  void _activateReservationSearch() {
    if (!_isReservationSearchActive) {
      setState(() {
        _isReservationSearchActive = true;
        _reservationSearchError = '';
      });
    }
    _reservationSearchFocusNode.requestFocus();
  }

  void _exitReservationSearch() {
    _reservationSearchRequestId++;
    _reservationSearchFocusNode.unfocus();
    setState(() {
      _isReservationSearchActive = false;
      _isSearchingReservations = false;
      _reservationSearchError = '';
      _searchedReservations = [];
      _reservationSearchController.clear();
    });
  }

  void _onReservationSearchChanged(String value) {
    if (!_isReservationSearchActive) {
      setState(() => _isReservationSearchActive = true);
    }
    _searchReservations(value);
  }

  // ── Dialog helpers ───────────────────────────────────────────────────────

  void _showAcceptAnotherReasonPopup() {
    _acceptAnotherReasonController.text = selectedStatus == "Other Reasons"
        ? ''
        : selectedStatus;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        text: "Reason for accepting another response",
                        size: 15,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Icon(Icons.close, size: 24, color: appTextColor3),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                TextField(
                  controller: _acceptAnotherReasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Type your reason",
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 40.h,
                  child: AppButton(
                    text: "Submit",
                    bgColor1: appButtonColor,
                    bgColor2: appButtonColor,
                    size: 15,
                    borderRadius: 10.r,
                    onPressed: () {
                      final reason = _acceptAnotherReasonController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please type a reason")),
                        );
                        return;
                      }
                      setState(() => selectedStatus = reason);
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

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
        body: Stack(
          children: [
            // ── Main scrollable content ──────────────────────────────────
            RefreshIndicator(
              color: appButtonColor,
              onRefresh: _fetchReservations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildMainContent(),
              ),
            ),

            // ── Overlays ─────────────────────────────────────────────────
            if (isSearchDeletePressed || isDeletePressed)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isCancellingReservation
                      ? null
                      : () {
                          setState(() {
                            isSearchDeletePressed = false;
                            isDeletePressed = false;
                            _selectedReservationId = '';
                          });
                        },
                  child: Container(
                    color: Colors.black54,
                    child: _cancelReasonSheet(),
                  ),
                ),
              ),

            if (isPartyRequestPressed)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => isPartyRequestPressed = false),
                  child: Container(
                    color: Colors.black54,
                    child: _viewPartyRequestWidget(),
                  ),
                ),
              ),

            if (isCateringRequestPressed)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => isCateringRequestPressed = false),
                  child: Container(
                    color: Colors.black54,
                    child: _viewCateringRequestWidget(),
                  ),
                ),
              ),

            if (isConfirmedPressed)
              Positioned.fill(
                child: Container(color: Colors.black54, child: _confirmedBox()),
              ),

            if (isBookingCanceled)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: _bookingCanceledBox(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // MAIN CONTENT
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMainContent() {
    return Column(
      children: [
        // ── Search bar ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 20.h),
          child: AppTextFeild(
            controller: _reservationSearchController,
            focusNode: _reservationSearchFocusNode,
            text: "Enter the Coupon Number",
            textColor: appTextColor3,
            isTextCenter: true,
            icon: _isReservationSearchActive ? Icons.close : Icons.search,
            iconColor: appTextColor3,
            size: 13.sp,
            onboxTap: _activateReservationSearch,
            iconOnTap: _isReservationSearchActive
                ? _exitReservationSearch
                : _activateReservationSearch,
            onChanged: _onReservationSearchChanged,
          ),
        ),
        SizedBox(height: 20.h),

        // ── Filter dropdown ──────────────────────────────────────────
        SizedBox(
          width: 200,
          child: AppFilterDropDown(
            hint: selectedFilter,
            imageIconPath: filterIcon,
            imageIconSize: 18.sp,
            toggleDropdown: _showFilterBottomSheet,
          ),
        ),
        SizedBox(height: 20.h),

        // ── Booking list / states ────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: _buildListSection(),
        ),

        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildListSection() {
    if (_isActiveListLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeListError.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: _activeListError,
                size: 15,
                fontWeight: FontWeight.w500,
                color: appTextColor3,
                isCentered: true,
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: 120.w,
                height: 38.h,
                child: AppButton(
                  text: "Retry",
                  size: 14,
                  borderRadius: 10.r,
                  onPressed: _retryActiveListRequest,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredBookings.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: Center(
          child: AppText(
            text: _emptyListText,
            size: 15,
            fontWeight: FontWeight.w500,
            color: appTextColor3,
            isCentered: true,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredBookings.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final booking = _filteredBookings[index];
        return CateringReservationBox(
          reservation: booking,
          onCancelTap: () {
            setState(() {
              _selectedReservationId = booking.uuid;
              isSearchDeletePressed = true;
            });
          },
          onRequestTap: () =>
              setState(() => isPartyRequestPressed = !isPartyRequestPressed),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // FILTER BOTTOM SHEET
  // ════════════════════════════════════════════════════════════════════════

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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
                width: double.infinity,
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
                    _buildFilterOption("Cancelled"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  // ════════════════════════════════════════════════════════════════════════
  // CANCEL REASON SHEET  (fixed: Cancel button pinned outside scroll)
  // ════════════════════════════════════════════════════════════════════════

  Widget _cancelReasonSheet() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: GestureDetector(
          // prevent backdrop tap from propagating into the card
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.74,
            ),
            padding: EdgeInsets.only(
              left: 40.w,
              right: 40.w,
              top: 24.h,
              bottom: 24.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.r),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(
                  children: [
                    AppText(
                      text: "Reason for Cancel",
                      size: 13,
                      fontWeight: FontWeight.w500,
                      color: appTextColor3,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _isCancellingReservation
                          ? null
                          : () {
                              setState(() {
                                isSearchDeletePressed = false;
                                isDeletePressed = false;
                                _selectedReservationId = '';
                              });
                            },
                      child: Icon(Icons.close, size: 25, color: appTextColor3),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),

                // ── Scrollable reason buttons + info text ────────────
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 40.h,
                          child: _buildStatusButton("I changed my mind"),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          height: 40.h,
                          child: _buildStatusButton(
                            "I need to reschedule the event",
                          ),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          height: 40.h,
                          child: _buildStatusButton(
                            "Entered the wrong details",
                          ),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          height: 40.h,
                          child: _buildStatusButton("I booked by mistake"),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          height: 40.h,
                          child: _buildStatusButton("Other Reasons"),
                        ),
                        SizedBox(height: 24.h),
                        AppText(
                          text:
                              "Canceling a confirmed booking may negatively impact your reliability rating.",
                          size: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          isCentered: true,
                        ),
                        SizedBox(height: 8.h),
                        AppText(
                          text:
                              "However, if you accept another response instead, the previous booking will be automatically replaced without affecting your rating.",
                          size: 13,
                          fontWeight: FontWeight.w400,
                          color: appTextColor2,
                          isCentered: true,
                        ),
                        SizedBox(height: 16.h),
                        GestureDetector(
                          onTap: _showAcceptAnotherReasonPopup,
                          child: AppText(
                            text: "Accept another response",
                            size: 15,
                            fontWeight: FontWeight.w400,
                            color: appLinkColor2,
                            isCentered: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Cancel button — pinned outside scroll ────────────
                SizedBox(height: 16.h),
                SizedBox(
                  width: 150,
                  height: 40,
                  child: AppButton(
                    text: _isCancellingReservation ? "Cancelling..." : "Cancel",
                    bgColor1: const Color(0xFFCE3F3F),
                    bgColor2: const Color(0xFFCE3F3F),
                    size: 15,
                    borderRadius: 10,
                    onPressed: _isCancellingReservation
                        ? null
                        : _cancelSelectedReservation,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BOOKING CANCELED CONFIRMATION BOX
  // ════════════════════════════════════════════════════════════════════════

  Widget _bookingCanceledBox() {
    return Center(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10.r,
                offset: Offset(0, 4.r),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isDeletePressed = false;
                        isBookingCanceled = false;
                      });
                    },
                    child: Icon(Icons.close, size: 30, color: appTextColor),
                  ),
                ],
              ),
              Image.asset(
                'assets/images/cancel.png',
                height: 60.h,
                width: 60.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20.h),
              AppText(
                text: "Booking Canceled!",
                size: 20,
                fontWeight: FontWeight.w500,
                color: Colors.red,
                isCentered: true,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CONFIRMED BOX  (secondary confirmation dialog)
  // ════════════════════════════════════════════════════════════════════════

  Widget _confirmedBox() {
    return Center(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10.r,
                offset: Offset(0, 4.r),
              ),
            ],
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
                        text: _isCancellingReservation
                            ? "Cancelling..."
                            : "Yes",
                        onPressed: _isCancellingReservation
                            ? null
                            : _cancelSelectedReservation,
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
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // REUSABLE BUTTON WIDGETS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildStatusButton(String text) {
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
        child: AppText(
          text: text,
          size: 13.sp,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildMainStatusButton(String text) {
    final bool isSelected = mainSelectedStatus == text;
    return GestureDetector(
      onTap: () => setState(() => mainSelectedStatus = text),
      child: Container(
        height: 35.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: AppText(
          text: text,
          size: 13.sp,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : appTextColor3,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // REQUEST DETAIL WIDGETS
  // ════════════════════════════════════════════════════════════════════════

  /// Shared row builder for request detail fields
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: appTextColor2),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: label,
                size: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              SizedBox(height: 5.h),
              AppText(
                text: value,
                size: 15,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
                lineSpacing: 1.5,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _viewPartyRequestWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // header
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
                      child: Icon(Icons.close, color: appTextColor3, size: 25),
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
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.dashboard,
                          label: "Your Menu",
                          value:
                              "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream.",
                        ),
                        SizedBox(height: 20.h),
                        _buildDetailRow(
                          icon: Icons.people,
                          label: "Number of Persons",
                          value: "12 Person",
                        ),
                        SizedBox(height: 20.h),
                        _buildDetailRow(
                          icon: Icons.calendar_today_sharp,
                          label: "Date and Time",
                          value: "April 12 - 2:30 pm",
                        ),
                        SizedBox(height: 20.h),
                        _buildDetailRow(
                          icon: Icons.wallet,
                          label: "Expected amount per person",
                          value: "1000 Per person",
                        ),
                        SizedBox(height: 20.h),
                        _buildDetailRow(
                          icon: Icons.analytics,
                          label: "Enquiry Radius",
                          value: "Moscow City - 20km Radius",
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewCateringRequestWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // header
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
                      child: Icon(Icons.close, color: appTextColor3, size: 25),
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
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.dashboard,
                          label: "Your Menu",
                          value:
                              "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream.",
                        ),
                        SizedBox(height: 20.h),
                        _buildDetailRow(
                          icon: Icons.handshake,
                          label: "Other Services",
                          value: "7 Service boys needed.",
                        ),
                        SizedBox(height: 20.h),
                        _buildDetailRow(
                          icon: Icons.people,
                          label: "Number of Persons",
                          value: "12 Person",
                        ),
                        SizedBox(height: 20.h),
                        _buildDetailRow(
                          icon: Icons.calendar_today_sharp,
                          label: "Date and Time",
                          value: "April 12 - 2:30 pm",
                        ),
                        SizedBox(height: 20.h),
                        _buildDetailRow(
                          icon: Icons.wallet,
                          label: "Expected amount per person",
                          value: "1000 Per person",
                        ),
                        SizedBox(height: 20.h),
                        _buildDetailRow(
                          icon: Icons.analytics,
                          label: "Enquiry Radius",
                          value: "Moscow City - 20km Radius",
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
