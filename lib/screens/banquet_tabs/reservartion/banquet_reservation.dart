import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/cancel_circle_x.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/banquet/banquet_reservation_modal.dart';
import 'package:fudikoclient/screens/banquet_tabs/reservartion/banquet_reservation_box.dart';
import 'package:fudikoclient/service/inquery/banquet_reservation_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class BanquetReservation extends StatefulWidget {
  const BanquetReservation({super.key});

  @override
  State<BanquetReservation> createState() => BanquetReservationState();
}

class BanquetReservationState extends State<BanquetReservation> {
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
  BanquetReservationModal? _selectedRequestReservation;
  int _reservationSearchRequestId = 0;
  List<BanquetReservationModal> _reservations = [];
  List<BanquetReservationModal> _searchedReservations = [];
  final Map<String, String> _reservationPlaceNames = {};
  final TextEditingController _reservationSearchController =
      TextEditingController();
  final TextEditingController _acceptAnotherReasonController =
      TextEditingController();
  final FocusNode _reservationSearchFocusNode = FocusNode();

  bool get _isAnyOverlayOpen =>
      isDeletePressed ||
      isSearchDeletePressed ||
      isPartyRequestPressed ||
      isCateringRequestPressed ||
      isConfirmedPressed ||
      isBookingCanceled;

  bool get _shouldHandleBack => _isAnyOverlayOpen || _isReservationSearchActive;

  void _closeAllOverlays() {
    setState(() {
      isDeletePressed = false;
      isSearchDeletePressed = false;
      isPartyRequestPressed = false;
      isCateringRequestPressed = false;
      isConfirmedPressed = false;
      isBookingCanceled = false;
      _selectedReservationId = '';
      _selectedRequestReservation = null;
    });
  }

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

