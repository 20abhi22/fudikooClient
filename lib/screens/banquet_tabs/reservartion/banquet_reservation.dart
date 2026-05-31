import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/model/banquet/banquet_reservation_modal.dart';
import 'package:fudikoclient/screens/banquet_tabs/reservartion/banquet_reservation_box.dart';
import 'package:fudikoclient/service/inquery/banquet_reservation_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class BanquetReservation extends StatefulWidget {
  const BanquetReservation({super.key});

  @override
  State<BanquetReservation> createState() => _BanquetReservationState();
}

class _BanquetReservationState extends State<BanquetReservation> {
  bool isDeletePressed = false;
  bool isConfirmedPressed = false;
  bool isBookingCanceled = false;
  bool isSearchDeletePressed = false;
  bool isPartyRequestPressed = false;
  bool isCateringRequestPressed = false;
  String selectedStatus = "Entered the wrong details";
  String mainSelectedStatus = "Party";
  String selectedFilter = "All Bookings";
  bool _isLoadingReservations = false;
  bool _isReservationSearchActive = false;
  bool _isSearchingReservations = false;
  bool _isCancellingReservation = false;
  String _reservationError = '';
  String _reservationSearchError = '';
  String _selectedReservationId = '';
  int _reservationSearchRequestId = 0;
  List<BanquetReservationModal> _reservations = [];
  List<BanquetReservationModal> _searchedReservations = [];
  final TextEditingController _reservationSearchController =
      TextEditingController();
  final TextEditingController _acceptAnotherReasonController =
      TextEditingController();
  final FocusNode _reservationSearchFocusNode = FocusNode();

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

