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
import 'package:geocoding/geocoding.dart';

class CateringInquery extends StatefulWidget {
  const CateringInquery({super.key});

  @override
  State<CateringInquery> createState() => _CateringInqueryState();
}

class _CateringInqueryState extends State<CateringInquery> {
  String selectedStatus = 'Book a Catering';
  String _previousStatus = 'Book a Catering';
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
  bool _isCtSearchActive = false;
  bool isSearchOnClick = false;
  bool isCtSearchOnClick = false;
  Map<String, String> ctEnquiryData = {};
  List<CateringInqueryModel> _ctEnquiries = [];
  bool _ctEnquiriesLoading = false;
  bool _ctResponsesLoading = false;
  String _ctResponsesError = '';
  Timer? _ctConfirmCloseTimer;
  Timer? _ctSearchDebounceTimer;
  String _pendingCtResponseUuid = '';
  String _pendingCtRestaurantName = '';
  ResponseModel? _selectedCtResponse;
  // for timer in ct review
  Timer? _ctTimer;
  int _ctSeconds = 180; // 3 minutes = 180 seconds

  int _ctResetCounter = 0;

  //for party
  // Map<String, String> partyEnquiryData = {};
  // Timer? _partyTimer;
  // int _partySeconds = 180;

  // ── Ct Response filter ──────────────────────────────────
  String _ctResponseFilter = "All";
  DateTime? _ctResponseCustomDate;

  // ── Ct Search filter ────────────────────────────────────
  String _ctSearchFilter = "All";
  DateTime? _ctSearchCustomDate;
  String _ctSearchQuery = "";
  final TextEditingController _ctSearchController = TextEditingController();

  // ── Ct Decline filter ───────────────────────────────────
  String _ctDeclineFilter = "All";
  DateTime? _ctDeclineCustomDate;

  // ── Ct Enquiry filter ───────────────────────────────────
  String _ctEnquiryFilter = "All";
  DateTime? _ctEnquiryCustomDate;

  List<ResponseModel> _allCtResponses = [];

  List<ResponseModel> _allCtDeclinedResponses = [];
  final Map<String, String> _ctPlaceNames =
      {}; // cache for lat,lng -> place name

