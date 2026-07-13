import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
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

class BookingSuccessTick extends StatefulWidget {
  const BookingSuccessTick({
    super.key,
    this.size = 120,
    this.duration = const Duration(milliseconds: 1250),
    this.circleColor1 = const Color(0xFF42C97A),
    this.circleColor2 = const Color(0xFF00A878),
    this.checkColor = Colors.white,
  });

  final double size;
  final Duration duration;
  final Color circleColor1;
  final Color circleColor2;
  final Color checkColor;

  @override
  State<BookingSuccessTick> createState() => _BookingSuccessTickState();
}

class _BookingSuccessTickState extends State<BookingSuccessTick>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScale;
  late final Animation<double> _tickProgress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _circleScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.0,
              end: 1.08,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 55,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.08,
              end: 0.97,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 20,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 0.97,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 25,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.55),
          ),
        );

    _tickProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 1.0, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
  }

  void replay() {
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BookingSuccessTickPainter(
              circleScale: _circleScale.value,
              tickProgress: _tickProgress.value,
              circleColor1: widget.circleColor1,
              circleColor2: widget.circleColor2,
              checkColor: widget.checkColor,
            ),
          );
        },
      ),
    );
  }
}

class _BookingSuccessTickPainter extends CustomPainter {
  _BookingSuccessTickPainter({
    required this.circleScale,
    required this.tickProgress,
    required this.circleColor1,
    required this.circleColor2,
    required this.checkColor,
  });

  final double circleScale;
  final double tickProgress;
  final Color circleColor1;
  final Color circleColor2;
  final Color checkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.44;

    if (circleScale <= 0) return;

    final scaledRadius = radius * circleScale;
    final circleRect = Rect.fromCircle(center: center, radius: scaledRadius);
    final circlePath = Path()..addOval(circleRect);

    canvas.drawShadow(
      circlePath,
      Colors.black.withValues(alpha: 0.22),
      8,
      false,
    );

