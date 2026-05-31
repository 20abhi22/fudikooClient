import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CtInquery extends StatefulWidget {
  final Function(Map<String, String> data) onReviewTap;
  final VoidCallback viewEnquiryOnTap;
  final int resetCounter; // ← increment from parent to clear all fields

  const CtInquery({
    super.key,
    required this.onReviewTap,
    required this.viewEnquiryOnTap,
    this.resetCounter = 0,
  });

  @override
  State<CtInquery> createState() => _CtInqueryState();
}

class _CtInqueryState extends State<CtInquery> {
  // ── state ────────────────────────────────────────────
  bool isLoading = false;

  // ── controllers ──────────────────────────────────────
  final TextEditingController menuController = TextEditingController();
  final TextEditingController otherServicesController = TextEditingController();
  final TextEditingController peopleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  // ── date & time ──────────────────────────────────────
  DateTime? selectedDateTime;
  DateTime? expirationDate;
  TimeOfDay? expirationTime;

  // ── location ─────────────────────────────────────────
  String lat = '';
  String lng = '';
  String searchRadius = '20';
  String locationLabel = 'Select Location';

  @override
  void didUpdateWidget(CtInquery oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When parent increments resetCounter, clear everything
    if (widget.resetCounter != oldWidget.resetCounter) {
      _clearFields();
    }
  }

  void _clearFields() {
    menuController.clear();
    otherServicesController.clear();
    peopleController.clear();
    amountController.clear();
    setState(() {
      selectedDateTime = null;
      expirationDate = null;
      expirationTime = null;
      lat = '';
      lng = '';
      searchRadius = '20';
      locationLabel = 'Select Location';
    });
  }

