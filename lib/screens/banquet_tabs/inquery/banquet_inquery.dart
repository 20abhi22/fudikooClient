import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/model/inquery/create-catering-inquery-model.dart';
import 'package:fudikoclient/model/inquery/create-inquery-model.dart';
import 'package:fudikoclient/model/inquery/list-catering-inquery-model.dart';
import 'package:fudikoclient/model/inquery/list-party-inquery-modal.dart';
import 'package:fudikoclient/model/inquery/response_model.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/responseBox.dart';
import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctInquery.dart';
import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctInqueryBox.dart';
import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctdecline.dart';
import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctresponseBox.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/declineBox.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/screens/tabs/inquery/inquery/planaparty.dart';
import 'package:fudikoclient/screens/tabs/inquery/inquery/viewinquery.dart';
import 'package:fudikoclient/screens/tabs/main_restaurant_nav.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class BanquetInquery extends StatefulWidget {
  const BanquetInquery({super.key});

  @override
  State<BanquetInquery> createState() => _BanquetInqueryState();
}

class _BanquetInqueryState extends State<BanquetInquery> {
  String selectedStatus = 'Plan a Party';
  DateTime selectedDateTime = DateTime.now();
  bool isReviewOnClick = false;
  bool isCtReviewOnClick = false;
  bool isWithdrawOnClick = false;
  bool viewEnquiryOnClick = false;
  bool viewCtEnquiryOnClick = false;
  bool isResponseAcceptOnClick = false;
  bool viewRequest = false;
  bool viewCtRequest = false;
  bool isResponseAcceptConfirmOnClick = false;
  bool isConfirmClicked = false;
  bool viewDeclineOnClick = false;
  bool viewCtDeclineOnClick = false;
  bool isSearchOnClick = false;
  bool isCtSearchOnClick = false;
  Timer? _confirmCloseTimer;
  Map<String, String> ctEnquiryData = {};
  List<CateringInqueryModel> _ctEnquiries = [];
  bool _ctEnquiriesLoading = false;
  String? _pendingEnquiryId; // ← add
  bool _hasExistingBooking = false; // ← add (set true if user already has one)
  String _pendingRestaurantName = ''; // ← add
  String? _pendingEnquiryUuid;

  Map<String, String> partyEnquiryData = {};
  Timer? _partyTimer;
  int _partySeconds = 180;
  bool _responsesLoading = false;
  String _responsesError = '';

  String _declineFilter = "All";
  DateTime? _declineCustomDate;

  List<ResponseModel> _allDeclinedResponses = [];

  /// Returns declined responses filtered by selected quick/custom date.
  List<ResponseModel> get _filteredDeclinedResponses {
    List<ResponseModel> result = _allDeclinedResponses;

    if (_declineFilter == "Today") {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      result = result.where((r) => r.date == today).toList();
    } else if (_declineFilter == "Custom" && _declineCustomDate != null) {
      final String target = DateFormat(
        'yyyy-MM-dd',
      ).format(_declineCustomDate!);
      result = result.where((r) => r.date == target).toList();
    }

    return result;
  }

  /// Returns the label shown in the decline filter dropdown.
  String get _declineFilterLabel {
    if (_declineFilter == "All") return "All";
    if (_declineFilter == "Today") return "Today";
    return DateFormat('MMM d, yyyy').format(_declineCustomDate!);
  }

