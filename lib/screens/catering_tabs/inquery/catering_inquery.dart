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

class CateringInquery extends StatefulWidget {
  const CateringInquery({super.key});

  @override
  State<CateringInquery> createState() => _CateringInqueryState();
}

class _CateringInqueryState extends State<CateringInquery> {
  String selectedStatus = 'Book a Catering';
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
  Map<String, String> ctEnquiryData = {};
  List<CateringInqueryModel> _ctEnquiries = [];
  bool _ctEnquiriesLoading = false;
  // for timer in ct review
  Timer? _ctTimer;
  int _ctSeconds = 180; // 3 minutes = 180 seconds

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

// ── Dummy data (reuse ResponseModel for ct responses/declines) ──
final List<ResponseModel> _allCtResponses = [
  ResponseModel(
    couponId: "C17854",
    restaurantName: "Bollywood Restaurant",
    pricePerPerson: 950,
    discount: "5% on extra drinks",
    message: "If you have more than 50 people, we can offer 850 per head.",
    date: "2026-04-07", // today
    time: "12:30pm",
  ),
  ResponseModel(
    couponId: "C17855",
    restaurantName: "Spice Garden",
    pricePerPerson: 800,
    discount: "10% on desserts",
    message: "Complimentary welcome drinks for groups above 30.",
    date: "2026-04-03",
    time: "3:00pm",
  ),
  ResponseModel(
    couponId: "C17856",
    restaurantName: "The Grand Feast",
    pricePerPerson: 1200,
    discount: "3% on beverages",
    message: "Special dessert platter for groups above 20.",
    date: "2026-04-07", // today
    time: "6:45pm",
  ),
  ResponseModel(
    couponId: "C17857",
    restaurantName: "Royal Dine",
    pricePerPerson: 1100,
    discount: "7% on starters",
    message: "Free mocktails for the first 10 guests.",
    date: "2026-03-30",
    time: "11:00am",
  ),
  ResponseModel(
    couponId: "C17858",
    restaurantName: "The Coastal Kitchen",
    pricePerPerson: 750,
    discount: "8% on seafood",
    message: "Live music available for events above 60 people.",
    date: "2026-04-01",
    time: "8:00pm",
  ),
];

final List<ResponseModel> _allCtDeclinedResponses = [
  ResponseModel(
    couponId: "C17860",
    restaurantName: "Bollywood Restaurant",
    pricePerPerson: 950,
    discount: "5% on extra drinks",
    message: "If you have more than 50 people, we can offer 850 per head.",
    date: "2026-04-07",
    time: "12:30pm",
  ),
  ResponseModel(
    couponId: "C17861",
    restaurantName: "Spice Garden",
    pricePerPerson: 800,
    discount: "10% on desserts",
    message: "Complimentary welcome drinks for groups above 30.",
    date: "2026-04-03",
    time: "3:00pm",
  ),
  ResponseModel(
    couponId: "C17862",
    restaurantName: "The Grand Feast",
    pricePerPerson: 1200,
    discount: "3% on beverages",
    message: "Special dessert platter for groups above 20.",
    date: "2026-04-07",
    time: "6:45pm",
  ),
];

// ── Filtered getters ─────────────────────────────────────
List<ResponseModel> get _filteredCtResponses {
  List<ResponseModel> result = _allCtResponses;
  if (_ctResponseFilter == "Today") {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    result = result.where((r) => r.date == today).toList();
  } else if (_ctResponseFilter == "Custom" && _ctResponseCustomDate != null) {
    final String target = DateFormat('yyyy-MM-dd').format(_ctResponseCustomDate!);
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
    final String target = DateFormat('yyyy-MM-dd').format(_ctSearchCustomDate!);
    result = result.where((r) => r.date == target).toList();
  }
  if (_ctSearchQuery.trim().isNotEmpty) {
    final String q = _ctSearchQuery.trim().toLowerCase();
    result = result
        .where((r) =>
            r.couponId.toLowerCase().contains(q) ||
            r.restaurantName.toLowerCase().contains(q))
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
    final String target = DateFormat('yyyy-MM-dd').format(_ctDeclineCustomDate!);
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
    final String target = DateFormat('yyyy-MM-dd').format(_ctEnquiryCustomDate!);
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

// ── Date pickers ──────────────────────────────────────────
Future<void> _pickCtResponseCustomDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _ctResponseCustomDate ?? DateTime.now(),
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
  if (picked != null) setState(() { _ctResponseCustomDate = picked; _ctResponseFilter = "Custom"; });
}

Future<void> _pickCtSearchCustomDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _ctSearchCustomDate ?? DateTime.now(),
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
  if (picked != null) setState(() { _ctSearchCustomDate = picked; _ctSearchFilter = "Custom"; });
}

Future<void> _pickCtDeclineCustomDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _ctDeclineCustomDate ?? DateTime.now(),
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
  if (picked != null) setState(() { _ctDeclineCustomDate = picked; _ctDeclineFilter = "Custom"; });
}

Future<void> _pickCtEnquiryCustomDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _ctEnquiryCustomDate ?? DateTime.now(),
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
  if (picked != null) setState(() { _ctEnquiryCustomDate = picked; _ctEnquiryFilter = "Custom"; });
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
  final bool isSelected =
      isCustom ? currentFilter == "Custom" : currentFilter == label;

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
                  _buildCtFilterOption("All",
                    currentFilter: currentFilter,
                    currentCustomDate: currentCustomDate,
                    onPickDate: onPickDate,
                    onSelect: onSelect),
                  Divider(color: Colors.grey[200]),
                  _buildCtFilterOption("Today",
                    currentFilter: currentFilter,
                    currentCustomDate: currentCustomDate,
                    onPickDate: onPickDate,
                    onSelect: onSelect),
                  Divider(color: Colors.grey[200]),
                  _buildCtFilterOption("Select a Date",
                    isCustom: true,
                    currentFilter: currentFilter,
                    currentCustomDate: currentCustomDate,
                    onPickDate: onPickDate,
                    onSelect: onSelect),
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
      setState(() => isCtReviewOnClick = false);
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
    _ctSearchController.dispose();
    // _partyTimer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: Stack(
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
                      Row(
                        children: [
                          buildStatusButton("Book a Catering"),
                          SizedBox(width: 10.w),
                          buildStatusButton("Catering Response"),
                        ],
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
                Expanded(
                  child: selectedStatus == "Book a Catering"
                      ? CtInquery(
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
                        )
                      : _ctResponseWidget(),
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
    );
  }
