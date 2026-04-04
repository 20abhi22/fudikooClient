import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/inquery/list-party-inquery-modal.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/inqueryBox.dart';
import 'package:fudikoclient/screens/tabs/main_restaurant_nav.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class ViewInquery extends StatefulWidget {
  final Function(bool) onEnquiryTap;
  const ViewInquery({
    super.key,
    required this.onEnquiryTap,
  });

  @override
  State<ViewInquery> createState() => _ViewInqueryState();
}

class _ViewInqueryState extends State<ViewInquery> {
  List<InqueryModel> inqueryList = [];
  bool _loading = true;


  // ── Filter state ─────────────────────────────────────────
  // "All" | "Today" | "Custom"
  String selectedFilter = "All";
  DateTime? customDate; // only set when selectedFilter == "Custom"

  final InqueryService inqueryService = InqueryService();

  @override
  void initState() {
    super.initState();
    fetchInqueryList();
  }

  Future<void> fetchInqueryList() async {
    setState(() => _loading = true);
    final response = await inqueryService.fetchInquerys();
    setState(() {
      inqueryList = response.enquiries;
      _loading = false;
    });
  }

  // ── Frontend filter ──────────────────────────────────────
  List<InqueryModel> get _filteredList {
    if (selectedFilter == "All") return inqueryList;

    final DateTime compareDate =
        selectedFilter == "Today" ? DateTime.now() : customDate!;

    final String targetDate = DateFormat('yyyy-MM-dd').format(compareDate);

    return inqueryList.where((item) => item.date == targetDate).toList();
  }

  // ── Filter label shown on button ─────────────────────────
  String get _filterLabel {
    if (selectedFilter == "All") return "All";
    if (selectedFilter == "Today") return "Today";
    // Custom: show the picked date
    return DateFormat('MMM d, yyyy').format(customDate!);
  }

  // ── Date picker for custom filter ───────────────────────
  Future<void> _pickCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: customDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFEC7B2D),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        customDate = picked;
        selectedFilter = "Custom";
      });
    }
  }

  // ── Filter option tile ───────────────────────────────────
  Widget _buildFilterOption(String label, {bool isCustom = false}) {
    final bool isSelected = isCustom
        ? selectedFilter == "Custom"
        : selectedFilter == label;

    return GestureDetector(
      onTap: () async {
        if (isCustom) {
          Navigator.pop(context); // close sheet first
          await _pickCustomDate();
        } else {
          setState(() {
            selectedFilter = label;
            if (label != "Custom") customDate = null;
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
              ? (selectedFilter == "Custom" && customDate != null
                  ? DateFormat('MMM d, yyyy').format(customDate!)
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;

    return Column(
      children: [
        // ── Header row ───────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onEnquiryTap(false),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: appTextColor3,
                  size: 28.w,
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 180.w,
                    child: AppFilterDropDown(
                      hint: _filterLabel, // ← shows selected label
                      icon: Icons.tune,
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
                                  // handle bar
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
                                        _buildFilterOption("All"),
                                        Divider(color: Colors.grey[200]),
                                        _buildFilterOption("Today"),
                                        Divider(color: Colors.grey[200]),
                                        // "Select a Date" opens date picker
                                        _buildFilterOption(
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
              SizedBox(width: 28.w), // balance spacer
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // ── List / loading / empty ────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: AppText(
                        text: selectedFilter == "All"
                            ? "No enquiries found"
                            : "No enquiries for ${_filterLabel}",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor3,
                        isCentered: true,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Padding(
                          padding:
                              EdgeInsets.only(left: 30.w, right: 30.w),
                          child: InqueryBox(
                            uuid: item.uuid,
                            enquiryId: item.enquiryId,
                            userId: item.userId,
                            lat: item.lat,
                            lng: item.lng,
                            menuItems: item.menuItems,
                            people: item.people,
                            date: item.date,
                            time: item.time,
                            estimatedAmount: item.estimatedAmount,
                            searchRadius: item.searchRadius,
                            expirationDate: item.expirationDate,
                            expirationTime: item.expirationTime,
                            status: item.status,
                            onDeleted: fetchInqueryList,
                            onEdit: () => widget.onEnquiryTap(false),
                            enquiry: item,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}