  // ── Lifecycle methods ─────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchCtEnquiries();
    _fetchCtResponses();
  }

  // ── Filtered getters ─────────────────────────────────────
  List<ResponseModel> get _filteredCtResponses {
    List<ResponseModel> result = _allCtResponses;
    if (_ctResponseFilter == "Today") {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      result = result.where((r) => r.date == today).toList();
    } else if (_ctResponseFilter == "Custom" && _ctResponseCustomDate != null) {
      final String target = DateFormat(
        'yyyy-MM-dd',
      ).format(_ctResponseCustomDate!);
      result = result.where((r) => r.date == target).toList();
    }
    return result;
  }

  List<ResponseModel> get _filteredCtSearchResponses {
    List<ResponseModel> result = _allCtResponses;
    if (_ctSearchFilter == "Today") {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      result = result.where((r) => r.date == today).toList();
    } else if (_ctSearchFilter == "Custom" && _ctSearchCustomDate != null) {
      final String target = DateFormat(
        'yyyy-MM-dd',
      ).format(_ctSearchCustomDate!);
      result = result.where((r) => r.date == target).toList();
    }
    if (_ctSearchQuery.trim().isNotEmpty) {
      final String q = _ctSearchQuery.trim().toLowerCase();
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

  List<ResponseModel> get _filteredCtDeclinedResponses {
    List<ResponseModel> result = _allCtDeclinedResponses;
    if (_ctDeclineFilter == "Today") {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      result = result.where((r) => r.date == today).toList();
    } else if (_ctDeclineFilter == "Custom" && _ctDeclineCustomDate != null) {
      final String target = DateFormat(
        'yyyy-MM-dd',
      ).format(_ctDeclineCustomDate!);
      result = result.where((r) => r.date == target).toList();
    }
    return result;
  }

  // For ct enquiry list — filters on the date field of CateringInqueryModel
  List<CateringInqueryModel> get _filteredCtEnquiries {
    List<CateringInqueryModel> result = _ctEnquiries;
    if (_ctEnquiryFilter == "Today") {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      result = result.where((e) => e.date == today).toList();
    } else if (_ctEnquiryFilter == "Custom" && _ctEnquiryCustomDate != null) {
      final String target = DateFormat(
        'yyyy-MM-dd',
      ).format(_ctEnquiryCustomDate!);
      result = result.where((e) => e.date == target).toList();
    }
    return result;
  }

  // ── Label getters ─────────────────────────────────────────
  String get _ctResponseFilterLabel {
    if (_ctResponseFilter == "All") return "All";
    if (_ctResponseFilter == "Today") return "Today";
    return DateFormat('MMM d, yyyy').format(_ctResponseCustomDate!);
  }

  String get _ctSearchFilterLabel {
    if (_ctSearchFilter == "All") return "All";
    if (_ctSearchFilter == "Today") return "Today";
    return DateFormat('MMM d, yyyy').format(_ctSearchCustomDate!);
  }

  String get _ctDeclineFilterLabel {
    if (_ctDeclineFilter == "All") return "All";
    if (_ctDeclineFilter == "Today") return "Today";
    return DateFormat('MMM d, yyyy').format(_ctDeclineCustomDate!);
  }

  String get _ctEnquiryFilterLabel {
    if (_ctEnquiryFilter == "All") return "All";
    if (_ctEnquiryFilter == "Today") return "Today";
    return DateFormat('MMM d, yyyy').format(_ctEnquiryCustomDate!);
  }

  double _filterDropdownWidth(String label) {
    final textWidth = (label.length * 7.5).w;
    return (textWidth + 76.w).clamp(120.w, 190.w).toDouble();
  }

  // ── Date pickers ──────────────────────────────────────────
  Future<void> _pickCtResponseCustomDate() async {
    final DateTime? picked = await _pickCustomCalendarDatePopup(
      _ctResponseCustomDate,
    );
    if (picked != null)
      setState(() {
        _ctResponseCustomDate = picked;
        _ctResponseFilter = "Custom";
      });
  }

  Future<void> _fetchCtDeclinedResponses() async {
    setState(() {
      _ctResponsesLoading = true;
      _ctResponsesError = '';
    });

    final result = await InqueryService()
        .fetchDeclinedCateringEnquiryResponses();

    if (!mounted) return;

    setState(() {
      _allCtDeclinedResponses = result.responses;
      _ctResponsesLoading = false;
      _ctResponsesError = result.status ? '' : result.message;
    });
  }

  Future<void> _searchCtResponses(String query) async {
    final String trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      await _fetchCtResponses();
      return;
    }

    setState(() {
      _ctResponsesLoading = true;
      _ctResponsesError = '';
    });

    final result = await InqueryService().searchCateringEnquiryResponses(
      trimmedQuery,
    );

    if (!mounted) return;
    if (_ctSearchQuery.trim() != trimmedQuery) return;

    final declined = result.responses.where((response) {
      final normalized = response.status.toLowerCase();
      return normalized == 'declined' ||
          normalized == 'rejected' ||
          normalized == 'cancelled';
    }).toList();

    setState(() {
      _allCtResponses = result.responses;
      _allCtDeclinedResponses = declined;
      _ctResponsesLoading = false;
      _ctResponsesError = result.status
          ? ''
          : (result.message.isEmpty
                ? 'Unable to search catering responses right now.'
                : result.message);
    });
  }

  void _queueCtSearch(String query) {
    _ctSearchDebounceTimer?.cancel();

    setState(() {
      _ctSearchQuery = query;
    });

    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      _fetchCtResponses();
      return;
    }

    _ctSearchDebounceTimer = Timer(
      const Duration(milliseconds: 350),
      () => _searchCtResponses(trimmedQuery),
    );
  }

  Future<void> _pickCtSearchCustomDate() async {
    final DateTime? picked = await _pickCustomCalendarDatePopup(
      _ctSearchCustomDate,
    );
    if (picked != null)
      setState(() {
        _ctSearchCustomDate = picked;
        _ctSearchFilter = "Custom";
      });
  }

  Future<void> _pickCtDeclineCustomDate() async {
    final DateTime? picked = await _pickCustomCalendarDatePopup(
      _ctDeclineCustomDate,
    );
    if (picked != null)
      setState(() {
        _ctDeclineCustomDate = picked;
        _ctDeclineFilter = "Custom";
      });
  }

  Future<void> _pickCtEnquiryCustomDate() async {
    final DateTime? picked = await _pickCustomCalendarDatePopup(
      _ctEnquiryCustomDate,
    );
    if (picked != null)
      setState(() {
        _ctEnquiryCustomDate = picked;
        _ctEnquiryFilter = "Custom";
      });
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

  // ── Shared filter option builder ──────────────────────────
  Widget _buildCtFilterOption(
    String label, {
    bool isCustom = false,
    required String currentFilter,
    required DateTime? currentCustomDate,
    required Future<void> Function() onPickDate,
    required void Function(String) onSelect,
  }) {
    final bool isSelected = isCustom
        ? currentFilter == "Custom"
        : currentFilter == label;

    return GestureDetector(
      onTap: () async {
        if (isCustom) {
          Navigator.pop(context);
          await onPickDate();
        } else {
          onSelect(label);
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
              ? (currentFilter == "Custom" && currentCustomDate != null
                    ? DateFormat('MMM d, yyyy').format(currentCustomDate)
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

  // ── Shared bottom sheet builder ───────────────────────────
  void _showCtFilterSheet({
    required String currentFilter,
    required DateTime? currentCustomDate,
    required Future<void> Function() onPickDate,
    required void Function(String) onSelect,
  }) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
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
                    _buildCtFilterOption(
                      "All",
                      currentFilter: currentFilter,
                      currentCustomDate: currentCustomDate,
                      onPickDate: onPickDate,
                      onSelect: onSelect,
                    ),
                    Divider(color: Colors.grey[200]),
                    _buildCtFilterOption(
                      "Today",
                      currentFilter: currentFilter,
                      currentCustomDate: currentCustomDate,
                      onPickDate: onPickDate,
                      onSelect: onSelect,
                    ),
                    Divider(color: Colors.grey[200]),
                    _buildCtFilterOption(
                      "Select a Date",
                      isCustom: true,
                      currentFilter: currentFilter,
                      currentCustomDate: currentCustomDate,
                      onPickDate: onPickDate,
                      onSelect: onSelect,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //----------------------------------Catering Timer--------------------------//
  String get _ctTimerText {
    final m = (_ctSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_ctSeconds % 60).toString().padLeft(2, '0');
    return "00:$m:$s";
  }

  void _startCtTimer() {
    _ctSeconds = 180;
    _ctTimer?.cancel();
    _ctTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_ctSeconds <= 0) {
        timer.cancel();
        setState(() => isCtReviewOnClick = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review time expired. Please try again.'),
          ),
        );
      } else {
        setState(() => _ctSeconds--);
      }
    });
  }

  void _stopCtTimer() {
    _ctTimer?.cancel();
    _ctSeconds = 180;
  }
  //----------------------------------Catering Timer--------------------------//
  //----------------------------------Party Timer--------------------------//

  // String get _partyTimerText {
  //   final m = (_partySeconds ~/ 60).toString().padLeft(2, '0');
  //   final s = (_partySeconds % 60).toString().padLeft(2, '0');
  //   return "00:$m:$s";
  // }

  // void _startPartyTimer() {
  //   _partySeconds = 180;
  //   _partyTimer?.cancel();
  //   _partyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (_partySeconds <= 0) {
  //       timer.cancel();
  //       setState(() => isReviewOnClick = false);
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Review time expired. Please try again.'),
  //         ),
  //       );
  //     } else {
  //       setState(() => _partySeconds--);
  //     }
  //   });
  // }

  // void _stopPartyTimer() {
  //   _partyTimer?.cancel();
  //   _partySeconds = 180;
  // }

  //----------------------------------Party Timer--------------------------//

  //----------------------------------Catering Enquires-------------------------------------//
  Future<void> _fetchCtEnquiries() async {
    setState(() => _ctEnquiriesLoading = true);
    final result = await InqueryService().fetchCateringInquerys();
    setState(() {
      _ctEnquiries = result.enquiries;
      _ctEnquiriesLoading = false;
    });
  }

  Future<void> _fetchCtResponses() async {
    print('[DEBUG] Starting _fetchCtResponses');
    setState(() {
      _ctResponsesLoading = true;
      _ctResponsesError = '';
    });

    final result = await InqueryService().fetchCateringEnquiryResponses();

    if (!mounted) {
      print('[DEBUG] Widget not mounted, skipping setState');
      return;
    }

    print(
      '[DEBUG] Fetch complete - status: ${result.status}, response count: ${result.responses.length}',
    );

    final declined = result.responses.where((response) {
      final normalized = response.status.toLowerCase();
      return normalized == 'declined' ||
          normalized == 'rejected' ||
          normalized == 'cancelled';
    }).toList();

    print('[DEBUG] Declined count: ${declined.length}');

    setState(() {
      _allCtResponses = result.responses;
      _allCtDeclinedResponses = declined;
      _ctResponsesLoading = false;
      _ctResponsesError = result.status
          ? ''
          : (result.message.isEmpty
                ? 'Unable to fetch catering responses right now.'
                : result.message);
      print('[DEBUG] State updated - all responses: ${_allCtResponses.length}');
    });
  }

  String _fallbackText(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  CateringInqueryModel? _ctEnquiryForResponse(ResponseModel? response) {
    if (response == null) return null;
    for (final enquiry in _ctEnquiries) {
      if (enquiry.enquiryId == response.enquiryId ||
          enquiry.enquiryId == response.couponId ||
          enquiry.uuid == response.enquiryId) {
        return enquiry;
      }
    }
    return null;
  }

  Future<void> _openCtRequestDetails(ResponseModel response) async {
    setState(() {
      _selectedCtResponse = response;
      viewCtRequest = true;
    });

    await _ensurePlaceNameFor(response);
  }

  Future<void> _ensurePlaceNameFor(ResponseModel? response) async {
    if (response == null) return;
    final enquiry = _ctEnquiryForResponse(response);
    final lat = (enquiry?.lat?.trim().isNotEmpty == true)
        ? enquiry!.lat.trim()
        : (response.requestLat?.trim().isNotEmpty == true
              ? response.requestLat.trim()
              : '');
    final lng = (enquiry?.lng?.trim().isNotEmpty == true)
        ? enquiry!.lng.trim()
        : (response.requestLng?.trim().isNotEmpty == true
              ? response.requestLng.trim()
              : '');

    if (lat.isEmpty || lng.isEmpty) return;

    final key = '$lat,$lng';
    if (_ctPlaceNames.containsKey(key)) return;

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
        if (name.isNotEmpty) {
          _ctPlaceNames[key] = name;
        } else {
          _ctPlaceNames[key] = '\$lat, \$lng';
        }
      } else {
        _ctPlaceNames[key] = '\$lat, \$lng';
      }
    } catch (_) {
      _ctPlaceNames[key] = '\$lat, \$lng';
    }

    if (!mounted) return;
    setState(() {});
  }

  String _ctRequestDateTime(
    ResponseModel? response,
    CateringInqueryModel? enquiry,
  ) {
    if (response == null && enquiry == null) return '-';

    String date = '';
    String time = '';

    final rawDate = enquiry?.date.isNotEmpty == true
        ? enquiry!.date
        : response?.requestDate.isNotEmpty == true
        ? response!.requestDate
        : response?.date ?? '';

    final rawTime = enquiry?.time.isNotEmpty == true
        ? enquiry!.time
        : response?.requestTime.isNotEmpty == true
        ? response!.requestTime
        : response?.time ?? '';

    // Format date to 'April 12'
    if (rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        date = DateFormat('MMMM d').format(parsed);
      } else {
        date = rawDate;
      }
    }

    // Format time to '2:30 pm'
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

  String _ctRequestRadius(
    ResponseModel? response,
    CateringInqueryModel? enquiry,
  ) {
    if (response == null && enquiry == null) return '-';
    final radius = enquiry?.searchRadius.trim().isNotEmpty == true
        ? enquiry!.searchRadius.trim()
        : response?.requestSearchRadius.trim() ?? '';
    final lat = enquiry?.lat.trim().isNotEmpty == true
        ? enquiry!.lat.trim()
        : response?.requestLat.trim() ?? '';
    final lng = enquiry?.lng.trim().isNotEmpty == true
        ? enquiry!.lng.trim()
        : response?.requestLng.trim() ?? '';

    final key = '\$lat,\$lng';
    final placeName =
        (lat.isNotEmpty && lng.isNotEmpty && _ctPlaceNames.containsKey(key))
        ? _ctPlaceNames[key]
        : '';

    if ((placeName == null || placeName.isEmpty) &&
        (lat.isEmpty || lng.isEmpty) &&
        radius.isEmpty)
      return '-';

    if (placeName != null && placeName.isNotEmpty && radius.isNotEmpty) {
      return '$placeName - ${radius}km Radius';
    }

    if (placeName != null && placeName.isNotEmpty) return placeName;

    if (lat.isNotEmpty && lng.isNotEmpty && radius.isNotEmpty)
      return '$lat, $lng - ${radius}km Radius';

    if (radius.isNotEmpty) return '$radius km Radius';

    if (lat.isNotEmpty && lng.isNotEmpty) return '$lat, $lng';

    return '-';
  }

  String _ctRequestAmount(
    ResponseModel? response,
    CateringInqueryModel? enquiry,
  ) {
    final amount = enquiry?.estimatedAmount.trim().isNotEmpty == true
        ? enquiry!.estimatedAmount.trim()
        : response?.requestEstimatedAmount.trim() ?? '';
    return amount.isEmpty ? '-' : '$amount Per person';
  }

  Future<void> _submitCateringEnquiry() async {
    final InqueryService service = InqueryService();
    final model = CreateCateringInqueryModel(
      lat: ctEnquiryData['lat'] ?? '',
      lng: ctEnquiryData['lng'] ?? '',
      menuItems: ctEnquiryData['menu'] ?? '',
      people: ctEnquiryData['people'] ?? '',
      // time: ctEnquiryData['dateTime']?.split(' ').last ?? '',
      // date: ctEnquiryData['dateTime']?.split(' ').first ?? '',
      date: ctEnquiryData['dateTime']?.split(' ').first ?? '',
      time: () {
        final parts = ctEnquiryData['dateTime']?.split(' ') ?? [];
        return parts.length >= 3 ? '${parts[1]} ${parts[2]}' : '';
      }(),
      estimatedAmount: ctEnquiryData['amount'] ?? '',
      searchRadius: ctEnquiryData['searchRadius'] ?? '20',
      expirationDate: ctEnquiryData['expirationDate'] ?? '',
      expirationTime: ctEnquiryData['expirationTime'] ?? '',
    );

    final response = await service.createCateringInquery(model);

    if (response.status) {
      setState(() {
        isCtReviewOnClick = false;
        ctEnquiryData = {};
        _ctSeconds = 180;
        _ctResetCounter++; // ← triggers CtInquery to clear its fields
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  //----------------------------------Catering Enquires-------------------------------------//
  //----------------------------------Party Enquires-------------------------------------//

  // Future<void> _submitPartyEnquiry() async {
  //   final InqueryService service = InqueryService();
  //   final model = CreateInqueryModel(
  //     lat: partyEnquiryData['lat'] ?? '',
  //     lng: partyEnquiryData['lng'] ?? '',
  //     menuItems: partyEnquiryData['menu'] ?? '',
  //     people: partyEnquiryData['people'] ?? '',
  //     date: partyEnquiryData['dateTime']?.split(' ').first ?? '',
  //     time: () {
  //       final parts = partyEnquiryData['dateTime']?.split(' ') ?? [];
  //       return parts.length >= 3 ? '${parts[1]} ${parts[2]}' : '';
  //     }(),
  //     estimatedAmount: partyEnquiryData['amount'] ?? '',
  //     searchRadius: partyEnquiryData['searchRadius'] ?? '20',
  //     expirationDate: partyEnquiryData['expirationDate'] ?? '',
  //     expirationTime: partyEnquiryData['expirationTime'] ?? '',
  //   );

  //   final response = await service.createInquery(model);
  //   if (response.status) {
  //     setState(() => isReviewOnClick = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Party enquiry submitted successfully!')),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text(response.message)));
  //   }
  // }

  //----------------------------------Party Enquires-------------------------------------//

  @override
  void dispose() {
    _ctTimer?.cancel();
    _ctConfirmCloseTimer?.cancel();
    _ctSearchDebounceTimer?.cancel();
    _ctSearchController.dispose();
    // _partyTimer?.cancel();
    super.dispose();
  }

  void _autoCloseCtConfirmBox() {
    _ctConfirmCloseTimer?.cancel();
    _ctConfirmCloseTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        isConfirmClicked = false;
        isResponseAcceptConfirmOnClick = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            if (viewCtEnquiryOnClick)
              _viewCtEnquiryWidget()
            else if (viewCtDeclineOnClick)
              _viewCtDeclineWidget()
            else if (isCtSearchOnClick)
              _viewCtSearchWidget()
            else
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 35.h,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return _buildAnimatedStatusTabs(
                                width: constraints.maxWidth,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragEnd: _handleTabSwipe,
                      child: ClipRect(child: _buildSlidingTabBody()),
                    ),
                  ),
                ],
              ),
            if (isResponseAcceptOnClick) _responseAcceptBox(),
            // if (viewRequest) _viewRequestWidget(),
            if (viewCtRequest) _viewCtRequestWidget(),
            if (isResponseAcceptConfirmOnClick) _responseAcceptConfirmBox(),
            if (isCtReviewOnClick) _ctReviewBox(),
            // if (isReviewOnClick) _partyReviewBox(),
          ],
        ),
      ),
    );
  }

  //---------------------Catering Widgets------------------------------//
  void _handleTabSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 250) return;

    if (velocity < 0 && selectedStatus == "Book a Catering") {
      _selectStatus("Response");
    } else if (velocity > 0 && selectedStatus == "Response") {
      _selectStatus("Book a Catering");
    }
  }

  Widget _buildSlidingTabBody() {
    final bool showBookTab = selectedStatus == "Book a Catering";
    const duration = Duration(milliseconds: 430);
    const curve = Curves.easeInOutCubic;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AnimatedSlide(
            offset: showBookTab ? Offset.zero : const Offset(-1, 0),
            duration: duration,
            curve: curve,
            child: IgnorePointer(
              ignoring: !showBookTab,
              child: CtInquery(
                onReviewTap: (data) {
                  setState(() {
                    ctEnquiryData = data;
                    isCtReviewOnClick = true;
                  });
                  _startCtTimer();
                },
                viewEnquiryOnTap: () {
                  setState(() {
                    viewCtEnquiryOnClick = !viewCtEnquiryOnClick;
                  });
                  _fetchCtEnquiries();
                },
                resetCounter: _ctResetCounter, // ← add this
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedSlide(
            offset: showBookTab ? const Offset(1, 0) : Offset.zero,
            duration: duration,
            curve: curve,
            child: IgnorePointer(
              ignoring: showBookTab,
              child: _ctResponseWidget(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _viewCtSearchWidget() {
    final results = _filteredCtSearchResponses;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
          child: Row(children: [Expanded(child: _ctSearchInputField())]),
        ),

        SizedBox(height: 12.h),

        SizedBox(
          width: _filterDropdownWidth(_ctSearchFilterLabel),
          child: AppFilterDropDown(
            height: 32.h,
            hint: _ctSearchFilterLabel,
            imageIconPath: filterIcon,
            imageIconSize: 18.sp,
            toggleDropdown: () => _showCtFilterSheet(
              currentFilter: _ctSearchFilter,
              currentCustomDate: _ctSearchCustomDate,
              onPickDate: _pickCtSearchCustomDate,
              onSelect: (label) => setState(() {
                _ctSearchFilter = label;
                if (label != "Custom") _ctSearchCustomDate = null;
              }),
            ),
          ),
        ),

        SizedBox(height: 20.h),

        Expanded(
          child: _ctResponsesLoading
              ? const Center(child: CircularProgressIndicator())
              : _ctResponsesError.isNotEmpty
              ? Center(
                  child: AppText(
                    text: _ctResponsesError,
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
                        text: _ctSearchQuery.isNotEmpty
                            ? 'No results for "$_ctSearchQuery"'
                            : "No responses for $_ctSearchFilterLabel",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor3,
                        isCentered: true,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: 24.h),
                  physics: const BouncingScrollPhysics(),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(left: 30.w, right: 30.w),
                      child: CtResponseBox(
                        response: results[index],
                        viewRequestClick: () =>
                            _openCtRequestDetails(results[index]),
                        onAcceptTap: () {
                          setState(() {
                            _pendingCtResponseUuid = results[index].uuid;
                            _pendingCtRestaurantName =
                                results[index].restaurantName;
                            isResponseAcceptOnClick = true;
                          });
                        },
                        onCancelTap: () {
                          _fetchCtResponses();
                          _fetchCtDeclinedResponses();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _ctSearchInputField() {
    if (!_isCtSearchActive) {
      return GestureDetector(
        onTap: () => setState(() => _isCtSearchActive = true),
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
              text: "Search by coupon code or restaurant name",
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
              _ctSearchController.clear();
              _ctSearchDebounceTimer?.cancel();

              setState(() {
                _isCtSearchActive = false;
                _ctSearchQuery = "";
              });

              _fetchCtResponses();
            },
            child: Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Icon(Icons.close, size: 20.w, color: appTextColor3),
            ),
          ),

          Expanded(
            child: AppTextFeild(
              text: "Search by coupon code or restaurant name",
              controller: _ctSearchController,
              backgroundColor: Colors.white,
              height: 50.h,
              fieldBorderRadius: 16.r,
              textColor: appTextColor5,
              size: 13,
              boxShadow: const [],
              onChanged: (val) {
                _queueCtSearch(val);
              },
              inputContentPadding: EdgeInsets.symmetric(
                vertical: 14.h,
                horizontal: 12.w,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Search by coupon code",
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: appTextColor3,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 14.h,
                  horizontal: 12.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewCtDeclineWidget() {
    final declined = _filteredCtDeclinedResponses;

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
                      () => viewCtDeclineOnClick = !viewCtDeclineOnClick,
                    ),
                    child: Image.asset(backOrange, height: 24.h, width: 24.w),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: _filterDropdownWidth(_ctDeclineFilterLabel),
                        child: AppFilterDropDown(
                          height: 32.h,
                          hint: _ctDeclineFilterLabel,
                          imageIconPath: filterIcon,
                          toggleDropdown: () => _showCtFilterSheet(
                            currentFilter: _ctDeclineFilter,
                            currentCustomDate: _ctDeclineCustomDate,
                            onPickDate: _pickCtDeclineCustomDate,
                            onSelect: (label) => setState(() {
                              _ctDeclineFilter = label;
                              if (label != "Custom")
                                _ctDeclineCustomDate = null;
                            }),
                          ),
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
                onRefresh: _fetchCtDeclinedResponses,
                child: _ctResponsesLoading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: const [
                          SizedBox(height: 120),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : _ctResponsesError.isNotEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(height: 120.h),
                          Center(
                            child: AppText(
                              text: _ctResponsesError,
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor3,
                              isCentered: true,
                            ),
                          ),
                        ],
                      )
                    : declined.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(height: 120.h),
                          Center(
                            child: AppText(
                              text:
                                  "No declined responses for $_ctDeclineFilterLabel",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor3,
                              isCentered: true,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: declined.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(left: 30.w, right: 30.w),
                            child: CtDeclineBox(
                              response: declined[index],
                              onCancelTap: () async {
                                final resp = await InqueryService()
                                    .deleteDeclinedCateringEnquiryResponse(
                                      declined[index].uuid,
                                    );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(resp['message'] ?? ''),
                                  ),
                                );
                                await _fetchCtDeclinedResponses();
                              },
                              onRestoreTap: () async {
                                final resp = await InqueryService()
                                    .restoreCateringEnquiryResponse(
                                      declined[index].uuid,
                                    );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(resp['message'] ?? ''),
                                  ),
                                );
                                await _fetchCtDeclinedResponses();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _viewCtRequestWidget() {
    final response = _selectedCtResponse;
    final enquiry = _ctEnquiryForResponse(response);
    final requestId = enquiry?.enquiryId.isNotEmpty == true
        ? enquiry!.enquiryId
        : response?.couponId.isNotEmpty == true
        ? response!.couponId
        : '-';
    final menuItems = enquiry?.menuItems.isNotEmpty == true
        ? enquiry!.menuItems
        : response?.requestMenuItems ?? '';
    final otherServices = response?.requestOtherServices ?? '';
    final people = enquiry?.people != null && enquiry!.people > 0
        ? enquiry.people
        : response?.requestPeople ?? 0;

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
                        text: "Requested Catering",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            viewCtRequest = false;
                            _selectedCtResponse = null;
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
                      text: requestId,
                      size: 20,
                      fontWeight: FontWeight.w700,
                      color: appTextColor3,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        menuIcon,
                        width: 20.w,
                        height: 20.h,
                        color: Color.fromARGB(255, 15, 15, 15),
                      ),
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
                              text: _fallbackText(menuItems),
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
                      Image.asset(
                        handshakeIcon,
                        width: 20.w,
                        height: 20.h,
                        color: Color.fromARGB(255, 15, 15, 15),
                      ),
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
                              text: _fallbackText(otherServices),
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
                      Image.asset(
                        peopleIcon,
                        width: 20.w,
                        height: 20.h,
                        color: Color.fromARGB(255, 15, 15, 15),
                      ),
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
                              text: people == 0
                                  ? '-'
                                  : people == 1
                                  ? '1 Person'
                                  : '$people Persons',
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
                      Image.asset(
                        calenderIcon,
                        width: 20.w,
                        height: 20.h,
                        color: Color.fromARGB(255, 15, 15, 15),
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
                              text: _ctRequestDateTime(response, enquiry),
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
                      Image.asset(
                        walletIcon,
                        width: 20.w,
                        height: 20.h,
                        color: Color.fromARGB(255, 15, 15, 15),
                      ),
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
                              text: _ctRequestAmount(response, enquiry),
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
                      Image.asset(
                        radiusIcon,
                        width: 20.w,
                        height: 20.h,
                        color: Color.fromARGB(255, 15, 15, 15),
                      ),
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
                              text: _ctRequestRadius(response, enquiry),
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

  Widget _ctResponseWidget() {
    final responses = _filteredCtResponses;

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
                    width: _filterDropdownWidth(_ctResponseFilterLabel),
                    child: AppFilterDropDown(
                      height: 32.h,
                      hint: _ctResponseFilterLabel,
                      imageIconPath: filterIcon,
                      imageIconSize: 15,
                      toggleDropdown: () => _showCtFilterSheet(
                        currentFilter: _ctResponseFilter,
                        currentCustomDate: _ctResponseCustomDate,
                        onPickDate: _pickCtResponseCustomDate,
                        onSelect: (label) => setState(() {
                          _ctResponseFilter = label;
                          if (label != "Custom") _ctResponseCustomDate = null;
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isCtSearchOnClick = true),
                    child: Row(
                      children: [
                        Image.asset(searchBlackIcon, width: 12.w, height: 12.h),
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
                      setState(() => viewCtDeclineOnClick = true);
                      _fetchCtDeclinedResponses();
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
          child: _ctResponsesLoading
              ? const Center(child: CircularProgressIndicator())
              : _ctResponsesError.isNotEmpty
              ? Center(
                  child: AppText(
                    text: _ctResponsesError,
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
                    isCentered: true,
                  ),
                )
              : responses.isEmpty
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
                        text: "No responses for $_ctResponseFilterLabel",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor3,
                        isCentered: true,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: appButtonColor,
                  onRefresh: _fetchCtResponses,
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: 24.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: responses.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.w),
                      child: CtResponseBox(
                        response: responses[index],
                        viewRequestClick: () =>
                            _openCtRequestDetails(responses[index]),
                        onAcceptTap: () {
                          setState(() {
                            _pendingCtResponseUuid = responses[index].uuid;
                            _pendingCtRestaurantName =
                                responses[index].restaurantName;
                            isResponseAcceptOnClick = true;
                          });
                        },
                        onCancelTap: () {
                          _fetchCtResponses();
                          _fetchCtDeclinedResponses();
                        },
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _viewCtEnquiryWidget() {
    final enquiries = _filteredCtEnquiries;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 20.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => viewCtEnquiryOnClick = false),
                child: Image.asset(backOrange, width: 30.w, height: 30.h),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: _filterDropdownWidth(_ctEnquiryFilterLabel),
                    child: AppFilterDropDown(
                      height: 32.h,
                      hint: _ctEnquiryFilterLabel,
                      imageIconPath: filterIcon,
                      imageIconSize: 18.sp,
                      toggleDropdown: () => _showCtFilterSheet(
                        currentFilter: _ctEnquiryFilter,
                        currentCustomDate: _ctEnquiryCustomDate,
                        onPickDate: _pickCtEnquiryCustomDate,
                        onSelect: (label) => setState(() {
                          _ctEnquiryFilter = label;
                          if (label != "Custom") _ctEnquiryCustomDate = null;
                        }),
                      ),
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
          child: _ctEnquiriesLoading
              ? const Center(child: CircularProgressIndicator())
              : enquiries.isEmpty
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
                        text: _ctEnquiries.isEmpty
                            ? "No enquiries found"
                            : "No enquiries for $_ctEnquiryFilterLabel",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor3,
                        isCentered: true,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: appButtonColor,
                  onRefresh: _fetchCtEnquiries,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: enquiries.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(left: 30.w, right: 30.w),
                        child: CtInqueryBox(
                          enquiry: enquiries[index],
                          onCancelTap: () async {
                            setState(
                              () => isWithdrawOnClick = !isWithdrawOnClick,
                            );
                            await _fetchCtEnquiries();
                          },
                          onEdit: () =>
                              setState(() => viewCtEnquiryOnClick = false),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // coorected with api call
  Widget _ctReviewBox() {
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
                          text: "C17854",
                          size: 20,
                          fontWeight: FontWeight.w700,
                          color: appTextColor3,
                        ),
                        GestureDetector(
                          onTap: () {
                            _stopCtTimer();
                            setState(() => isCtReviewOnClick = false);
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
                      menuIcon,
                      "Your Menu",
                      ctEnquiryData['menu'] ?? '',
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      handshakeIcon,
                      "Other Services",
                      ctEnquiryData['otherServices'] ?? '',
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      peopleIcon,
                      "Number of Persons",
                      "${ctEnquiryData['people'] ?? ''} Person",
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      calenderIcon,
                      "Date and Time",
                      ctEnquiryData['dateTime'] ?? '',
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      walletIcon,
                      "Expected amount per person",
                      "${ctEnquiryData['amount'] ?? ''} Per person",
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      radiusIcon,
                      "Enquiry Radius",
                      ctEnquiryData['location'] ?? '',
                    ),
                    SizedBox(height: 30.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(stopwatchIcon, width: 17.w, height: 17.h),
                        SizedBox(width: 5.w),
                        AppText(
                          text: _ctTimerText,
                          size: 10,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFED4444),
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
                          _stopCtTimer();
                          _submitCateringEnquiry();
                        },
                        size: 18,
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

  // helper widget for each row
  Widget _reviewRow(String icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(icon, width: 20.w, height: 20.h, color: appTextColor2),
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
                            isResponseAcceptConfirmOnClick = false;
                            if (isConfirmClicked) {
                              isConfirmClicked = false;
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
                              "After confirmation, your catering order will be booked at $_pendingCtRestaurantName.",
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
                              if (_pendingCtResponseUuid.isEmpty) return;

                              final result = await InqueryService()
                                  .confirmCateringEnquiry(
                                    _pendingCtResponseUuid,
                                  );
                              if (!mounted) return;

                              if (result['status'] == true) {
                                setState(() => isConfirmClicked = true);
                                await _fetchCtResponses();
                                await _fetchCtDeclinedResponses();
                                _autoCloseCtConfirmBox();
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
                            bgColor1: Color(0xFF73B256),
                            bgColor2: Color(0xFF73B256),
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
                borderRadius: BorderRadius.circular(25.r),
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
                    softWrap: true,
                    text:
                        " You already have a catering booked at $_pendingCtRestaurantName.  Booking another catering will automatically cancel your previous booking",
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
                          size: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF3954DB),
                        ),
                      ),
                      SizedBox(
                        width: 80.w,
                        height: 25.h,
                        child: AppButton(
                          text: "Yes,Book",
                          onPressed: () {
                            setState(() {
                              isResponseAcceptOnClick = false;
                              isResponseAcceptConfirmOnClick = true;
                            });
                          },
                          size: 12,
                          bgColor1: Color(0XFF73B256),
                          bgColor2: Color(0XFF73B256),
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

  void _selectStatus(String text) {
    if (selectedStatus == text) return;

    setState(() {
      _previousStatus = selectedStatus;
      selectedStatus = text;
    });
  }

  Widget _buildAnimatedStatusTabs({required double width}) {
    final tabs = ["Book a Catering", "Response"];

    return Stack(
      children: [
        _buildStatusIndicator(width: width),
        ...tabs.map((tab) => _buildPositionedStatusButton(tab, width: width)),
      ],
    );
  }

  Widget _buildStatusIndicator({required double width}) {
    final rect = _statusTabRect(selectedStatus, width: width);
    final bool isStatusSwitch = _previousStatus != selectedStatus;
    final indicator = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
        ),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6.r,
            offset: Offset(2.w, 2.w),
          ),
        ],
      ),
    );

    return AnimatedPositioned.fromRect(
      rect: rect,
      duration: Duration(milliseconds: isStatusSwitch ? 430 : 280),
      curve: Curves.easeInOutCubic,
      child: indicator,
    );
  }

  Widget _buildPositionedStatusButton(String text, {required double width}) {
    final isSelected = selectedStatus == text;

    return Positioned.fromRect(
      rect: _statusTabRect(text, width: width),
      child: GestureDetector(
        onTap: () => _selectStatus(text),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          scale: isSelected ? 1.02 : 1,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: isSelected
                  ? null
                  : [
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
      ),
    );
  }

  Rect _statusTabRect(String text, {required double width}) {
    final double gap = 10.w;
    final double tabHeight = 35.h;
    final double tabWidth = (width - gap) / 2;

    switch (text) {
      case "Response":
        return Rect.fromLTWH(tabWidth + gap, 0, tabWidth, tabHeight);
      case "Book a Catering":
      default:
        return Rect.fromLTWH(0, 0, tabWidth, tabHeight);
    }
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
