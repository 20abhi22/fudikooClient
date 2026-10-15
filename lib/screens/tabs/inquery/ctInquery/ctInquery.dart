import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/utils/snackbar.dart';

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
    showErrorSnack(context, msg);
  }

  // ── validation + submit ──────────────────────────────
  Future<void> _submitEnquiry() async {
    FocusScope.of(context).unfocus();

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
    final metrics = _CtInqueryMetrics.fromContext(context);
    DateTime tempDate = selectedDateTime ?? DateTime.now();
    TimeOfDay tempTime = selectedDateTime != null
        ? TimeOfDay(
            hour: selectedDateTime!.hour,
            minute: selectedDateTime!.minute,
          )
        : TimeOfDay.now();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dialogWidth = _dateDialogWidth(context, metrics);

            return PopScope(
              canPop: true,
              child: Dialog(
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
                      _buildCustomCalendar(
                        tempDate: tempDate,
                        onDateChanged: (date) =>
                            setDialogState(() => tempDate = date),
                      ),
                      SizedBox(height: metrics.dialogGap),
                      _buildTimeRow(
                        tempTime: tempTime,
                        setDialogState: setDialogState,
                        onTimeChanged: (t) => tempTime = t,
                        highlightPm: true,
                      ),
                      SizedBox(height: metrics.dialogGap),
                      _buildDialogActions(
                        onApply: () {
                          setState(() {
                            selectedDateTime = DateTime(
                              tempDate.year,
                              tempDate.month,
                              tempDate.day,
                              tempTime.hour,
                              tempTime.minute,
                            );
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
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
    final metrics = _CtInqueryMetrics.fromContext(context);
    DateTime tempDate = expirationDate ?? DateTime.now();
    TimeOfDay tempTime = expirationTime ?? TimeOfDay.now();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dialogWidth = _dateDialogWidth(context, metrics);

            return PopScope(
              canPop: true,
              child: Dialog(
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
                      _buildCustomCalendar(
                        tempDate: tempDate,
                        onDateChanged: (date) =>
                            setDialogState(() => tempDate = date),
                      ),
                      SizedBox(height: metrics.dialogGap),
                      _buildTimeRow(
                        tempTime: tempTime,
                        setDialogState: setDialogState,
                        onTimeChanged: (t) => tempTime = t,
                        highlightPm: false,
                      ),
                      SizedBox(height: metrics.dialogGap),
                      _buildDialogActions(
                        onApply: () {
                          setState(() {
                            expirationDate = DateTime(
                              tempDate.year,
                              tempDate.month,
                              tempDate.day,
                            );
                            expirationTime = tempTime;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
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
    final metrics = _CtInqueryMetrics.fromContext(context);

    return Container(
      padding: EdgeInsets.only(left: metrics.timePickerPaddingLeft),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(metrics.timePickerRadius),
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
          Text(
            ' : ',
            style: TextStyle(
              fontSize: metrics.timeColonSize,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          SizedBox(width: metrics.iconTextGap),
          GestureDetector(
            onTap: () {
              setDialogState(() {
                final newHour = tempTime.period == DayPeriod.am
                    ? tempTime.hour + 12
                    : tempTime.hour - 12;
                onTimeChanged(
                  TimeOfDay(hour: newHour, minute: tempTime.minute),
                );
              });
            },
            child: Container(
              width: metrics.timeAmPmWidth,
              height: metrics.timeAmPmHeight,
              decoration: BoxDecoration(
                color:
                    (highlightPm
                        ? tempTime.period == DayPeriod.pm
                        : tempTime.period == DayPeriod.am)
                    ? const Color(0xFFD9D9D9)
                    : Colors.transparent,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(metrics.timePickerRadius),
                  bottomRight: Radius.circular(metrics.timePickerRadius),
                ),
              ),
              child: Center(
                child: Text(
                  tempTime.period == DayPeriod.am ? 'AM' : 'PM',
                  style: TextStyle(
                    fontSize: metrics.timeAmPmTextSize,
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
    final metrics = _CtInqueryMetrics.fromContext(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black54,
                fontSize: metrics.iconTextSize,
              ),
            ),
          ),
          TextButton(
            onPressed: onApply,
            child: Text(
              'Apply',
              style: TextStyle(
                color: const Color(0xFF3954DB),
                fontSize: metrics.iconTextSize,
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
    final metrics = _CtInqueryMetrics.fromContext(context);
    final controller = FixedExtentScrollController(initialItem: value - min);
    return SizedBox(
      width: metrics.timeScrollerWidth,
      height: metrics.timeScrollerHeight,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: metrics.timeScrollerItemExtent,
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
                  fontSize: metrics.timeScrollerTextSize,
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

  double _dateDialogWidth(BuildContext context, _CtInqueryMetrics metrics) {
    final calendarWidth = _CalendarMetrics.fromContext(context).calendarWidth;
    return calendarWidth + (metrics.dialogPaddingHorizontal * 2);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _CtInqueryMetrics.fromContext(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: metrics.verticalPadding,
      ),
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
                  width: metrics.linkIconSize,
                  height: metrics.linkIconSize,
                  color: appLinkColor3.withValues(alpha: .9),
                ),
                SizedBox(width: metrics.linkGap),
                AppText(
                  text: "View Enquiries",
                  size: metrics.linkTextSize,
                  fontWeight: FontWeight.w400,
                  color: appLinkColor3.withValues(alpha: .9),
                ),
              ],
            ),
          ),
          SizedBox(height: metrics.fieldGap),

          // ── menu ──
          DescriptionTextArea(
            hintText:
                "Example: Chicken Biriyani , Porotta ,Rotti  , Payasam, Butter Chicken , Ice cream, Salad",
            topHintText: "Your Menu",
            iconColor: Color.fromARGB(255, 15, 15, 15),
            imageIconPath: menuIcon,
            height: metrics.menuHeight,
            maxLength: 300,
            controller: menuController,
          ),
          SizedBox(height: metrics.fieldGap),

          // ── other services ──
          DescriptionTextArea(
            hintText: "Example: 10 Service Boys needed",
            topHintText: "Other Services",
            iconColor: Color.fromARGB(255, 15, 15, 15),
            imageIconPath: handshakeIcon,
            maxLength: 100,
            controller: otherServicesController,
            height: metrics.otherServicesHeight,
          ),
          SizedBox(height: metrics.fieldGap),

          // ── people ──
          AppTextFeild(
            text: "Number of People",
            iconImagePath: peopleIcon,
            sideIconSlotWidth: metrics.sideIconSlotWidth,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
            iconImagecolor: Color.fromARGB(255, 15, 15, 15),
            controller: peopleController,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: metrics.fieldGap),

          // ── date & time ──
          GestureDetector(
            onTap: () => _selectDateTime(context),
            child: AppTextFeild(
              text: selectedDateTime != null
                  ? _formatDate(selectedDateTime!)
                  : "Date",
              secondText: selectedDateTime != null
                  ? _formatTime(
                      selectedDateTime!.hour,
                      selectedDateTime!.minute,
                    )
                  : "Time",
              iconImagePath: calenderIcon,
              secondIconImagePath: timeIcon,
              iconImagecolor: Color.fromARGB(255, 15, 15, 15),
              secondIconImageColor: Color.fromARGB(255, 15, 15, 15),
              sideIconSlotWidth: metrics.dateTimeIconSize,
              isDateTimeField: true,
              height: metrics.dateFieldHeight,
              fieldBorderRadius: metrics.dateFieldRadius,
              backgroundColor: const Color(0xFFFFFFFF),
              padding: EdgeInsets.symmetric(
                horizontal: metrics.dateFieldHorizontalPadding,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  offset: const Offset(0, 0),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
              textColor: Colors.grey,
              size: metrics.dateFieldTextSize,
              isreadonly: true,
            ),
          ),
          SizedBox(height: metrics.fieldGap),

          // ── expected amount ──
          AppTextFeild(
            text: "Expected amount per person",
            iconImagePath: walletIcon,
            sideIconSlotWidth: metrics.sideIconSlotWidth,
            iconImagecolor: Color.fromARGB(255, 15, 15, 15),
            controller: amountController,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: metrics.fieldGap),

          // ── location ──
          GestureDetector(
            onTap: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              // Root navigator, not the tab's nested one: the tab shell's
              // Scaffold resizes its body for the keyboard, and anything
              // pushed inside it is laid out in that shortened box — which
              // drags the picker's bottom-pinned radius panel up with the
              // keyboard however the picker's own Scaffold is configured.
              await Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => LocationSelect(
                    initialLat: double.tryParse(lat),
                    initialLng: double.tryParse(lng),
                    initialDistance: double.tryParse(searchRadius),
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
                          name = [
                            p.subLocality,
                            p.locality,
                          ].where((s) => s != null && s.isNotEmpty).join(', ');
                          if (name.isEmpty) name = p.country ?? '';
                        }
                        setState(() {
                          locationLabel = name.isNotEmpty
                              ? '$name - ${distance}km Radius'
                              : '$newLat, $newLng - ${distance}km Radius';
                        });
                      } catch (_) {
                        setState(() {
                          locationLabel =
                              '$newLat, $newLng - ${distance}km Radius';
                        });
                      }
                    },
                  ),
                ),
              );

              if (!mounted) return;
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              padding: EdgeInsets.symmetric(
                horizontal: metrics.locationHorizontalPadding,
                vertical: metrics.locationVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF798FFF),
                borderRadius: BorderRadius.circular(metrics.locationRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: AppText(
                  text: locationLabel,
                  size: metrics.locationTextSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  isCentered: true,
                  maxLines: null,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ),
          SizedBox(height: metrics.locationTopGap),

          // ── enquiry valid for ──
          Padding(
            padding: EdgeInsets.only(top: metrics.expiryOuterTopPadding),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.expiryHorizontalPadding,
                    vertical: metrics.expiryVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: appSecondaryBackgroundColor,
                    borderRadius: BorderRadius.circular(metrics.expiryRadius),
                    border: Border.all(color: Colors.black54),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.expiryInnerHorizontalPadding,
                      vertical: metrics.expiryInnerVerticalPadding,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _IconTextButton(
                          imageIcon: calenderIcon,
                          label: expirationDate != null
                              ? _formatDate(expirationDate!)
                              : 'Date',
                          onTap: () => _selectExpirationDateTime(context),
                        ),
                        _IconTextButton(
                          imageIcon: timeIcon,
                          label: expirationTime != null
                              ? _formatTime(
                                  expirationTime!.hour,
                                  expirationTime!.minute,
                                )
                              : 'Time',
                          onTap: () => _selectExpirationDateTime(context),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: metrics.expiryLabelTop,
                  left: metrics.expiryLabelLeft,
                  child: Container(
                    color: appSecondaryBackgroundColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.expiryLabelHorizontalPadding,
                    ),
                    child: AppText(
                      text: 'Enquiry valid for',
                      size: metrics.expiryLabelSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: metrics.reviewTopGap),

          // ── review button ──
          SizedBox(
            width: metrics.reviewButtonWidth,
            height: metrics.reviewButtonHeight,
            child: AppButton(
              text: isLoading ? "Submitting..." : "Review",
              onPressed: isLoading ? () {} : _submitEnquiry,
              size: metrics.reviewButtonTextSize,
              borderRadius: metrics.reviewButtonRadius,
              bgColor1: Colors.green,
              bgColor2: Colors.green,
            ),
          ),
          SizedBox(height: metrics.bottomGap),
        ],
      ),
    );
  }
}

// ── shared helper widget ─────────────────────────────────────────────────────
class _CtInqueryMetrics {
  const _CtInqueryMetrics({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.linkIconSize,
    required this.linkGap,
    required this.linkTextSize,
    required this.fieldGap,
    required this.menuHeight,
    required this.otherServicesHeight,
    required this.dateFieldHeight,
    required this.dateFieldRadius,
    required this.dateFieldHorizontalPadding,
    required this.dateFieldTextSize,
    required this.dateTimeIconSize,
    required this.sideIconSlotWidth,
    required this.locationHorizontalPadding,
    required this.locationVerticalPadding,
    required this.locationRadius,
    required this.locationTextSize,
    required this.locationTopGap,
    required this.expiryOuterTopPadding,
    required this.expiryHorizontalPadding,
    required this.expiryVerticalPadding,
    required this.expiryInnerHorizontalPadding,
    required this.expiryInnerVerticalPadding,
    required this.expiryRadius,
    required this.expiryLabelTop,
    required this.expiryLabelLeft,
    required this.expiryLabelHorizontalPadding,
    required this.expiryLabelSize,
    required this.reviewTopGap,
    required this.reviewButtonWidth,
    required this.reviewButtonHeight,
    required this.reviewButtonTextSize,
    required this.reviewButtonRadius,
    required this.bottomGap,
    required this.iconTextIconSize,
    required this.iconTextGap,
    required this.iconTextSize,
    required this.dialogPaddingHorizontal,
    required this.dialogPaddingVertical,
    required this.dialogRadius,
    required this.dialogGap,
    required this.timePickerPaddingLeft,
    required this.timePickerRadius,
    required this.timeColonSize,
    required this.timeAmPmWidth,
    required this.timeAmPmHeight,
    required this.timeAmPmTextSize,
    required this.timeScrollerWidth,
    required this.timeScrollerHeight,
    required this.timeScrollerItemExtent,
    required this.timeScrollerTextSize,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double linkIconSize;
  final double linkGap;
  final double linkTextSize;
  final double fieldGap;
  final double? menuHeight;
  final double? otherServicesHeight;
  final double dateFieldHeight;
  final double dateFieldRadius;
  final double dateFieldHorizontalPadding;
  final double dateFieldTextSize;
  final double dateTimeIconSize;
  final double sideIconSlotWidth;
  final double locationHorizontalPadding;
  final double locationVerticalPadding;
  final double locationRadius;
  final double locationTextSize;
  final double locationTopGap;
  final double expiryOuterTopPadding;
  final double expiryHorizontalPadding;
  final double expiryVerticalPadding;
  final double expiryInnerHorizontalPadding;
  final double expiryInnerVerticalPadding;
  final double expiryRadius;
  final double expiryLabelTop;
  final double expiryLabelLeft;
  final double expiryLabelHorizontalPadding;
  final double expiryLabelSize;
  final double reviewTopGap;
  final double reviewButtonWidth;
  final double reviewButtonHeight;
  final double reviewButtonTextSize;
  final double reviewButtonRadius;
  final double bottomGap;
  final double iconTextIconSize;
  final double iconTextGap;
  final double iconTextSize;
  final double dialogPaddingHorizontal;
  final double dialogPaddingVertical;
  final double dialogRadius;
  final double dialogGap;
  final double timePickerPaddingLeft;
  final double timePickerRadius;
  final double timeColonSize;
  final double timeAmPmWidth;
  final double timeAmPmHeight;
  final double timeAmPmTextSize;
  final double timeScrollerWidth;
  final double timeScrollerHeight;
  final double timeScrollerItemExtent;
  final double timeScrollerTextSize;

  factory _CtInqueryMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final verticalScale = (size.height / 1024).clamp(1.0, 1.28).toDouble();
      double v(double value) => value * verticalScale;

      return _CtInqueryMetrics(
        horizontalPadding: 48,
        verticalPadding: v(12),
        linkIconSize: 24,
        linkGap: 8,
        linkTextSize: 15,
        fieldGap: v(26),
        menuHeight: (size.height * 0.13).clamp(145.0, 200.0).toDouble(),
        otherServicesHeight: (size.height * 0.1).clamp(110.0, 150.0).toDouble(),
        dateFieldHeight: v(58),
        dateFieldRadius: 10,
        dateFieldHorizontalPadding: 24,
        dateFieldTextSize: 13,
        dateTimeIconSize: 13,
        sideIconSlotWidth: 20,
        locationHorizontalPadding: 22,
        locationVerticalPadding: v(12),
        locationRadius: 10,
        locationTextSize: 22,
        locationTopGap: v(44),
        expiryOuterTopPadding: v(12),
        expiryHorizontalPadding: 18,
        expiryVerticalPadding: v(13),
        expiryInnerHorizontalPadding: 22,
        expiryInnerVerticalPadding: v(5),
        expiryRadius: 15,
        expiryLabelTop: -10,
        expiryLabelLeft: 32,
        expiryLabelHorizontalPadding: 5,
        expiryLabelSize: 18,
        reviewTopGap: v(38),
        reviewButtonWidth: 220,
        reviewButtonHeight: v(56),
        reviewButtonTextSize: 15,
        reviewButtonRadius: 10,
        bottomGap: v(76),
        iconTextIconSize: 22,
        iconTextGap: 9,
        iconTextSize: 14,
        dialogPaddingHorizontal: 16,
        dialogPaddingVertical: 16,
        dialogRadius: 10,
        dialogGap: 14,
        timePickerPaddingLeft: 6,
        timePickerRadius: 10,
        timeColonSize: 18,
        timeAmPmWidth: 42,
        timeAmPmHeight: 32,
        timeAmPmTextSize: 13,
        timeScrollerWidth: 34,
        timeScrollerHeight: 32,
        timeScrollerItemExtent: 34,
        timeScrollerTextSize: 16,
      );
    }

    if (isWideShortPhone) {
      return const _CtInqueryMetrics(
        horizontalPadding: 28,
        verticalPadding: 8,
        linkIconSize: 18,
        linkGap: 5,
        linkTextSize: 13,
        fieldGap: 16,
        menuHeight: null,
        otherServicesHeight: 90,
        dateFieldHeight: 48,
        dateFieldRadius: 10,
        dateFieldHorizontalPadding: 18,
        dateFieldTextSize: 11.5,
        dateTimeIconSize: 15,
        sideIconSlotWidth: 16,
        locationHorizontalPadding: 18,
        locationVerticalPadding: 9,
        locationRadius: 10,
        locationTextSize: 17,
        locationTopGap: 28,
        expiryOuterTopPadding: 8,
        expiryHorizontalPadding: 14,
        expiryVerticalPadding: 10,
        expiryInnerHorizontalPadding: 14,
        expiryInnerVerticalPadding: 3,
        expiryRadius: 14,
        expiryLabelTop: -9,
        expiryLabelLeft: 24,
        expiryLabelHorizontalPadding: 4,
        expiryLabelSize: 14,
        reviewTopGap: 22,
        reviewButtonWidth: 190,
        reviewButtonHeight: 44,
        reviewButtonTextSize: 13,
        reviewButtonRadius: 10,
        bottomGap: 22,
        iconTextIconSize: 18,
        iconTextGap: 7,
        iconTextSize: 12.5,
        dialogPaddingHorizontal: 14,
        dialogPaddingVertical: 14,
        dialogRadius: 10,
        dialogGap: 11,
        timePickerPaddingLeft: 5,
        timePickerRadius: 10,
        timeColonSize: 17,
        timeAmPmWidth: 36,
        timeAmPmHeight: 28,
        timeAmPmTextSize: 12,
        timeScrollerWidth: 28,
        timeScrollerHeight: 28,
        timeScrollerItemExtent: 30,
        timeScrollerTextSize: 14,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _CtInqueryMetrics(
        horizontalPadding: s(22),
        verticalPadding: s(8),
        linkIconSize: s(17),
        linkGap: s(5),
        linkTextSize: s(12.5),
        fieldGap: s(15),
        menuHeight: null,
        otherServicesHeight: s(86),
        dateFieldHeight: s(46),
        dateFieldRadius: s(10),
        dateFieldHorizontalPadding: s(16),
        dateFieldTextSize: s(11.5),
        dateTimeIconSize: s(12),
        sideIconSlotWidth: s(16),
        locationHorizontalPadding: s(16),
        locationVerticalPadding: s(8),
        locationRadius: s(10),
        locationTextSize: s(15),
        locationTopGap: s(26),
        expiryOuterTopPadding: s(8),
        expiryHorizontalPadding: s(12),
        expiryVerticalPadding: s(10),
        expiryInnerHorizontalPadding: s(10),
        expiryInnerVerticalPadding: s(3),
        expiryRadius: s(14),
        expiryLabelTop: s(-9),
        expiryLabelLeft: s(20),
        expiryLabelHorizontalPadding: s(4),
        expiryLabelSize: s(12.5),
        reviewTopGap: s(22),
        reviewButtonWidth: s(160),
        reviewButtonHeight: s(44),
        reviewButtonTextSize: s(13),
        reviewButtonRadius: s(10),
        bottomGap: s(22),
        iconTextIconSize: s(17),
        iconTextGap: s(6),
        iconTextSize: s(12),
        dialogPaddingHorizontal: s(12),
        dialogPaddingVertical: s(12),
        dialogRadius: s(10),
        dialogGap: s(10),
        timePickerPaddingLeft: s(5),
        timePickerRadius: s(10),
        timeColonSize: s(16),
        timeAmPmWidth: s(34),
        timeAmPmHeight: s(27),
        timeAmPmTextSize: s(11.5),
        timeScrollerWidth: s(27),
        timeScrollerHeight: s(27),
        timeScrollerItemExtent: s(29),
        timeScrollerTextSize: s(13.5),
      );
    }

    return _CtInqueryMetrics(
      horizontalPadding: 35.w,
      verticalPadding: 10.h,
      linkIconSize: 18.w,
      linkGap: 5.w,
      linkTextSize: 15,
      fieldGap: 20.h,
      menuHeight: null,
      otherServicesHeight: 100.h,
      dateFieldHeight: 55.h,
      dateFieldRadius: 10.r,
      dateFieldHorizontalPadding: 20.w,
      dateFieldTextSize: 12.sp,
      dateTimeIconSize: 13.w,
      sideIconSlotWidth: 17.w,
      locationHorizontalPadding: 18.w,
      locationVerticalPadding: 9.h,
      locationRadius: 10.r,
      locationTextSize: 15.sp,
      locationTopGap: 40.h,
      expiryOuterTopPadding: 10.h,
      expiryHorizontalPadding: 16.w,
      expiryVerticalPadding: 12.h,
      expiryInnerHorizontalPadding: 15,
      expiryInnerVerticalPadding: 4,
      expiryRadius: 15.r,
      expiryLabelTop: -10.h,
      expiryLabelLeft: 25.w,
      expiryLabelHorizontalPadding: 4.w,
      expiryLabelSize: 12.sp,
      reviewTopGap: 30.h,
      reviewButtonWidth: 150.w,
      reviewButtonHeight: 50.h,
      reviewButtonTextSize: 15,
      reviewButtonRadius: 10,
      bottomGap: 30.h,
      iconTextIconSize: 20.w,
      iconTextGap: 8.w,
      iconTextSize: 14,
      dialogPaddingHorizontal: 16.w,
      dialogPaddingVertical: 16.h,
      dialogRadius: 10.r,
      dialogGap: 12.h,
      timePickerPaddingLeft: 5.r,
      timePickerRadius: 10.r,
      timeColonSize: 18.sp,
      timeAmPmWidth: 38.w,
      timeAmPmHeight: 30.h,
      timeAmPmTextSize: 13.sp,
      timeScrollerWidth: 30.w,
      timeScrollerHeight: 30.h,
      timeScrollerItemExtent: 32.h,
      timeScrollerTextSize: 16.sp,
    );
  }
}

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
    final metrics = _CtInqueryMetrics.fromContext(context);

    return InkWell(
      borderRadius: BorderRadius.circular(metrics.expiryRadius),
      onTap: onTap,
      child: Row(
        children: [
          Image.asset(
            imageIcon,
            width: metrics.iconTextIconSize,
            height: metrics.iconTextIconSize,
            color: Color.fromARGB(255, 15, 15, 15),
          ),
          SizedBox(width: metrics.iconTextGap),
          AppText(
            text: label,
            size: metrics.iconTextSize,
            color: appTextColor2.withValues(alpha: .8),
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

// ── Custom calendar ──────────────────────────────────────────────────────────
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

  void _selectMonthYear(int month, int year) => setState(() {
    _displayMonth = DateTime(year, month);
    _showMonthYearPicker = false;
  });

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
            final isPast = DateTime(
              _pickerYear,
              month,
            ).isBefore(DateTime(DateTime.now().year, DateTime.now().month));
            return GestureDetector(
              onTap: isPast ? null : () => _selectMonthYear(month, _pickerYear),
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
                      color: isSelected
                          ? Colors.white
                          : isPast
                          ? Colors.black26
                          : Colors.black87,
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
    final currentYear = DateTime.now().year;
    final years = List.generate(20, (i) => currentYear + i);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: true,
      enableDrag: true,
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
        final isPast = date.isBefore(
          DateTime(today.year, today.month, today.day),
        );

        return GestureDetector(
          onTap: isPast ? null : () => widget.onDateChanged(date),
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
                      color: isSelected
                          ? Colors.white
                          : isPast
                          ? Colors.black26
                          : Colors.black87,
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