//---------------------Catering Widgets------------------------------//
  Widget _viewCtSearchWidget() {
  final results = _filteredCtSearchResponses;

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
                controller: _ctSearchController,
                onChanged: (val) => setState(() => _ctSearchQuery = val),
                style: TextStyle(fontSize: 13.sp, color: appTextColor3),
                decoration: InputDecoration(
                  hintText: "Search by coupon code or restaurant name",
                  hintStyle: TextStyle(fontSize: 13.sp, color: appTextColor3),
                  prefixIcon: Icon(Icons.search, color: appTextColor3, size: 20.w),
                  suffixIcon: _ctSearchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _ctSearchQuery = "";
                            _ctSearchController.clear();
                          }),
                          child: Icon(Icons.close, color: appTextColor3, size: 20.w),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: 180.w,
            child: AppFilterDropDown(
              hint: _ctSearchFilterLabel,
              icon: Icons.tune,
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
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48.w, color: appTextColor3.withOpacity(0.4)),
                        SizedBox(height: 12.h),
                        AppText(
                          text: _ctSearchQuery.isNotEmpty
                              ? "No results for \"$_ctSearchQuery\""
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
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(left: 30.w, right: 30.w),
                        child: CtResponseBox(
                          response: results[index],
                          viewRequestClick: () => setState(() => viewCtRequest = !viewCtRequest),
                          onAcceptTap: () => setState(() => isResponseAcceptOnClick = !isResponseAcceptOnClick),
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
                  onTap: () => setState(() => viewCtDeclineOnClick = !viewCtDeclineOnClick),
                  child: Icon(Icons.arrow_back_ios_new, color: appTextColor3, size: 28.w),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 180.w,
                      child: AppFilterDropDown(
                        hint: _ctDeclineFilterLabel,
                        icon: Icons.tune,
                        toggleDropdown: () => _showCtFilterSheet(
                          currentFilter: _ctDeclineFilter,
                          currentCustomDate: _ctDeclineCustomDate,
                          onPickDate: _pickCtDeclineCustomDate,
                          onSelect: (label) => setState(() {
                            _ctDeclineFilter = label;
                            if (label != "Custom") _ctDeclineCustomDate = null;
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
            child: declined.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48.w, color: appTextColor3.withOpacity(0.4)),
                        SizedBox(height: 12.h),
                        AppText(
                          text: "No declined responses for $_ctDeclineFilterLabel",
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
                        child: CtDeclineBox(
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

  Widget _viewCtRequestWidget() {
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
                            viewCtRequest = !viewCtRequest;
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
                      Icon(Icons.handshake, size: 20.w, color: appTextColor2),
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
                      Icon(Icons.wallet, size: 20.w, color: appTextColor2),
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
                      Icon(Icons.analytics, size: 20.w, color: appTextColor2),
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

  Widget _ctResponseWidget() {
  final responses = _filteredCtResponses;

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
                hint: _ctResponseFilterLabel,
                icon: Icons.tune,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.search, size: 17.w, color: Colors.black),
                    SizedBox(width: 2.w),
                    GestureDetector(
                      onTap: () => setState(() => isCtSearchOnClick = !isCtSearchOnClick),
                      child: AppText(text: "Search", size: 15, fontWeight: FontWeight.w400, color: Colors.black),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    Icon(Icons.book, size: 17.w, color: appLinkColor2),
                    SizedBox(width: 2.w),
                    GestureDetector(
                      onTap: () => setState(() => viewCtDeclineOnClick = !viewCtDeclineOnClick),
                      child: AppText(text: "View Declined", size: 15, fontWeight: FontWeight.w400, color: appLinkColor2),
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
        child: responses.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48.w, color: appTextColor3.withOpacity(0.4)),
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
            : ListView.builder(
                itemCount: responses.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: CtResponseBox(
                      response: responses[index],
                      viewRequestClick: () => setState(() => viewCtRequest = !viewCtRequest),
                      onAcceptTap: () => setState(() => isResponseAcceptOnClick = !isResponseAcceptOnClick),
                      onCancelTap: () => setState(() {}),
                    ),
                  );
                },
              ),
      ),
    ],
  );
}

  // Widget _viewCtEnquiryWidget() {
  //   return Column(
  //     children: [
  //       GestureDetector(
  //         onTap: () {
  //           setState(() => viewCtEnquiryOnClick = false);
  //  Navigator.pop(context);

  //         },
  //         child: Align(
  //           alignment: Alignment.centerLeft,
  //           child: Padding(
  //             padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
  //             child: Icon(
  //               Icons.arrow_back_ios_new,
  //               color: appTextColor3,
  //               size: 28.w,
  //             ),
  //           ),
  //         ),
  //       ),

  //         SizedBox(height: 20.h),
  //        Expanded(child:   _ctEnquiriesLoading?
  //        Center(child: CircularProgressIndicator())
  //     :(_ctEnquiries.isEmpty)?

  //         Center(
  //           child: AppText(
  //             text: "No enquiries found",
  //             size: 15,
  //             fontWeight: FontWeight.w500,
  //             color: appTextColor3,
  //           ),
  //         )
  //       : ListView.builder(
  //           shrinkWrap: true,
  //           itemCount: _ctEnquiries.length,
  //           itemBuilder: (context, index) {
  //             return Padding(
  //               padding: EdgeInsets.only(left: 30.w, right: 30.w),
  //               child: CtInqueryBox(
  //                 enquiry: _ctEnquiries[index],
  //                 onCancelTap: () {
  //                   setState(() {
  //                     isWithdrawOnClick = !isWithdrawOnClick;
  //                   });
  //                 },
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //       SizedBox(
  //         width: 180.w,
  //         child: AppFilterDropDown(
  //           hint: "Today",
  //           toggleDropdown: () {
  //             showModalBottomSheet(
  //               backgroundColor: Colors.white,
  //               context: context,
  //               isScrollControlled: true,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.vertical(
  //                   top: Radius.circular(25),
  //                 ),
  //               ),
  //               builder: (context) {
  //                 return Padding(
  //                   padding: EdgeInsets.all(30.w),
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Container(
  //                         width: 40.w,
  //                         height: 5.h,
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey[300],
  //                           borderRadius: BorderRadius.circular(10.r),
  //                         ),
  //                       ),
  //                       SizedBox(height: 16.h),
  //                       Container(
  //                         width: MediaQuery.of(context).size.width,
  //                         decoration: BoxDecoration(
  //                           color: Colors.white,
  //                           borderRadius: BorderRadius.circular(20.r),
  //                         ),
  //                         padding: EdgeInsets.all(16.w),
  //                         child: Column(
  //                           children: [
  //                             Divider(color: Colors.grey[200]),
  //                             SizedBox(height: 10.h),
  //                             AppText(
  //                               text: "item1",
  //                               size: 15,
  //                               fontWeight: FontWeight.w500,
  //                               color: Colors.black,
  //                             ),
  //                             SizedBox(height: 10.h),
  //                             Divider(color: Colors.grey[200]),
  //                             SizedBox(height: 10.h),
  //                             AppText(
  //                               text: "item2",
  //                               size: 15,
  //                               fontWeight: FontWeight.w500,
  //                               color: Colors.black,
  //                             ),
  //                             SizedBox(height: 10.h),
  //                             Divider(color: Colors.grey[200]),
  //                             SizedBox(height: 10.h),
  //                             AppText(
  //                               text: "item3",
  //                               size: 15,
  //                               fontWeight: FontWeight.w500,
  //                               color: Colors.black,
  //                             ),
  //                             SizedBox(height: 10),
  //                             Divider(color: Colors.grey[200]),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               },
  //             );
  //           },
  //           icon: Icons.tune,
  //         ),
  //       ),
  //       SizedBox(height: 20.h),
  //       Expanded(
  //         child: ListView.builder(
  //           shrinkWrap: true,
  //           itemCount: 10,
  //           itemBuilder: (context, index) {
  //             return Padding(
  //               padding: EdgeInsets.only(left: 30.w, right: 30.w),
  //              //////////////////////////////
  //               child: CtInqueryBox(
  //                 onCancelTap: () {
  //                   setState(() {
  //                     isWithdrawOnClick = !isWithdrawOnClick;
  //                   });
  //                 }, enquiry: _ctEnquiries[index],
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _viewCtEnquiryWidget() {
  final enquiries = _filteredCtEnquiries;

  return Column(
    children: [
      Padding(
        padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => viewCtEnquiryOnClick = false),
              child: Icon(Icons.arrow_back_ios_new, color: appTextColor3, size: 28.w),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 180.w,
                  child: AppFilterDropDown(
                    hint: _ctEnquiryFilterLabel,
                    icon: Icons.tune,
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
                        Icon(Icons.inbox_outlined, size: 48.w, color: appTextColor3.withOpacity(0.4)),
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
                : ListView.builder(
                    itemCount: enquiries.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(left: 30.w, right: 30.w),
                        child: CtInqueryBox(
                          enquiry: enquiries[index],
                          onCancelTap: () => setState(() => isWithdrawOnClick = !isWithdrawOnClick),
                          onEdit: () => setState(() => viewCtEnquiryOnClick = false),
                        ),
                      );
                    },
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
                          // AppText(
                          //   text: "C17854",
                          //   size: 20,
                          //   fontWeight: FontWeight.w700,
                          //   color: appTextColor3,
                          // ),

                          // AppText(
                          //   text: "Edit",
                          //   size: 15,
                          //   fontWeight: FontWeight.w700,
                          //   color: appLinkColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.dashboard,
                      "Your Menu",
                      ctEnquiryData['menu'] ?? '',
                    ),

                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Your Menu",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text:
                    //                 "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.handshake,
                      "Other Services",
                      ctEnquiryData['otherServices'] ?? '',
                    ),

                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.handshake, size: 20.w, color: appTextColor2),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Other Services",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text: "7 Service boys needed.",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.people,
                      "Number of Persons",
                      "${ctEnquiryData['people'] ?? ''} Person",
                    ),
                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.people, size: 20.w, color: appTextColor2),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Number of Persons",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text: "200 Person ",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.calendar_today_sharp,
                      "Date and Time",
                      ctEnquiryData['dateTime'] ?? '',
                    ),

                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(
                    //       Icons.calendar_today_sharp,
                    //       size: 20.w,
                    //       color: appTextColor2,
                    //     ),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Date and Time ",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text: "April 12 - 2:30 pm",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.wallet,
                      "Expected amount per person",
                      "${ctEnquiryData['amount'] ?? ''} Per person",
                    ),

                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.wallet, size: 20.w, color: appTextColor2),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Expected amount per person",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text: "450 Per person",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.analytics,
                      "Enquiry Radius",
                      ctEnquiryData['location'] ?? '',
                    ),
                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.analytics, size: 20.w, color: appTextColor2),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Enquiry Radius ",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text: "Moscow City - 20km Radius",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 30.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, size: 20.w, color: Colors.red),
                        SizedBox(width: 5.w),
                        AppText(
                          text: _ctTimerText,
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
                          _stopCtTimer(); // add this
                          _submitCateringEnquiry();
                        },
                        // onPressed: () {
                        //   setState(() {
                        //     isCtReviewOnClick = !isCtReviewOnClick;
                        //   });
                        // },
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
//-----------------------------Catering Widgets--------------------------//
//-----------------------------Party Widgets--------------------------//

