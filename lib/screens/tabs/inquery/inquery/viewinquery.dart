import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/inquery/list-party-inquery-modal.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/inqueryBox.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class ViewInquery extends StatefulWidget {
  final Function(bool) onEnquiryTap;
  const ViewInquery({super.key, required this.onEnquiryTap});

  @override
  State<ViewInquery> createState() => _ViewInqueryState();
}

class _ViewInqueryState extends State<ViewInquery> {
  // ── Data ─────────────────────────────────────────────────
  List<InqueryModel> _inqueryList = [];
  bool _loading = true;
  String? _error;

  // ── Filter state ─────────────────────────────────────────
  String selectedFilter = "All";
  DateTime? _customStart;
  DateTime? _customEnd;

  final InqueryService _inqueryService = InqueryService();

  @override
  void initState() {
    super.initState();
    _fetchList();
  }

  // ── Network ───────────────────────────────────────────────
  Future<void> _fetchList() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _inqueryService.fetchInquerys();
      if (!mounted) return;
      setState(() {
        _inqueryList = response.enquiries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load enquiries. Please try again.';
        _loading = false;
      });
    }
  }

  // ── Filter logic ──────────────────────────────────────────
  List<InqueryModel> get _filteredList {
    if (selectedFilter == "All") return _inqueryList;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _inqueryList.where((item) {
      DateTime? itemDate;
      try {
        itemDate = DateFormat('yyyy-MM-dd').parse(item.date);
      } catch (_) {
        return false;
      }
      final itemDay = DateTime(itemDate.year, itemDate.month, itemDate.day);

      switch (selectedFilter) {
        case "Today":
          return itemDay == today;
        case "Last 7 Days":
          return !itemDay.isBefore(today.subtract(const Duration(days: 6)));
        case "Last 30 Days":
          return !itemDay.isBefore(today.subtract(const Duration(days: 29)));
        case "Custom Range":
          if (_customStart == null || _customEnd == null) return true;
          final start = DateTime(
            _customStart!.year,
            _customStart!.month,
            _customStart!.day,
          );
          final end = DateTime(
            _customEnd!.year,
            _customEnd!.month,
            _customEnd!.day,
          );
          return !itemDay.isBefore(start) && !itemDay.isAfter(end);
        default:
          return true;
      }
    }).toList();
  }

  String get _filterLabel {
    if (selectedFilter == "Custom Range" &&
        _customStart != null &&
        _customEnd != null) {
      return "${DateFormat('MMM d').format(_customStart!)} – ${DateFormat('MMM d, yyyy').format(_customEnd!)}";
    }
    return selectedFilter;
  }

  // ── Custom date range picker ──────────────────────────────
  Future<void> _pickCustomRange() async {
    final DateTimeRange? picked = await _pickCustomCalendarRangePopup();
    if (picked != null && mounted) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        selectedFilter = "Custom Range";
      });
    }
  }

  Future<DateTimeRange?> _pickCustomCalendarRangePopup() {
    DateTime tempStart = _customStart ?? DateTime.now();
    DateTime tempEnd = _customEnd ?? tempStart;
    bool selectingStart = true;

    return showDialog<DateTimeRange>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final metrics = _ViewInqueryMetrics.fromContext(context);
            final activeDate = selectingStart ? tempStart : tempEnd;

            final dialogWidth = _rangeDialogWidth(context, metrics);

            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: metrics.dialogPaddingHorizontal,
                vertical: metrics.dialogPaddingVertical,
              ),
              constraints: BoxConstraints(
                minWidth: dialogWidth,
                maxWidth: dialogWidth,
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              backgroundColor: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(metrics.dialogRadius),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.dialogPaddingHorizontal,
                  vertical: metrics.dialogPaddingVertical,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      text: "Select Date Range",
                      size: metrics.dialogTitleSize,
                      fontWeight: FontWeight.w600,
                      color: appTextColor3,
                    ),
                    SizedBox(height: metrics.dialogGap),
                    Row(
                      children: [
                        Expanded(
                          child: _rangeDateButton(
                            label: "Start",
                            date: tempStart,
                            isSelected: selectingStart,
                            onTap: () =>
                                setDialogState(() => selectingStart = true),
                          ),
                        ),
                        SizedBox(width: metrics.rangeButtonGap),
                        Expanded(
                          child: _rangeDateButton(
                            label: "End",
                            date: tempEnd,
                            isSelected: !selectingStart,
                            onTap: () =>
                                setDialogState(() => selectingStart = false),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.dialogGap),
                    _buildCustomCalendar(
                      key: ValueKey(
                        '${selectingStart ? 'start' : 'end'}-${activeDate.year}-${activeDate.month}',
                      ),
                      tempDate: activeDate,
                      onDateChanged: (date) {
                        setDialogState(() {
                          if (selectingStart) {
                            tempStart = date;
                            if (tempEnd.isBefore(tempStart)) {
                              tempEnd = tempStart;
                            }
                          } else {
                            tempEnd = date;
                            if (tempStart.isAfter(tempEnd)) {
                              tempStart = tempEnd;
                            }
                          }
                        });
                      },
                    ),
                    SizedBox(height: metrics.dialogGap),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.dialogActionHorizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: metrics.dialogActionTextSize,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(
                              dialogContext,
                              DateTimeRange(start: tempStart, end: tempEnd),
                            ),
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                color: const Color(0xFF3954DB),
                                fontSize: metrics.dialogActionTextSize,
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

  double _rangeDialogWidth(BuildContext context, _ViewInqueryMetrics metrics) {
    final calendarWidth = _CalendarMetrics.fromContext(context).calendarWidth;
    return calendarWidth + (metrics.dialogPaddingHorizontal * 2);
  }

  Widget _rangeDateButton({
    required String label,
    required DateTime date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final metrics = _ViewInqueryMetrics.fromContext(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.rangeButtonHorizontalPadding,
          vertical: metrics.rangeButtonVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFf87b0d) : Colors.white,
          borderRadius: BorderRadius.circular(metrics.rangeButtonRadius),
          border: Border.all(
            color: isSelected ? const Color(0xFFf87b0d) : Colors.black12,
          ),
        ),
        child: Column(
          children: [
            AppText(
              text: label,
              size: metrics.rangeLabelSize,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor2,
              isCentered: true,
            ),
            SizedBox(height: metrics.rangeTextGap),
            AppText(
              text: DateFormat('MMM d, yyyy').format(date),
              size: metrics.rangeDateSize,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : appTextColor3,
              isCentered: true,
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter option tile — matches Reservation pattern exactly ─
  Widget _buildFilterOption(String label, {bool isCustom = false}) {
    final metrics = _ViewInqueryMetrics.fromContext(context);
    final bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () async {
        if (isCustom) {
          Navigator.pop(context);
          await _pickCustomRange();
        } else {
          setState(() {
            selectedFilter = label;
            _customStart = null;
            _customEnd = null;
          });
          Navigator.pop(context);
        }
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
          text: isCustom
              ? (selectedFilter == "Custom Range" &&
                        _customStart != null &&
                        _customEnd != null
                    ? "${DateFormat('MMM d').format(_customStart!)} – ${DateFormat('MMM d, yyyy').format(_customEnd!)}"
                    : "Custom Range")
              : label,
          size: metrics.filterOptionTextSize,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }

  void _openFilterSheet() {
    final metrics = _ViewInqueryMetrics.fromContext(context);

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        maxWidth: metrics.sheetMaxWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(metrics.sheetRadius),
        ),
      ),
      builder: (context) {
        return SingleChildScrollView(
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
              SizedBox(height: metrics.sheetHandleGap),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(metrics.sheetInnerRadius),
                ),
                padding: EdgeInsets.all(metrics.sheetInnerPadding),
                child: Column(
                  children: [
                    _buildFilterOption("All"),
                    Divider(color: Colors.grey[200]),
                    _buildFilterOption("Today"),
                    Divider(color: Colors.grey[200]),
                    _buildFilterOption("Last 7 Days"),
                    Divider(color: Colors.grey[200]),
                    _buildFilterOption("Last 30 Days"),
                    Divider(color: Colors.grey[200]),
                    _buildFilterOption("Custom Range", isCustom: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final metrics = _ViewInqueryMetrics.fromContext(context);
    final filtered = _filteredList;

    return Column(
      children: [
        // ── Header ─────────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(
            left: metrics.headerHorizontalPadding,
            right: metrics.headerHorizontalPadding,
            top: metrics.headerTopPadding,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onEnquiryTap(false),
                child: Image.asset(backOrange, width: metrics.backIconSize),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: metrics.filterDropdownMinWidth,
                      maxWidth: metrics.filterDropdownMaxWidth,
                    ),
                    child: IntrinsicWidth(
                      child: AppFilterDropDown(
                        height: metrics.filterHeight,
                        hint: _filterLabel,
                        imageIconPath: filterIcon, // ← same as Reservation
                        imageIconSize: metrics.filterIconSize,
                        toggleDropdown: _openFilterSheet,
                      ),
                    ),
                  ),
                ),
              ),
              // Balance spacer so dropdown stays centred
              SizedBox(width: metrics.backIconSize),
            ],
          ),
        ),
        SizedBox(height: metrics.headerBottomGap),

        // ── Content ────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: Color(0xFFEC7B2D),
            onRefresh: _fetchList,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: metrics.emptyIconSize,
                              color: appTextColor3.withValues(alpha: 0.4),
                            ),
                            SizedBox(height: metrics.emptyGap),
                            AppText(
                              text: _error!,
                              size: metrics.emptyTextSize,
                              fontWeight: FontWeight.w500,
                              color: appTextColor3,
                              isCentered: true,
                            ),
                            SizedBox(height: metrics.retryTopGap),
                            GestureDetector(
                              onTap: _fetchList,
                              child: AppText(
                                text: "Retry",
                                size: metrics.retryTextSize,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEC7B2D),
                                isCentered: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : filtered.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: metrics.emptyIconSize,
                              color: appTextColor3.withValues(alpha: 0.4),
                            ),
                            SizedBox(height: metrics.emptyGap),
                            AppText(
                              text: selectedFilter == "All"
                                  ? "No enquiries found"
                                  : "No enquiries for $_filterLabel",
                              size: metrics.emptyTextSize,
                              fontWeight: FontWeight.w500,
                              color: appTextColor3,
                              isCentered: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          left: metrics.listHorizontalPadding,
                          right: metrics.listHorizontalPadding,
                        ),
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
                          onDeleted: _fetchList,
                          onEdit: () {
                            widget.onEnquiryTap(false);
                            _fetchList();
                          },
                          enquiry: item,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _ViewInqueryMetrics {
  const _ViewInqueryMetrics({
    required this.headerHorizontalPadding,
    required this.headerTopPadding,
    required this.headerBottomGap,
    required this.backIconSize,
    required this.filterHeight,
    required this.filterIconSize,
    required this.filterDropdownMinWidth,
    required this.filterDropdownMaxWidth,
    required this.listHorizontalPadding,
    required this.listBottomPadding,
    required this.emptyIconSize,
    required this.emptyGap,
    required this.emptyTextSize,
    required this.retryTopGap,
    required this.retryTextSize,
    required this.dialogPaddingHorizontal,
    required this.dialogPaddingVertical,
    required this.dialogRadius,
    required this.dialogTitleSize,
    required this.dialogGap,
    required this.dialogActionHorizontalPadding,
    required this.dialogActionTextSize,
    required this.rangeButtonGap,
    required this.rangeButtonHorizontalPadding,
    required this.rangeButtonVerticalPadding,
    required this.rangeButtonRadius,
    required this.rangeLabelSize,
    required this.rangeDateSize,
    required this.rangeTextGap,
    required this.filterOptionVerticalPadding,
    required this.filterOptionHorizontalPadding,
    required this.filterOptionRadius,
    required this.filterOptionTextSize,
    required this.sheetPadding,
    required this.sheetMaxWidth,
    required this.sheetRadius,
    required this.sheetHandleWidth,
    required this.sheetHandleHeight,
    required this.sheetHandleRadius,
    required this.sheetHandleGap,
    required this.sheetInnerPadding,
    required this.sheetInnerRadius,
  });

  final double headerHorizontalPadding;
  final double headerTopPadding;
  final double headerBottomGap;
  final double backIconSize;
  final double filterHeight;
  final double filterIconSize;
  final double filterDropdownMinWidth;
  final double filterDropdownMaxWidth;
  final double listHorizontalPadding;
  final double listBottomPadding;
  final double emptyIconSize;
  final double emptyGap;
  final double emptyTextSize;
  final double retryTopGap;
  final double retryTextSize;
  final double dialogPaddingHorizontal;
  final double dialogPaddingVertical;
  final double dialogRadius;
  final double dialogTitleSize;
  final double dialogGap;
  final double dialogActionHorizontalPadding;
  final double dialogActionTextSize;
  final double rangeButtonGap;
  final double rangeButtonHorizontalPadding;
  final double rangeButtonVerticalPadding;
  final double rangeButtonRadius;
  final double rangeLabelSize;
  final double rangeDateSize;
  final double rangeTextGap;
  final double filterOptionVerticalPadding;
  final double filterOptionHorizontalPadding;
  final double filterOptionRadius;
  final double filterOptionTextSize;
  final double sheetPadding;
  final double sheetMaxWidth;
  final double sheetRadius;
  final double sheetHandleWidth;
  final double sheetHandleHeight;
  final double sheetHandleRadius;
  final double sheetHandleGap;
  final double sheetInnerPadding;
  final double sheetInnerRadius;

  factory _ViewInqueryMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final scale = (size.width / 768).clamp(1.0, 1.18).toDouble();
      final verticalScale = (size.height / 1024).clamp(1.0, 1.2).toDouble();
      double s(double value) => value * scale;
      double v(double value) => value * verticalScale;

      return _ViewInqueryMetrics(
        headerHorizontalPadding: s(48),
        headerTopPadding: v(36),
        headerBottomGap: v(24),
        backIconSize: s(34),
        filterHeight: v(38),
        filterIconSize: s(17),
        filterDropdownMinWidth: s(140),
        filterDropdownMaxWidth: s(260),
        listHorizontalPadding: s(48),
        listBottomPadding: v(34),
        emptyIconSize: s(56),
        emptyGap: v(14),
        emptyTextSize: 16,
        retryTopGap: v(18),
        retryTextSize: 15,
        dialogPaddingHorizontal: s(16),
        dialogPaddingVertical: v(16),
        dialogRadius: s(10),
        dialogTitleSize: 16,
        dialogGap: v(14),
        dialogActionHorizontalPadding: s(10),
        dialogActionTextSize: 14,
        rangeButtonGap: s(10),
        rangeButtonHorizontalPadding: s(10),
        rangeButtonVerticalPadding: v(9),
        rangeButtonRadius: s(10),
        rangeLabelSize: 11,
        rangeDateSize: 12,
        rangeTextGap: v(3),
        filterOptionVerticalPadding: v(13),
        filterOptionHorizontalPadding: s(10),
        filterOptionRadius: s(10),
        filterOptionTextSize: 16,
        sheetPadding: s(34),
        sheetMaxWidth: 480,
        sheetRadius: s(25),
        sheetHandleWidth: s(44),
        sheetHandleHeight: v(5),
        sheetHandleRadius: s(10),
        sheetHandleGap: v(18),
        sheetInnerPadding: s(18),
        sheetInnerRadius: s(20),
      );
    }

    if (isWideShortPhone) {
      return const _ViewInqueryMetrics(
        headerHorizontalPadding: 24,
        headerTopPadding: 20,
        headerBottomGap: 14,
        backIconSize: 26,
        filterHeight: 30,
        filterIconSize: 13,
        filterDropdownMinWidth: 115,
        filterDropdownMaxWidth: 190,
        listHorizontalPadding: 24,
        listBottomPadding: 20,
        emptyIconSize: 42,
        emptyGap: 10,
        emptyTextSize: 13.5,
        retryTopGap: 14,
        retryTextSize: 13,
        dialogPaddingHorizontal: 14,
        dialogPaddingVertical: 14,
        dialogRadius: 10,
        dialogTitleSize: 15,
        dialogGap: 12,
        dialogActionHorizontalPadding: 8,
        dialogActionTextSize: 13,
        rangeButtonGap: 8,
        rangeButtonHorizontalPadding: 8,
        rangeButtonVerticalPadding: 8,
        rangeButtonRadius: 10,
        rangeLabelSize: 10.5,
        rangeDateSize: 11,
        rangeTextGap: 3,
        filterOptionVerticalPadding: 10,
        filterOptionHorizontalPadding: 8,
        filterOptionRadius: 10,
        filterOptionTextSize: 13.5,
        sheetPadding: 24,
        sheetMaxWidth: 420,
        sheetRadius: 22,
        sheetHandleWidth: 38,
        sheetHandleHeight: 5,
        sheetHandleRadius: 10,
        sheetHandleGap: 14,
        sheetInnerPadding: 14,
        sheetInnerRadius: 18,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _ViewInqueryMetrics(
        headerHorizontalPadding: s(24),
        headerTopPadding: s(22),
        headerBottomGap: s(16),
        backIconSize: s(26),
        filterHeight: s(30),
        filterIconSize: s(13),
        filterDropdownMinWidth: s(115),
        filterDropdownMaxWidth: s(190),
        listHorizontalPadding: s(24),
        listBottomPadding: s(20),
        emptyIconSize: s(42),
        emptyGap: s(10),
        emptyTextSize: s(13.5),
        retryTopGap: s(14),
        retryTextSize: s(13),
        dialogPaddingHorizontal: s(12),
        dialogPaddingVertical: s(12),
        dialogRadius: s(10),
        dialogTitleSize: s(15),
        dialogGap: s(10),
        dialogActionHorizontalPadding: s(6),
        dialogActionTextSize: s(12.5),
        rangeButtonGap: s(8),
        rangeButtonHorizontalPadding: s(8),
        rangeButtonVerticalPadding: s(7),
        rangeButtonRadius: s(10),
        rangeLabelSize: s(10),
        rangeDateSize: s(10.5),
        rangeTextGap: s(3),
        filterOptionVerticalPadding: s(10),
        filterOptionHorizontalPadding: s(8),
        filterOptionRadius: s(10),
        filterOptionTextSize: s(13.5),
        sheetPadding: s(22),
        sheetMaxWidth: 420,
        sheetRadius: s(22),
        sheetHandleWidth: s(38),
        sheetHandleHeight: s(5),
        sheetHandleRadius: s(10),
        sheetHandleGap: s(14),
        sheetInnerPadding: s(14),
        sheetInnerRadius: s(18),
      );
    }

    return _ViewInqueryMetrics(
      headerHorizontalPadding: 30.w,
      headerTopPadding: 30.h,
      headerBottomGap: 20.h,
      backIconSize: 30.w,
      filterHeight: 32.h,
      filterIconSize: 15.sp,
      filterDropdownMinWidth: 120.w,
      filterDropdownMaxWidth: 210.w,
      listHorizontalPadding: 30.w,
      listBottomPadding: 24.h,
      emptyIconSize: 48.w,
      emptyGap: 12.h,
      emptyTextSize: 15,
      retryTopGap: 16.h,
      retryTextSize: 14,
      dialogPaddingHorizontal: 16.w,
      dialogPaddingVertical: 16.h,
      dialogRadius: 10.r,
      dialogTitleSize: 16,
      dialogGap: 14.h,
      dialogActionHorizontalPadding: 10.w,
      dialogActionTextSize: 14.sp,
      rangeButtonGap: 10.w,
      rangeButtonHorizontalPadding: 10.w,
      rangeButtonVerticalPadding: 9.h,
      rangeButtonRadius: 10.r,
      rangeLabelSize: 11,
      rangeDateSize: 12,
      rangeTextGap: 3.h,
      filterOptionVerticalPadding: 12.h,
      filterOptionHorizontalPadding: 8.w,
      filterOptionRadius: 10,
      filterOptionTextSize: 15,
      sheetPadding: 30.w,
      sheetMaxWidth: 440.w,
      sheetRadius: 25,
      sheetHandleWidth: 40,
      sheetHandleHeight: 5,
      sheetHandleRadius: 10,
      sheetHandleGap: 16.h,
      sheetInnerPadding: 16.w,
      sheetInnerRadius: 20,
    );
  }
}

class _CalendarMetrics {
  const _CalendarMetrics({
    required this.calendarWidth,
    required this.headerIconButtonSize,
    required this.headerIconSize,
    required this.headerTextSize,
    required this.headerTextGap,
    required this.dropdownIconSize,
    required this.sectionGap,
    required this.yearIconSize,
    required this.yearTextSize,
    required this.monthGridMainSpacing,
    required this.monthGridCrossSpacing,
    required this.monthGridAspectRatio,
    required this.monthCellHeight,
    required this.monthCellRadius,
    required this.monthTextSize,
    required this.yearSheetHeight,
    required this.yearSheetRadius,
    required this.yearItemTextSize,
    required this.weekdayCellWidth,
    required this.weekdayTextSize,
    required this.dayMainSpacing,
    required this.dayCellSize,
    required this.dayRadius,
    required this.dayTextSize,
    required this.todayDotSize,
    required this.todayDotGap,
  });

  final double calendarWidth;
  final double headerIconButtonSize;
  final double headerIconSize;
  final double headerTextSize;
  final double headerTextGap;
  final double dropdownIconSize;
  final double sectionGap;
  final double yearIconSize;
  final double yearTextSize;
  final double monthGridMainSpacing;
  final double monthGridCrossSpacing;
  final double monthGridAspectRatio;
  final double monthCellHeight;
  final double monthCellRadius;
  final double monthTextSize;
  final double yearSheetHeight;
  final double yearSheetRadius;
  final double yearItemTextSize;
  final double weekdayCellWidth;
  final double weekdayTextSize;
  final double dayMainSpacing;
  final double dayCellSize;
  final double dayRadius;
  final double dayTextSize;
  final double todayDotSize;
  final double todayDotGap;

  factory _CalendarMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    // Phones rotated to landscape with very little vertical room —
    // needs its own, tighter sizing rather than reusing isWideShortPhone.
    final isShortLandscape =
        !isTablet && size.width > size.height && size.height < 450;
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final scale = (size.width / 768).clamp(1.0, 1.18).toDouble();
      double s(double value) => value * scale;

      return _CalendarMetrics(
        calendarWidth: (size.width * 0.36).clamp(310.0, 380.0).toDouble(),
        headerIconButtonSize: s(38),
        headerIconSize: s(22),
        headerTextSize: s(16),
        headerTextGap: s(4),
        dropdownIconSize: s(20),
        sectionGap: s(7),
        yearIconSize: s(20),
        yearTextSize: s(15),
        monthGridMainSpacing: s(8),
        monthGridCrossSpacing: s(8),
        monthGridAspectRatio: 2.25,
        monthCellHeight: s(42),
        monthCellRadius: s(8),
        monthTextSize: s(12.5),
        yearSheetHeight: s(280),
        yearSheetRadius: s(16),
        yearItemTextSize: s(15),
        weekdayCellWidth: s(36),
        weekdayTextSize: s(12),
        dayMainSpacing: s(4),
        dayCellSize: s(32),
        dayRadius: s(9),
        dayTextSize: s(13),
        todayDotSize: s(5),
        todayDotGap: s(2),
      );
    }

    if (isShortLandscape) {
      return const _CalendarMetrics(
        calendarWidth: 230,
        headerIconButtonSize: 28,
        headerIconSize: 18,
        headerTextSize: 13,
        headerTextGap: 3,
        dropdownIconSize: 16,
        sectionGap: 3,
        yearIconSize: 16,
        yearTextSize: 12,
        monthGridMainSpacing: 5,
        monthGridCrossSpacing: 5,
        monthGridAspectRatio: 2.5,
        monthCellHeight: 28,
        monthCellRadius: 6,
        monthTextSize: 10,
        yearSheetHeight: 170,
        yearSheetRadius: 12,
        yearItemTextSize: 12,
        weekdayCellWidth: 24,
        weekdayTextSize: 9.5,
        dayMainSpacing: 2,
        dayCellSize: 21,
        dayRadius: 6,
        dayTextSize: 10.5,
        todayDotSize: 3,
        todayDotGap: 1,
      );
    }

    if (isWideShortPhone) {
      return const _CalendarMetrics(
        calendarWidth: 270,
        headerIconButtonSize: 34,
        headerIconSize: 21,
        headerTextSize: 15,
        headerTextGap: 4,
        dropdownIconSize: 19,
        sectionGap: 5,
        yearIconSize: 19,
        yearTextSize: 14,
        monthGridMainSpacing: 7,
        monthGridCrossSpacing: 7,
        monthGridAspectRatio: 2.35,
        monthCellHeight: 38,
        monthCellRadius: 8,
        monthTextSize: 11.5,
        yearSheetHeight: 220,
        yearSheetRadius: 14,
        yearItemTextSize: 14,
        weekdayCellWidth: 32,
        weekdayTextSize: 11,
        dayMainSpacing: 3,
        dayCellSize: 28,
        dayRadius: 8,
        dayTextSize: 12,
        todayDotSize: 4,
        todayDotGap: 2,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.86, 1.0).toDouble();
      double s(double value) => value * scale;

      return _CalendarMetrics(
        calendarWidth: s(270),
        headerIconButtonSize: s(34),
        headerIconSize: s(21),
        headerTextSize: s(15),
        headerTextGap: s(4),
        dropdownIconSize: s(19),
        sectionGap: s(5),
        yearIconSize: s(19),
        yearTextSize: s(14),
        monthGridMainSpacing: s(7),
        monthGridCrossSpacing: s(7),
        monthGridAspectRatio: 2.25,
        monthCellHeight: s(38),
        monthCellRadius: s(8),
        monthTextSize: s(11.5),
        yearSheetHeight: s(220),
        yearSheetRadius: s(14),
        yearItemTextSize: s(14),
        weekdayCellWidth: s(32),
        weekdayTextSize: s(11),
        dayMainSpacing: s(3),
        dayCellSize: s(28),
        dayRadius: s(8),
        dayTextSize: s(12),
        todayDotSize: s(4),
        todayDotGap: s(2),
      );
    }

    return _CalendarMetrics(
      calendarWidth: (size.width * 0.68).clamp(260.0, 300.0).toDouble(),
      headerIconButtonSize: 40.w,
      headerIconSize: 24.sp,
      headerTextSize: 16.sp,
      headerTextGap: 4.w,
      dropdownIconSize: 20.sp,
      sectionGap: 6.h,
      yearIconSize: 20,
      yearTextSize: 15.sp,
      monthGridMainSpacing: 8,
      monthGridCrossSpacing: 8,
      monthGridAspectRatio: 2.2,
      monthCellHeight: 50.h,
      monthCellRadius: 8.r,
      monthTextSize: 12.sp,
      yearSheetHeight: 250.h,
      yearSheetRadius: 16.r,
      yearItemTextSize: 15.sp,
      weekdayCellWidth: 36.w,
      weekdayTextSize: 12.sp,
      dayMainSpacing: 4,
      dayCellSize: 32.w,
      dayRadius: 10.r,
      dayTextSize: 13.sp,
      todayDotSize: 5.w,
      todayDotGap: 2.h,
    );
  }
}

Widget _buildCustomCalendar({
  Key? key,
  required DateTime tempDate,
  required void Function(DateTime) onDateChanged,
}) {
  return _CustomCalendar(
    key: key,
    selectedDate: tempDate,
    onDateChanged: onDateChanged,
  );
}

class _CustomCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateChanged;

  const _CustomCalendar({
    super.key,
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
    final metrics = _CalendarMetrics.fromContext(context);
    final today = DateTime.now();
    final monthName = _monthName(_displayMonth.month);

    return SizedBox(
      width: metrics.calendarWidth,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: metrics.headerIconSize),
                constraints: BoxConstraints.tightFor(
                  width: metrics.headerIconButtonSize,
                  height: metrics.headerIconButtonSize,
                ),
                padding: EdgeInsets.zero,
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
                        fontSize: metrics.headerTextSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: metrics.headerTextGap),
                    Icon(
                      _showMonthYearPicker
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: Colors.black54,
                      size: metrics.dropdownIconSize,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, size: metrics.headerIconSize),
                constraints: BoxConstraints.tightFor(
                  width: metrics.headerIconButtonSize,
                  height: metrics.headerIconButtonSize,
                ),
                padding: EdgeInsets.zero,
                onPressed: _showMonthYearPicker ? null : _nextMonth,
              ),
            ],
          ),
          if (_showMonthYearPicker) ...[
            SizedBox(height: metrics.sectionGap),
            _buildMonthYearPicker(),
          ] else ...[
            SizedBox(height: metrics.sectionGap),
            _buildWeekdayLabels(),
            SizedBox(height: metrics.sectionGap),
            _buildDayGrid(today),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthYearPicker() {
    final metrics = _CalendarMetrics.fromContext(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, size: metrics.yearIconSize),
              constraints: BoxConstraints.tightFor(
                width: metrics.headerIconButtonSize,
                height: metrics.headerIconButtonSize,
              ),
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _pickerYear--),
            ),
            GestureDetector(
              onTap: () => _showYearScrollPicker(context),
              child: Text(
                '$_pickerYear',
                style: TextStyle(
                  fontSize: metrics.yearTextSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFf87b0d),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, size: metrics.yearIconSize),
              constraints: BoxConstraints.tightFor(
                width: metrics.headerIconButtonSize,
                height: metrics.headerIconButtonSize,
              ),
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _pickerYear++),
            ),
          ],
        ),
        SizedBox(height: metrics.sectionGap),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: metrics.monthGridMainSpacing,
            crossAxisSpacing: metrics.monthGridCrossSpacing,
            childAspectRatio: metrics.monthGridAspectRatio,
          ),
          itemBuilder: (context, index) {
            final month = index + 1;
            final isSelected =
                month == _displayMonth.month &&
                _pickerYear == _displayMonth.year;
            return GestureDetector(
              onTap: () => _selectMonthYear(month, _pickerYear),
              child: Container(
                height: metrics.monthCellHeight,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFE943A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(metrics.monthCellRadius),
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
                      fontSize: metrics.monthTextSize,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: metrics.sectionGap),
      ],
    );
  }

  void _showYearScrollPicker(BuildContext context) {
    final metrics = _CalendarMetrics.fromContext(context);
    const firstYear = 2020;
    final lastYear = DateTime.now().year + 20;
    final years = List.generate(lastYear - firstYear + 1, (i) => firstYear + i);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(metrics.yearSheetRadius),
        ),
      ),
      builder: (_) => SizedBox(
        height: metrics.yearSheetHeight,
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
                    fontSize: metrics.yearItemTextSize,
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
    final metrics = _CalendarMetrics.fromContext(context);

    return Container(
      color: const Color(0xFFF5F7FA),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
            .map(
              (d) => SizedBox(
                width: metrics.weekdayCellWidth,
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: metrics.weekdayTextSize,
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
    final metrics = _CalendarMetrics.fromContext(context);
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: metrics.dayMainSpacing,
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
                width: metrics.dayCellSize,
                height: metrics.dayCellSize,
                decoration: isSelected
                    ? BoxDecoration(
                        color: const Color(0xFFf87b0d),
                        borderRadius: BorderRadius.circular(metrics.dayRadius),
                      )
                    : null,
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: metrics.dayTextSize,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: metrics.todayDotGap),
              isToday
                  ? Container(
                      width: metrics.todayDotSize,
                      height: metrics.todayDotSize,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : SizedBox(height: metrics.todayDotSize),
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
