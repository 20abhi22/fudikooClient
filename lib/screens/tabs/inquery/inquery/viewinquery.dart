import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
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

  double _filterDropdownWidth(String label) {
    final textWidth = (label.length * 7.5).w;
    return (textWidth + 76.w).clamp(120.w, 210.w).toDouble();
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
            final activeDate = selectingStart ? tempStart : tempEnd;

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
                    AppText(
                      text: "Select Date Range",
                      size: 16,
                      fontWeight: FontWeight.w600,
                      color: appTextColor3,
                    ),
                    SizedBox(height: 14.h),
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
                        SizedBox(width: 10.w),
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
                    SizedBox(height: 14.h),
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
                            onPressed: () => Navigator.pop(
                              dialogContext,
                              DateTimeRange(start: tempStart, end: tempEnd),
                            ),
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

  Widget _rangeDateButton({
    required String label,
    required DateTime date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFf87b0d) : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? const Color(0xFFf87b0d) : Colors.black12,
          ),
        ),
        child: Column(
          children: [
            AppText(
              text: label,
              size: 11,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor2,
              isCentered: true,
            ),
            SizedBox(height: 3.h),
            AppText(
              text: DateFormat('MMM d, yyyy').format(date),
              size: 12,
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
              ? (selectedFilter == "Custom Range" &&
                        _customStart != null &&
                        _customEnd != null
                    ? "${DateFormat('MMM d').format(_customStart!)} – ${DateFormat('MMM d, yyyy').format(_customEnd!)}"
                    : "Custom Range")
              : label,
          size: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }

  void _openFilterSheet() {
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
    final filtered = _filteredList;

    return Column(
      children: [
        // ── Header ─────────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onEnquiryTap(false),
                child: Image.asset(backOrange, width: 30.w),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: _filterDropdownWidth(_filterLabel),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x1A000000),
                            offset: const Offset(0, 0),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: AppFilterDropDown(
                        height: 32.h,
                        hint: _filterLabel,
                        imageIconPath: filterIcon, // ← same as Reservation
                        imageIconSize: 15.sp,
                        toggleDropdown: _openFilterSheet,
                      ),
                    ),
                  ),
                ),
              ),
              // Balance spacer so dropdown stays centred
              SizedBox(width: 28.w),
            ],
          ),
        ),
        SizedBox(height: 20.h),

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
                              size: 48.w,
                              color: appTextColor3.withOpacity(0.4),
                            ),
                            SizedBox(height: 12.h),
                            AppText(
                              text: _error!,
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor3,
                              isCentered: true,
                            ),
                            SizedBox(height: 16.h),
                            GestureDetector(
                              onTap: _fetchList,
                              child: AppText(
                                text: "Retry",
                                size: 14,
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
                              size: 48.w,
                              color: appTextColor3.withOpacity(0.4),
                            ),
                            SizedBox(height: 12.h),
                            AppText(
                              text: selectedFilter == "All"
                                  ? "No enquiries found"
                                  : "No enquiries for $_filterLabel",
                              size: 15,
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
                    padding: EdgeInsets.only(bottom: 24.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return Padding(
                        padding: EdgeInsets.only(left: 30.w, right: 30.w),
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