  @override
  void dispose() {
    menuController.dispose();
    otherServicesController.dispose();
    peopleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────
  String _formatDate(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return "$h:${minute.toString().padLeft(2, '0')} $period";
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── validation + submit ──────────────────────────────
  Future<void> _submitEnquiry() async {
    if (menuController.text.isEmpty) {
      _showSnack('Menu is empty');
      return;
    }
    if (peopleController.text.isEmpty) {
      _showSnack('Number of people is empty');
      return;
    }
    if (amountController.text.isEmpty) {
      _showSnack('Expected amount is empty');
      return;
    }
    if (selectedDateTime == null) {
      _showSnack('Date & Time not selected');
      return;
    }
    if (expirationDate == null || expirationTime == null) {
      _showSnack('Expiration date/time not selected');
      return;
    }
    if (lat.isEmpty) {
      _showSnack('Location not selected');
      return;
    }

    final expirationDateTime = DateTime(
      expirationDate!.year,
      expirationDate!.month,
      expirationDate!.day,
      expirationTime!.hour,
      expirationTime!.minute,
    );

    if (!expirationDateTime.isBefore(selectedDateTime!)) {
      _showSnack('Enquiry expiry must be before the event date & time');
      return;
    }

    if (expirationDateTime.isBefore(DateTime.now())) {
      _showSnack('Enquiry expiry cannot be in the past');
      return;
    }

    widget.onReviewTap({
      'menu': menuController.text,
      'otherServices': otherServicesController.text,
      'people': peopleController.text,
      'dateTime':
          "${_formatDate(selectedDateTime!)} ${_formatTime(selectedDateTime!.hour, selectedDateTime!.minute)}",
      'amount': amountController.text,
      'location': locationLabel,
      'lat': lat,
      'lng': lng,
      'searchRadius': searchRadius,
      'expirationDate': _formatDate(expirationDate!),
      'expirationTime': _formatTime(
        expirationTime!.hour,
        expirationTime!.minute,
      ),
    });
  }

  // ── Event date & time picker ─────────────────────────
  Future<void> _selectDateTime(BuildContext context) async {
    DateTime tempDate = selectedDateTime ?? DateTime.now();
    TimeOfDay tempTime = selectedDateTime != null
        ? TimeOfDay(hour: selectedDateTime!.hour, minute: selectedDateTime!.minute)
        : TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCustomCalendar(
                      tempDate: tempDate,
                      onDateChanged: (date) => setDialogState(() => tempDate = date),
                    ),
                    SizedBox(height: 12.h),
                    _buildTimeRow(
                      tempTime: tempTime,
                      setDialogState: setDialogState,
                      onTimeChanged: (t) => tempTime = t,
                      highlightPm: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildDialogActions(
                      onApply: () {
                        setState(() {
                          selectedDateTime = DateTime(
                            tempDate.year, tempDate.month, tempDate.day,
                            tempTime.hour, tempTime.minute,
                          );
                        });
                        Navigator.pop(context);
                      },
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

  // ── Expiration date & time picker ────────────────────
  Future<void> _selectExpirationDateTime(BuildContext context) async {
    DateTime tempDate = expirationDate ?? DateTime.now();
    TimeOfDay tempTime = expirationTime ?? TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCustomCalendar(
                      tempDate: tempDate,
                      onDateChanged: (date) => setDialogState(() => tempDate = date),
                    ),
                    SizedBox(height: 12.h),
                    _buildTimeRow(
                      tempTime: tempTime,
                      setDialogState: setDialogState,
                      onTimeChanged: (t) => tempTime = t,
                      highlightPm: false,
                    ),
                    SizedBox(height: 16.h),
                    _buildDialogActions(
                      onApply: () {
                        setState(() {
                          expirationDate = DateTime(tempDate.year, tempDate.month, tempDate.day);
                          expirationTime = tempTime;
                        });
                        Navigator.pop(context);
                      },
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

  // ── Shared time row ──────────────────────────────────
  Widget _buildTimeRow({
    required TimeOfDay tempTime,
    required StateSetter setDialogState,
    required void Function(TimeOfDay) onTimeChanged,
    required bool highlightPm,
  }) {
    return Container(
      padding: EdgeInsets.only(left: 5.r),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _timeScroller(
            value: tempTime.hour % 12 == 0 ? 12 : tempTime.hour % 12,
            min: 1,
            max: 12,
            onChanged: (val) {
              setDialogState(() {
                final isPm = tempTime.period == DayPeriod.pm;
                final updated = TimeOfDay(
                  hour: isPm ? (val % 12) + 12 : val % 12,
                  minute: tempTime.minute,
                );
                onTimeChanged(updated);
              });
            },
          ),
          Text(' : ', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          _timeScroller(
            value: tempTime.minute,
            min: 0,
            max: 59,
            onChanged: (val) {
              setDialogState(() {
                final updated = TimeOfDay(hour: tempTime.hour, minute: val);
                onTimeChanged(updated);
              });
            },
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: () {
              setDialogState(() {
                final newHour = tempTime.period == DayPeriod.am
                    ? tempTime.hour + 12
                    : tempTime.hour - 12;
                onTimeChanged(TimeOfDay(hour: newHour, minute: tempTime.minute));
              });
            },
            child: Container(
              width: 38.w,
              height: 30.h,
              decoration: BoxDecoration(
                color: (highlightPm
                        ? tempTime.period == DayPeriod.pm
                        : tempTime.period == DayPeriod.am)
                    ? const Color(0xFFD9D9D9)
                    : Colors.transparent,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10.r),
                  bottomRight: Radius.circular(10.r),
                ),
              ),
              child: Center(
                child: Text(
                  tempTime.period == DayPeriod.am ? 'AM' : 'PM',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared dialog Cancel/Apply row ───────────────────
  Widget _buildDialogActions({required VoidCallback onApply}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black54, fontSize: 14.sp)),
          ),
          TextButton(
            onPressed: onApply,
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
    );
  }

  // ── Scroll-wheel time helper ─────────────────────────
  Widget _timeScroller({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final controller = FixedExtentScrollController(initialItem: value - min);
    return SizedBox(
      width: 20.w,
      height: 30.h,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 32.h,
        perspective: 0.003,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => onChanged(index + min),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: max - min + 1,
          builder: (context, index) {
            final val = index + min;
            return Center(
              child: Text(
                val.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 35.w, vertical: 10.h),
      child: Column(
        children: [
          // ── view enquiries link ──
          GestureDetector(
            onTap: widget.viewEnquiryOnTap,
            child: Row(
              children: [
                Image.asset(
                  inqueryIcon,
                  fit: BoxFit.cover,
                  width: 18.w,
                  height: 18.w,
                  color: appLinkColor3.withOpacity(.9),
                ),
                SizedBox(width: 5.w),
                AppText(
                  text: "View Enquiries",
                  size: 15,
                  fontWeight: FontWeight.w400,
                  color: appLinkColor3.withOpacity(.9),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // ── menu ──
          DescriptionTextArea(
            hintText:
                "Example: Chicken Biriyani , Porotta ,Rotti  , Payasam, Butter Chicken , Ice cream, Salad",
            topHintText: "Your Menu",
            iconColor: appTextColor2,
            imageIconPath: menuIcon,
            maxLength: 300,
            controller: menuController,
          ),
          SizedBox(height: 20.h),

          // ── other services ──
          DescriptionTextArea(
            hintText: "Example: 10 Service Boys needed",
            topHintText: "Other Services",
            iconColor: appTextColor2,
            imageIconPath: handshakeIcon,
            maxLength: 100,
            controller: otherServicesController,
            height: 100.h,
          ),
          SizedBox(height: 20.h),

          // ── people ──
          AppTextFeild(
            text: "Number of People",
            iconImagePath: peopleIcon,
            sideIconSlotWidth: 17.w,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
            iconImagecolor: appTextColor2,
            controller: peopleController,
          ),
          SizedBox(height: 20.h),

          // ── date & time ──
          GestureDetector(
            onTap: () => _selectDateTime(context),
            child: AppTextFeild(
              text: selectedDateTime != null ? _formatDate(selectedDateTime!) : "Date",
              secondText: selectedDateTime != null
                  ? _formatTime(selectedDateTime!.hour, selectedDateTime!.minute)
                  : "Time",
              iconImagePath: calenderIcon,
              secondIconImagePath: timeIcon,
              iconImagecolor: appTextColor2,
              secondIconImageColor: appTextColor2,
              isDateTimeField: true,
              height: 55.h,
              fieldBorderRadius: 10.r,
              backgroundColor: const Color(0xFFFFFFFF),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  offset: const Offset(0, 0),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
              textColor: Colors.grey,
              size: 12.sp,
              isreadonly: true,
            ),
          ),
          SizedBox(height: 20.h),

          // ── expected amount ──
          AppTextFeild(
            text: "Expected amount per person",
            iconImagePath: walletIcon,
            sideIconSlotWidth: 17.w,
            iconImagecolor: appTextColor2,
            controller: amountController,
          ),
          SizedBox(height: 20.h),

          // ── location ──
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationSelect(
                  returndata: (newLat, newLng, distance) async {
                    setState(() {
                      lat = newLat.toString();
                      lng = newLng.toString();
                      searchRadius = distance.toString();
                      locationLabel = 'Locating...';
                    });
                    try {
                      final placemarks = await placemarkFromCoordinates(
                        double.parse(newLat.toString()),
                        double.parse(newLng.toString()),
                      );
                      String name = '';
                      if (placemarks.isNotEmpty) {
                        final p = placemarks.first;
                        name = [p.subLocality, p.locality]
                            .where((s) => s != null && s.isNotEmpty)
                            .join(', ');
                        if (name.isEmpty) name = p.country ?? '';
                      }
                      setState(() {
                        locationLabel = name.isNotEmpty
                            ? '$name - ${distance}km Radius'
                            : '$newLat, $newLng - ${distance}km Radius';
                      });
                    } catch (_) {
                      setState(() {
                        locationLabel = '$newLat, $newLng - ${distance}km Radius';
                      });
                    }
                  },
                ),
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 75.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: const Color(0xFF798FFF),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4.w),
                  ),
                ],
              ),
              child: Center(
                child: AppText(
                  text: locationLabel,
                  size: 15.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 40.h),

          // ── enquiry valid for ──
          Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: appSecondaryBackgroundColor,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: Colors.black54),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _IconTextButton(
                          imageIcon: calenderIcon,
                          label: expirationDate != null ? _formatDate(expirationDate!) : 'Date',
                          onTap: () => _selectExpirationDateTime(context),
                        ),
                        _IconTextButton(
                          imageIcon: timeIcon,
                          label: expirationTime != null
                              ? _formatTime(expirationTime!.hour, expirationTime!.minute)
                              : 'Time',
                          onTap: () => _selectExpirationDateTime(context),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -10.h,
                  left: 25.w,
                  child: Container(
                    color: appSecondaryBackgroundColor,
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      'Enquiry valid for',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30.h),

          // ── review button ──
          SizedBox(
            width: 150.w,
            height: 50.h,
            child: AppButton(
              text: isLoading ? "Submitting..." : "Review",
              onPressed: isLoading ? () {} : _submitEnquiry,
              size: 15,
              borderRadius: 10,
              bgColor1: Colors.green,
              bgColor2: Colors.green,
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}

// ── shared helper widget ─────────────────────────────────────────────────────
class _IconTextButton extends StatelessWidget {
  final String imageIcon;
  final String label;
  final VoidCallback onTap;

  const _IconTextButton({
    required this.imageIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Row(
        children: [
          Image.asset(imageIcon, width: 20.w, height: 20.h, color: appTextColor2),
          SizedBox(width: 8.w),
          AppText(
            text: label,
            size: 14,
            color: appTextColor2.withOpacity(.8),
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

// ── Custom calendar ──────────────────────────────────────────────────────────
Widget _buildCustomCalendar({
  required DateTime tempDate,
  required void Function(DateTime) onDateChanged,
}) {
  return _CustomCalendar(selectedDate: tempDate, onDateChanged: onDateChanged);
}

class _CustomCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateChanged;

  const _CustomCalendar({required this.selectedDate, required this.onDateChanged});

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
    _displayMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _pickerYear = _displayMonth.year;
  }

  void _prevMonth() => setState(
      () => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1));

  void _nextMonth() => setState(
      () => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1));

  void _togglePicker() => setState(() {
        _showMonthYearPicker = !_showMonthYearPicker;
        _pickerYear = _displayMonth.year;
      });

  void _selectMonthYear(int month, int year) => setState(() {
        _displayMonth = DateTime(year, month);
        _showMonthYearPicker = false;
      });

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
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    _showMonthYearPicker ? Icons.arrow_drop_up : Icons.arrow_drop_down,
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
            IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: () => setState(() => _pickerYear--)),
            GestureDetector(
              onTap: () => _showYearScrollPicker(context),
              child: Text(
                '$_pickerYear',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFFf87b0d)),
              ),
            ),
            IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: () => setState(() => _pickerYear++)),
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
            final isSelected = month == _displayMonth.month && _pickerYear == _displayMonth.year;
            final isPast = DateTime(_pickerYear, month).isBefore(
              DateTime(DateTime.now().year, DateTime.now().month),
            );
            return GestureDetector(
              onTap: isPast ? null : () => _selectMonthYear(month, _pickerYear),
              child: Container(
                height: 50.h,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFE943A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: isSelected ? const Color(0xFFFE943A) : Colors.black12),
                ),
                child: Center(
                  child: Text(
                    _shortMonth(month),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : isPast ? Colors.black26 : Colors.black87,
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
    final currentYear = DateTime.now().year;
    final years = List.generate(20, (i) => currentYear + i);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
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
                    color: isSelected ? const Color(0xFFf87b0d) : Colors.black87,
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
            .map((d) => SizedBox(
                  width: 36.w,
                  child: Center(
                    child: Text(d,
                        style: TextStyle(fontSize: 12.sp, color: Colors.black54, fontWeight: FontWeight.w500)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDayGrid(DateTime today) {
    final daysInMonth = DateUtils.getDaysInMonth(_displayMonth.year, _displayMonth.month);
    final firstWeekday = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday % 7;

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
        final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

        return GestureDetector(
          onTap: isPast ? null : () => widget.onDateChanged(date),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: isSelected
                    ? BoxDecoration(color: const Color(0xFFf87b0d), borderRadius: BorderRadius.circular(10.r))
                    : null,
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : isPast ? Colors.black26 : Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              isToday
                  ? Container(
                      width: 5.w,
                      height: 5.w,
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    )
                  : SizedBox(height: 5.w),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int month) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][month - 1];

  String _shortMonth(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];
}