import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
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
import 'package:geocoding/geocoding.dart';

class BanquetInquery extends StatefulWidget {
  const BanquetInquery({super.key});

  @override
  State<BanquetInquery> createState() => _BanquetInqueryState();
}

class _BanquetInqueryState extends State<BanquetInquery> {
  // ── Tab selection ─────────────────────────────────────────
  String selectedStatus = 'Plan a Party';

  // ── Overlay/modal flags ───────────────────────────────────
  bool isReviewOnClick = false;
  bool isCtReviewOnClick = false;
  bool isWithdrawOnClick = false;
  bool viewEnquiryOnClick = false; // ← controls ViewInquery subview
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

  // ── Confirm auto-close ────────────────────────────────────
  Timer? _confirmCloseTimer;

  // ── Pending booking state ─────────────────────────────────
  String? _pendingEnquiryId;
  String? _pendingEnquiryUuid;
  String _pendingRestaurantName = '';
  bool _hasExistingBooking = false;

  // ── Catering enquiries ────────────────────────────────────
  Map<String, String> ctEnquiryData = {};
  List<CateringInqueryModel> _ctEnquiries = [];
  bool _ctEnquiriesLoading = false;

  // ── Party review timer ────────────────────────────────────
  Map<String, String> partyEnquiryData = {};
  Timer? _partyTimer;
  int _partySeconds = 180;
  // Key to access PlanAParty state for clearing fields after send
  final GlobalKey planPartyKey = GlobalKey();

  // ── Responses ─────────────────────────────────────────────
  bool _responsesLoading = false;
  String _responsesError = '';
  List<ResponseModel> _allResponses = [];
  List<ResponseModel> _allDeclinedResponses = [];
  ResponseModel? _selectedResponse;
  final Map<String, String> _placeNames = {}; // cache lat,lng -> place name

  // ── Decline filter ────────────────────────────────────────
  String _declineFilter = "All";
  DateTime? _declineCustomDate;

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

  String get _declineFilterLabel {
    if (_declineFilter == "All") return "All";
    if (_declineFilter == "Today") return "Today";
    if (_declineCustomDate != null)
      return DateFormat('MMM d, yyyy').format(_declineCustomDate!);
    return "All";
  }

  Future<void> _pickDeclineCustomDate() async {
    final DateTime? picked = await _pickCustomCalendarDatePopup(
      _declineCustomDate,
    );
    if (picked != null && mounted) {
      setState(() {
        _declineCustomDate = picked;
        _declineFilter = "Custom";
      });
    }
  }

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
          borderRadius: BorderRadius.circular(10.r),
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

  // ── Search filter ─────────────────────────────────────────
  String _searchFilter = "All";
  DateTime? _searchCustomDate;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;

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

  String get _searchFilterLabel {
    if (_searchFilter == "All") return "All";
    if (_searchFilter == "Today") return "Today";
    if (_searchCustomDate != null)
      return DateFormat('MMM d, yyyy').format(_searchCustomDate!);
    return "All";
  }

  Future<void> _pickSearchCustomDate() async {
    final DateTime? picked = await _pickCustomCalendarDatePopup(
      _searchCustomDate,
    );
    if (picked != null && mounted) {
      setState(() {
        _searchCustomDate = picked;
        _searchFilter = "Custom";
      });
    }
  }

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
          borderRadius: BorderRadius.circular(10.r),
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

  // ── Response filter ───────────────────────────────────────
  String _responseFilter = "All";
  DateTime? _responseCustomDate;

  List<ResponseModel> get _filteredResponses {
    if (_responseFilter == "All") return _allResponses;
    if (_responseFilter == "Custom" && _responseCustomDate == null)
      return _allResponses;
    final DateTime compareDate = _responseFilter == "Today"
        ? DateTime.now()
        : _responseCustomDate!;
    final String target = DateFormat('yyyy-MM-dd').format(compareDate);
    return _allResponses.where((r) => r.date == target).toList();
  }

  String get _responseFilterLabel {
    if (_responseFilter == "All") return "All";
    if (_responseFilter == "Today") return "Today";
    if (_responseCustomDate != null)
      return DateFormat('MMM d, yyyy').format(_responseCustomDate!);
    return "All";
  }