    final circlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [circleColor1, circleColor2],
      ).createShader(circleRect);

    canvas.drawPath(circlePath, circlePaint);
    if (tickProgress <= 0) return;

    canvas.save();

    // Clip everything inside circle
    canvas.clipPath(circlePath);

    // SVG-like coordinate system: 110 x 100
    final scaleX = size.width / 110;
    final scaleY = size.height / 100;

    canvas.scale(scaleX, scaleY);
    canvas.translate(55, 50);
    canvas.scale(0.60);
    canvas.translate(-55, -50);

    // This path controls the ticking animation direction.
    final tickPath = Path()
      ..moveTo(15, 49)
      ..lineTo(44, 76)
      ..lineTo(99, 19);

    final visibleTickPath = _extractProgress(tickPath, tickProgress);
    const tickStrokeWidth = 30.0;

    canvas.drawPath(
      visibleTickPath.shift(const Offset(5, 5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = tickStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );

    canvas.drawPath(
      visibleTickPath,
      Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = tickStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  Path _extractProgress(Path path, double progress) {
    final metrics = path.computeMetrics().toList();

    final totalLength = metrics.fold<double>(
      0,
      (sum, metric) => sum + metric.length,
    );

    final targetLength = totalLength * progress;

    final result = Path();
    double currentLength = 0;

    for (final metric in metrics) {
      if (currentLength >= targetLength) break;

      final remainingLength = targetLength - currentLength;
      final extractLength = remainingLength.clamp(0, metric.length).toDouble();

      result.addPath(metric.extractPath(0, extractLength), Offset.zero);

      currentLength += metric.length;
    }

    return result;
  }

  @override
  bool shouldRepaint(covariant _BookingSuccessTickPainter oldDelegate) {
    return oldDelegate.circleScale != circleScale ||
        oldDelegate.tickProgress != tickProgress ||
        oldDelegate.circleColor1 != circleColor1 ||
        oldDelegate.circleColor2 != circleColor2 ||
        oldDelegate.checkColor != checkColor;
  }
}

class BanquetInquery extends StatefulWidget {
  const BanquetInquery({super.key});

  @override
  State<BanquetInquery> createState() => BanquetInqueryState();
}

class BanquetInqueryState extends State<BanquetInquery> {
  // -- Tab selection -----------------------------------------
  String selectedStatus = 'Plan a Party';
  String _previousStatus = 'Plan a Party';

  // -- Overlay/modal flags -----------------------------------
  bool isReviewOnClick = false;
  bool isCtReviewOnClick = false;
  bool isWithdrawOnClick = false;
  bool viewEnquiryOnClick = false; // ? controls ViewInquery subview
  bool viewCtEnquiryOnClick = false;
  bool isResponseAcceptOnClick = false;
  bool viewRequest = false;
  bool viewCtRequest = false;
  bool isResponseAcceptConfirmOnClick = false;
  bool isConfirmClicked = false;
  bool _isConfirmLoading = false;
  bool viewDeclineOnClick = false;
  bool viewCtDeclineOnClick = false;
  bool isSearchOnClick = false;
  bool isCtSearchOnClick = false;

  bool get _isAnyOverlayOpen =>
      isReviewOnClick ||
      isCtReviewOnClick ||
      viewEnquiryOnClick ||
      viewCtEnquiryOnClick ||
      isResponseAcceptOnClick ||
      viewRequest ||
      viewCtRequest ||
      isResponseAcceptConfirmOnClick ||
      isConfirmClicked ||
      viewDeclineOnClick ||
      viewCtDeclineOnClick ||
      isSearchOnClick ||
      isCtSearchOnClick;

  void _closeTopOverlay() {
    if (isReviewOnClick) {
      _stopPartyTimer();
    }

    setState(() {
      if (isResponseAcceptConfirmOnClick || isConfirmClicked) {
        isResponseAcceptConfirmOnClick = false;
        isConfirmClicked = false;
        _isConfirmLoading = false;
      } else if (isResponseAcceptOnClick) {
        isResponseAcceptOnClick = false;
      } else if (isReviewOnClick) {
        isReviewOnClick = false;
      } else if (isCtReviewOnClick) {
        isCtReviewOnClick = false;
      } else if (viewRequest) {
        viewRequest = false;
        _selectedResponse = null;
      } else if (viewCtRequest) {
        viewCtRequest = false;
      } else if (isSearchOnClick) {
        isSearchOnClick = false;
      } else if (isCtSearchOnClick) {
        isCtSearchOnClick = false;
      } else if (viewDeclineOnClick) {
        viewDeclineOnClick = false;
      } else if (viewCtDeclineOnClick) {
        viewCtDeclineOnClick = false;
      } else if (viewEnquiryOnClick) {
        viewEnquiryOnClick = false;
      } else if (viewCtEnquiryOnClick) {
        viewCtEnquiryOnClick = false;
      }
    });
  }

  void resetToPlanAParty() {
    _stopPartyTimer();
    _confirmCloseTimer?.cancel();
    _searchController.clear();

    setState(() {
      selectedStatus = 'Plan a Party';
      _previousStatus = 'Plan a Party';
      isReviewOnClick = false;
      isCtReviewOnClick = false;
      isWithdrawOnClick = false;
      viewEnquiryOnClick = false;
      viewCtEnquiryOnClick = false;
      isResponseAcceptOnClick = false;
      viewRequest = false;
      viewCtRequest = false;
      isResponseAcceptConfirmOnClick = false;
      isConfirmClicked = false;
      _isConfirmLoading = false;
      _isPartySubmitLoading = false;
      viewDeclineOnClick = false;
      viewCtDeclineOnClick = false;
      isSearchOnClick = false;
      isCtSearchOnClick = false;
      _selectedResponse = null;
      _isSearchActive = false;
      _searchQuery = '';
    });
  }

  // -- Confirm auto-close ------------------------------------
  Timer? _confirmCloseTimer;

  // -- Pending booking state ---------------------------------
  String? _pendingEnquiryId;
  String? _pendingEnquiryUuid;
  String _pendingRestaurantName = '';
  bool _hasExistingBooking = false;

  // -- Catering enquiries ------------------------------------
  Map<String, String> ctEnquiryData = {};
  List<CateringInqueryModel> _ctEnquiries = [];
  bool _ctEnquiriesLoading = false;

  // -- Party review timer ------------------------------------
  Map<String, String> partyEnquiryData = {};
  Timer? _partyTimer;
  int _partySeconds = 180;
  bool _isPartySubmitLoading = false;
  // Key to access PlanAParty state for clearing fields after send
  final GlobalKey planPartyKey = GlobalKey();

  // -- Responses ---------------------------------------------
  bool _responsesLoading = false;
  String _responsesError = '';
  List<ResponseModel> _allResponses = [];
  List<ResponseModel> _allDeclinedResponses = [];
  ResponseModel? _selectedResponse;
  final Map<String, String> _placeNames = {}; // cache lat,lng -> place name

  // -- Decline filter ----------------------------------------
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
    final metrics = _BanquetInqueryMetrics.fromContext(context);
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
        padding: EdgeInsets.symmetric(
          vertical: metrics.searchVerticalPadding,
          horizontal: metrics.searchFieldHorizontalPadding,
        ),
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
          size: metrics.overlayBodySize,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }

  // -- Search filter -----------------------------------------
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
    final metrics = _BanquetInqueryMetrics.fromContext(context);
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
        padding: EdgeInsets.symmetric(
          vertical: metrics.searchVerticalPadding,
          horizontal: metrics.searchFieldHorizontalPadding,
        ),
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
          size: metrics.overlayBodySize,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }

  // -- Response filter ---------------------------------------
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
    final metrics = _BanquetInqueryMetrics.fromContext(context);
    final textWidth = label.length * metrics.filterTextUnitWidth;
    return (textWidth + metrics.filterDropdownExtraWidth)
        .clamp(metrics.filterDropdownMinWidth, metrics.filterDropdownMaxWidth)
        .toDouble();
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
    final metrics = _BanquetInqueryMetrics.fromContext(context);
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
        padding: EdgeInsets.symmetric(
          vertical: metrics.searchVerticalPadding,
          horizontal: metrics.searchFieldHorizontalPadding,
        ),
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
          size: metrics.overlayBodySize,
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
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final calendarMetrics = _CalendarMetrics.fromContext(context);
            final size = MediaQuery.sizeOf(context);
            final isTablet = Breakpoints.isTablet(size.width);
            final isWideShortPhone =
                !isTablet && size.width >= 500 && size.height <= 760;
            final isCompactPhone = size.width < 390 || size.height < 700;
            final dialogHorizontalPadding = isTablet
                ? 16.0
                : isWideShortPhone
                ? 14.0
                : isCompactPhone
                ? 12.0
                : 16.w;
            final dialogVerticalPadding = isTablet
                ? 16.0
                : isWideShortPhone
                ? 14.0
                : isCompactPhone
                ? 12.0
                : 16.h;
            final actionHorizontalPadding = isTablet
                ? 10.0
                : isWideShortPhone
                ? 8.0
                : isCompactPhone
                ? 6.0
                : 10.w;
            final actionTextSize = isTablet
                ? 14.0
                : isWideShortPhone
                ? 13.0
                : isCompactPhone
                ? 12.5
                : 14.sp;

            return PopScope(
              canPop: true,
              child: Dialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: dialogHorizontalPadding,
                  vertical: dialogVerticalPadding,
                ),
                constraints: BoxConstraints.tightFor(
                  width:
                      calendarMetrics.calendarWidth +
                      (dialogHorizontalPadding * 2),
                ),
                backgroundColor: const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 10.r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: dialogHorizontalPadding,
                    vertical: dialogVerticalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCustomCalendar(
                        tempDate: tempDate,
                        onDateChanged: (date) =>
                            setDialogState(() => tempDate = date),
                      ),
                      SizedBox(height: dialogVerticalPadding),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: actionHorizontalPadding,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(
                                dialogContext,
                                rootNavigator: true,
                              ).pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: actionTextSize,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(
                                dialogContext,
                                rootNavigator: true,
                              ).pop(tempDate),
                              child: Text(
                                'Apply',
                                style: TextStyle(
                                  color: const Color(0xFF3954DB),
                                  fontSize: actionTextSize,
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
      isDismissible: true,
      enableDrag: true,
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

  // -- Lifecycle ---------------------------------------------
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

  // -- Data fetching -----------------------------------------
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

  // -- Party timer -------------------------------------------
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

  // -- Submit party enquiry ----------------------------------
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

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final metrics = _BanquetInqueryMetrics.fromContext(context);

    return PopScope(
      canPop: !_isAnyOverlayOpen && selectedStatus == 'Plan a Party',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_isAnyOverlayOpen) {
          _closeTopOverlay();
        } else if (selectedStatus == 'Response') {
          _selectStatus('Plan a Party');
        }
      },
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              if (viewEnquiryOnClick)
                Positioned.fill(
                  child: ViewInquery(
                    onEnquiryTap: (val) =>
                        setState(() => viewEnquiryOnClick = val),
                  ),
                )
              else if (viewDeclineOnClick)
                // ? Wrap this too
                Positioned.fill(child: _viewDeclineWidget())
              // else if (isSearchOnClick)
              //   _viewSearchWidget()
              else if (isSearchOnClick)
                // ? And this
                Positioned.fill(child: _viewSearchWidget())
              else
                Column(
                  children: [
                    // -- Tab buttons ------------------------------
                    Padding(
                      padding: EdgeInsets.all(metrics.pagePadding),
                      child: SizedBox(
                        height: metrics.tabHeight,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return _buildAnimatedStatusTabs(
                              width: constraints.maxWidth,
                            );
                          },
                        ),
                      ),
                    ),
                    // -- Tab content ------------------------------
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragEnd: _handleTabSwipe,
                        child: ClipRect(child: _buildSlidingTabBody()),
                      ),
                    ),
                  ],
                ),

              // -- Overlays (always on top in Stack) -------------
              if (isResponseAcceptOnClick) _responseAcceptBox(),
              if (viewRequest) _viewRequestWidget(),
              if (isResponseAcceptConfirmOnClick) _responseAcceptConfirmBox(),
              if (isReviewOnClick) _partyReviewBox(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // SUBVIEW: Decline list
  // ---------------------------------------------------------
  void _handleTabSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 250) return;

    if (velocity < 0 && selectedStatus == "Plan a Party") {
      _selectStatus("Response");
    } else if (velocity > 0 && selectedStatus == "Response") {
      _selectStatus("Plan a Party");
    }
  }

  Widget _buildSlidingTabBody() {
    final bool showPartyTab = selectedStatus == "Plan a Party";
    const duration = Duration(milliseconds: 430);
    const curve = Curves.easeInOutCubic;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AnimatedSlide(
            offset: showPartyTab ? Offset.zero : const Offset(-1, 0),
            duration: duration,
            curve: curve,
            child: IgnorePointer(
              ignoring: !showPartyTab,
              child: PlanAParty(
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
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedSlide(
            offset: showPartyTab ? const Offset(1, 0) : Offset.zero,
            duration: duration,
            curve: curve,
            child: IgnorePointer(
              ignoring: showPartyTab,
              child: _responseWidget(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _viewDeclineWidget() {
    final metrics = _BanquetInqueryMetrics.fromContext(context);
    final declined = _filteredDeclinedResponses;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: metrics.subviewHorizontalPadding,
            right: metrics.subviewHorizontalPadding,
            top: metrics.subviewTopPadding,
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => viewDeclineOnClick = false),
                child: Image.asset(
                  backOrange,
                  height: metrics.backIconSize,
                  width: metrics.backIconSize,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: _filterDropdownWidth(_declineFilterLabel),
                    child: AppFilterDropDown(
                      height: metrics.filterHeight,
                      hint: _declineFilterLabel,
                      imageIconPath: filterIcon,
                      imageIconSize: metrics.filterIconSize,
                      toggleDropdown: () {
                        showModalBottomSheet(
                          backgroundColor: Colors.white,
                          context: context,
                          isScrollControlled: true,
                          isDismissible: true,
                          enableDrag: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(metrics.sheetTopRadius),
                            ),
                          ),
                          builder: (_) => Padding(
                            padding: EdgeInsets.all(metrics.sheetPadding),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _sheetHandle(),
                                SizedBox(height: metrics.sheetGap),
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
              SizedBox(width: metrics.backIconSize),
            ],
          ),
        ),
        SizedBox(height: metrics.subviewGap),
        Expanded(
          child: RefreshIndicator(
            color: appButtonColor,
            onRefresh: _fetchDeclinedResponses,
            child: _responsesLoading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      SizedBox(height: metrics.loadingTopHeight),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  )
                : _responsesError.isNotEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      SizedBox(height: metrics.loadingTopHeight),
                      _errorText(_responsesError),
                    ],
                  )
                : declined.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      SizedBox(height: metrics.loadingTopHeight),
                      _emptyState(
                        Icons.inbox_outlined,
                        "No declined responses for $_declineFilterLabel",
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: declined.length,
                    itemBuilder: (ctx, index) => Padding(
                      padding: EdgeInsets.only(
                        left: metrics.subviewHorizontalPadding,
                        right: metrics.subviewHorizontalPadding,
                      ),
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

  // ---------------------------------------------------------
  // SUBVIEW: Search
  // ---------------------------------------------------------
  Widget _viewSearchWidget() {
    final metrics = _BanquetInqueryMetrics.fromContext(context);
    final results = _filteredSearchResponses;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: metrics.subviewHorizontalPadding,
            right: metrics.subviewHorizontalPadding,
            top: metrics.subviewTopPadding,
          ),
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
        SizedBox(height: metrics.actionGap),
        SizedBox(
          width: _filterDropdownWidth(_searchFilterLabel),
          child: AppFilterDropDown(
            height: metrics.filterHeight,
            hint: _searchFilterLabel,
            imageIconPath: filterIcon,
            imageIconSize: metrics.filterIconSize,
            toggleDropdown: () {
              showModalBottomSheet(
                backgroundColor: Colors.white,
                context: context,
                isScrollControlled: true,
                isDismissible: true,
                enableDrag: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(metrics.sheetTopRadius),
                  ),
                ),
                builder: (_) => Padding(
                  padding: EdgeInsets.all(metrics.sheetPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sheetHandle(),
                      SizedBox(height: metrics.sheetGap),
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
        SizedBox(height: metrics.subviewGap),
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
                    padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
                    physics: const BouncingScrollPhysics(),
                    itemCount: results.length,
                    itemBuilder: (ctx, index) => Padding(
                      padding: EdgeInsets.only(
                        left: metrics.subviewHorizontalPadding,
                        right: metrics.subviewHorizontalPadding,
                      ),
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

  // -- Search input with toggle (replicates reservation search UX) --
  Widget _searchInputField() {
    final metrics = _BanquetInqueryMetrics.fromContext(context);

    if (!_isSearchActive) {
      return GestureDetector(
        onTap: () => setState(() => _isSearchActive = true),
        child: Container(
          height: metrics.searchHeight,
          padding: EdgeInsets.symmetric(
            vertical: metrics.searchVerticalPadding,
            horizontal: metrics.searchHorizontalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(metrics.searchRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 0),
                blurRadius: metrics.searchShadowBlur,
                spreadRadius: metrics.searchShadowSpread,
              ),
            ],
          ),
          child: Center(
            child: AppText(
              text: "Search by coupon code or hotel name",
              size: metrics.searchTextSize,
              color: appTextColor3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      height: metrics.searchHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.searchActiveRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 0),
            blurRadius: metrics.searchShadowBlur,
            spreadRadius: metrics.searchShadowSpread,
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
              padding: EdgeInsets.only(left: metrics.searchClosePadding),
              child: Icon(
                Icons.close,
                size: metrics.searchCloseIconSize,
                color: appTextColor3,
              ),
            ),
          ),

          Expanded(
            child: AppTextFeild(
              text: "Search by coupon code or hotel name",

              controller: _searchController,

              backgroundColor: Colors.white,

              height: metrics.searchHeight,

              fieldBorderRadius: metrics.searchActiveRadius,

              textColor: appTextColor5,

              size: metrics.searchTextSize,

              isTextCenter: true,

              boxShadow: const [],

              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },

              inputContentPadding: EdgeInsets.symmetric(
                vertical: metrics.searchVerticalPadding,
                horizontal: metrics.searchFieldHorizontalPadding,
              ),

              decoration: InputDecoration(
                border: InputBorder.none,

                hintText: "Search by coupon code ",

                hintStyle: TextStyle(
                  fontSize: metrics.searchTextSize,
                  color: appTextColor3,
                  fontWeight: FontWeight.w400,
                ),

                contentPadding: EdgeInsets.symmetric(
                  vertical: metrics.searchVerticalPadding,
                  horizontal: metrics.searchFieldHorizontalPadding,
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

  // ---------------------------------------------------------
  // SUBVIEW: Response list
  // ---------------------------------------------------------
  Widget _responseWidget() {
    final metrics = _BanquetInqueryMetrics.fromContext(context);
    final responses = _filteredResponses;
    return Column(
      children: [
        SizedBox(height: metrics.subviewGap),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.subviewHorizontalPadding,
          ),
          child: Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: _filterDropdownWidth(_responseFilterLabel),
                    child: AppFilterDropDown(
                      height: metrics.filterHeight,
                      hint: _responseFilterLabel,
                      imageIconPath: filterIcon,
                      imageIconSize: metrics.filterIconSize,
                      toggleDropdown: () {
                        showModalBottomSheet(
                          backgroundColor: Colors.white,
                          context: context,
                          isScrollControlled: true,
                          isDismissible: true,
                          enableDrag: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(metrics.sheetTopRadius),
                            ),
                          ),
                          builder: (_) => Padding(
                            padding: EdgeInsets.all(metrics.sheetPadding),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _sheetHandle(),
                                SizedBox(height: metrics.sheetGap),
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
              SizedBox(width: metrics.actionGap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isSearchOnClick = true),
                    child: Row(
                      children: [
                        // Icon(Icons.search, size: 17.w, color: Colors.black),
                        Image.asset(
                          searchBlackIcon,
                          width: metrics.actionIconSmall,
                          height: metrics.actionIconSmall,
                        ),

                        SizedBox(width: metrics.actionTinyGap),
                        AppText(
                          text: "Search",
                          size: metrics.actionTextSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: metrics.actionStackGap),
                  GestureDetector(
                    onTap: () {
                      setState(() => viewDeclineOnClick = true);
                      _fetchDeclinedResponses();
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          inqueryIcon,
                          width: metrics.actionIconLarge,
                          height: metrics.actionIconLarge,
                        ),
                        SizedBox(width: metrics.actionTinyGap),
                        AppText(
                          text: "View Declined",
                          size: metrics.actionTextSize,
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
        SizedBox(height: metrics.subviewGap),
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
                    padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
                    physics: const BouncingScrollPhysics(),
                    itemCount: responses.length,
                    itemBuilder: (ctx, index) => Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.subviewHorizontalPadding,
                      ),
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

  // -- Accept tap shared logic -------------------------------
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

  // ---------------------------------------------------------
  // OVERLAY WIDGETS
  // ---------------------------------------------------------
  Widget _tabPopupShell({
    required Widget child,
    bool scrollable = false,
    VoidCallback? onDismiss,
  }) {
    final metrics = _BanquetInqueryMetrics.fromContext(context);
    final content = scrollable ? SingleChildScrollView(child: child) : child;

    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.overlayHorizontalPadding,
              ),
              child: GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: metrics.overlayMaxWidth,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.overlayPaddingHorizontal,
                      vertical: metrics.overlayPaddingVertical,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        metrics.overlayRadius,
                      ),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _partyReviewBox() {
    final metrics = _BanquetInqueryMetrics.fromContext(context);

    return _tabPopupShell(
      onDismiss: () {
        _stopPartyTimer();
        setState(() => isReviewOnClick = false);
      },
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: partyEnquiryData['couponId'] ?? 'Review',
                size: metrics.overlayTitleSize,
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
                  size: metrics.overlayBodySize,
                  fontWeight: FontWeight.w700,
                  color: Color(0XFF3954DB),
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(menuIcon, "Your Menu", partyEnquiryData['menu'] ?? ''),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            peopleIcon,
            "Number of Persons",
            "${partyEnquiryData['people'] ?? ''} Person",
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            calenderIcon,
            "Date and Time",
            partyEnquiryData['dateTime'] ?? '',
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            walletIcon,
            "Expected amount per person",
            "${partyEnquiryData['amount'] ?? ''} Per person",
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            radiusIcon,
            "Enquiry Radius",
            partyEnquiryData['location'] ?? '',
          ),
          SizedBox(height: metrics.overlayLargeGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                stopwatchIcon,
                width: metrics.actionIconLarge,
                height: metrics.actionIconLarge,
              ),
              SizedBox(width: metrics.actionStackGap),
              AppText(
                text: _partyTimerText,
                size: 10,
                fontWeight: FontWeight.w400,
                color: Color(0xFFED4444),
              ),
            ],
          ),
          SizedBox(height: metrics.overlaySmallGap),
          SizedBox(
            width: metrics.overlayButtonWidth,
            height: metrics.overlayButtonHeight,
            child: AppButton(
              text: "Send",
              onPressed: () async {
                if (_isPartySubmitLoading) return;
                setState(() => _isPartySubmitLoading = true);
                _stopPartyTimer();

                try {
                  await _submitPartyEnquiry();
                } finally {
                  if (mounted) {
                    setState(() => _isPartySubmitLoading = false);
                  }
                }
              },
              isLoading: _isPartySubmitLoading,
              size: metrics.overlayButtonTextSize,
              bgColor1: Color(0xFF73B256),
              bgColor2: Color(0xFF73B256),
              borderRadius: metrics.tabRadius,
            ),
          ),
        ],
      ),
    );
  }

  Widget _responseAcceptConfirmBox() {
    final metrics = _BanquetInqueryMetrics.fromContext(context);

    return _tabPopupShell(
      onDismiss: () => setState(() {
        isResponseAcceptConfirmOnClick = false;
        isConfirmClicked = false;
        _isConfirmLoading = false;
      }),
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
                  _isConfirmLoading = false;
                }),
                child: Icon(
                  Icons.close,
                  color: appTextColor3,
                  size: metrics.overlayCloseIconSize,
                ),
              ),
            ],
          ),
          if (isConfirmClicked) ...[
            BookingSuccessTick(size: metrics.overlaySuccessIconSize),
            SizedBox(height: metrics.overlayRowGap),
            AppText(
              text: "Booking Successful!",
              size: metrics.overlayTitleSize,
              fontWeight: FontWeight.w500,
              color: appTextColor3,
              isCentered: true,
            ),
            SizedBox(height: metrics.overlayRowGap),
          ] else ...[
            SizedBox(height: metrics.overlayRowGap),
            AppText(
              text:
                  "After confirmation, your party order will be booked at $_pendingRestaurantName.",
              size: metrics.overlayBodySize,
              fontWeight: FontWeight.w500,
              color: appTextColor2,
              isCentered: true,
            ),
            SizedBox(height: metrics.overlayRowGap),
            SizedBox(
              width: metrics.overlayButtonWidth,
              height: metrics.overlayButtonHeight,
              child: AppButton(
                text: "Confirm",
                onPressed: () async {
                  if (_isConfirmLoading || _pendingEnquiryUuid == null) return;
                  setState(() => _isConfirmLoading = true);

                  try {
                    final result = await InqueryService().confirmEnquiry(
                      _pendingEnquiryUuid!,
                    );
                    if (!mounted) return;
                    if (result['status'] == true) {
                      setState(() {
                        _isConfirmLoading = false;
                        isConfirmClicked = true;
                      });
                      await _fetchPartyResponses();
                      await _fetchDeclinedResponses();
                      _autoCloseConfirmBox();
                    } else {
                      setState(() => _isConfirmLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['message'] ?? 'Confirmation failed',
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    if (!mounted) return;
                    setState(() => _isConfirmLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Confirmation failed. Please try again.'),
                      ),
                    );
                  }
                },
                isLoading: _isConfirmLoading,
                bgColor1: Colors.green,
                bgColor2: Colors.green,
                size: metrics.overlayButtonTextSize,
                borderRadius: metrics.tabRadius,
              ),
            ),
            SizedBox(height: metrics.overlayRowGap),
          ],
        ],
      ),
    );
  }

  Widget _responseAcceptBox() {
    final metrics = _BanquetInqueryMetrics.fromContext(context);

    return _tabPopupShell(
      onDismiss: () => setState(() => isResponseAcceptOnClick = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            attentionIcon,
            width: metrics.overlayIconSize,
            height: metrics.overlayIconSize,
          ),
          SizedBox(height: metrics.overlaySmallGap),
          AppText(
            text: "Switch Banquet Booking?",
            isCentered: true,
            lineSpacing: 1.5,
            size: metrics.overlayBodySize,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD34545),
          ),
          SizedBox(height: metrics.overlaySmallGap),
          AppText(
            text:
                "You already have a banquet booked at $_pendingRestaurantName. Booking another Banquet will automatically cancel your previous booking.",
            isCentered: true,
            lineSpacing: 1.5,
            size: metrics.overlayBodySize,
            fontWeight: FontWeight.w500,
            color: appTextColor2,
          ),
          SizedBox(height: metrics.overlayRowGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => isResponseAcceptOnClick = false),
                child: AppText(
                  text: "Cancel",
                  size: metrics.overlayBodySize,
                  fontWeight: FontWeight.w400,
                  color: appLinkColor2,
                ),
              ),
              SizedBox(
                width: metrics.overlayButtonWidth,
                height: metrics.overlayButtonHeight,
                child: AppButton(
                  text: "Yes, Book",
                  onPressed: () => setState(() {
                    isResponseAcceptOnClick = false;
                    isResponseAcceptConfirmOnClick = true;
                  }),
                  size: metrics.overlayButtonTextSize,
                  bgColor1: Color(0xFF73B256),
                  bgColor2: Color(0xFF73B256),
                  borderRadius: metrics.tabRadius,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewRequestWidget() {
    final metrics = _BanquetInqueryMetrics.fromContext(context);

    return _tabPopupShell(
      onDismiss: () => setState(() {
        viewRequest = false;
        _selectedResponse = null;
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: "Requested party",
                size: metrics.overlayHeaderSize,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
              ),
              GestureDetector(
                onTap: () => setState(() {
                  viewRequest = false;
                  _selectedResponse = null;
                }),
                child: Icon(
                  Icons.close,
                  color: appTextColor3,
                  size: metrics.overlayCloseIconSize,
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.overlayRowGap),
          Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              text:
                  _selectedResponse?.enquiryId ??
                  _selectedResponse?.couponId ??
                  _selectedResponse?.uuid ??
                  '-',
              size: metrics.overlayTitleSize,
              fontWeight: FontWeight.w700,
              color: appTextColor3,
            ),
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            menuIcon,
            "Your Menu",
            _selectedResponse?.requestMenuItems?.isNotEmpty == true
                ? _selectedResponse!.requestMenuItems
                : (_selectedResponse?.requestOtherServices?.isNotEmpty == true
                      ? _selectedResponse!.requestOtherServices
                      : '-'),
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            peopleIcon,
            "Number of Persons",
            _selectedResponse != null
                ? '${_selectedResponse!.requestPeople} Person'
                : '-',
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            calenderIcon,
            "Date and Time",
            _requestDateTime(_selectedResponse),
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            walletIcon,
            "Expected amount per person",
            _selectedResponse != null
                ? (_selectedResponse!.requestEstimatedAmount.isNotEmpty
                      ? '${_selectedResponse!.requestEstimatedAmount} Per person'
                      : '${_selectedResponse!.pricePerPerson} Per person')
                : '-',
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            radiusIcon,
            "Enquiry Radius",
            _requestRadius(_selectedResponse),
          ),
          SizedBox(height: metrics.overlayRowGap),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // SHARED HELPERS
  // ---------------------------------------------------------
  Widget _reviewRow(String imageIcon, String label, String value) {
    final metrics = _BanquetInqueryMetrics.fromContext(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imageIcon,
          width: metrics.reviewIconSize,
          height: metrics.reviewIconSize,
          color: Color.fromARGB(255, 8, 8, 8),
        ),
        SizedBox(width: metrics.reviewGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: label,
                size: metrics.reviewLabelSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              SizedBox(height: metrics.actionStackGap),
              AppText(
                text: value,
                size: metrics.reviewValueSize,
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
    width: _BanquetInqueryMetrics.fromContext(context).sheetHandleWidth,
    height: _BanquetInqueryMetrics.fromContext(context).sheetHandleHeight,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(
        _BanquetInqueryMetrics.fromContext(context).sheetHandleRadius,
      ),
    ),
  );

  Widget _sheetContainer(List<Widget> children) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        _BanquetInqueryMetrics.fromContext(context).sheetContainerRadius,
      ),
    ),
    padding: EdgeInsets.all(
      _BanquetInqueryMetrics.fromContext(context).sheetContainerPadding,
    ),
    child: Column(children: children),
  );

  Widget _emptyState(IconData icon, String message) {
    final metrics = _BanquetInqueryMetrics.fromContext(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: metrics.emptyIconSize,
            color: appTextColor3.withValues(alpha: 0.4),
          ),
          SizedBox(height: metrics.emptyGap),
          AppText(
            text: message,
            size: metrics.emptyTextSize,
            fontWeight: FontWeight.w500,
            color: appTextColor3,
            isCentered: true,
          ),
        ],
      ),
    );
  }

  Widget _errorText(String message) {
    final metrics = _BanquetInqueryMetrics.fromContext(context);

    return Center(
      child: AppText(
        text: message,
        size: metrics.emptyTextSize,
        fontWeight: FontWeight.w500,
        color: appTextColor3,
        isCentered: true,
      ),
    );
  }

  void _selectStatus(String text) {
    if (selectedStatus == text) return;

    setState(() {
      _previousStatus = selectedStatus;
      selectedStatus = text;
    });

    if (text == "Response") _fetchPartyResponses();
  }

  Widget _buildAnimatedStatusTabs({required double width}) {
    final tabs = ["Plan a Party", "Response"];

    return Stack(
      children: [
        _buildStatusIndicator(width: width),
        ...tabs.map((tab) => _buildPositionedStatusButton(tab, width: width)),
      ],
    );
  }

  Widget _buildStatusIndicator({required double width}) {
    final metrics = _BanquetInqueryMetrics.fromContext(context);
    final rect = _statusTabRect(selectedStatus, width: width);
    final bool isStatusSwitch = _previousStatus != selectedStatus;
    final indicator = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
        ),
        borderRadius: BorderRadius.circular(metrics.tabRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: metrics.tabShadowBlur,
            offset: metrics.tabShadowOffset,
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
    final metrics = _BanquetInqueryMetrics.fromContext(context);
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
              borderRadius: BorderRadius.circular(metrics.tabRadius),
              boxShadow: isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: metrics.tabShadowBlur,
                        offset: metrics.tabShadowOffset,
                      ),
                    ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: metrics.tabTextSize,
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
    final metrics = _BanquetInqueryMetrics.fromContext(context);
    final double gap = metrics.tabGap;
    final double tabHeight = metrics.tabHeight;
    final double tabWidth = (width - gap) / 2;

    switch (text) {
      case "Response":
        return Rect.fromLTWH(tabWidth + gap, 0, tabWidth, tabHeight);
      case "Plan a Party":
      default:
        return Rect.fromLTWH(0, 0, tabWidth, tabHeight);
    }
  }
}

class _BanquetInqueryMetrics {
  const _BanquetInqueryMetrics({
    required this.contentWidth,
    required this.pagePadding,
    required this.tabHeight,
    required this.tabGap,
    required this.tabRadius,
    required this.tabTextSize,
    required this.tabShadowBlur,
    required this.tabShadowOffset,
    required this.subviewHorizontalPadding,
    required this.subviewTopPadding,
    required this.subviewGap,
    required this.listBottomPadding,
    required this.backIconSize,
    required this.filterHeight,
    required this.filterIconSize,
    required this.filterTextUnitWidth,
    required this.filterDropdownExtraWidth,
    required this.filterDropdownMinWidth,
    required this.filterDropdownMaxWidth,
    required this.sheetPadding,
    required this.sheetTopRadius,
    required this.sheetHandleWidth,
    required this.sheetHandleHeight,
    required this.sheetHandleRadius,
    required this.sheetGap,
    required this.sheetContainerPadding,
    required this.sheetContainerRadius,
    required this.searchHeight,
    required this.searchVerticalPadding,
    required this.searchHorizontalPadding,
    required this.searchRadius,
    required this.searchActiveRadius,
    required this.searchShadowBlur,
    required this.searchShadowSpread,
    required this.searchTextSize,
    required this.searchCloseIconSize,
    required this.searchClosePadding,
    required this.searchFieldHorizontalPadding,
    required this.actionGap,
    required this.actionTinyGap,
    required this.actionIconSmall,
    required this.actionIconLarge,
    required this.actionTextSize,
    required this.actionStackGap,
    required this.overlayHorizontalPadding,
    required this.overlayMaxWidth,
    required this.overlayPaddingHorizontal,
    required this.overlayPaddingVertical,
    required this.overlayRadius,
    required this.overlayTitleSize,
    required this.overlayBodySize,
    required this.overlayHeaderSize,
    required this.overlayCloseIconSize,
    required this.overlayIconSize,
    required this.overlaySuccessIconSize,
    required this.overlayRowGap,
    required this.overlayLargeGap,
    required this.overlaySmallGap,
    required this.overlayButtonWidth,
    required this.overlayButtonHeight,
    required this.overlayButtonTextSize,
    required this.reviewIconSize,
    required this.reviewGap,
    required this.reviewLabelSize,
    required this.reviewValueSize,
    required this.emptyIconSize,
    required this.emptyGap,
    required this.emptyTextSize,
    required this.loadingTopHeight,
  });

  final double contentWidth;
  final double pagePadding;
  final double tabHeight;
  final double tabGap;
  final double tabRadius;
  final double tabTextSize;
  final double tabShadowBlur;
  final Offset tabShadowOffset;
  final double subviewHorizontalPadding;
  final double subviewTopPadding;
  final double subviewGap;
  final double listBottomPadding;
  final double backIconSize;
  final double filterHeight;
  final double filterIconSize;
  final double filterTextUnitWidth;
  final double filterDropdownExtraWidth;
  final double filterDropdownMinWidth;
  final double filterDropdownMaxWidth;
  final double sheetPadding;
  final double sheetTopRadius;
  final double sheetHandleWidth;
  final double sheetHandleHeight;
  final double sheetHandleRadius;
  final double sheetGap;
  final double sheetContainerPadding;
  final double sheetContainerRadius;
  final double searchHeight;
  final double searchVerticalPadding;
  final double searchHorizontalPadding;
  final double searchRadius;
  final double searchActiveRadius;
  final double searchShadowBlur;
  final double searchShadowSpread;
  final double searchTextSize;
  final double searchCloseIconSize;
  final double searchClosePadding;
  final double searchFieldHorizontalPadding;
  final double actionGap;
  final double actionTinyGap;
  final double actionIconSmall;
  final double actionIconLarge;
  final double actionTextSize;
  final double actionStackGap;
  final double overlayHorizontalPadding;
  final double overlayMaxWidth;
  final double overlayPaddingHorizontal;
  final double overlayPaddingVertical;
  final double overlayRadius;
  final double overlayTitleSize;
  final double overlayBodySize;
  final double overlayHeaderSize;
  final double overlayCloseIconSize;
  final double overlayIconSize;
  final double overlaySuccessIconSize;
  final double overlayRowGap;
  final double overlayLargeGap;
  final double overlaySmallGap;
  final double overlayButtonWidth;
  final double overlayButtonHeight;
  final double overlayButtonTextSize;
  final double reviewIconSize;
  final double reviewGap;
  final double reviewLabelSize;
  final double reviewValueSize;
  final double emptyIconSize;
  final double emptyGap;
  final double emptyTextSize;
  final double loadingTopHeight;

  factory _BanquetInqueryMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final contentWidth = (size.width * 0.82).clamp(700.0, 980.0).toDouble();
      final scale = (contentWidth / 760).clamp(1.0, 1.14).toDouble();
      double s(double value) => value * scale;

      return _BanquetInqueryMetrics(
        contentWidth: contentWidth,
        pagePadding: s(28),
        tabHeight: s(44),
        tabGap: s(14),
        tabRadius: s(12),
        tabTextSize: s(15),
        tabShadowBlur: s(8),
        tabShadowOffset: Offset(s(2), s(2)),
        subviewHorizontalPadding: s(38),
        subviewTopPadding: s(34),
        subviewGap: s(24),
        listBottomPadding: s(32),
        backIconSize: s(32),
        filterHeight: s(38),
        filterIconSize: s(18),
        filterTextUnitWidth: s(8),
        filterDropdownExtraWidth: s(84),
        filterDropdownMinWidth: s(132),
        filterDropdownMaxWidth: s(220),
        sheetPadding: s(36),
        sheetTopRadius: s(28),
        sheetHandleWidth: s(48),
        sheetHandleHeight: s(5),
        sheetHandleRadius: s(10),
        sheetGap: s(18),
        sheetContainerPadding: s(20),
        sheetContainerRadius: s(22),
        searchHeight: s(58),
        searchVerticalPadding: s(16),
        searchHorizontalPadding: s(20),
        searchRadius: s(14),
        searchActiveRadius: s(18),
        searchShadowBlur: s(12),
        searchShadowSpread: s(4),
        searchTextSize: s(15),
        searchCloseIconSize: s(24),
        searchClosePadding: s(16),
        searchFieldHorizontalPadding: s(14),
        actionGap: s(16),
        actionTinyGap: s(4),
        actionIconSmall: s(15),
        actionIconLarge: s(20),
        actionTextSize: s(16),
        actionStackGap: s(7),
        overlayHorizontalPadding: s(40),
        overlayMaxWidth: s(560),
        overlayPaddingHorizontal: s(34),
        overlayPaddingVertical: s(30),
        overlayRadius: s(22),
        overlayTitleSize: s(22),
        overlayBodySize: s(16),
        overlayHeaderSize: s(17),
        overlayCloseIconSize: s(28),
        overlayIconSize: s(52),
        overlaySuccessIconSize: s(82),
        overlayRowGap: s(20),
        overlayLargeGap: s(30),
        overlaySmallGap: s(12),
        overlayButtonWidth: s(150),
        overlayButtonHeight: s(44),
        overlayButtonTextSize: s(16),
        reviewIconSize: s(20),
        reviewGap: s(12),
        reviewLabelSize: s(15),
        reviewValueSize: s(15),
        emptyIconSize: s(56),
        emptyGap: s(14),
        emptyTextSize: s(16),
        loadingTopHeight: s(130),
      );
    }

    if (isWideShortPhone) {
      return const _BanquetInqueryMetrics(
        contentWidth: 484,
        pagePadding: 24,
        tabHeight: 36,
        tabGap: 10,
        tabRadius: 10,
        tabTextSize: 13,
        tabShadowBlur: 6,
        tabShadowOffset: Offset(2, 2),
        subviewHorizontalPadding: 26,
        subviewTopPadding: 22,
        subviewGap: 14,
        listBottomPadding: 22,
        backIconSize: 27,
        filterHeight: 32,
        filterIconSize: 15,
        filterTextUnitWidth: 7.5,
        filterDropdownExtraWidth: 74,
        filterDropdownMinWidth: 120,
        filterDropdownMaxWidth: 190,
        sheetPadding: 26,
        sheetTopRadius: 24,
        sheetHandleWidth: 40,
        sheetHandleHeight: 5,
        sheetHandleRadius: 10,
        sheetGap: 14,
        sheetContainerPadding: 15,
        sheetContainerRadius: 18,
        searchHeight: 44,
        searchVerticalPadding: 11,
        searchHorizontalPadding: 16,
        searchRadius: 12,
        searchActiveRadius: 14,
        searchShadowBlur: 9,
        searchShadowSpread: 3,
        searchTextSize: 12.5,
        searchCloseIconSize: 19,
        searchClosePadding: 12,
        searchFieldHorizontalPadding: 10,
        actionGap: 10,
        actionTinyGap: 2,
        actionIconSmall: 12,
        actionIconLarge: 16,
        actionTextSize: 13,
        actionStackGap: 4,
        overlayHorizontalPadding: 38,
        overlayMaxWidth: 430,
        overlayPaddingHorizontal: 24,
        overlayPaddingVertical: 20,
        overlayRadius: 18,
        overlayTitleSize: 18,
        overlayBodySize: 13,
        overlayHeaderSize: 14,
        overlayCloseIconSize: 22,
        overlayIconSize: 42,
        overlaySuccessIconSize: 70,
        overlayRowGap: 14,
        overlayLargeGap: 22,
        overlaySmallGap: 9,
        overlayButtonWidth: 124,
        overlayButtonHeight: 36,
        overlayButtonTextSize: 14,
        reviewIconSize: 16,
        reviewGap: 9,
        reviewLabelSize: 12.5,
        reviewValueSize: 13,
        emptyIconSize: 42,
        emptyGap: 10,
        emptyTextSize: 13,
        loadingTopHeight: 96,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _BanquetInqueryMetrics(
        contentWidth: double.infinity,
        pagePadding: s(16),
        tabHeight: s(32),
        tabGap: s(8),
        tabRadius: s(9),
        tabTextSize: s(12),
        tabShadowBlur: s(5),
        tabShadowOffset: Offset(s(1.5), s(1.5)),
        subviewHorizontalPadding: s(18),
        subviewTopPadding: s(18),
        subviewGap: s(14),
        listBottomPadding: s(20),
        backIconSize: s(24),
        filterHeight: s(30),
        filterIconSize: s(14),
        filterTextUnitWidth: s(7),
        filterDropdownExtraWidth: s(68),
        filterDropdownMinWidth: s(108),
        filterDropdownMaxWidth: s(172),
        sheetPadding: s(22),
        sheetTopRadius: s(22),
        sheetHandleWidth: s(38),
        sheetHandleHeight: s(4),
        sheetHandleRadius: s(9),
        sheetGap: s(13),
        sheetContainerPadding: s(14),
        sheetContainerRadius: s(18),
        searchHeight: s(43),
        searchVerticalPadding: s(10),
        searchHorizontalPadding: s(14),
        searchRadius: s(11),
        searchActiveRadius: s(13),
        searchShadowBlur: s(8),
        searchShadowSpread: s(3),
        searchTextSize: s(12),
        searchCloseIconSize: s(18),
        searchClosePadding: s(10),
        searchFieldHorizontalPadding: s(10),
        actionGap: s(9),
        actionTinyGap: s(2),
        actionIconSmall: s(11),
        actionIconLarge: s(15),
        actionTextSize: s(12.5),
        actionStackGap: s(4),
        overlayHorizontalPadding: s(22),
        overlayMaxWidth: double.infinity,
        overlayPaddingHorizontal: s(22),
        overlayPaddingVertical: s(18),
        overlayRadius: s(17),
        overlayTitleSize: s(17),
        overlayBodySize: s(13),
        overlayHeaderSize: s(13),
        overlayCloseIconSize: s(22),
        overlayIconSize: s(40),
        overlaySuccessIconSize: s(66),
        overlayRowGap: s(14),
        overlayLargeGap: s(22),
        overlaySmallGap: s(9),
        overlayButtonWidth: s(118),
        overlayButtonHeight: s(36),
        overlayButtonTextSize: s(13),
        reviewIconSize: s(16),
        reviewGap: s(8),
        reviewLabelSize: s(12.5),
        reviewValueSize: s(13),
        emptyIconSize: s(42),
        emptyGap: s(10),
        emptyTextSize: s(13),
        loadingTopHeight: s(96),
      );
    }

    return _BanquetInqueryMetrics(
      contentWidth: double.infinity,
      pagePadding: 20.w,
      tabHeight: 35.h,
      tabGap: 10.w,
      tabRadius: 10.r,
      tabTextSize: 13.sp,
      tabShadowBlur: 6.r,
      tabShadowOffset: Offset(2.w, 2.w),
      subviewHorizontalPadding: 30.w,
      subviewTopPadding: 30.h,
      subviewGap: 20.h,
      listBottomPadding: 24.h,
      backIconSize: 28.w,
      filterHeight: 32.h,
      filterIconSize: 15.sp,
      filterTextUnitWidth: 7.5.w,
      filterDropdownExtraWidth: 76.w,
      filterDropdownMinWidth: 120.w,
      filterDropdownMaxWidth: 190.w,
      sheetPadding: 30.w,
      sheetTopRadius: 25.r,
      sheetHandleWidth: 40.w,
      sheetHandleHeight: 5.h,
      sheetHandleRadius: 10.r,
      sheetGap: 16.h,
      sheetContainerPadding: 16.w,
      sheetContainerRadius: 20.r,
      searchHeight: 50.h,
      searchVerticalPadding: 14.h,
      searchHorizontalPadding: 16.w,
      searchRadius: 12.r,
      searchActiveRadius: 16.r,
      searchShadowBlur: 10,
      searchShadowSpread: 5,
      searchTextSize: 13.sp,
      searchCloseIconSize: 20.w,
      searchClosePadding: 12.w,
      searchFieldHorizontalPadding: 12.w,
      actionGap: 12.w,
      actionTinyGap: 2.w,
      actionIconSmall: 12.w,
      actionIconLarge: 17.w,
      actionTextSize: 15,
      actionStackGap: 5.h,
      overlayHorizontalPadding: 30.w,
      overlayMaxWidth: double.infinity,
      overlayPaddingHorizontal: 30.w,
      overlayPaddingVertical: 30.h,
      overlayRadius: 20.r,
      overlayTitleSize: 20,
      overlayBodySize: 15,
      overlayHeaderSize: 15,
      overlayCloseIconSize: 25.w,
      overlayIconSize: 50.w,
      overlaySuccessIconSize: 78.w,
      overlayRowGap: 20.h,
      overlayLargeGap: 30.h,
      overlaySmallGap: 10.h,
      overlayButtonWidth: 120.w,
      overlayButtonHeight: 40.h,
      overlayButtonTextSize: 15,
      reviewIconSize: 18.w,
      reviewGap: 10.w,
      reviewLabelSize: 15,
      reviewValueSize: 15,
      emptyIconSize: 48.w,
      emptyGap: 12.h,
      emptyTextSize: 15,
      loadingTopHeight: 120.h,
    );
  }
}

Widget _buildCustomCalendar({
  required DateTime tempDate,
  required void Function(DateTime) onDateChanged,
  DateTime? minDate,
}) {
  return _CustomCalendar(
    selectedDate: tempDate,
    onDateChanged: onDateChanged,
    minDate: minDate,
  );
}

class _CustomCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime? minDate;
  final void Function(DateTime) onDateChanged;

  const _CustomCalendar({
    required this.selectedDate,
    required this.onDateChanged,
    this.minDate,
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
            final isPast =
                widget.minDate != null &&
                DateTime(_pickerYear, month).isBefore(
                  DateTime(widget.minDate!.year, widget.minDate!.month),
                );

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
    final minDate = widget.minDate;

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
        final isPast =
            minDate != null &&
            date.isBefore(DateTime(minDate.year, minDate.month, minDate.day));

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