  /// Opens date picker for decline filter and stores the selected custom date.
  Future<void> _pickDeclineCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _declineCustomDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFEC7B2D),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _declineCustomDate = picked;
        _declineFilter = "Custom";
      });
    }
  }

  /// Renders one decline-filter option inside the bottom sheet.
  Widget _buildDeclineFilterOption(String label, {bool isCustom = false}) {
    final bool isSelected = isCustom
        ? _declineFilter == "Custom"
        : _declineFilter == label;

    return GestureDetector(
      onTap: () async {
        if (isCustom) {
          Navigator.pop(context);
          await _pickDeclineCustomDate();
        } else {
          setState(() {
            _declineFilter = label;
            if (label != "Custom") _declineCustomDate = null;
          });
          Navigator.pop(context);
        }
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
          text: isCustom
              ? (_declineFilter == "Custom" && _declineCustomDate != null
                    ? DateFormat('MMM d, yyyy').format(_declineCustomDate!)
                    : "Select a Date")
              : label,
          size: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }

  String _searchFilter = "All";
  DateTime? _searchCustomDate;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  /// Returns search results after applying date and query filters.
  List<ResponseModel> get _filteredSearchResponses {
    List<ResponseModel> result = _allResponses;

    if (_searchFilter == "Today") {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      result = result.where((r) => r.date == today).toList();
    } else if (_searchFilter == "Custom" && _searchCustomDate != null) {
      final String target = DateFormat('yyyy-MM-dd').format(_searchCustomDate!);
      result = result.where((r) => r.date == target).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final String q = _searchQuery.trim().toLowerCase();
      result = result
          .where(
            (r) =>
                r.couponId.toLowerCase().contains(q) ||
                r.restaurantName.toLowerCase().contains(q),
          )
          .toList();
    }

    return result;
  }

  /// Returns the active search filter label for UI.
  String get _searchFilterLabel {
    if (_searchFilter == "All") return "All";
    if (_searchFilter == "Today") return "Today";
    return DateFormat('MMM d, yyyy').format(_searchCustomDate!);
  }

  /// Opens date picker for search filter and saves custom date.
  Future<void> _pickSearchCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _searchCustomDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFEC7B2D),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _searchCustomDate = picked;
        _searchFilter = "Custom";
      });
    }
  }

  /// Renders one search-filter option inside the bottom sheet.
  Widget _buildSearchFilterOption(String label, {bool isCustom = false}) {
    final bool isSelected = isCustom
        ? _searchFilter == "Custom"
        : _searchFilter == label;

    return GestureDetector(
      onTap: () async {
        if (isCustom) {
          Navigator.pop(context);
          await _pickSearchCustomDate();
        } else {
          setState(() {
            _searchFilter = label;
            if (label != "Custom") _searchCustomDate = null;
          });
          Navigator.pop(context);
        }
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
          text: isCustom
              ? (_searchFilter == "Custom" && _searchCustomDate != null
                    ? DateFormat('MMM d, yyyy').format(_searchCustomDate!)
                    : "Select a Date")
              : label,
          size: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }

  String _responseFilter = "All";
  DateTime? _responseCustomDate;

  List<ResponseModel> _allResponses = [];

  @override
  /// Initializes screen state and loads enquiry responses.
  void initState() {
    super.initState();
    _fetchPartyResponses();
  }

  /// Fetches all party responses and derives declined list for decline tab.
  Future<void> _fetchPartyResponses() async {
    setState(() {
      _responsesLoading = true;
      _responsesError = '';
    });

    final EnquiryResponsesListModel result = await InqueryService()
        .fetchEnquiryResponses();

    if (!mounted) return;

    final List<ResponseModel> declined = result.responses.where((response) {
      final String normalized = response.status.toLowerCase();
      return normalized == 'declined' ||
          normalized == 'rejected' ||
          normalized == 'cancelled';
    }).toList();

    setState(() {
      _allResponses = result.responses;
      _allDeclinedResponses = declined;
      _responsesLoading = false;
      _responsesError = result.status
          ? ''
          : (result.message.isEmpty
                ? 'Unable to fetch responses right now.'
                : result.message);
    });
  }

  /// Returns responses filtered by response-date filter.
  List<ResponseModel> get _filteredResponses {
    if (_responseFilter == "All") return _allResponses;

    final DateTime compareDate = _responseFilter == "Today"
        ? DateTime.now()
        : _responseCustomDate!;
    final String target = DateFormat('yyyy-MM-dd').format(compareDate);

    return _allResponses.where((r) => r.date == target).toList();
  }

  /// Returns selected label for the response filter dropdown.
  String get _responseFilterLabel {
    if (_responseFilter == "All") return "All";
    if (_responseFilter == "Today") return "Today";
    return DateFormat('MMM d, yyyy').format(_responseCustomDate!);
  }

  /// Opens date picker for response filter and stores selected date.
  Future<void> _pickResponseCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _responseCustomDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFEC7B2D),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _responseCustomDate = picked;
        _responseFilter = "Custom";
      });
    }
  }

  /// Renders one response-filter option for the bottom sheet.
  Widget _buildResponseFilterOption(String label, {bool isCustom = false}) {
    final bool isSelected = isCustom
        ? _responseFilter == "Custom"
        : _responseFilter == label;

    return GestureDetector(
      onTap: () async {
        if (isCustom) {
          Navigator.pop(context);
          await _pickResponseCustomDate();
        } else {
          setState(() {
            _responseFilter = label;
            if (label != "Custom") _responseCustomDate = null;
          });
          Navigator.pop(context);
        }
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
          text: isCustom
              ? (_responseFilter == "Custom" && _responseCustomDate != null
                    ? DateFormat('MMM d, yyyy').format(_responseCustomDate!)
                    : "Select a Date")
              : label,
          size: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }

  /// Formats countdown timer text for the review dialog.
  String get _partyTimerText {
    final m = (_partySeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_partySeconds % 60).toString().padLeft(2, '0');
    return "00:$m:$s";
  }

  /// Starts a 3-minute timer for party enquiry review confirmation.
  void _startPartyTimer() {
    _partySeconds = 180;
    _partyTimer?.cancel();
    _partyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_partySeconds <= 0) {
        timer.cancel();
        setState(() => isReviewOnClick = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review time expired. Please try again.'),
          ),
        );
      } else {
        setState(() => _partySeconds--);
      }
    });
  }

  /// Stops and resets the party review timer.
  void _stopPartyTimer() {
    _partyTimer?.cancel();
    _partySeconds = 180;
  }

  /// Converts review data into API model and submits party enquiry.
  Future<void> _submitPartyEnquiry() async {
    final InqueryService service = InqueryService();
    final model = CreateInqueryModel(
      lat: partyEnquiryData['lat'] ?? '',
      lng: partyEnquiryData['lng'] ?? '',
      menuItems: partyEnquiryData['menu'] ?? '',
      people: partyEnquiryData['people'] ?? '',
      date: partyEnquiryData['dateTime']?.split(' ').first ?? '',
      time: () {
        final parts = partyEnquiryData['dateTime']?.split(' ') ?? [];
        return parts.length >= 3 ? '${parts[1]} ${parts[2]}' : '';
      }(),
      estimatedAmount: partyEnquiryData['amount'] ?? '',
      searchRadius: partyEnquiryData['searchRadius'] ?? '20',
      expirationDate: partyEnquiryData['expirationDate'] ?? '',
      expirationTime: partyEnquiryData['expirationTime'] ?? '',
    );

    final response = await service.createInquery(model);
    if (response.status) {
      setState(() => isReviewOnClick = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Party enquiry submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  /// Shows the success state briefly before closing the confirm modal.
  void _autoCloseConfirmBox() {
    _confirmCloseTimer?.cancel();
    _confirmCloseTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        isConfirmClicked = false;
        isResponseAcceptConfirmOnClick = false;
      });
    });
  }

  @override
  /// Disposes local controllers and timers used by this screen.
  void dispose() {
    _partyTimer?.cancel();
    _confirmCloseTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  /// Builds the enquiry screen and switches between major subviews.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: Stack(
        children: [
          if (viewEnquiryOnClick)
            ViewInquery(
              onEnquiryTap: (val) {
                setState(() {
                  viewEnquiryOnClick = val;
                });
              },
            )
          else if (viewDeclineOnClick)
            _viewDeclineWidget()
          else if (isSearchOnClick)
            _viewSearchWidget()
          else
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              buildStatusButton("Plan a Party"),
                              SizedBox(width: 10.w),
                              buildStatusButton("Party Response"),
                            ],
                          ),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: selectedStatus == "Plan a Party"
                      ? PlanAParty(
                          onReviewTap: (data) {
                            setState(() {
                              partyEnquiryData = data;
                              isReviewOnClick = true;
                            });
                            _startPartyTimer();
                          },
                          viewEnquiryOnTap: () {
                            setState(
                              () => viewEnquiryOnClick = !viewEnquiryOnClick,
                            );
                          },
                        )
                      : _responseWidget(),
                ),
              ],
            ),
          if (isResponseAcceptOnClick) _responseAcceptBox(),
          if (viewRequest) _viewRequestWidget(),
          if (isResponseAcceptConfirmOnClick) _responseAcceptConfirmBox(),
          if (isReviewOnClick) _partyReviewBox(),
        ],
      ),
    );
  }

  /// Shows review modal before sending a new party enquiry.
  Widget _partyReviewBox() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(30.w),
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
                          text: partyEnquiryData['couponId'] ?? 'Review',
                          size: 20,
                          fontWeight: FontWeight.w700,
                          color: appTextColor3,
                        ),
                        GestureDetector(
                          onTap: () {
                            _stopPartyTimer();
                            setState(() => isReviewOnClick = false);
                          },
                          child: AppText(
                            text: "Edit",
                            size: 15,
                            fontWeight: FontWeight.w700,
                            color: appLinkColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.dashboard,
                      "Your Menu",
                      partyEnquiryData['menu'] ?? '',
                    ),

                    SizedBox(height: 20.h),

                    _reviewRow(
                      Icons.people,
                      "Number of Persons",
                      "${partyEnquiryData['people'] ?? ''} Person",
                    ),

                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.calendar_today_sharp,
                      "Date and Time",
                      partyEnquiryData['dateTime'] ?? '',
                    ),

                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.wallet,
                      "Expected amount per person",
                      "${partyEnquiryData['amount'] ?? ''} Per person",
                    ),

                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.analytics,
                      "Enquiry Radius",
                      partyEnquiryData['location'] ?? '',
                    ),

                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.date_range,
                      "Enquiry Valid Until (Date)",
                      partyEnquiryData['expirationDate'] ?? '',
                    ),

                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.schedule,
                      "Enquiry Valid Until (Time)",
                      partyEnquiryData['expirationTime'] ?? '',
                    ),

                    SizedBox(height: 30.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, size: 20.w, color: Colors.red),
                        SizedBox(width: 5.w),
                        AppText(
                          text: _partyTimerText,
                          size: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    SizedBox(
                      width: 150.w,
                      height: 50.h,
                      child: AppButton(
                        text: "Send",
                        onPressed: () {
                          _stopPartyTimer();
                          _submitPartyEnquiry();
                        },
                        size: 15,
                        bgColor1: Colors.green,
                        bgColor2: Colors.green,
                        borderRadius: 10,
                      ),
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

  /// Reusable row used in enquiry review and request details.
  Widget _reviewRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.w, color: appTextColor2),
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

  /// Modal that confirms booking action after accept flow.
  Widget _responseAcceptConfirmBox() {
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isResponseAcceptConfirmOnClick =
                                !isResponseAcceptConfirmOnClick;
                            if (isConfirmClicked) {
                              isConfirmClicked = !isConfirmClicked;
                            }
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: appTextColor3,
                          size: 25.w,
                        ),
                      ),
                    ],
                  ),

                  if (isConfirmClicked)
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/checked.png',
                          height: 50.h,
                          width: 50.w,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 20.h),
                        AppText(
                          text: "Booking Successful!",
                          size: 20,
                          fontWeight: FontWeight.w500,
                          color: appTextColor3,
                          isCentered: true,
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),

                  if (!isConfirmClicked)
                    Column(
                      children: [
                        SizedBox(height: 20.h),
                        AppText(
                          text:
                              "After confirmation, your party order will be booked at $_pendingRestaurantName.",
                          size: 15,
                          fontWeight: FontWeight.w500,
                          color: appTextColor2,
                          isCentered: true,
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: 150.w,
                          height: 40.h,
                          child: AppButton(
                            text: "Confirm",
                            onPressed: () async {
                              if (_pendingEnquiryId == null) return;

                              print(
                                'Confirming with enquiry_id: $_pendingEnquiryUuid',
                              );
                              final result = await InqueryService()
                                  .confirmEnquiry(_pendingEnquiryUuid!);
                              if (!mounted) return;
                              if (result['status'] == true) {
                                setState(() => isConfirmClicked = true);
                                _autoCloseConfirmBox();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['message'] ??
                                          'Confirmation failed',
                                    ),
                                  ),
                                );
                              }
                            },
                            bgColor1: Colors.green,
                            bgColor2: Colors.green,
                            size: 15,
                            borderRadius: 10,
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Search screen for responses with text and date filters.
  Widget _viewSearchWidget() {
    final results = _filteredSearchResponses;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(fontSize: 13.sp, color: appTextColor3),
                  decoration: InputDecoration(
                    hintText: "Search by coupon code or hotel name",
                    hintStyle: TextStyle(fontSize: 13.sp, color: appTextColor3),
                    prefixIcon: Icon(
                      Icons.search,
                      color: appTextColor3,
                      size: 20.w,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchQuery = "";
                                _searchController.clear();
                              });
                            },
                            child: Icon(
                              Icons.close,
                              color: appTextColor3,
                              size: 20.w,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14.h,
                      horizontal: 16.w,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            SizedBox(
              width: 180.w,
              child: AppFilterDropDown(
                hint: _searchFilterLabel, // â† shows selected label
                icon: Icons.tune,
                toggleDropdown: () {
                  showModalBottomSheet(
                    backgroundColor: Colors.white,
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25.r),
                      ),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: EdgeInsets.all(30.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40.w,
                              height: 5.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                children: [
                                  _buildSearchFilterOption("All"),
                                  Divider(color: Colors.grey[200]),
                                  _buildSearchFilterOption("Today"),
                                  Divider(color: Colors.grey[200]),
                                  _buildSearchFilterOption(
                                    "Select a Date",
                                    isCustom: true,
                                  ),
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

            Expanded(
              child: _responsesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _responsesError.isNotEmpty
                  ? Center(
                      child: AppText(
                        text: _responsesError,
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor3,
                        isCentered: true,
                      ),
                    )
                  : results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48.w,
                            color: appTextColor3.withOpacity(0.4),
                          ),
                          SizedBox(height: 12.h),
                          AppText(
                            text: _searchQuery.isNotEmpty
                                ? "No results for \"$_searchQuery\""
                                : "No responses for $_searchFilterLabel",
                            size: 15,
                            fontWeight: FontWeight.w500,
                            color: appTextColor3,
                            isCentered: true,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(left: 30.w, right: 30.w),
                          child: ResponseBox(
                            response: results[index],
                            viewRequestClick: () =>
                                setState(() => viewRequest = !viewRequest),
                            onAcceptTap: () {
                              _pendingEnquiryId = results[index].couponId;
                              _pendingRestaurantName =
                                  results[index].restaurantName; // ← add
                              _pendingEnquiryUuid = results[index].uuid;
                              ;
                              setState(
                                () => isResponseAcceptOnClick =
                                    _hasExistingBooking,
                              );
                              if (!_hasExistingBooking) {
                                setState(
                                  () => isResponseAcceptConfirmOnClick = true,
                                );
                              }
                            },
                            onCancelTap: () => setState(() {}),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ],
    );
  }

  /// Screen showing declined responses with date filtering.
  Widget _viewDeclineWidget() {
    final declined = _filteredDeclinedResponses;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                      () => viewDeclineOnClick = !viewDeclineOnClick,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: appTextColor3,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 180.w,
                        child: AppFilterDropDown(
                          hint: _declineFilterLabel, // â† shows selected label
                          icon: Icons.tune,
                          toggleDropdown: () {
                            showModalBottomSheet(
                              backgroundColor: Colors.white,
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(25.r),
                                ),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: EdgeInsets.all(30.w),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40.w,
                                        height: 5.h,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      Container(
                                        width: MediaQuery.of(
                                          context,
                                        ).size.width,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                        ),
                                        padding: EdgeInsets.all(16.w),
                                        child: Column(
                                          children: [
                                            _buildDeclineFilterOption("All"),
                                            Divider(color: Colors.grey[200]),
                                            _buildDeclineFilterOption("Today"),
                                            Divider(color: Colors.grey[200]),
                                            _buildDeclineFilterOption(
                                              "Select a Date",
                                              isCustom: true,
                                            ),
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
                  ),
                  SizedBox(width: 28.w),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            Expanded(
              child: _responsesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _responsesError.isNotEmpty
                  ? Center(
                      child: AppText(
                        text: _responsesError,
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor3,
                        isCentered: true,
                      ),
                    )
                  : declined.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48.w,
                            color: appTextColor3.withOpacity(0.4),
                          ),
                          SizedBox(height: 12.h),
                          AppText(
                            text:
                                "No declined responses for $_declineFilterLabel",
                            size: 15,
                            fontWeight: FontWeight.w500,
                            color: appTextColor3,
                            isCentered: true,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: declined.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(left: 30.w, right: 30.w),
                          child: DeclineBox(
                            response: declined[index],
                            onCancelTap: () => setState(() {}),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ],
    );
  }

  /// Overlay showing static requested-party detail preview.
  Widget _viewRequestWidget() {
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
                            viewRequest = !viewRequest;
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: appTextColor3,
                          size: 25.w,
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
                      Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
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
                      Icon(Icons.people, size: 20.w, color: appTextColor2),
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
                        size: 20.w,
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

  /// Warning modal shown before switching banquet booking.
  Widget _responseAcceptBox() {
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
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 50.w,
                    color: Colors.red,
                  ),
                  SizedBox(height: 10.h),
                  AppText(
                    text: "Switch Banquet Booking?",
                    isCentered: true,
                    lineSpacing: 1.5,
                    size: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                  SizedBox(height: 10.h),
                  AppText(
                    text:
                        " You already have a banquet booked at $_pendingRestaurantName. Booking another Banquet will automatically cancel your previous booking.",
                    isCentered: true,
                    lineSpacing: 1.5,
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor2,
                  ),

                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        text: "Cancel",
                        size: 15,
                        fontWeight: FontWeight.w400,
                        color: appLinkColor2,
                      ),
                      SizedBox(
                        width: 120.w,
                        height: 40.h,
                        child: AppButton(
                          text: "Yes,Book",
                          onPressed: () {
                            setState(() {
                              isResponseAcceptOnClick = false;
                              isResponseAcceptConfirmOnClick = true;
                            });
                          },
                          size: 15,
                          bgColor1: Colors.green,
                          bgColor2: Colors.green,
                          borderRadius: 10,
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
    );
  }

  /// Main response list section with filters and quick actions.
  Widget _responseWidget() {
    final responses = _filteredResponses;

    return Column(
      children: [
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 150.w,
                child: AppFilterDropDown(
                  hint: _responseFilterLabel, // â† shows selected label
                  icon: Icons.tune,
                  toggleDropdown: () {
                    showModalBottomSheet(
                      backgroundColor: Colors.white,
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25.r),
                        ),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.all(30.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40.w,
                                height: 5.h,
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
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  children: [
                                    _buildResponseFilterOption("All"),
                                    Divider(color: Colors.grey[200]),
                                    _buildResponseFilterOption("Today"),
                                    Divider(color: Colors.grey[200]),
                                    _buildResponseFilterOption(
                                      "Select a Date",
                                      isCustom: true,
                                    ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.search, size: 17.w, color: Colors.black),
                      SizedBox(width: 2.w),
                      GestureDetector(
                        onTap: () =>
                            setState(() => isSearchOnClick = !isSearchOnClick),
                        child: AppText(
                          text: "Search",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.book, size: 17.w, color: appLinkColor2),
                      SizedBox(width: 2.w),
                      GestureDetector(
                        onTap: () => setState(
                          () => viewDeclineOnClick = !viewDeclineOnClick,
                        ),
                        child: AppText(
                          text: "View Declined",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: appLinkColor2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Expanded(
          child: _responsesLoading
              ? const Center(child: CircularProgressIndicator())
              : _responsesError.isNotEmpty
              ? Center(
                  child: AppText(
                    text: _responsesError,
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
                    isCentered: true,
                  ),
                )
              : responses.isEmpty
              ? Center(
                  child: AppText(
                    text: "No responses for $_responseFilterLabel",
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
                    isCentered: true,
                  ),
                )
              : ListView.builder(
                  itemCount: responses.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.w),
                      child: ResponseBox(
                        response: responses[index],
                        viewRequestClick: () =>
                            setState(() => viewRequest = !viewRequest),
                        onAcceptTap: () {
                          _pendingEnquiryId = responses[index].couponId;
                          _pendingRestaurantName =
                              responses[index].restaurantName; // ← add
                          _pendingEnquiryUuid = responses[index].uuid;
                          ;
                          setState(
                            () => isResponseAcceptOnClick = _hasExistingBooking,
                          );
                          if (!_hasExistingBooking) {
                            setState(
                              () => isResponseAcceptConfirmOnClick = true,
                            );
                          }
                        },
                        onCancelTap: () => setState(() {}),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Builds a tab-like status button for top section switching.
  Widget buildStatusButton(String text) {
    final bool isSelected = selectedStatus == text;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStatus = text;
          });
          if (text == "Party Response") {
            _fetchPartyResponses();
          }
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
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6.r,
                offset: Offset(2.w, 2.w),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.w,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor3,
            ),
          ),
        ),
      ),
    );
  }
}