  double _filterDropdownWidth(String label) {
    final textWidth = (label.length * 7.5).w;
    return (textWidth + 76.w).clamp(120.w, 190.w).toDouble();
  }

  Future<void> _pickResponseCustomDate() async {
    final DateTime? picked = await _pickCustomCalendarDatePopup(
      _responseCustomDate,
    );
    if (picked != null && mounted) {
      setState(() {
        _responseCustomDate = picked;
        _responseFilter = "Custom";
      });
    }
  }

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
          borderRadius: BorderRadius.circular(10.r),
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

  Future<DateTime?> _pickCustomCalendarDatePopup(DateTime? selectedDate) {
    DateTime tempDate = selectedDate ?? DateTime.now();

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCustomCalendar(
                      tempDate: tempDate,
                      onDateChanged: (date) =>
                          setDialogState(() => tempDate = date),
                    ),
                    SizedBox(height: 16.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, tempDate),
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                color: const Color(0xFF3954DB),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _pickCustomCalendarDate(DateTime? selectedDate) {
    DateTime tempDate = selectedDate ?? DateTime.now();

    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  SizedBox(height: 16.h),
                  AppText(
                    text: "Select a Date",
                    size: 16,
                    fontWeight: FontWeight.w600,
                    color: appTextColor3,
                  ),
                  SizedBox(height: 12.h),
                  _buildCustomCalendar(
                    tempDate: tempDate,
                    onDateChanged: (date) =>
                        setSheetState(() => tempDate = date),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: AppText(
                            text: "Cancel",
                            size: 14,
                            fontWeight: FontWeight.w500,
                            color: appTextColor2,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: SizedBox(
                          height: 42.h,
                          child: AppButton(
                            text: "Apply",
                            size: 14,
                            borderRadius: 10.r,
                            onPressed: () =>
                                Navigator.pop(sheetContext, tempDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchPartyResponses();
    _fetchDeclinedResponses(); // Fetch declined responses when the tab is opened
  }

  Future<void> _openRequestDetails(ResponseModel response) async {
    setState(() {
      _selectedResponse = response;
      viewRequest = true;
    });

    await _ensurePlaceNameFor(response);
  }

  Future<void> _ensurePlaceNameFor(ResponseModel? response) async {
    if (response == null) return;
    final lat = response.requestLat?.trim() ?? '';
    final lng = response.requestLng?.trim() ?? '';
    if (lat.isEmpty || lng.isEmpty) return;
    final key = '$lat,$lng';
    if (_placeNames.containsKey(key)) return;
    try {
      final double latD = double.parse(lat);
      final double lngD = double.parse(lng);
      final placemarks = await placemarkFromCoordinates(latD, lngD);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final name = [
          place.subLocality,
          place.locality,
          place.country,
        ].where((p) => p != null && p.isNotEmpty).join(', ');
        _placeNames[key] = name.isNotEmpty ? name : '$lat, $lng';
      } else {
        _placeNames[key] = '$lat, $lng';
      }
    } catch (_) {
      _placeNames[key] = '$lat, $lng';
    }
    if (!mounted) return;
    setState(() {});
  }

  String _requestDateTime(ResponseModel? response) {
    if (response == null) return '-';
    final rawDate = response.requestDate?.trim() ?? response.date ?? '';
    final rawTime = response.requestTime?.trim() ?? response.time ?? '';
    String date = '';
    String time = '';
    if (rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      date = parsed != null ? DateFormat('MMMM d').format(parsed) : rawDate;
    }
    if (rawTime.isNotEmpty) {
      final lower = rawTime.toLowerCase();
      if (lower.contains('am') || lower.contains('pm')) {
        time = lower;
      } else {
        try {
          final parsedTime = DateFormat('HH:mm').parse(rawTime);
          time = DateFormat('h:mm a').format(parsedTime).toLowerCase();
        } catch (_) {
          time = rawTime;
        }
      }
    }
    if (date.isEmpty && time.isEmpty) return '-';
    if (date.isEmpty) return time;
    if (time.isEmpty) return date;
    return '$date - $time';
  }

  String _requestRadius(ResponseModel? response) {
    if (response == null) return '-';
    final radius = response.requestSearchRadius?.trim() ?? '';
    final lat = response.requestLat?.trim() ?? '';
    final lng = response.requestLng?.trim() ?? '';
    if (lat.isEmpty && lng.isEmpty && radius.isEmpty) return '-';
    final key = '$lat,$lng';
    final placeName =
        (lat.isNotEmpty && lng.isNotEmpty && _placeNames.containsKey(key))
        ? _placeNames[key]
        : '';
    if (placeName != null && placeName.isNotEmpty && radius.isNotEmpty)
      return '$placeName - ${radius}km Radius';
    if (placeName != null && placeName.isNotEmpty) return placeName;
    if (lat.isNotEmpty && lng.isNotEmpty && radius.isNotEmpty)
      return '$lat, $lng - ${radius}km Radius';
    if (radius.isNotEmpty) return '$radius km Radius';
    if (lat.isNotEmpty && lng.isNotEmpty) return '$lat, $lng';
    return '-';
  }

  @override
  void dispose() {
    _partyTimer?.cancel();
    _confirmCloseTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data fetching ─────────────────────────────────────────
  Future<void> _fetchPartyResponses() async {
    if (!mounted) return;
    setState(() {
      _responsesLoading = true;
      _responsesError = '';
    });
    try {
      final EnquiryResponsesListModel result = await InqueryService()
          .fetchEnquiryResponses();
      if (!mounted) return;

      // Debug: log result to help diagnose empty responses
      try {
        // ignore: avoid_print
        print(
          'FETCH ENQUIRY RESPONSES - status: ${result.status}, message: ${result.message}, count: ${result.responses.length}',
        );
      } catch (_) {}

      final List<ResponseModel> declined = result.responses.where((r) {
        final String normalized = r.status.toLowerCase();
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _responsesLoading = false;
        _responsesError = 'Failed to load responses. Please try again.';
      });
    }
  }

  Future<void> _fetchDeclinedResponses() async {
    if (!mounted) return;
    setState(() {
      _responsesLoading = true;
      _responsesError = '';
    });

    try {
      final EnquiryResponsesListModel result = await InqueryService()
          .fetchDeclinedEnquiryResponses();
      if (!mounted) return;

      setState(() {
        _allDeclinedResponses = result.responses;
        _responsesLoading = false;
        _responsesError = result.status
            ? ''
            : (result.message.isEmpty
                  ? 'Unable to fetch declined responses right now.'
                  : result.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _responsesLoading = false;
        _responsesError =
            'Failed to load declined responses. Please try again.';
      });
    }
  }

  // ── Party timer ───────────────────────────────────────────
  String get _partyTimerText {
    final m = (_partySeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_partySeconds % 60).toString().padLeft(2, '0');
    return "00:$m:$s";
  }

  void _startPartyTimer() {
    _partySeconds = 180;
    _partyTimer?.cancel();
    _partyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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

  void _stopPartyTimer() {
    _partyTimer?.cancel();
    _partySeconds = 180;
  }

  // ── Submit party enquiry ──────────────────────────────────
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
    if (!mounted) return;
    if (response.status) {
      setState(() => isReviewOnClick = false);
      // Clear the PlanAParty form fields
      try {
        (planPartyKey.currentState as dynamic)?.clearFields();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Party enquiry submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

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

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main content area ─────────────────────────────
            // KEY FIX: ViewInquery is placed inside Expanded inside a Column.
            // It is a plain Column widget (no Scaffold), so it inherits the
            // bounded height from the Expanded and no longer overflows.
            if (viewEnquiryOnClick)
              Positioned.fill(
                child: ViewInquery(
                  onEnquiryTap: (val) => setState(() => viewEnquiryOnClick = val),
                ),
              )
            // Column(
            //   children: [
            //     Expanded(
            //       child: ViewInquery(
            //         onEnquiryTap: (val) =>
            //             setState(() => viewEnquiryOnClick = val),
            //       ),
            //     ),
            //   ],
            // )
            // else if (viewDeclineOnClick)
            //   _viewDeclineWidget()
            else if (viewDeclineOnClick)
              // ✅ Wrap this too
              Positioned.fill(child: _viewDeclineWidget())
            // else if (isSearchOnClick)
            //   _viewSearchWidget()
            else if (isSearchOnClick)
              // ✅ And this
              Positioned.fill(child: _viewSearchWidget())
            else
              Column(
                children: [
                  // ── Tab buttons ──────────────────────────────
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      children: [
                        buildStatusButton("Plan a Party"),
                        SizedBox(width: 10.w),
                        buildStatusButton("Response"),
                      ],
                    ),
                  ),
                  // ── Tab content ──────────────────────────────
                  Expanded(
                    child: selectedStatus == "Plan a Party"
                        ? PlanAParty(
                            key: planPartyKey,
                            onReviewTap: (data) {
                              setState(() {
                                partyEnquiryData = data;
                                isReviewOnClick = true;
                              });
                              _startPartyTimer();
                            },
                            viewEnquiryOnTap: () =>
                                setState(() => viewEnquiryOnClick = true),
                          )
                        : _responseWidget(),
                  ),
                ],
              ),
        
            // ── Overlays (always on top in Stack) ─────────────
            if (isResponseAcceptOnClick) _responseAcceptBox(),
            if (viewRequest) _viewRequestWidget(),
            if (isResponseAcceptConfirmOnClick) _responseAcceptConfirmBox(),
            if (isReviewOnClick) _partyReviewBox(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SUBVIEW: Decline list
  // ─────────────────────────────────────────────────────────
  Widget _viewDeclineWidget() {
    final declined = _filteredDeclinedResponses;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => viewDeclineOnClick = false),
                child: Image.asset(
                  backOrange,
                  height: 28.h,
                  width: 28.w,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: _filterDropdownWidth(_declineFilterLabel),
                    child: AppFilterDropDown(
                      height: 32.h,
                      hint: _declineFilterLabel,
                      imageIconPath: filterIcon,
                      imageIconSize: 15.sp,
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
                          builder: (_) => Padding(
                            padding: EdgeInsets.all(30.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _sheetHandle(),
                                SizedBox(height: 16.h),
                                _sheetContainer([
                                  _buildDeclineFilterOption("All"),
                                  Divider(color: Colors.grey[200]),
                                  _buildDeclineFilterOption("Today"),
                                  Divider(color: Colors.grey[200]),
                                  _buildDeclineFilterOption(
                                    "Select a Date",
                                    isCustom: true,
                                  ),
                                ]),
                              ],
                            ),
                          ),
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
          child: RefreshIndicator(
            color: appButtonColor,
            onRefresh: _fetchDeclinedResponses,
            child: _responsesLoading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : _responsesError.isNotEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      SizedBox(height: 120.h),
                      _errorText(_responsesError),
                    ],
                  )
                : declined.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      SizedBox(height: 120.h),
                      _emptyState(
                        Icons.inbox_outlined,
                        "No declined responses for $_declineFilterLabel",
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 24.h),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: declined.length,
                    itemBuilder: (ctx, index) => Padding(
                      padding: EdgeInsets.only(left: 30.w, right: 30.w),
                      child: DeclineBox(
                        response: declined[index],
                        onCancelTap: () async {
                          final resp = await InqueryService()
                              .deleteDeclinedEnquiryResponse(
                                declined[index].uuid,
                              );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(resp['message'] ?? '')),
                          );
                          await _fetchDeclinedResponses();
                        },
                        onRestoreTap: () async {
                          final resp = await InqueryService()
                              .restoreEnquiryResponse(declined[index].uuid);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(resp['message'] ?? '')),
                          );
                          await _fetchDeclinedResponses();
                        },
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // SUBVIEW: Search
  // ─────────────────────────────────────────────────────────
  Widget _viewSearchWidget() {
    final results = _filteredSearchResponses;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
          child: Row(
            children: [
              //  GestureDetector(
              //     onTap: () => setState(() => isSearchOnClick = false),
              //     child: Icon(
              //       Icons.arrow_back_ios_new,
              //       color: appTextColor3,
              //       size: 28.w,
              //     ),
              //   ),
              // SizedBox(width: 12.w),
              Expanded(child: _searchInputField()),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: _filterDropdownWidth(_searchFilterLabel),
          child: AppFilterDropDown(
            height: 32.h,
            hint: _searchFilterLabel,
            imageIconPath: filterIcon,
            imageIconSize: 18.sp,
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
                builder: (_) => Padding(
                  padding: EdgeInsets.all(30.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sheetHandle(),
                      SizedBox(height: 16.h),
                      _sheetContainer([
                        _buildSearchFilterOption("All"),
                        Divider(color: Colors.grey[200]),
                        _buildSearchFilterOption("Today"),
                        Divider(color: Colors.grey[200]),
                        _buildSearchFilterOption(
                          "Select a Date",
                          isCustom: true,
                        ),
                      ]),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20.h),
        Expanded(
          child: _responsesLoading
              ? const Center(child: CircularProgressIndicator())
              : _responsesError.isNotEmpty
              ? _errorText(_responsesError)
              : results.isEmpty
              ? _emptyState(
                  Icons.search_off,
                  _searchQuery.isNotEmpty
                      ? 'No results for "$_searchQuery"'
                      : "No responses for $_searchFilterLabel",
                )
              : RefreshIndicator(
                  color: appButtonColor,
                  onRefresh: _fetchPartyResponses,
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: 24.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: results.length,
                    itemBuilder: (ctx, index) => Padding(
                      padding: EdgeInsets.only(left: 30.w, right: 30.w),
                      child: ResponseBox(
                        response: results[index],
                        viewRequestClick: () =>
                            _openRequestDetails(results[index]),
                        onAcceptTap: () => _handleAcceptTap(results[index]),
                        onCancelTap: () => _fetchPartyResponses(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Search input with toggle (replicates reservation search UX) ──
  Widget _searchInputField() {
    if (!_isSearchActive) {
      return GestureDetector(
        onTap: () => setState(() => _isSearchActive = true),
        child: Container(
          height: 50.h,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 0),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: AppText(
              text: "Search by coupon code or hotel name",
              size: 13,
              color: appTextColor3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 0),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _searchController.clear();

              setState(() {
                _isSearchActive = false;
                _searchQuery = "";
              });
            },
            child: Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Icon(Icons.close, size: 20.w, color: appTextColor3),
            ),
          ),

          Expanded(
            child: AppTextFeild(
              text: "Search by coupon code or hotel name",

              controller: _searchController,

              backgroundColor: Colors.white,

              height: 50.h,

              fieldBorderRadius: 16.r,

              textColor: appTextColor5,

              size: 13,

              boxShadow: const [],

              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },

              inputContentPadding: EdgeInsets.symmetric(
                vertical: 14.h,
                horizontal: 12.w,
              ),

              decoration: InputDecoration(
                border: InputBorder.none,

                hintText: "Search by coupon code ",

                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: appTextColor3,
                  fontWeight: FontWeight.w400,
                ),

                contentPadding: EdgeInsets.symmetric(
                  vertical: 14.h,
                  horizontal: 12.w,
                ),

                // suffixIcon: _searchQuery.isNotEmpty
                //     ? GestureDetector(
                //         onTap: () {
                //           setState(() {
                //             _searchQuery = "";
                //             _searchController.clear();
                //           });
                //         },
                //         // child: Icon(
                //         //   Icons.close,
                //         //   color: appTextColor3,
                //         //   size: 18.w,
                //         // ),
                //       )
                //     : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SUBVIEW: Response list
  // ─────────────────────────────────────────────────────────
  Widget _responseWidget() {
    final responses = _filteredResponses;
    return Column(
      children: [
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: _filterDropdownWidth(_responseFilterLabel),
                    child: AppFilterDropDown(
                      height: 32.h,
                      hint: _responseFilterLabel,
                      imageIconPath: filterIcon,
                      imageIconSize: 15,
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
                          builder: (_) => Padding(
                            padding: EdgeInsets.all(30.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _sheetHandle(),
                                SizedBox(height: 16.h),
                                _sheetContainer([
                                  _buildResponseFilterOption("All"),
                                  Divider(color: Colors.grey[200]),
                                  _buildResponseFilterOption("Today"),
                                  Divider(color: Colors.grey[200]),
                                  _buildResponseFilterOption(
                                    "Select a Date",
                                    isCustom: true,
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isSearchOnClick = true),
                    child: Row(
                      children: [
                        // Icon(Icons.search, size: 17.w, color: Colors.black),
                        Image.asset(searchBlackIcon, width: 12.w, height: 12.h),
                        // SvgPicture.asset(
                        //   searchBlackIcon,
                        //   width: 17.w,
                        //   height: 17.h,
                        //   colorFilter: ColorFilter.mode(
                        //     appTextColor2,
                        //     BlendMode.srcIn,
                        //   ),
                        // ),
                        SizedBox(width: 2.w),
                        AppText(
                          text: "Search",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5.h),
                  GestureDetector(
                    onTap: () {
                      setState(() => viewDeclineOnClick = true);
                      _fetchDeclinedResponses();
                    },
                    child: Row(
                      children: [
                        Image.asset(inqueryIcon, width: 17.w, height: 17.h),
                        SizedBox(width: 2.w),
                        AppText(
                          text: "View Declined",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: appLinkColor2,
                        ),
                      ],
                    ),
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
              ? _errorText(_responsesError)
              : responses.isEmpty
              ? _emptyState(
                  Icons.inbox_outlined,
                  "No responses for $_responseFilterLabel",
                )
              : RefreshIndicator(
                  color: appButtonColor,
                  onRefresh: _fetchPartyResponses,
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: 24.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: responses.length,
                    itemBuilder: (ctx, index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.w),
                      child: ResponseBox(
                        response: responses[index],
                        viewRequestClick: () =>
                            _openRequestDetails(responses[index]),
                        onAcceptTap: () => _handleAcceptTap(responses[index]),
                        onCancelTap: () => _fetchPartyResponses(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Accept tap shared logic ───────────────────────────────
  void _handleAcceptTap(ResponseModel r) {
    _pendingEnquiryId = r.couponId;
    _pendingRestaurantName = r.restaurantName;
    _pendingEnquiryUuid = r.uuid;
    if (_hasExistingBooking) {
      setState(() => isResponseAcceptOnClick = true);
    } else {
      setState(() => isResponseAcceptConfirmOnClick = true);
    }
  }

  // ─────────────────────────────────────────────────────────
  // OVERLAY WIDGETS
  // ─────────────────────────────────────────────────────────
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
                            color: Color(0XFF3954DB),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      menuIcon,
                      "Your Menu",
                      partyEnquiryData['menu'] ?? '',
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      peopleIcon,
                      "Number of Persons",
                      "${partyEnquiryData['people'] ?? ''} Person",
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      calenderIcon,
                      "Date and Time",
                      partyEnquiryData['dateTime'] ?? '',
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      walletIcon,
                      "Expected amount per person",
                      "${partyEnquiryData['amount'] ?? ''} Per person",
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      radiusIcon,
                      "Enquiry Radius",
                      partyEnquiryData['location'] ?? '',
                    ),
                    SizedBox(height: 30.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(stopwatchIcon, width: 17.w, height: 17.h),
                        SizedBox(width: 5.w),
                        AppText(
                          text: _partyTimerText,
                          size: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFED4444),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    SizedBox(
                      width: 102.w,
                      height: 38.h,
                      child: AppButton(
                        text: "Send",
                        onPressed: () {
                          _stopPartyTimer();
                          _submitPartyEnquiry();
                        },
                        size: 18,
                        bgColor1: Color(0xFFF73B256),
                        bgColor2: Color(0xFFF73B256),
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

  Widget _responseAcceptConfirmBox() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          isResponseAcceptConfirmOnClick = false;
                          isConfirmClicked = false;
                        }),
                        child: Icon(
                          Icons.close,
                          color: appTextColor3,
                          size: 25.w,
                        ),
                      ),
                    ],
                  ),
                  if (isConfirmClicked) ...[
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
                  ] else ...[
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
                          if (_pendingEnquiryUuid == null) return;
                          final result = await InqueryService().confirmEnquiry(
                            _pendingEnquiryUuid!,
                          );
                          if (!mounted) return;
                          if (result['status'] == true) {
                            setState(() => isConfirmClicked = true);
                            await _fetchPartyResponses();
                            await _fetchDeclinedResponses();
                            _autoCloseConfirmBox();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] ?? 'Confirmation failed',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                  Image.asset(attentionIcon, width: 40.w, height: 40.h),
                  SizedBox(height: 10.h),
                  AppText(
                    text: "Switch Banquet Booking?",
                    isCentered: true,
                    lineSpacing: 1.5,
                    size: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD34545),
                  ),
                  SizedBox(height: 10.h),
                  AppText(
                    text:
                        "You already have a banquet booked at $_pendingRestaurantName. Booking another Banquet will automatically cancel your previous booking.",
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
                      GestureDetector(
                        onTap: () =>
                            setState(() => isResponseAcceptOnClick = false),
                        child: AppText(
                          text: "Cancel",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: appLinkColor2,
                        ),
                      ),
                      SizedBox(
                        width: 120.w,
                        height: 40.h,
                        child: AppButton(
                          text: "Yes, Book",
                          onPressed: () => setState(() {
                            isResponseAcceptOnClick = false;
                            isResponseAcceptConfirmOnClick = true;
                          }),
                          size: 15,
                          bgColor1: Color(0xFF73B256),
                          bgColor2: Color(0xFF73B256),
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
                        onTap: () => setState(() => viewRequest = false),
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
                      text:
                          _selectedResponse?.enquiryId ??
                          _selectedResponse?.couponId ??
                          _selectedResponse?.uuid ??
                          '-',
                      size: 20,
                      fontWeight: FontWeight.w700,
                      color: appTextColor3,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _reviewRow(
                    menuIcon,
                    "Your Menu",
                    _selectedResponse?.requestMenuItems?.isNotEmpty == true
                        ? _selectedResponse!.requestMenuItems
                        : (_selectedResponse
                                      ?.requestOtherServices
                                      ?.isNotEmpty ==
                                  true
                              ? _selectedResponse!.requestOtherServices
                              : '-'),
                  ),
                  SizedBox(height: 20.h),
                  _reviewRow(
                    peopleIcon,
                    "Number of Persons",
                    _selectedResponse != null
                        ? '${_selectedResponse!.requestPeople} Person'
                        : '-',
                  ),
                  SizedBox(height: 20.h),
                  _reviewRow(
                    calenderIcon,
                    "Date and Time",
                    _requestDateTime(_selectedResponse),
                  ),
                  SizedBox(height: 20.h),
                  _reviewRow(
                    walletIcon,
                    "Expected amount per person",
                    _selectedResponse != null
                        ? (_selectedResponse!.requestEstimatedAmount.isNotEmpty
                              ? '${_selectedResponse!.requestEstimatedAmount} Per person'
                              : '${_selectedResponse!.pricePerPerson} Per person')
                        : '-',
                  ),
                  SizedBox(height: 20.h),
                  _reviewRow(
                    radiusIcon,
                    "Enquiry Radius",
                    _requestRadius(_selectedResponse),
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

  // ─────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────────
  Widget _reviewRow(String imageIcon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIcon,
          width: 18.w,
          height: 18.w,
          color: Color.fromARGB(255, 8, 8, 8),
        ),
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

  Widget _sheetHandle() => Container(
    width: 40.w,
    height: 5.h,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(10.r),
    ),
  );

  Widget _sheetContainer(List<Widget> children) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
    ),
    padding: EdgeInsets.all(16.w),
    child: Column(children: children),
  );

  Widget _emptyState(IconData icon, String message) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48.w, color: appTextColor3.withOpacity(0.4)),
        SizedBox(height: 12.h),
        AppText(
          text: message,
          size: 15,
          fontWeight: FontWeight.w500,
          color: appTextColor3,
          isCentered: true,
        ),
      ],
    ),
  );

  Widget _errorText(String message) => Center(
    child: AppText(
      text: message,
      size: 15,
      fontWeight: FontWeight.w500,
      color: appTextColor3,
      isCentered: true,
    ),
  );

  Widget buildStatusButton(String text) {
    final bool isSelected = selectedStatus == text;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedStatus = text);
          if (text == "Response") _fetchPartyResponses();
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
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor3,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildCustomCalendar({
  required DateTime tempDate,
  required void Function(DateTime) onDateChanged,
}) {
  return _CustomCalendar(selectedDate: tempDate, onDateChanged: onDateChanged);
}

class _CustomCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateChanged;

  const _CustomCalendar({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<_CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<_CustomCalendar> {
  late DateTime _displayMonth;
  bool _showMonthYearPicker = false;
  late int _pickerYear;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
    _pickerYear = _displayMonth.year;
  }

  void _prevMonth() => setState(
    () => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1),
  );

  void _nextMonth() => setState(
    () => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1),
  );

  void _togglePicker() => setState(() {
    _showMonthYearPicker = !_showMonthYearPicker;
    _pickerYear = _displayMonth.year;
  });

  void _selectMonthYear(int month, int year) {
    setState(() {
      _displayMonth = DateTime(year, month);
      _showMonthYearPicker = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final monthName = _monthName(_displayMonth.month);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _showMonthYearPicker ? null : _prevMonth,
            ),
            GestureDetector(
              onTap: _togglePicker,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$monthName  ${_displayMonth.year}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    _showMonthYearPicker
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: Colors.black54,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _showMonthYearPicker ? null : _nextMonth,
            ),
          ],
        ),
        if (_showMonthYearPicker) ...[
          SizedBox(height: 6.h),
          _buildMonthYearPicker(),
        ] else ...[
          SizedBox(height: 6.h),
          _buildWeekdayLabels(),
          SizedBox(height: 6.h),
          _buildDayGrid(today),
        ],
      ],
    );
  }

  Widget _buildMonthYearPicker() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: () => setState(() => _pickerYear--),
            ),
            GestureDetector(
              onTap: () => _showYearScrollPicker(context),
              child: Text(
                '$_pickerYear',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFf87b0d),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: () => setState(() => _pickerYear++),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            final month = index + 1;
            final isSelected =
                month == _displayMonth.month &&
                _pickerYear == _displayMonth.year;
            return GestureDetector(
              onTap: () => _selectMonthYear(month, _pickerYear),
              child: Container(
                height: 50.h,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFE943A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFE943A)
                        : Colors.black12,
                  ),
                ),
                child: Center(
                  child: Text(
                    _shortMonth(month),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  void _showYearScrollPicker(BuildContext context) {
    const firstYear = 2020;
    final lastYear = DateTime.now().year + 20;
    final years = List.generate(lastYear - firstYear + 1, (i) => firstYear + i);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => SizedBox(
        height: 250.h,
        child: ListView.builder(
          itemCount: years.length,
          itemBuilder: (context, index) {
            final year = years[index];
            final isSelected = year == _pickerYear;
            return ListTile(
              onTap: () {
                setState(() => _pickerYear = year);
                Navigator.pop(context);
              },
              title: Center(
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFFf87b0d)
                        : Colors.black87,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
            .map(
              (d) => SizedBox(
                width: 36.w,
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDayGrid(DateTime today) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayMonth.year,
      _displayMonth.month,
    );
    final firstWeekday =
        DateTime(_displayMonth.year, _displayMonth.month, 1).weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: firstWeekday + daysInMonth,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        if (index < firstWeekday) return const SizedBox();

        final day = index - firstWeekday + 1;
        final date = DateTime(_displayMonth.year, _displayMonth.month, day);
        final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
        final isToday = DateUtils.isSameDay(date, today);
        return GestureDetector(
          onTap: () => widget.onDateChanged(date),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: isSelected
                    ? BoxDecoration(
                        color: const Color(0xFFf87b0d),
                        borderRadius: BorderRadius.circular(10.r),
                      )
                    : null,
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              isToday
                  ? Container(
                      width: 5.w,
                      height: 5.w,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : SizedBox(height: 5.w),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  String _shortMonth(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