//  Widget _partyReviewBox() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(30.w),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         AppText(
//                           text: "C17854",
//                           size: 20,
//                           fontWeight: FontWeight.w700,
//                           color: appTextColor3,
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             _stopPartyTimer();
//                             setState(() => isReviewOnClick = false);
//                           },
//                           child: AppText(
//                             text: "Edit",
//                             size: 15,
//                             fontWeight: FontWeight.w700,
//                             color: appLinkColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 20.h),
//                     _reviewRow(
//                       Icons.dashboard,
//                       "Your Menu",
//                       partyEnquiryData['menu'] ?? '',
//                     ),


//                     SizedBox(height: 20.h),
//                     _reviewRow(
//                       Icons.handshake,
//                       "Other Services",
//                       partyEnquiryData['otherServices'] ?? '',
//                     ),

//                     SizedBox(height: 20.h),
//                     _reviewRow(
//                       Icons.people,
//                       "Number of Persons",
//                       "${partyEnquiryData['people'] ?? ''} Person",
//                     ),
         

//                     SizedBox(height: 20.h),
//                     _reviewRow(
//                       Icons.calendar_today_sharp,
//                       "Date and Time",
//                       partyEnquiryData['dateTime'] ?? '',
//                     ),


//                     SizedBox(height: 20.h),
//                     _reviewRow(
//                       Icons.wallet,
//                       "Expected amount per person",
//                       "${partyEnquiryData['amount'] ?? ''} Per person",
//                     ),

                    
//                     SizedBox(height: 20.h),
//                     _reviewRow(
//                       Icons.analytics,
//                       "Enquiry Radius",
//                       partyEnquiryData['location'] ?? '',
//                     ),