  Future<void> _fetchReservations() async {
    setState(() {
      _isLoadingReservations = true;
      _reservationError = '';
    });

    final result = await BanquetReservationService().fetchReservations();

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
      // close any visible confirm/delete overlays
      isDeletePressed = false;
      isSearchDeletePressed = false;
      isConfirmedPressed = false;
    });

    final result = await BanquetReservationService().cancelReservation(
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
      setState(() {
        _isReservationSearchActive = true;
      });
    }
    _searchReservations(value);
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

    final result = await BanquetReservationService().searchReservations(query);

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
            borderRadius: BorderRadius.circular(10.r),
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

                      setState(() {
                        selectedStatus = reason;
                      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: appButtonColor,
              onRefresh: _fetchReservations,
              child: SingleChildScrollView(child: _viewSearchWidget()),
            ),
        
            if (isDeletePressed)
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
            if (isSearchDeletePressed)
              Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: _deleteSearchBox(),
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

  Widget _viewSearchWidget() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 20.h),
          child: AppTextFeild(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // #000000 5%
                offset: const Offset(0, 0), // X: 0, Y: 0
                blurRadius: 10, // Blur: 10
                spreadRadius: 5, // Spread: 5
              ),
            ],
            controller: _reservationSearchController,
            focusNode: _reservationSearchFocusNode,
            text: "Enter the Coupon Number",
            textColor: appTextColor3,
            isTextCenter: true,
            icon: _isReservationSearchActive ? Icons.close : null,
            iconColor: appTextColor3,
            size: 13.sp,
            onboxTap: _activateReservationSearch,
            iconOnTap: _isReservationSearchActive
                ? _exitReservationSearch
                : null,
            onChanged: _onReservationSearchChanged,
            fieldBorderRadius: 16,
          ),
        ),
        SizedBox(height: 20.h),

        SizedBox(
          width: 150.w,
          child: AppFilterDropDown(
            height: 30.h,
            hint: selectedFilter, // ← shows selected option instead of "filter"
            imageIconPath: filterIcon,
            imageIconSize: 18.sp,
            textSize: 10.sp,
            toggleDropdown: () {
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
                              _buildFilterOption("Cancelled"),
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
        SizedBox(height: 20.h),

        // Padding(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: _isActiveListLoading
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 60.h),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : _activeListError.isNotEmpty
              ? Padding(
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
                )
              : _filteredBookings.isEmpty
              ? Padding(
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
                )
              : ListView.builder(
                  itemCount: _filteredBookings.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final booking = _filteredBookings[index];
                    return BanquetReservationBox(
                      reservation: booking,
                      onCancelTap: () {
                        setState(() {
                          _selectedReservationId = booking.uuid;
                          isSearchDeletePressed = true;
                        });
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

  Widget _deleteSearchBox() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
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
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Spacer(),
                      AppText(
                        text: "Reason for Cancel",
                        size: 14,
                        fontWeight: FontWeight.w500,
                        color: menuIconColor,
                        isCentered: true,
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: _isCancellingReservation
                            ? null
                            : () {
                                setState(() {
                                  isSearchDeletePressed = false;
                                  _selectedReservationId = '';
                                });
                              },
                        child: Icon(
                          Icons.close,
                          size: 25,
                          color: appTextColor3,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),
                  SizedBox(
                    height: 35.h,
                    child: buildStatusButton("I changed my mind"),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 35.h,
                    child: buildStatusButton("I need to reschedule the event"),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 35.h,
                    child: buildStatusButton("Entered the wrong details"),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 35.h,
                    child: buildStatusButton("I booked by mistake"),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 35.h,
                    child: buildStatusButton("Other Reasons"),
                  ),
                  SizedBox(height: 35.h),
                  AppText(
                    text:
                        "Canceling a confirmed booking may negatively impact your reliability rating.",
                    size: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    isCentered: true,
                  ),
                  SizedBox(height: 10.h),
                  AppText(
                    text:
                        "However, if you accept another response instead, the previous booking will be automatically replaced without affecting your rating.",
                    size: 13,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                    isCentered: true,
                    maxLines: 4,
                  ),
                  SizedBox(height: 15.h),
                  GestureDetector(
                    onTap: _showAcceptAnotherReasonPopup,
                    child: AppText(
                      text: "Accept another response",
                      size: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF3954DB).withOpacity(.9),
                      isCentered: true,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: 120.w,
                    height: 35.h,
                    child: AppButton(
                      
                      text: _isCancellingReservation
                          ? "Cancelling..."
                          : "Cancel",
                      bgColor1: Color(0xFFCE3F3F),
                      bgColor2: Color(0xFFCE3F3F),
                      size: 15,
                      borderRadius: 8,
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
      ],
    );
  }

  Widget buildStatusButton(String text) {
    final bool isSelected = selectedStatus == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStatus = text;
        });
      },
      child: Container(
        height: 35.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFF97A0D), Color(0xFFF97A0D)],
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
          size: 13,
          fontWeight: FontWeight.w400,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget buildMainStatusButton(String text) {
    final bool isSelected = mainSelectedStatus == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          mainSelectedStatus = text;
        });
      },
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

  Widget _bookingCanceledBox() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
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
                            if (isDeletePressed) {
                              isDeletePressed = !isDeletePressed;
                            }
                            isBookingCanceled = !isBookingCanceled;
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
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
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
                            onPressed: () {
                              setState(() {
                                isDeletePressed = !isDeletePressed;
                              });
                            },
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

  Widget _deleteBox() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
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
                    size: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    isCentered: true,
                    lineSpacing: 1.2,
                  ),
                  SizedBox(height: 10.h),
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
                            onPressed: () {
                              setState(() {
                                isDeletePressed = !isDeletePressed;
                              });
                            },
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

  Widget _buildFilterOption(String label) {
    final bool isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
        Navigator.pop(context); // closes the bottom sheet
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
                        onTap: () {
                          setState(() {
                            isCateringRequestPressed =
                                !isCateringRequestPressed;
                          });
                        },
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.dashboard, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Your Menu",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text:
                                  "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.handshake, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Other Services",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "7 Service boys needed.",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.people, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Number of Persons",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "12 Person ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.calendar_today_sharp,
                        size: 20,
                        color: appTextColor2,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Date and Time ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "April 12 - 2:30 pm",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.wallet, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Expected amount per person",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "1000 Per person",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.analytics, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Enquiry Radius ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "Moscow City - 20km Radius",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
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
                        onTap: () {
                          setState(() {
                            isPartyRequestPressed = !isPartyRequestPressed;
                          });
                        },
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.dashboard, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Your Menu",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text:
                                  "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.people, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Number of Persons",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "12 Person ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.calendar_today_sharp,
                        size: 20,
                        color: appTextColor2,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Date and Time ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "April 12 - 2:30 pm",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.wallet, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Expected amount per person",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "1000 Per person",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.analytics, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Enquiry Radius ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "Moscow City - 20km Radius",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