  Future<void> refreshReservations() {
    if (_isReservationSearchActive) {
      return _searchReservations(_reservationSearchController.text);
    }
    return _fetchReservations();
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

    showStatusSnack(context, isSuccess, message);

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
        final size = MediaQuery.sizeOf(dialogContext);
        final isTablet = Breakpoints.isTabletDevice(size);
        final isLandscape = size.width > size.height;
        final isShortHeight = isLandscape && size.height <= 500;

        final double width = isTablet
            ? (isLandscape ? 480 : 520)
            : isLandscape
            ? size.width * 0.6
            : size.width - 60;

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: isShortHeight ? 12.h : 24.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width,
              maxHeight: size.height * (isShortHeight ? 0.92 : 0.82),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: isShortHeight ? 16.h : 24.h,
              ),
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
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: appTextColor3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isShortHeight ? 10.h : 18.h),
                  TranslatedBuilder(
                    text: "Type your reason",
                    builder: (context, translatedHint) => TextField(
                      controller: _acceptAnotherReasonController,
                      maxLines: isShortHeight ? 2 : 4,
                      decoration: InputDecoration(
                        hintText: translatedHint,
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
                  ),
                  SizedBox(height: isShortHeight ? 12.h : 20.h),
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
                        final reason = _acceptAnotherReasonController.text
                            .trim();
                        if (reason.isEmpty) {
                          showErrorSnack(context, "Please type a reason");
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
          ),
        );
      },
    );
  }

  final List<String> _cancelReasons = const [
    "I changed my mind",
    "I need to reschedule the event",
    "Entered the wrong details",
    "I booked by mistake",
    "Other Reasons",
  ];

  Widget _responsiveDialog({required Widget child}) {
    final size = MediaQuery.sizeOf(context);

    final isTablet = Breakpoints.isTabletDevice(size);
    final isLandscape = size.width > size.height;

    double width;

    if (isTablet) {
      width = isLandscape ? 520 : 560;
    } else if (isLandscape) {
      width = size.width * 0.85;
    } else {
      width = size.width - 60;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: size.height * 0.82,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_shouldHandleBack,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isAnyOverlayOpen) {
          _closeAllOverlays();
        } else if (_isReservationSearchActive) {
          _exitReservationSearch();
        }
      },
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
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

  Widget _viewSearchWidget() {
    final metrics = _BanquetReservationMetrics.fromContext(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: metrics.contentHorizontalPadding,
            right: metrics.contentHorizontalPadding,
            top: metrics.contentTopPadding,
          ),
          child: AppTextFeild(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 0),
                blurRadius: metrics.searchShadowBlur,
                spreadRadius: metrics.searchShadowSpread,
              ),
            ],
            controller: _reservationSearchController,
            focusNode: _reservationSearchFocusNode,
            text: "Enter the Coupon Number",
            textColor: appTextColor3,
            isTextCenter: true,
            icon: _isReservationSearchActive ? Icons.close : null,
            iconColor: appTextColor3,
            size: metrics.searchTextSize,
            onboxTap: _activateReservationSearch,
            iconOnTap: _isReservationSearchActive
                ? _exitReservationSearch
                : null,
            onChanged: _onReservationSearchChanged,
            fieldBorderRadius: metrics.searchRadius,
          ),
        ),
        SizedBox(height: metrics.sectionGap),

        SizedBox(
          width: metrics.filterWidth,
          child: AppFilterDropDown(
            height: metrics.filterHeight,
            hint: selectedFilter, // ← shows selected option instead of "filter"
            imageIconPath: filterIcon,
            imageIconSize: metrics.filterIconSize,
            textSize: metrics.filterTextSize,
            toggleDropdown: _showFilterBottomSheet,
          ),
        ),
        SizedBox(height: metrics.sectionGap),

        // Padding(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.contentHorizontalPadding,
          ),
          child: _isActiveListLoading
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: metrics.stateVerticalPadding,
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : _activeListError.isNotEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: metrics.stateVerticalPadding,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          text: _activeListError,
                          size: metrics.stateTextSize,
                          fontWeight: FontWeight.w500,
                          color: appTextColor3,
                          isCentered: true,
                        ),
                        SizedBox(height: metrics.stateGap),
                        SizedBox(
                          width: metrics.retryButtonWidth,
                          height: metrics.retryButtonHeight,
                          child: AppButton(
                            text: "Retry",
                            size: metrics.retryButtonTextSize,
                            borderRadius: metrics.retryButtonRadius,
                            onPressed: _retryActiveListRequest,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _filteredBookings.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: metrics.stateVerticalPadding,
                  ),
                  child: Center(
                    child: AppText(
                      text: _emptyListText,
                      size: metrics.stateTextSize,
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
                      onRequestTap: () => _openPartyRequest(booking),
                      onCouponClosed: refreshReservations,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openPartyRequest(BanquetReservationModal reservation) async {
    setState(() {
      _selectedRequestReservation = reservation;
      isPartyRequestPressed = true;
    });

    await _ensurePlaceNameFor(reservation);
  }

  Future<void> _ensurePlaceNameFor(BanquetReservationModal? reservation) async {
    if (reservation == null) return;

    final lat = reservation.lat.trim();
    final lng = reservation.lng.trim();
    if (lat.isEmpty || lng.isEmpty) return;

    final key = '$lat,$lng';
    if (_reservationPlaceNames.containsKey(key)) return;

    try {
      final latValue = double.parse(lat);
      final lngValue = double.parse(lng);
      final placemarks = await placemarkFromCoordinates(latValue, lngValue);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final name = [
          place.subLocality,
          place.locality,
          place.country,
        ].where((part) => part != null && part.isNotEmpty).join(', ');
        _reservationPlaceNames[key] = name.isNotEmpty ? name : '$lat, $lng';
      } else {
        _reservationPlaceNames[key] = '$lat, $lng';
      }
    } catch (_) {
      _reservationPlaceNames[key] = '$lat, $lng';
    }

    if (!mounted) return;
    setState(() {});
  }

  void _showFilterBottomSheet() {
    final metrics = _BanquetReservationMetrics.fromContext(context);

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(metrics.sheetTopRadius),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(metrics.sheetPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: metrics.sheetHandleWidth,
                height: metrics.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(
                    metrics.sheetHandleRadius,
                  ),
                ),
              ),
              SizedBox(height: metrics.sheetGap),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    metrics.sheetContainerRadius,
                  ),
                ),
                padding: EdgeInsets.all(metrics.sheetContainerPadding),
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

  Widget _buildCancelHeader() {
    return Row(
      children: [
        const Spacer(),
        AppText(
          text: "Reason for Cancel",
          size: 14,
          fontWeight: FontWeight.w500,
          color: menuIconColor,
          isCentered: true,
        ),
        const Spacer(),
        GestureDetector(
          onTap: _isCancellingReservation
              ? null
              : () {
                  setState(() {
                    isSearchDeletePressed = false;
                    _selectedReservationId = '';
                  });
                },
          child: Icon(Icons.close, size: 25, color: appTextColor3),
        ),
      ],
    );
  }

  Widget _deleteSearchBox() {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.black.withOpacity(.5))),

        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _responsiveDialog(
              child: Container(
                width: double.infinity,

                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .80,
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.22),
                      blurRadius: 32,
                      spreadRadius: 4,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    _buildCancelHeader(),

                    const SizedBox(height: 24),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final size = MediaQuery.sizeOf(context);
                                final isLandscape = size.width > size.height;

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),

                                  itemCount: _cancelReasons.length,

                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isLandscape ? 3 : 1,

                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        mainAxisExtent: 48,
                                      ),

                                  itemBuilder: (_, index) =>
                                      buildStatusButton(_cancelReasons[index]),
                                );
                              },
                            ),

                            const SizedBox(height: 28),

                            AppText(
                              text:
                                  "Canceling a confirmed booking may negatively impact your reliability rating.",
                              size: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              isCentered: true,
                            ),

                            const SizedBox(height: 12),

                            AppText(
                              text:
                                  "However, if you accept another response instead, the previous booking will be automatically replaced without affecting your rating.",
                              size: 13,
                              fontWeight: FontWeight.w400,
                              color: appTextColor2,
                              isCentered: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _showAcceptAnotherReasonPopup,
                      child: AppText(
                        text: "Accept another response",
                        size: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3954DB),
                        isCentered: true,
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: 160,
                      height: 44,
                      child: AppButton(
                        text: _isCancellingReservation
                            ? "Cancelling..."
                            : "Cancel",
                        bgColor1: const Color(0xFFCE3F3F),
                        bgColor2: const Color(0xFFCE3F3F),
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
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          // height: 35.h,
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
          child: _responsiveDialog(
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
                  CancelCircleX(size: 86.w),
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
          child: _responsiveDialog(
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

  // Widget _deleteBox() {
  //   return Stack(
  //     children: [
  //       Container(
  //         height: MediaQuery.of(context).size.height,
  //         width: MediaQuery.of(context).size.width,
  //         decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
  //       ),
  //       Center(
  //         child: Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 30.w),
  //           child: Container(
  //             width: double.infinity,
  //             padding: EdgeInsets.only(
  //               left: 40.w,
  //               right: 40.w,
  //               top: 30.h,
  //               bottom: 30.h,
  //             ),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(15.r),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.1),
  //                   blurRadius: 10.r,
  //                   offset: Offset(0, 4.r),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 AppText(
  //                   text: "Are you sure you want to Cancel this Booking?",
  //                   size: 13,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.black,
  //                   isCentered: true,
  //                   lineSpacing: 1.2,
  //                 ),
  //                 SizedBox(height: 10.h),
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: SizedBox(
  //                         height: 35.h,
  //                         child: AppButton(
  //                           text: _isCancellingReservation
  //                               ? "Cancelling..."
  //                               : "Yes",
  //                           onPressed: _isCancellingReservation
  //                               ? null
  //                               : _cancelSelectedReservation,
  //                           borderRadius: 5.r,
  //                           bgColor1: Colors.green,
  //                           bgColor2: Colors.green,
  //                           size: 12,
  //                         ),
  //                       ),
  //                     ),
  //                     SizedBox(width: 20.w),
  //                     Expanded(
  //                       child: SizedBox(
  //                         height: 35.h,
  //                         child: AppButton(
  //                           text: "No",
  //                           onPressed: () {
  //                             setState(() {
  //                               isDeletePressed = !isDeletePressed;
  //                             });
  //                           },
  //                           size: 12,
  //                           borderRadius: 5.r,
  //                           bgColor1: Colors.red,
  //                           bgColor2: Colors.red,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildFilterOption(String label) {
    final metrics = _BanquetReservationMetrics.fromContext(context);
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
          borderRadius: BorderRadius.circular(metrics.filterOptionRadius),
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
    final reservation = _selectedRequestReservation;
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isLandscape = size.width > size.height;
    final couponId = reservation?.couponId.trim().isNotEmpty == true
        ? reservation!.couponId
        : 'Request details';
    final menuItems = reservation?.menuItems.trim().isNotEmpty == true
        ? reservation!.menuItems
              .split(RegExp(r'[,\n]'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .join(', ')
        : 'No menu details available';
    final persons = reservation == null
        ? 'No person count available'
        : '${reservation.persons} Person';
    final dateTime = reservation == null
        ? 'No date available'
        : '${DateFormat("MMM d").format(reservation.eventDate)} - ${DateFormat("h:mm a").format(reservation.eventDate)}';
    final amount = reservation == null
        ? 'No amount available'
        : '${reservation.pricePerPerson} Per person';
    final radius = _formatRequestRadius(reservation);

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: _responsiveDialog(
            child: Container(
              width: double.infinity,
              //             constraints: BoxConstraints(
              //   maxHeight: MediaQuery.of(context).size.height * 0.85,
              // ),
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: SingleChildScrollView(
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
                              isPartyRequestPressed = false;
                              _selectedRequestReservation = null;
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
                        text: couponId,
                        size: 20,
                        fontWeight: FontWeight.w700,
                        color: appTextColor3,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    // _requestDetailRow(
                    //   iconPath: menuIcon,
                    //   title: "Your Menu",
                    //   value: menuItems,
                    // ),
                    // SizedBox(height: 20.h),
                    // _requestDetailRow(
                    //   iconPath: peopleIcon,
                    //   title: "Number of Persons",
                    //   value: persons,
                    // ),
                    // SizedBox(height: 20.h),
                    // _requestDetailRow(
                    //   iconPath: calenderIcon,
                    //   title: "Date and Time ",
                    //   value: dateTime,
                    // ),
                    // SizedBox(height: 20.h),
                    // _requestDetailRow(
                    //   iconPath: walletIcon,
                    //   title: "Expected amount per person",
                    //   value: amount,
                    // ),
                    // SizedBox(height: 20.h),
                    // _requestDetailRow(
                    //   iconPath: radiusIcon,
                    //   title: "Enquiry Radius ",
                    //   value: radius,
                    // ),
                    if (isTablet && isLandscape) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _requestDetailRow(
                              iconPath: menuIcon,
                              title: "Your Menu",
                              value: menuItems,
                              maxLines: 20,
                            ),
                          ),
                          SizedBox(width: 24.w),
                          Expanded(
                            child: _requestDetailRow(
                              iconPath: peopleIcon,
                              title: "Number of Persons",
                              value: persons,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _requestDetailRow(
                              iconPath: calenderIcon,
                              title: "Date and Time",
                              value: dateTime,
                            ),
                          ),
                          SizedBox(width: 24.w),
                          Expanded(
                            child: _requestDetailRow(
                              iconPath: walletIcon,
                              title: "Expected amount",
                              value: amount,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      _requestDetailRow(
                        iconPath: radiusIcon,
                        title: "Enquiry Radius",
                        value: radius,
                      ),
                    ] else ...[
                      _requestDetailRow(
                        iconPath: menuIcon,
                        title: "Your Menu",
                        value: menuItems,
                        maxLines: 20,
                      ),

                      SizedBox(height: 20.h),

                      _requestDetailRow(
                        iconPath: peopleIcon,
                        title: "Number of Persons",
                        value: persons,
                      ),

                      SizedBox(height: 20.h),

                      _requestDetailRow(
                        iconPath: calenderIcon,
                        title: "Date and Time",
                        value: dateTime,
                      ),

                      SizedBox(height: 20.h),

                      _requestDetailRow(
                        iconPath: walletIcon,
                        title: "Expected amount per person",
                        value: amount,
                      ),

                      SizedBox(height: 20.h),

                      _requestDetailRow(
                        iconPath: radiusIcon,
                        title: "Enquiry Radius",
                        value: radius,
                      ),
                    ],
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _requestDetailRow({
    required String iconPath,
    required String title,
    required String value,
    int? maxLines,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          iconPath,
          width: 20.w,
          height: 20.h,
          color: const Color.fromARGB(255, 15, 15, 15),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: title,
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
                maxLines: maxLines,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatRequestRadius(BanquetReservationModal? reservation) {
    if (reservation == null) return 'No radius available';

    final rawRadius = reservation.searchRadius.trim();
    final lat = reservation.lat.trim();
    final lng = reservation.lng.trim();
    final key = '$lat,$lng';
    final placeName = lat.isNotEmpty && lng.isNotEmpty
        ? _reservationPlaceNames[key]
        : null;

    if (rawRadius.isEmpty && (placeName == null || placeName.isEmpty)) {
      return 'No radius available';
    }

    String radius = rawRadius;
    final parsed = double.tryParse(rawRadius);
    if (parsed != null) {
      radius = parsed % 1 == 0 ? parsed.toInt().toString() : rawRadius;
    }

    final radiusText = radius.isEmpty ? '' : '${radius}km Radius';

    if (placeName != null && placeName.isNotEmpty && radiusText.isNotEmpty) {
      return '$placeName - $radiusText';
    }

    if (placeName != null && placeName.isNotEmpty) return placeName;
    if (lat.isNotEmpty && lng.isNotEmpty && radiusText.isNotEmpty) {
      return '$lat, $lng - $radiusText';
    }
    if (lat.isNotEmpty && lng.isNotEmpty) return '$lat, $lng';
    return radiusText;
  }
}

class _BanquetReservationMetrics {
  const _BanquetReservationMetrics({
    required this.contentHorizontalPadding,
    required this.contentTopPadding,
    required this.searchShadowBlur,
    required this.searchShadowSpread,
    required this.searchTextSize,
    required this.searchRadius,
    required this.sectionGap,
    required this.filterWidth,
    required this.filterHeight,
    required this.filterIconSize,
    required this.filterTextSize,
    required this.stateVerticalPadding,
    required this.stateTextSize,
    required this.stateGap,
    required this.retryButtonWidth,
    required this.retryButtonHeight,
    required this.retryButtonTextSize,
    required this.retryButtonRadius,
    required this.sheetTopRadius,
    required this.sheetPadding,
    required this.sheetHandleWidth,
    required this.sheetHandleHeight,
    required this.sheetHandleRadius,
    required this.sheetGap,
    required this.sheetContainerRadius,
    required this.sheetContainerPadding,
    required this.filterOptionVerticalPadding,
    required this.filterOptionHorizontalPadding,
    required this.filterOptionRadius,
    required this.filterOptionTextSize,
  });

  final double contentHorizontalPadding;
  final double contentTopPadding;
  final double searchShadowBlur;
  final double searchShadowSpread;
  final double searchTextSize;
  final double searchRadius;
  final double sectionGap;
  final double filterWidth;
  final double filterHeight;
  final double filterIconSize;
  final double filterTextSize;
  final double stateVerticalPadding;
  final double stateTextSize;
  final double stateGap;
  final double retryButtonWidth;
  final double retryButtonHeight;
  final double retryButtonTextSize;
  final double retryButtonRadius;
  final double sheetTopRadius;
  final double sheetPadding;
  final double sheetHandleWidth;
  final double sheetHandleHeight;
  final double sheetHandleRadius;
  final double sheetGap;
  final double sheetContainerRadius;
  final double sheetContainerPadding;
  final double filterOptionVerticalPadding;
  final double filterOptionHorizontalPadding;
  final double filterOptionRadius;
  final double filterOptionTextSize;

  factory _BanquetReservationMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final isTablet = Breakpoints.isTabletDevice(size);
    final isLandscape = size.width > size.height;

    final isWideShortPhone = !isTablet && isLandscape && size.height <= 500;

    final isCompactPhone = !isTablet && (size.width < 390 || size.height < 700);

    if (isTablet) {
      final horizontalScale = (size.width / 768).clamp(1.0, 1.16).toDouble();

      final verticalScale = (size.height / 1024).clamp(1.0, 1.18).toDouble();

      double s(double value) => value * horizontalScale;
      double v(double value) => value * verticalScale;

      return _BanquetReservationMetrics(
        contentHorizontalPadding: s(38),
        contentTopPadding: v(30),

        searchShadowBlur: s(12),
        searchShadowSpread: s(4),
        searchTextSize: 15,
        searchRadius: s(18),

        sectionGap: v(20),

        filterWidth: s(170),
        filterHeight: v(38),
        filterIconSize: s(18),
        filterTextSize: 12,

        stateVerticalPadding: v(70),
        stateTextSize: 16,
        stateGap: v(10),

        retryButtonWidth: s(132),
        retryButtonHeight: v(42),
        retryButtonTextSize: 14,
        retryButtonRadius: s(10),

        // Bottom Sheet
        sheetTopRadius: s(28),
        sheetPadding: s(36),
        sheetHandleWidth: s(48),
        sheetHandleHeight: s(5),
        sheetHandleRadius: s(10),
        sheetGap: v(18),
        sheetContainerRadius: s(22),
        sheetContainerPadding: s(20),

        filterOptionVerticalPadding: v(14),
        filterOptionHorizontalPadding: s(10),
        filterOptionRadius: s(10),
        filterOptionTextSize: 16,
      );
    }

    if (isWideShortPhone) {
      return const _BanquetReservationMetrics(
        contentHorizontalPadding: 26,
        contentTopPadding: 18,

        searchShadowBlur: 9,
        searchShadowSpread: 3,
        searchTextSize: 12.5,
        searchRadius: 14,

        sectionGap: 14,

        filterWidth: 132,
        filterHeight: 30,
        filterIconSize: 15,
        filterTextSize: 10,

        stateVerticalPadding: 48,
        stateTextSize: 13,
        stateGap: 12,

        retryButtonWidth: 110,
        retryButtonHeight: 34,
        retryButtonTextSize: 12,
        retryButtonRadius: 9,

        sheetTopRadius: 24,
        sheetPadding: 26,
        sheetHandleWidth: 40,
        sheetHandleHeight: 5,
        sheetHandleRadius: 10,
        sheetGap: 14,
        sheetContainerRadius: 18,
        sheetContainerPadding: 15,

        filterOptionVerticalPadding: 11,
        filterOptionHorizontalPadding: 8,
        filterOptionRadius: 9,
        filterOptionTextSize: 13,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();

      double s(double value) => value * scale;

      return _BanquetReservationMetrics(
        contentHorizontalPadding: s(18),
        contentTopPadding: s(18),

        searchShadowBlur: s(8),
        searchShadowSpread: s(3),
        searchTextSize: s(12),
        searchRadius: s(14),

        sectionGap: s(14),

        filterWidth: s(126),
        filterHeight: s(30),
        filterIconSize: s(14),
        filterTextSize: s(10),

        stateVerticalPadding: s(48),
        stateTextSize: s(13),
        stateGap: s(12),

        retryButtonWidth: s(108),
        retryButtonHeight: s(34),
        retryButtonTextSize: s(12),
        retryButtonRadius: s(9),

        sheetTopRadius: s(22),
        sheetPadding: s(22),
        sheetHandleWidth: s(38),
        sheetHandleHeight: s(4),
        sheetHandleRadius: s(9),
        sheetGap: s(13),
        sheetContainerRadius: s(18),
        sheetContainerPadding: s(14),

        filterOptionVerticalPadding: s(10),
        filterOptionHorizontalPadding: s(8),
        filterOptionRadius: s(9),
        filterOptionTextSize: s(13),
      );
    }

    return _BanquetReservationMetrics(
      contentHorizontalPadding: 20,
      contentTopPadding: 20,

      searchShadowBlur: 10,
      searchShadowSpread: 5,
      searchTextSize: 13,
      searchRadius: 16,

      sectionGap: 20,

      filterWidth: 150.w,
      filterHeight: 30.h,
      filterIconSize: 18.sp,
      filterTextSize: 10.sp,

      stateVerticalPadding: 60,
      stateTextSize: 15,
      stateGap: 14,

      retryButtonWidth: 120,
      retryButtonHeight: 38,
      retryButtonTextSize: 14,
      retryButtonRadius: 10,

      sheetTopRadius: 25.r,
      sheetPadding: 30.w,
      sheetHandleWidth: 40.w,
      sheetHandleHeight: 5.h,
      sheetHandleRadius: 10.r,
      sheetGap: 16.h,
      sheetContainerRadius: 20.r,
      sheetContainerPadding: 16.w,

      filterOptionVerticalPadding: 12.h,
      filterOptionHorizontalPadding: 8.w,
      filterOptionRadius: 10,
      filterOptionTextSize: 15,
    );
  }
}