//                     SizedBox(height: 30.h),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.timer, size: 20.w, color: Colors.red),
//                         SizedBox(width: 5.w),
//                         AppText(
//                           text: _partyTimerText,
//                           size: 15,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.red,
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 15.h),
//                     SizedBox(
//                       width: 150.w,
//                       height: 50.h,
//                       child: AppButton(
//                         text: "Send",
//                         onPressed: () {
//                           _stopPartyTimer(); 
//                           _submitPartyEnquiry();
//                         },
//                         size: 15,
//                         bgColor1: Colors.green,
//                         bgColor2: Colors.green,
//                         borderRadius: 10,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//-----------------------------Party Widgets--------------------------//



  // helper widget for each row
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
                              "After confirmation, your party order will be booked at Bollywood Restaurant.",
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
                            onPressed: () {
                              setState(() {
                                isConfirmClicked = !isConfirmClicked;
                              });
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

  // Widget _viewSearchWidget() {
  //   return Stack(
  //     children: [
  //       Column(
  //         children: [
  //           Padding(
  //             padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
  //             child: AppTextFeild(
  //               text: "Your Current Location",
  //               textColor: appTextColor3,
  //               icon: Icons.close,
  //               iconColor: appTextColor3,
  //               iconOnTap: () {
  //                 setState(() {
  //                   isSearchOnClick = !isSearchOnClick;
  //                 });
  //               },
  //             ),
  //           ),

  //           SizedBox(height: 20.h),
  //           SizedBox(
  //             width: 180.w,
  //             child: AppFilterDropDown(
  //               hint: "Today",
  //               toggleDropdown: () {
  //                 showModalBottomSheet(
  //                   backgroundColor: Colors.white,
  //                   context: context,
  //                   isScrollControlled: true,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.vertical(
  //                       top: Radius.circular(25.r),
  //                     ),
  //                   ),
  //                   builder: (context) {
  //                     return Padding(
  //                       padding: EdgeInsets.all(30.w),
  //                       child: Column(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Container(
  //                             width: 40.w,
  //                             height: 5.h,
  //                             decoration: BoxDecoration(
  //                               color: Colors.grey[300],
  //                               borderRadius: BorderRadius.circular(10.r),
  //                             ),
  //                           ),
  //                           SizedBox(height: 16.h),
  //                           Container(
  //                             width: MediaQuery.of(context).size.width,
  //                             decoration: BoxDecoration(
  //                               color: Colors.white,
  //                               borderRadius: BorderRadius.circular(20.r),
  //                             ),
  //                             padding: EdgeInsets.all(16.w),
  //                             child: Column(
  //                               children: [
  //                                 Divider(color: Colors.grey[200]),
  //                                 SizedBox(height: 10.h),
  //                                 AppText(
  //                                   text: "item1",
  //                                   size: 15.w,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Colors.black,
  //                                 ),
  //                                 SizedBox(height: 10.h),
  //                                 Divider(color: Colors.grey[200]),
  //                                 SizedBox(height: 10.h),
  //                                 AppText(
  //                                   text: "item2",
  //                                   size: 15.w,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Colors.black,
  //                                 ),
  //                                 SizedBox(height: 10.h),
  //                                 Divider(color: Colors.grey[200]),
  //                                 SizedBox(height: 10.h),
  //                                 AppText(
  //                                   text: "item3",
  //                                   size: 15.w,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Colors.black,
  //                                 ),
  //                                 SizedBox(height: 10.h),
  //                                 Divider(color: Colors.grey[200]),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   },
  //                 );
  //               },
  //               icon: Icons.tune,
  //             ),
  //           ),
  //           SizedBox(height: 20.h),
  //           Expanded(
  //             child: ListView.builder(
  //               shrinkWrap: true,
  //               itemCount: 2,
  //               itemBuilder: (context, index) {
  //                 return Padding(
  //                   padding: EdgeInsets.only(left: 30.w, right: 30.w),
  //                   child: SizedBox.shrink(),

  //                   // child: ResponseBox(
  //                   //   viewRequestClick: () {
  //                   //     setState(() {
  //                   //       viewRequest = !viewRequest;
  //                   //     });
  //                   //   },
  //                   //   onAcceptTap: () {
  //                   //     setState(() {
  //                   //       isResponseAcceptOnClick = !isResponseAcceptOnClick;
  //                   //     });
  //                   //   },
  //                   //   onCancelTap: () {
  //                   //     setState(() {});
  //                   //   },
  //                   // ),
  //                 );
  //               },
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // Widget _viewDeclineWidget() {
  //   return Stack(
  //     children: [
  //       Column(
  //         children: [
  //           GestureDetector(
  //             onTap: () {
  //               setState(() {
  //                 viewDeclineOnClick = !viewDeclineOnClick;
  //               });
  //             },
  //             child: Align(
  //               alignment: Alignment.centerLeft,
  //               child: Padding(
  //                 padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
  //                 child: Icon(
  //                   Icons.arrow_back_ios_new,
  //                   color: appTextColor3,
  //                   size: 28,
  //                 ),
  //               ),
  //             ),
  //           ),
  //           SizedBox(
  //             width: 180.w,
  //             child: AppFilterDropDown(
  //               hint: "Today",
  //               toggleDropdown: () {
  //                 showModalBottomSheet(
  //                   backgroundColor: Colors.white,
  //                   context: context,
  //                   isScrollControlled: true,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.vertical(
  //                       top: Radius.circular(25.r),
  //                     ),
  //                   ),
  //                   builder: (context) {
  //                     return Padding(
  //                       padding: EdgeInsets.all(30.w),
  //                       child: Column(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Container(
  //                             width: 40.w,
  //                             height: 5.h,
  //                             decoration: BoxDecoration(
  //                               color: Colors.grey[300],
  //                               borderRadius: BorderRadius.circular(10.r),
  //                             ),
  //                           ),
  //                           SizedBox(height: 16.h),
  //                           Container(
  //                             width: MediaQuery.of(context).size.width,
  //                             decoration: BoxDecoration(
  //                               color: Colors.white,
  //                               borderRadius: BorderRadius.circular(20.r),
  //                             ),
  //                             padding: EdgeInsets.all(16.w),
  //                             child: Column(
  //                               children: [
  //                                 Divider(color: Colors.grey[200]),
  //                                 SizedBox(height: 10.h),
  //                                 AppText(
  //                                   text: "item1",
  //                                   size: 15,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Colors.black,
  //                                 ),
  //                                 SizedBox(height: 10.h),
  //                                 Divider(color: Colors.grey[200]),
  //                                 SizedBox(height: 10.h),
  //                                 AppText(
  //                                   text: "item2",
  //                                   size: 15,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Colors.black,
  //                                 ),
  //                                 SizedBox(height: 10.h),
  //                                 Divider(color: Colors.grey[200]),
  //                                 SizedBox(height: 10.h),
  //                                 AppText(
  //                                   text: "item3",
  //                                   size: 15,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Colors.black,
  //                                 ),
  //                                 SizedBox(height: 10.h),
  //                                 Divider(color: Colors.grey[200]),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   },
  //                 );
  //               },
  //               icon: Icons.tune,
  //             ),
  //           ),
  //           SizedBox(height: 20.h),
  //           Expanded(
  //             child: ListView.builder(
  //               shrinkWrap: true,
  //               itemCount: 2,
  //               itemBuilder: (context, index) {
  //                 return Padding(
  //                   padding: EdgeInsets.only(left: 30.w, right: 30.w),
  //                     // child: DeclineBox(onCancelTap: () {}),
  //                     child: SizedBox.shrink(),
  //                 );
  //               },
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // //---------------------------------------------------------------------------
  // Widget _viewRequestWidget() {
  //   return Positioned.fill(
  //     child: Container(
  //       color: Colors.black54,
  //       child: Center(
  //         child: Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 30.w),
  //           child: Container(
  //             width: double.infinity,
  //             padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(20.r),
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     AppText(
  //                       text: "Requested party",
  //                       size: 15,
  //                       fontWeight: FontWeight.w500,
  //                       color: appTextColor2,
  //                     ),
  //                     GestureDetector(
  //                       onTap: () {
  //                         setState(() {
  //                           viewRequest = !viewRequest;
  //                         });
  //                       },
  //                       child: Icon(
  //                         Icons.close,
  //                         color: appTextColor3,
  //                         size: 25.w,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 SizedBox(height: 20.h),
  //                 Align(
  //                   alignment: Alignment.centerLeft,
  //                   child: AppText(
  //                     text: "P17854",
  //                     size: 20,
  //                     fontWeight: FontWeight.w700,
  //                     color: appTextColor3,
  //                   ),
  //                 ),
  //                 SizedBox(height: 20.h),
  //                 Row(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
  //                     SizedBox(width: 10.w),
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           AppText(
  //                             text: "Your Menu",
  //                             size: 15,
  //                             fontWeight: FontWeight.w500,
  //                             color: Colors.grey,
  //                           ),
  //                           SizedBox(height: 5.h),
  //                           AppText(
  //                             text:
  //                                 "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
  //                             size: 15,
  //                             fontWeight: FontWeight.w500,
  //                             color: appTextColor2,
  //                             lineSpacing: 1.5,
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 SizedBox(height: 20.h),
  //                 Row(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Icon(Icons.people, size: 20.w, color: appTextColor2),
  //                     SizedBox(width: 10.w),
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           AppText(
  //                             text: "Number of Persons",
  //                             size: 15,
  //                             fontWeight: FontWeight.w500,
  //                             color: Colors.grey,
  //                           ),
  //                           SizedBox(height: 5.h),
  //                           AppText(
  //                             text: "12 Person ",
  //                             size: 15,
  //                             fontWeight: FontWeight.w500,
  //                             color: appTextColor2,
  //                             lineSpacing: 1.5,
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 SizedBox(height: 20.h),
  //                 Row(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Icon(
  //                       Icons.calendar_today_sharp,
  //                       size: 20.w,
  //                       color: appTextColor2,
  //                     ),
  //                     SizedBox(width: 10.w),
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           AppText(
  //                             text: "Date and Time ",
  //                             size: 15,
  //                             fontWeight: FontWeight.w500,
  //                             color: Colors.grey,
  //                           ),
  //                           SizedBox(height: 5.h),
  //                           AppText(
  //                             text: "April 12 - 2:30 pm",
  //                             size: 15,
  //                             fontWeight: FontWeight.w500,
  //                             color: appTextColor2,
  //                             lineSpacing: 1.5,
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 SizedBox(height: 20.h),
  //                 Row(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Icon(Icons.wallet, size: 20, color: appTextColor2),
  //                     SizedBox(width: 10.w),
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           AppText(
  //                             text: "Expected amount per person",
  //                             size: 15,
  //                             fontWeight: FontWeight.w500,
  //                             color: Colors.grey,
  //                           ),
  //                           SizedBox(height: 5.h),
  //                           AppText(
  //                             text: "1000 Per person",
  //                             size: 15,
  //                             fontWeight: FontWeight.w500,
  //                             color: appTextColor2,
  //                             lineSpacing: 1.5,
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 SizedBox(height: 20.h),
  //                 Row(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Icon(Icons.analytics, size: 20, color: appTextColor2),
  //                     SizedBox(width: 10.w),
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           AppText(
  //                             text: "Enquiry Radius ",
  //                             size: 15,
  //                             fontWeight: FontWeight.w500,
  //                             color: Colors.grey,
  //                           ),
  //                           SizedBox(height: 5.h),
  //                           AppText(
  //                             text: "Moscow City - 20km Radius",
  //                             size: 15,
  //                             fontWeight: FontWeight.w500,
  //                             color: appTextColor2,
  //                             lineSpacing: 1.5,
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 SizedBox(height: 20.h),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
                        " You already have a banquet booked at Bollywood Restaurant. Booking another Banquet will automatically cancel your previous booking.",
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
                              isResponseAcceptOnClick =
                                  !isResponseAcceptOnClick;
                              isResponseAcceptConfirmOnClick =
                                  !isResponseAcceptConfirmOnClick;
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

  // Widget _responseWidget() {
  //   return Column(
  //     children: [
  //       SizedBox(height: 20.h),
  //       Padding(
  //         padding: EdgeInsets.symmetric(horizontal: 30.w),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             SizedBox(
  //               width: 150.w,
  //               child: AppFilterDropDown(
  //                 hint: "Today",
  //                 icon: Icons.tune,
  //                 toggleDropdown: () {
  //                   showModalBottomSheet(
  //                     backgroundColor: Colors.white,
  //                     context: context,
  //                     isScrollControlled: true,
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.vertical(
  //                         top: Radius.circular(25.r),
  //                       ),
  //                     ),
  //                     builder: (context) {
  //                       return Padding(
  //                         padding: EdgeInsets.all(30.w),
  //                         child: Column(
  //                           mainAxisSize: MainAxisSize.min,
  //                           children: [
  //                             Container(
  //                               width: 40.w,
  //                               height: 5.h,
  //                               decoration: BoxDecoration(
  //                                 color: Colors.grey[300],
  //                                 borderRadius: BorderRadius.circular(10),
  //                               ),
  //                             ),
  //                             SizedBox(height: 16.h),
  //                             Container(
  //                               width: MediaQuery.of(context).size.width,
  //                               decoration: BoxDecoration(
  //                                 color: Colors.white,
  //                                 borderRadius: BorderRadius.circular(20.r),
  //                               ),
  //                               padding: EdgeInsets.all(16.w),
  //                               child: Column(
  //                                 children: [
  //                                   Divider(color: Colors.grey[200]),
  //                                   SizedBox(height: 10.h),
  //                                   AppText(
  //                                     text: "item1",
  //                                     size: 15,
  //                                     fontWeight: FontWeight.w500,
  //                                     color: Colors.black,
  //                                   ),
  //                                   SizedBox(height: 10.h),
  //                                   Divider(color: Colors.grey[200]),
  //                                   SizedBox(height: 10.h),
  //                                   AppText(
  //                                     text: "item2",
  //                                     size: 15.w,
  //                                     fontWeight: FontWeight.w500,
  //                                     color: Colors.black,
  //                                   ),
  //                                   SizedBox(height: 10.h),
  //                                   Divider(color: Colors.grey[200]),
  //                                   SizedBox(height: 10.h),
  //                                   AppText(
  //                                     text: "item3",
  //                                     size: 15.w,
  //                                     fontWeight: FontWeight.w500,
  //                                     color: Colors.black,
  //                                   ),
  //                                   SizedBox(height: 10.h),
  //                                   Divider(color: Colors.grey[200]),
  //                                 ],
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       );
  //                     },
  //                   );
  //                 },
  //               ),
  //             ),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.end,
  //               children: [
  //                 Row(
  //                   children: [
  //                     Icon(Icons.search, size: 17.w, color: Colors.black),
  //                     SizedBox(width: 2.w),
  //                     GestureDetector(
  //                       onTap: () {
  //                         setState(() {
  //                           isSearchOnClick = !isSearchOnClick;
  //                         });
  //                       },
  //                       child: AppText(
  //                         text: "Search",
  //                         size: 15,
  //                         fontWeight: FontWeight.w400,
  //                         color: Colors.black,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 SizedBox(height: 5.h),
  //                 Row(
  //                   children: [
  //                     Icon(Icons.book, size: 17.w, color: appLinkColor2),
  //                     SizedBox(width: 2.w),
  //                     GestureDetector(
  //                       onTap: () {
  //                         setState(() {
  //                           viewDeclineOnClick = !viewDeclineOnClick;
  //                         });
  //                       },
  //                       child: AppText(
  //                         text: "View Declined",
  //                         size: 15,
  //                         fontWeight: FontWeight.w400,
  //                         color: appLinkColor2,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //       SizedBox(height: 20.h),
  //       Expanded(
  //         child: ListView.builder(
  //           itemCount: 10,
  //           itemBuilder: (context, index) {
  //             return Padding(
  //               padding: EdgeInsets.symmetric(horizontal: 30.w),
  //               // child: ResponseBox(
  //               //   viewRequestClick: () {
  //               //     setState(() {
  //               //       viewRequest = !viewRequest;
  //               //     });
  //               //   },
  //               //   onAcceptTap: () {
  //               //     setState(() {
  //               //       isResponseAcceptOnClick = !isResponseAcceptOnClick;
  //               //     });
  //               //   },
  //               //   onCancelTap: () {
  //               //     setState(() {});
  //               //   },
  //               // ),
  //               child:SizedBox.shrink(),

  //             );
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget buildStatusButton(String text) {
    final bool isSelected = selectedStatus == text;

    return Expanded(
      child: GestureDetector(
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

























// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fudikoclient/components/appbutton.dart';
// import 'package:fudikoclient/components/apptext.dart';
// import 'package:fudikoclient/components/apptextfeild.dart';
// import 'package:fudikoclient/components/descriptionBox.dart';
// import 'package:fudikoclient/model/inquery/list-inquery-modal.dart';
// import 'package:fudikoclient/screens/tabs/inquery/common/responseBox.dart';
// import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctInquery.dart';
// import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctInqueryBox.dart';
// import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctdecline.dart';
// import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctresponseBox.dart';
// import 'package:fudikoclient/screens/tabs/inquery/common/declineBox.dart';
// import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
// import 'package:fudikoclient/components/appfilterdropdown.dart';
// import 'package:fudikoclient/screens/tabs/inquery/inquery/planaparty.dart';
// import 'package:fudikoclient/screens/tabs/inquery/inquery/viewinquery.dart';
// import 'package:fudikoclient/screens/tabs/mainnav.dart';
// import 'package:fudikoclient/service/inquery/inquery-service.dart';
// import 'package:fudikoclient/utils/constants.dart';

// class Inquery extends StatefulWidget {
//   const Inquery({super.key});

//   @override
//   State<Inquery> createState() => _InqueryState();
// }

// class _InqueryState extends State<Inquery> {
//   String selectedStatus = 'Plan a Party';
//   DateTime selectedDateTime = DateTime.now();
//   bool isReviewOnClick = false;
//   bool isCtReviewOnClick = false;
//   bool isWithdrawOnClick = false;
//   bool viewEnquiryOnClick = false;
//   bool viewCtEnquiryOnClick = false;
//   bool isResponseAcceptOnClick = false;
//   bool viewRequest = false;
//   bool viewCtRequest = false;
//   bool isResponseAcceptConfirmOnClick = false;
//   bool isConfirmClicked = false;
//   bool viewDeclineOnClick = false;
//   bool viewCtDeclineOnClick = false;
//   bool isSearchOnClick = false;
//   bool isCtSearchOnClick = false;
//   Map<String, String> ctEnquiryData = {};
//   Future<void> _submitCateringEnquiry() async {
//   final InqueryService service = InqueryService();
//   final model = CreateCateringInqueryModel(
//     lat: ctEnquiryData['lat'] ?? '',
//     lng: ctEnquiryData['lng'] ?? '',
//     menuItems: ctEnquiryData['menu'] ?? '',
//     people: ctEnquiryData['people'] ?? '',
//     time: ctEnquiryData['dateTime']?.split(' ').last ?? '',
//     date: ctEnquiryData['dateTime']?.split(' ').first ?? '',
//     estimatedAmount: ctEnquiryData['amount'] ?? '',
//     searchRadius: ctEnquiryData['searchRadius'] ?? '20',
//     expirationDate: ctEnquiryData['expirationDate'] ?? '',
//     expirationTime: ctEnquiryData['expirationTime'] ?? '',
//   );

//   final response = await service.createCateringInquery(model);

//   if (response.status) {
//     setState(() => isCtReviewOnClick = false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Enquiry submitted successfully!')),
//     );
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(response.message)),
//     );
//   }
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: appSecondaryBackgroundColor,
//       body: Stack(
//         children: [
//           if (viewEnquiryOnClick)
//             ViewInquery(
//               onEnquiryTap: (val) {
//                 setState(() {
//                   viewEnquiryOnClick = val;
//                 });
//               },
//             )
//           else if (viewCtEnquiryOnClick)
//             _viewCtEnquiryWidget()
//           else if (viewDeclineOnClick)
//             _viewDeclineWidget()
//           else if (viewCtDeclineOnClick)
//             _viewCtDeclineWidget()
//           else if (isSearchOnClick)
//             _viewSearchWidget()
//           else if (isCtSearchOnClick)
//             _viewCtSearchWidget()
//           else
//             Column(
//               children: [
//                 Padding(
//                   padding: EdgeInsets.all(20.w),
//                   child: Column(
//                     children: [
//                       Column(
//                         children: [
//                           Row(
//                             children: [
//                               buildStatusButton("Plan a Party"),
//                               SizedBox(width: 10.w),
//                               buildStatusButton("Book a Catering"),
//                             ],
//                           ),
//                           SizedBox(height: 10.h),
//                           Row(
//                             children: [
//                               buildStatusButton("Party Response"),
//                               SizedBox(width: 10.w),
//                               buildStatusButton("Catering Response"),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: selectedStatus == "Plan a Party"
//                       ? PlanAParty(
//                           onEnquiryTap: (val) {
//                             setState(() {
//                               viewEnquiryOnClick = val;
//                             });
//                           },
//                           onReviewTap: (val) {
//                             setState(() {
//                               isReviewOnClick = val;
//                             });
//                           },
//                         )
//                       : selectedStatus == "Party Response"
//                       ? _responseWidget()
//                       : selectedStatus == "Book a Catering"
//                       // ? CtInquery(
//                       //   onReviewTap: (){
//                       //     setState(() {
//                       //       isCtReviewOnClick = !isCtReviewOnClick;
//                       //     });
//                       //   },
//                       ? CtInquery(
//                           onReviewTap: (data) {
//                             setState(() {
//                               ctEnquiryData = data;
//                               isCtReviewOnClick = true;
//                             });
//                           },
//                           viewEnquiryOnTap: () {
//                             setState(() {
//                               viewCtEnquiryOnClick = !viewCtEnquiryOnClick;
//                             });
//                           },
//                         )
//                       : _ctResponseWidget(),
//                 ),
//               ],
//             ),
//           if (isResponseAcceptOnClick) _responseAcceptBox(),
//           if (viewRequest) _viewRequestWidget(),
//           if (viewCtRequest) _viewCtRequestWidget(),
//           if (isResponseAcceptConfirmOnClick) _responseAcceptConfirmBox(),
//           if (isCtReviewOnClick) _ctReviewBox(),
//         ],
//       ),
//     );
//   }

//   Widget _viewCtSearchWidget() {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             Padding(
//               padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
//               child: AppTextFeild(
//                 text: "Enter the Coupon Number",
//                 textColor: appTextColor3,
//                 icon: Icons.close,
//                 iconColor: appTextColor3,
//                 iconOnTap: () {
//                   setState(() {
//                     isCtSearchOnClick = !isCtSearchOnClick;
//                   });
//                 },
//               ),
//             ),

//             SizedBox(height: 20.h),
//             SizedBox(
//               width: 180.w,
//               child: AppFilterDropDown(
//                 hint: "Today",
//                 toggleDropdown: () {
//                   showModalBottomSheet(
//                     backgroundColor: Colors.white,
//                     context: context,
//                     isScrollControlled: true,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(25),
//                       ),
//                     ),
//                     builder: (context) {
//                       return Padding(
//                         padding: EdgeInsets.all(30.w),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 40.w,
//                               height: 5.h,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(10.r),
//                               ),
//                             ),
//                             SizedBox(height: 16.h),
//                             Container(
//                               width: MediaQuery.of(context).size.width,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20.r),
//                               ),
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 children: [
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item1",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item2",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item3",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 icon: Icons.tune,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: 2,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.only(left: 30.w, right: 30.w),
//                     child: CtResponseBox(
//                       viewRequestClick: () {
//                         setState(() {
//                           viewCtRequest = !viewCtRequest;
//                         });
//                       },
//                       onAcceptTap: () {
//                         setState(() {
//                           isResponseAcceptOnClick = !isResponseAcceptOnClick;
//                         });
//                       },
//                       onCancelTap: () {
//                         setState(() {});
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _viewCtDeclineWidget() {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             GestureDetector(
//               onTap: () {
//                 setState(() {
//                   viewCtDeclineOnClick = !viewCtDeclineOnClick;
//                 });
//               },
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Padding(
//                   padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
//                   child: Icon(
//                     Icons.arrow_back_ios_new,
//                     color: appTextColor3,
//                     size: 28.w,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 180.w,
//               child: AppFilterDropDown(
//                 hint: "Today",
//                 toggleDropdown: () {
//                   showModalBottomSheet(
//                     backgroundColor: Colors.white,
//                     context: context,
//                     isScrollControlled: true,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(25),
//                       ),
//                     ),
//                     builder: (context) {
//                       return Padding(
//                         padding: EdgeInsets.all(30.w),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 40.w,
//                               height: 5.h,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(10.r),
//                               ),
//                             ),
//                             SizedBox(height: 16.h),
//                             Container(
//                               width: MediaQuery.of(context).size.width,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20.r),
//                               ),
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 children: [
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item1",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item2",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item3",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 icon: Icons.tune,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: 2,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.only(left: 30.w, right: 30.w),
//                     child: CtDeclineBox(onCancelTap: () {}),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _viewCtRequestWidget() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
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
//                             viewCtRequest = !viewCtRequest;
//                           });
//                         },
//                         child: Icon(
//                           Icons.close,
//                           color: appTextColor3,
//                           size: 25.w,
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
//                       Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
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
//                       Icon(Icons.handshake, size: 20.w, color: appTextColor2),
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
//                       Icon(Icons.people, size: 20.w, color: appTextColor2),
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
//                         size: 20.w,
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
//                       Icon(Icons.wallet, size: 20.w, color: appTextColor2),
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
//                       Icon(Icons.analytics, size: 20.w, color: appTextColor2),
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

//   Widget _ctResponseWidget() {
//     return Column(
//       children: [
//         SizedBox(height: 20.h),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 30.w),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SizedBox(
//                 width: 150.w,
//                 child: AppFilterDropDown(
//                   hint: "Today",
//                   icon: Icons.tune,
//                   toggleDropdown: () {
//                     showModalBottomSheet(
//                       backgroundColor: Colors.white,
//                       context: context,
//                       isScrollControlled: true,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.vertical(
//                           top: Radius.circular(25),
//                         ),
//                       ),
//                       builder: (context) {
//                         return Padding(
//                           padding: EdgeInsets.all(30.w),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Container(
//                                 width: 40.w,
//                                 height: 5.h,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[300],
//                                   borderRadius: BorderRadius.circular(10.r),
//                                 ),
//                               ),
//                               SizedBox(height: 16.h),
//                               Container(
//                                 width: MediaQuery.of(context).size.width,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(20.r),
//                                 ),
//                                 padding: EdgeInsets.all(16.w),
//                                 child: Column(
//                                   children: [
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item1",
//                                       size: 15,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item2",
//                                       size: 15,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item3",
//                                       size: 15,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10),
//                                     Divider(color: Colors.grey[200]),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.search, size: 17.w, color: Colors.black),
//                       SizedBox(width: 2.w),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             isCtSearchOnClick = !isCtSearchOnClick;
//                           });
//                         },
//                         child: AppText(
//                           text: "Search",
//                           size: 15,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 5.h),
//                   Row(
//                     children: [
//                       Icon(Icons.book, size: 17.w, color: appLinkColor2),
//                       SizedBox(width: 2.w),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             viewCtDeclineOnClick = !viewCtDeclineOnClick;
//                           });
//                         },
//                         child: AppText(
//                           text: "View Declined",
//                           size: 15,
//                           fontWeight: FontWeight.w400,
//                           color: appLinkColor2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 20.h),
//         Expanded(
//           child: ListView.builder(
//             itemCount: 10,
//             itemBuilder: (context, index) {
//               return Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 30.w),
//                 child: CtResponseBox(
//                   viewRequestClick: () {
//                     setState(() {
//                       viewCtRequest = !viewCtRequest;
//                     });
//                   },
//                   onAcceptTap: () {
//                     setState(() {
//                       isResponseAcceptOnClick = !isResponseAcceptOnClick;
//                     });
//                   },
//                   onCancelTap: () {
//                     setState(() {});
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _viewCtEnquiryWidget() {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//               },
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Padding(
//                   padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
//                   child: Icon(
//                     Icons.arrow_back_ios_new,
//                     color: appTextColor3,
//                     size: 28.w,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 180.w,
//               child: AppFilterDropDown(
//                 hint: "Today",
//                 toggleDropdown: () {
//                   showModalBottomSheet(
//                     backgroundColor: Colors.white,
//                     context: context,
//                     isScrollControlled: true,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(25),
//                       ),
//                     ),
//                     builder: (context) {
//                       return Padding(
//                         padding: EdgeInsets.all(30.w),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 40.w,
//                               height: 5.h,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(10.r),
//                               ),
//                             ),
//                             SizedBox(height: 16.h),
//                             Container(
//                               width: MediaQuery.of(context).size.width,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20.r),
//                               ),
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 children: [
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item1",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item2",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item3",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10),
//                                   Divider(color: Colors.grey[200]),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 icon: Icons.tune,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: 10,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.only(left: 30.w, right: 30.w),
//                     child: CtInqueryBox(
//                       onCancelTap: () {
//                         setState(() {
//                           isWithdrawOnClick = !isWithdrawOnClick;
//                         });
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// // coorected with api call
//   Widget _ctReviewBox() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(30.w),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                           AppText(text: "C17854", size: 20, fontWeight: FontWeight.w700, color: appTextColor3),
//                       GestureDetector(
//                         onTap: () => setState(() => isCtReviewOnClick = false),
//                          child: AppText(text: "Edit", size: 15, fontWeight: FontWeight.w700, color: appLinkColor),
//                         // AppText(
//                         //   text: "C17854",
//                         //   size: 20,
//                         //   fontWeight: FontWeight.w700,
//                         //   color: appTextColor3,
//                         // ),
                        
//                         // AppText(
//                         //   text: "Edit",
//                         //   size: 15,
//                         //   fontWeight: FontWeight.w700,
//                         //   color: appLinkColor,
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 20.h),
//                      _reviewRow(Icons.dashboard, "Your Menu", ctEnquiryData['menu'] ?? ''),
//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.start,
//                     //   children: [
//                     //     Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
//                     //     SizedBox(width: 10.w),
//                     //     Expanded(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           AppText(
//                     //             text: "Your Menu",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: Colors.grey,
//                     //           ),
//                     //           SizedBox(height: 5.h),
//                     //           AppText(
//                     //             text:
//                     //                 "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: appTextColor2,
//                     //             lineSpacing: 1.5,
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
                
//                     SizedBox(height: 20.h),
//                                       _reviewRow(Icons.handshake, "Other Services", ctEnquiryData['otherServices'] ?? ''),
//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.start,
//                     //   children: [
//                     //     Icon(Icons.handshake, size: 20.w, color: appTextColor2),
//                     //     SizedBox(width: 10.w),
//                     //     Expanded(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           AppText(
//                     //             text: "Other Services",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: Colors.grey,
//                     //           ),
//                     //           SizedBox(height: 5.h),
//                     //           AppText(
//                     //             text: "7 Service boys needed.",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: appTextColor2,
//                     //             lineSpacing: 1.5,
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
                
//                     SizedBox(height: 20.h),
//                     _reviewRow(Icons.people, "Number of Persons", "${ctEnquiryData['people'] ?? ''} Person"),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Icon(Icons.people, size: 20.w, color: appTextColor2),
//                         SizedBox(width: 10.w),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               AppText(
//                                 text: "Number of Persons",
//                                 size: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey,
//                               ),
//                               SizedBox(height: 5.h),
//                               AppText(
//                                 text: "200 Person ",
//                                 size: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: appTextColor2,
//                                 lineSpacing: 1.5,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 20.h),
//                     _reviewRow(Icons.calendar_today_sharp, "Date and Time", ctEnquiryData['dateTime'] ?? ''),

//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.start,
//                     //   children: [
//                     //     Icon(
//                     //       Icons.calendar_today_sharp,
//                     //       size: 20.w,
//                     //       color: appTextColor2,
//                     //     ),
//                     //     SizedBox(width: 10.w),
//                     //     Expanded(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           AppText(
//                     //             text: "Date and Time ",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: Colors.grey,
//                     //           ),
//                     //           SizedBox(height: 5.h),
//                     //           AppText(
//                     //             text: "April 12 - 2:30 pm",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: appTextColor2,
//                     //             lineSpacing: 1.5,
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
//                     SizedBox(height: 20.h),
//                   _reviewRow(Icons.wallet, "Expected amount per person", "${ctEnquiryData['amount'] ?? ''} Per person"),
                   
//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.start,
//                     //   children: [
//                     //     Icon(Icons.wallet, size: 20.w, color: appTextColor2),
//                     //     SizedBox(width: 10.w),
//                     //     Expanded(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           AppText(
//                     //             text: "Expected amount per person",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: Colors.grey,
//                     //           ),
//                     //           SizedBox(height: 5.h),
//                     //           AppText(
//                     //             text: "450 Per person",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: appTextColor2,
//                     //             lineSpacing: 1.5,
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
//                     SizedBox(height: 20.h),
//                     _reviewRow(Icons.analytics, "Enquiry Radius", ctEnquiryData['location'] ?? ''),
//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.start,
//                     //   children: [
//                     //     Icon(Icons.analytics, size: 20.w, color: appTextColor2),
//                     //     SizedBox(width: 10.w),
//                     //     Expanded(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           AppText(
//                     //             text: "Enquiry Radius ",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: Colors.grey,
//                     //           ),
//                     //           SizedBox(height: 5.h),
//                     //           AppText(
//                     //             text: "Moscow City - 20km Radius",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: appTextColor2,
//                     //             lineSpacing: 1.5,
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
//                     SizedBox(height: 30.h),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.timer, size: 20.w, color: Colors.red),
//                         SizedBox(width: 5.w),
//                         AppText(
//                           text: "03:00:00",
//                           size: 15,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.red,
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 15.h),
//                     SizedBox(
//                       width: 150.w,
//                       height: 50.h,
//                       child: AppButton(
//                         text: "Send",
//                         onPressed: () => _submitCateringEnquiry(),
//                         // onPressed: () {
//                         //   setState(() {
//                         //     isCtReviewOnClick = !isCtReviewOnClick;
//                         //   });
//                         // },
//                         size: 15,
//                         bgColor1: Colors.green,
//                         bgColor2: Colors.green,
//                         borderRadius: 10,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// // helper widget for each row
//   Widget _reviewRow(IconData icon, String label, String value) {
//   return Row(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Icon(icon, size: 20.w, color: appTextColor2),
//       SizedBox(width: 10.w),
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             AppText(text: label, size: 15, fontWeight: FontWeight.w500, color: Colors.grey),
//             SizedBox(height: 5.h),
//             AppText(text: value, size: 15, fontWeight: FontWeight.w500, color: appTextColor2, lineSpacing: 1.5),
//           ],
//         ),
//       ),
//     ],
//   );
// }

//   Widget _responseAcceptConfirmBox() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
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
//                             isResponseAcceptConfirmOnClick =
//                                 !isResponseAcceptConfirmOnClick;
//                             if (isConfirmClicked) {
//                               isConfirmClicked = !isConfirmClicked;
//                             }
//                           });
//                         },
//                         child: Icon(
//                           Icons.close,
//                           color: appTextColor3,
//                           size: 25.w,
//                         ),
//                       ),
//                     ],
//                   ),

//                   if (isConfirmClicked)
//                     Column(
//                       children: [
//                         Image.asset(
//                           'assets/images/checked.png',
//                           height: 50.h,
//                           width: 50.w,
//                           fit: BoxFit.contain,
//                         ),
//                         SizedBox(height: 20.h),
//                         AppText(
//                           text: "Booking Successful!",
//                           size: 20,
//                           fontWeight: FontWeight.w500,
//                           color: appTextColor3,
//                           isCentered: true,
//                         ),
//                         SizedBox(height: 20.h),
//                       ],
//                     ),

//                   if (!isConfirmClicked)
//                     Column(
//                       children: [
//                         SizedBox(height: 20.h),
//                         AppText(
//                           text:
//                               "After confirmation, your party order will be booked at Bollywood Restaurant.",
//                           size: 15,
//                           fontWeight: FontWeight.w500,
//                           color: appTextColor2,
//                           isCentered: true,
//                         ),
//                         SizedBox(height: 20.h),
//                         SizedBox(
//                           width: 150.w,
//                           height: 40.h,
//                           child: AppButton(
//                             text: "Confirm",
//                             onPressed: () {
//                               setState(() {
//                                 isConfirmClicked = !isConfirmClicked;
//                               });
//                             },
//                             bgColor1: Colors.green,
//                             bgColor2: Colors.green,
//                             size: 15,
//                             borderRadius: 10,
//                           ),
//                         ),
//                         SizedBox(height: 20.h),
//                       ],
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _viewSearchWidget() {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             Padding(
//               padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
//               child: AppTextFeild(
//                 text: "Your Current Location",
//                 textColor: appTextColor3,
//                 icon: Icons.close,
//                 iconColor: appTextColor3,
//                 iconOnTap: () {
//                   setState(() {
//                     isSearchOnClick = !isSearchOnClick;
//                   });
//                 },
//               ),
//             ),

//             SizedBox(height: 20.h),
//             SizedBox(
//               width: 180.w,
//               child: AppFilterDropDown(
//                 hint: "Today",
//                 toggleDropdown: () {
//                   showModalBottomSheet(
//                     backgroundColor: Colors.white,
//                     context: context,
//                     isScrollControlled: true,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(25.r),
//                       ),
//                     ),
//                     builder: (context) {
//                       return Padding(
//                         padding: EdgeInsets.all(30.w),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 40.w,
//                               height: 5.h,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(10.r),
//                               ),
//                             ),
//                             SizedBox(height: 16.h),
//                             Container(
//                               width: MediaQuery.of(context).size.width,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20.r),
//                               ),
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 children: [
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item1",
//                                     size: 15.w,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item2",
//                                     size: 15.w,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item3",
//                                     size: 15.w,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 icon: Icons.tune,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: 2,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.only(left: 30.w, right: 30.w),
//                     child: ResponseBox(
//                       viewRequestClick: () {
//                         setState(() {
//                           viewRequest = !viewRequest;
//                         });
//                       },
//                       onAcceptTap: () {
//                         setState(() {
//                           isResponseAcceptOnClick = !isResponseAcceptOnClick;
//                         });
//                       },
//                       onCancelTap: () {
//                         setState(() {});
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _viewDeclineWidget() {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             GestureDetector(
//               onTap: () {
//                 setState(() {
//                   viewDeclineOnClick = !viewDeclineOnClick;
//                 });
//               },
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Padding(
//                   padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
//                   child: Icon(
//                     Icons.arrow_back_ios_new,
//                     color: appTextColor3,
//                     size: 28,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 180.w,
//               child: AppFilterDropDown(
//                 hint: "Today",
//                 toggleDropdown: () {
//                   showModalBottomSheet(
//                     backgroundColor: Colors.white,
//                     context: context,
//                     isScrollControlled: true,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(25.r),
//                       ),
//                     ),
//                     builder: (context) {
//                       return Padding(
//                         padding: EdgeInsets.all(30.w),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 40.w,
//                               height: 5.h,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(10.r),
//                               ),
//                             ),
//                             SizedBox(height: 16.h),
//                             Container(
//                               width: MediaQuery.of(context).size.width,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20.r),
//                               ),
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 children: [
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item1",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item2",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item3",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 icon: Icons.tune,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: 2,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.only(left: 30.w, right: 30.w),
//                     child: DeclineBox(onCancelTap: () {}),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   //---------------------------------------------------------------------------
//   Widget _viewRequestWidget() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
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
//                             viewRequest = !viewRequest;
//                           });
//                         },
//                         child: Icon(
//                           Icons.close,
//                           color: appTextColor3,
//                           size: 25.w,
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
//                       Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
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
//                       Icon(Icons.people, size: 20.w, color: appTextColor2),
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
//                         size: 20.w,
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
//                   SizedBox(height: 20.h),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _responseAcceptBox() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.warning_amber_outlined,
//                     size: 50.w,
//                     color: Colors.red,
//                   ),
//                   SizedBox(height: 10.h),
//                   AppText(
//                     text: "Switch Banquet Booking?",
//                     isCentered: true,
//                     lineSpacing: 1.5,
//                     size: 15,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.red,
//                   ),
//                   SizedBox(height: 10.h),
//                   AppText(
//                     text:
//                         " You already have a banquet booked at Bollywood Restaurant. Booking another Banquet will automatically cancel your previous booking.",
//                     isCentered: true,
//                     lineSpacing: 1.5,
//                     size: 15,
//                     fontWeight: FontWeight.w500,
//                     color: appTextColor2,
//                   ),

//                   SizedBox(height: 20.h),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       AppText(
//                         text: "Cancel",
//                         size: 15,
//                         fontWeight: FontWeight.w400,
//                         color: appLinkColor2,
//                       ),
//                       SizedBox(
//                         width: 120.w,
//                         height: 40.h,
//                         child: AppButton(
//                           text: "Yes,Book",
//                           onPressed: () {
//                             setState(() {
//                               isResponseAcceptOnClick =
//                                   !isResponseAcceptOnClick;
//                               isResponseAcceptConfirmOnClick =
//                                   !isResponseAcceptConfirmOnClick;
//                             });
//                           },
//                           size: 15,
//                           bgColor1: Colors.green,
//                           bgColor2: Colors.green,
//                           borderRadius: 10,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _responseWidget() {
//     return Column(
//       children: [
//         SizedBox(height: 20.h),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 30.w),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SizedBox(
//                 width: 150.w,
//                 child: AppFilterDropDown(
//                   hint: "Today",
//                   icon: Icons.tune,
//                   toggleDropdown: () {
//                     showModalBottomSheet(
//                       backgroundColor: Colors.white,
//                       context: context,
//                       isScrollControlled: true,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.vertical(
//                           top: Radius.circular(25.r),
//                         ),
//                       ),
//                       builder: (context) {
//                         return Padding(
//                           padding: EdgeInsets.all(30.w),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Container(
//                                 width: 40.w,
//                                 height: 5.h,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[300],
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                               SizedBox(height: 16.h),
//                               Container(
//                                 width: MediaQuery.of(context).size.width,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(20.r),
//                                 ),
//                                 padding: EdgeInsets.all(16.w),
//                                 child: Column(
//                                   children: [
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item1",
//                                       size: 15,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item2",
//                                       size: 15.w,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item3",
//                                       size: 15.w,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     Divider(color: Colors.grey[200]),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.search, size: 17.w, color: Colors.black),
//                       SizedBox(width: 2.w),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             isSearchOnClick = !isSearchOnClick;
//                           });
//                         },
//                         child: AppText(
//                           text: "Search",
//                           size: 15,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 5.h),
//                   Row(
//                     children: [
//                       Icon(Icons.book, size: 17.w, color: appLinkColor2),
//                       SizedBox(width: 2.w),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             viewDeclineOnClick = !viewDeclineOnClick;
//                           });
//                         },
//                         child: AppText(
//                           text: "View Declined",
//                           size: 15,
//                           fontWeight: FontWeight.w400,
//                           color: appLinkColor2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 20.h),
//         Expanded(
//           child: ListView.builder(
//             itemCount: 10,
//             itemBuilder: (context, index) {
//               return Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 30.w),
//                 child: ResponseBox(
//                   viewRequestClick: () {
//                     setState(() {
//                       viewRequest = !viewRequest;
//                     });
//                   },
//                   onAcceptTap: () {
//                     setState(() {
//                       isResponseAcceptOnClick = !isResponseAcceptOnClick;
//                     });
//                   },
//                   onCancelTap: () {
//                     setState(() {});
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget buildStatusButton(String text) {
//     final bool isSelected = selectedStatus == text;

//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           setState(() {
//             selectedStatus = text;
//           });
//         },
//         child: Container(
//           height: 35.h,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             gradient: isSelected
//                 ? const LinearGradient(
//                     colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
//                   )
//                 : null,
//             color: isSelected ? null : Colors.white,
//             borderRadius: BorderRadius.circular(10.r),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.2),
//                 blurRadius: 6.r,
//                 offset: Offset(2.w, 2.w),
//               ),
//             ],
//           ),
//           child: Text(
//             text,
//             style: TextStyle(
//               fontSize: 13.w,
//               fontWeight: FontWeight.w500,
//               color: isSelected ? Colors.white : appTextColor3,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
