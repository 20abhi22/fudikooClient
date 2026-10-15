import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:fudikoclient/utils/snackbar.dart';

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
    canvas.clipPath(circlePath);

    final scaleX = size.width / 110;
    final scaleY = size.height / 100;

    canvas.scale(scaleX, scaleY);
    canvas.translate(55, 50);
    canvas.scale(0.60);
    canvas.translate(-55, -50);

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

class CateringInquery extends StatefulWidget {
  const CateringInquery({super.key});

  @override
  State<CateringInquery> createState() => CateringInqueryState();
}

class CateringInqueryState extends State<CateringInquery> {
  String selectedStatus = 'Book a Catering';
  String _previousStatus = 'Book a Catering';
  DateTime selectedDateTime = DateTime.now();
  bool isReviewOnClick = false;
  bool isCtReviewOnClick = false;
  bool _isCateringSubmitLoading = false;
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
    if (isCtReviewOnClick) {
      _stopCtTimer();
    }

    setState(() {
      if (isResponseAcceptConfirmOnClick || isConfirmClicked) {
        isResponseAcceptConfirmOnClick = false;
        isConfirmClicked = false;
      } else if (isResponseAcceptOnClick) {
        isResponseAcceptOnClick = false;
      } else if (isCtReviewOnClick) {
        isCtReviewOnClick = false;
      } else if (isReviewOnClick) {
        isReviewOnClick = false;
      } else if (viewCtRequest) {
        viewCtRequest = false;
        _selectedCtResponse = null;
      } else if (viewRequest) {
        viewRequest = false;
      } else if (isCtSearchOnClick) {
        isCtSearchOnClick = false;
      } else if (isSearchOnClick) {
        isSearchOnClick = false;
      } else if (viewCtDeclineOnClick) {
        viewCtDeclineOnClick = false;
      } else if (viewDeclineOnClick) {
        viewDeclineOnClick = false;
      } else if (viewCtEnquiryOnClick) {
        viewCtEnquiryOnClick = false;
      } else if (viewEnquiryOnClick) {
        viewEnquiryOnClick = false;
      }
    });

    // Nothing covering the list any more — safe to apply a held-back reload.
    _flushPendingRefresh();
  }

  void resetToBookACatering() {
    _stopCtTimer();
    _ctConfirmCloseTimer?.cancel();
    _ctSearchDebounceTimer?.cancel();
    _ctSearchController.clear();

    setState(() {
      selectedStatus = 'Book a Catering';
      _previousStatus = 'Book a Catering';
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
      viewDeclineOnClick = false;
      viewCtDeclineOnClick = false;
      _isCtSearchActive = false;
      isSearchOnClick = false;
      isCtSearchOnClick = false;
      ctEnquiryData = {};
      _selectedCtResponse = null;
      _pendingCtResponseUuid = '';
      _pendingCtRestaurantName = '';
      _ctSearchQuery = '';
      _ctSeconds = 180;
      _ctResetCounter++;
    });
  }

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
  DateTime? _ctEnquiryCustomStart;
  DateTime? _ctEnquiryCustomEnd;

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
    if (_ctEnquiryFilter == "All") return _ctEnquiries;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _ctEnquiries.where((item) {
      DateTime? itemDate;
      try {
        itemDate = DateFormat('yyyy-MM-dd').parse(item.date);
      } catch (_) {
        return false;
      }
      final itemDay = DateTime(itemDate.year, itemDate.month, itemDate.day);

      switch (_ctEnquiryFilter) {
        case "Today":
          return itemDay == today;
        case "Last 7 Days":
          return !itemDay.isBefore(today.subtract(const Duration(days: 6)));
        case "Last 30 Days":
          return !itemDay.isBefore(today.subtract(const Duration(days: 29)));
        case "Custom Range":
          if (_ctEnquiryCustomStart == null || _ctEnquiryCustomEnd == null) {
            return true;
          }
          final start = DateTime(
            _ctEnquiryCustomStart!.year,
            _ctEnquiryCustomStart!.month,
            _ctEnquiryCustomStart!.day,
          );
          final end = DateTime(
            _ctEnquiryCustomEnd!.year,
            _ctEnquiryCustomEnd!.month,
            _ctEnquiryCustomEnd!.day,
          );
          return !itemDay.isBefore(start) && !itemDay.isAfter(end);
        default:
          return true;
      }
    }).toList();
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
    if (_ctEnquiryFilter == "Custom Range" &&
        _ctEnquiryCustomStart != null &&
        _ctEnquiryCustomEnd != null) {
      return "${DateFormat('MMM d').format(_ctEnquiryCustomStart!)} – ${DateFormat('MMM d, yyyy').format(_ctEnquiryCustomEnd!)}";
    }
    return _ctEnquiryFilter;
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

  Future<void> _pickCtEnquiryCustomRange() async {
    final DateTimeRange? picked =
        await _pickCtEnquiryCustomCalendarRangePopup();
    if (picked != null) {
      setState(() {
        _ctEnquiryCustomStart = picked.start;
        _ctEnquiryCustomEnd = picked.end;
        _ctEnquiryFilter = "Custom Range";
      });
    }
  }

  Future<DateTimeRange?> _pickCtEnquiryCustomCalendarRangePopup() {
    DateTime tempStart = _ctEnquiryCustomStart ?? DateTime.now();
    DateTime tempEnd = _ctEnquiryCustomEnd ?? tempStart;
    bool selectingStart = true;

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
    final dialogTitleSize = isTablet
        ? 16.0
        : isWideShortPhone
        ? 15.0
        : isCompactPhone
        ? 15.0
        : 16.0;
    final rangeButtonGap = isTablet
        ? 10.0
        : isWideShortPhone
        ? 8.0
        : isCompactPhone
        ? 8.0
        : 10.w;

    return showDialog<DateTimeRange>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final activeDate = selectingStart ? tempStart : tempEnd;
            final dialogWidth =
                calendarMetrics.calendarWidth + (dialogHorizontalPadding * 2);

            return PopScope(
              canPop: true,
              child: Dialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: dialogHorizontalPadding,
                  vertical: dialogVerticalPadding,
                ),
                constraints: BoxConstraints(
                  minWidth: dialogWidth,
                  maxWidth: dialogWidth,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                ),
                backgroundColor: const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 10.r),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: dialogHorizontalPadding,
                    vertical: dialogVerticalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        text: "Select Date Range",
                        size: dialogTitleSize,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: dialogVerticalPadding),
                      Row(
                        children: [
                          Expanded(
                            child: _ctRangeDateButton(
                              label: "Start",
                              date: tempStart,
                              isSelected: selectingStart,
                              onTap: () =>
                                  setDialogState(() => selectingStart = true),
                            ),
                          ),
                          SizedBox(width: rangeButtonGap),
                          Expanded(
                            child: _ctRangeDateButton(
                              label: "End",
                              date: tempEnd,
                              isSelected: !selectingStart,
                              onTap: () =>
                                  setDialogState(() => selectingStart = false),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dialogVerticalPadding),
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
                              onPressed: () =>
                                  Navigator.of(
                                    dialogContext,
                                    rootNavigator: true,
                                  ).pop(
                                    DateTimeRange(
                                      start: tempStart,
                                      end: tempEnd,
                                    ),
                                  ),
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

  Widget _ctRangeDateButton({
    required String label,
    required DateTime date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;
    final horizontalPadding = isTablet
        ? 10.0
        : isWideShortPhone
        ? 8.0
        : isCompactPhone
        ? 8.0
        : 10.w;
    final verticalPadding = isTablet
        ? 9.0
        : isWideShortPhone
        ? 8.0
        : isCompactPhone
        ? 7.0
        : 9.h;
    final radius = isTablet ? 10.0 : 10.r;
    final labelSize = isTablet
        ? 11.0
        : isWideShortPhone
        ? 10.5
        : isCompactPhone
        ? 10.0
        : 11.0;
    final dateSize = isTablet
        ? 12.0
        : isWideShortPhone
        ? 11.0
        : isCompactPhone
        ? 10.5
        : 12.0;
    final textGap = isTablet ? 3.0 : 3.h;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFf87b0d) : Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isSelected ? const Color(0xFFf87b0d) : Colors.black12,
          ),
        ),
        child: Column(
          children: [
            AppText(
              text: label,
              size: labelSize,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor2,
              isCentered: true,
            ),
            SizedBox(height: textGap),
            AppText(
              text: DateFormat('MMM d, yyyy').format(date),
              size: dateSize,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : appTextColor3,
              isCentered: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickCustomCalendarDatePopup(DateTime? selectedDate) {
    DateTime tempDate = selectedDate ?? DateTime.now();
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

    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Keep the calendar dialog as the active pop target so Android's
            // back gesture dismisses it before the page below can handle back.
            final dialogWidth =
                calendarMetrics.calendarWidth + (dialogHorizontalPadding * 2);

            return PopScope(
              canPop: true,
              child: Dialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: dialogHorizontalPadding,
                  vertical: dialogVerticalPadding,
                ),
                constraints: BoxConstraints(
                  minWidth: dialogWidth,
                  maxWidth: dialogWidth,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                ),
                backgroundColor: const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 10.r),
                ),
                child: SingleChildScrollView(
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

  // ── Shared filter option builder ──────────────────────────
  Widget _buildCtFilterOption(
    String label, {
    bool isCustom = false,
    required String currentFilter,
    required DateTime? currentCustomDate,
    required Future<void> Function() onPickDate,
    required void Function(String) onSelect,
  }) {
    final metrics = _CateringInqueryMetrics.fromContext(context);
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
          borderRadius: BorderRadius.circular(metrics.tabRadius),
        ),
        child: AppText(
          text: isCustom
              ? (currentFilter == "Custom" && currentCustomDate != null
                    ? DateFormat('MMM d, yyyy').format(currentCustomDate)
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

  // ── Shared bottom sheet builder ───────────────────────────
  void _showCtFilterSheet({
    required String currentFilter,
    required DateTime? currentCustomDate,
    required Future<void> Function() onPickDate,
    required void Function(String) onSelect,
  }) {
    final metrics = _CateringInqueryMetrics.fromContext(context);

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
      builder: (context) {
        return Padding(
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
              SizedBox(height: metrics.sheetGap),
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    metrics.sheetContainerRadius,
                  ),
                ),
                padding: EdgeInsets.all(metrics.sheetContainerPadding),
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

  // ── Enquiry filter option — All/Today/Last 7/Last 30/Custom Range ────
  Widget _buildCtEnquiryFilterOption(String label, {bool isCustom = false}) {
    final metrics = _CateringInqueryMetrics.fromContext(context);
    final bool isSelected = _ctEnquiryFilter == label;

    return GestureDetector(
      onTap: () async {
        if (isCustom) {
          Navigator.pop(context);
          await _pickCtEnquiryCustomRange();
        } else {
          setState(() {
            _ctEnquiryFilter = label;
            _ctEnquiryCustomStart = null;
            _ctEnquiryCustomEnd = null;
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
          borderRadius: BorderRadius.circular(metrics.tabRadius),
        ),
        child: AppText(
          text: isCustom
              ? (_ctEnquiryFilter == "Custom Range" &&
                        _ctEnquiryCustomStart != null &&
                        _ctEnquiryCustomEnd != null
                    ? "${DateFormat('MMM d').format(_ctEnquiryCustomStart!)} – ${DateFormat('MMM d, yyyy').format(_ctEnquiryCustomEnd!)}"
                    : "Custom Range")
              : label,
          size: metrics.overlayBodySize,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }

  void _showCtEnquiryFilterSheet() {
    final metrics = _CateringInqueryMetrics.fromContext(context);

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        maxWidth: metrics.sheetMaxWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(metrics.sheetTopRadius),
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
              SizedBox(height: metrics.sheetGap),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    metrics.sheetContainerRadius,
                  ),
                ),
                padding: EdgeInsets.all(metrics.sheetContainerPadding),
                child: Column(
                  children: [
                    _buildCtEnquiryFilterOption("All"),
                    Divider(color: Colors.grey[200]),
                    _buildCtEnquiryFilterOption("Today"),
                    Divider(color: Colors.grey[200]),
                    _buildCtEnquiryFilterOption("Last 7 Days"),
                    Divider(color: Colors.grey[200]),
                    _buildCtEnquiryFilterOption("Last 30 Days"),
                    Divider(color: Colors.grey[200]),
                    _buildCtEnquiryFilterOption("Custom Range", isCustom: true),
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
        showErrorSnack(context, 'Review time expired. Please try again.');
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

  /// Set when a refresh arrives while an overlay is open, so the reload can
  /// run once the customer closes it.
  bool _refreshPending = false;

  /// Re-pulls the responses behind this tab. Called by the shell when the
  /// Inquiries badge changes while this tab is open.
  ///
  /// Only the Response tab is reloaded. The other tab is the enquiry form, and
  /// rebuilding it under a half-filled form would throw away what the customer
  /// has typed — nothing there reflects the badge anyway, and switching to
  /// Response fetches on its own.
  ///
  /// A reload underneath an open review/request/search overlay would swap the
  /// data out from under whatever the customer is reading, so it waits for the
  /// overlay to close instead.
  Future<void> refresh() {
    if (selectedStatus != 'Response') return Future<void>.value();
    if (_isAnyOverlayOpen) {
      _refreshPending = true;
      return Future<void>.value();
    }
    return _fetchCtResponses();
  }

  /// Runs a refresh that was held back while an overlay was open.
  void _flushPendingRefresh() {
    if (!_refreshPending || _isAnyOverlayOpen) return;
    _refreshPending = false;
    // The customer may have moved to the form tab while the overlay was up.
    if (selectedStatus != 'Response') return;
    _fetchCtResponses();
  }

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

  String _multilineText(String value) {
    final items = value
        .split(RegExp(r'[,\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return items.isEmpty ? '-' : items.join(', ');
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
    final lat = response.requestLat.trim().isNotEmpty
        ? response.requestLat.trim()
        : enquiry?.lat.trim() ?? '';
    final lng = response.requestLng.trim().isNotEmpty
        ? response.requestLng.trim()
        : enquiry?.lng.trim() ?? '';

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
          _ctPlaceNames[key] = '$lat, $lng';
        }
      } else {
        _ctPlaceNames[key] = '$lat, $lng';
      }
    } catch (_) {
      _ctPlaceNames[key] = '$lat, $lng';
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
    final radius = response?.requestSearchRadius.trim().isNotEmpty == true
        ? response!.requestSearchRadius.trim()
        : enquiry?.searchRadius.trim() ?? '';
    final lat = response?.requestLat.trim().isNotEmpty == true
        ? response!.requestLat.trim()
        : enquiry?.lat.trim() ?? '';
    final lng = response?.requestLng.trim().isNotEmpty == true
        ? response!.requestLng.trim()
        : enquiry?.lng.trim() ?? '';

    final key = '$lat,$lng';
    final placeName =
        (lat.isNotEmpty && lng.isNotEmpty && _ctPlaceNames.containsKey(key))
        ? _ctPlaceNames[key]
        : '';

    if ((placeName == null || placeName.isEmpty) &&
        (lat.isEmpty || lng.isEmpty) &&
        radius.isEmpty)
      return '-';

    if (placeName != null && placeName.isNotEmpty && radius.isNotEmpty) {
      return '$placeName - ${_formatRadiusValue(radius)}km Radius';
    }

    if (placeName != null && placeName.isNotEmpty) return placeName;

    if (lat.isNotEmpty && lng.isNotEmpty && radius.isNotEmpty)
      return '$lat, $lng - ${_formatRadiusValue(radius)}km Radius';

    if (radius.isNotEmpty) return '${_formatRadiusValue(radius)} km Radius';

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

  String _formatRadiusValue(String radius) {
    final parsed = double.tryParse(radius);
    if (parsed == null) return radius;
    return parsed % 1 == 0 ? parsed.toInt().toString() : radius;
  }

  Future<void> _submitCateringEnquiry() async {
    final InqueryService service = InqueryService();
    final model = CreateCateringInqueryModel(
      lat: ctEnquiryData['lat'] ?? '',
      lng: ctEnquiryData['lng'] ?? '',
      menuItems: ctEnquiryData['menu'] ?? '',
      otherServices: ctEnquiryData['otherServices'] ?? '',
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
      showSuccessSnack(context, 'Enquiry submitted successfully!');
    } else {
      showErrorSnack(context, response.message);
    }
  }

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
    final metrics = _CateringInqueryMetrics.fromContext(context);

    return PopScope(
      canPop: !_isAnyOverlayOpen && selectedStatus == 'Book a Catering',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_isAnyOverlayOpen) {
          _closeTopOverlay();
        } else if (selectedStatus == 'Response') {
          _selectStatus('Book a Catering');
        }
      },
      child: Scaffold(
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
                Center(
                  child: SizedBox(
                    width: metrics.contentWidth,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(metrics.pagePadding),
                          child: Column(
                            children: [
                              SizedBox(
                                height: metrics.tabHeight,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return _buildAnimatedStatusTabs(
                                      width: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: metrics.headerBottomGap),
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
                  ),
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
    final metrics = _CateringInqueryMetrics.fromContext(context);
    final results = _filteredCtSearchResponses;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: metrics.subviewHorizontalPadding,
            right: metrics.subviewHorizontalPadding,
            top: metrics.subviewTopPadding,
          ),
          child: Row(children: [Expanded(child: _ctSearchInputField())]),
        ),

        SizedBox(height: metrics.actionGap),

        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: metrics.filterDropdownMinWidth,
            maxWidth: metrics.filterDropdownMaxWidth,
          ),
          child: IntrinsicWidth(
            child: AppFilterDropDown(
              height: metrics.filterHeight,
              hint: _ctSearchFilterLabel,
              imageIconPath: filterIcon,
              imageIconSize: metrics.filterIconSize,
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
        ),

        SizedBox(height: metrics.subviewGap),

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
                        size: metrics.emptyIconSize,
                        color: appTextColor3.withValues(alpha: 0.4),
                      ),
                      SizedBox(height: metrics.emptyGap),
                      AppText(
                        text: _ctSearchQuery.isNotEmpty
                            ? 'No results for "$_ctSearchQuery"'
                            : "No responses for $_ctSearchFilterLabel",
                        size: metrics.emptyTextSize,
                        fontWeight: FontWeight.w500,
                        color: appTextColor3,
                        isCentered: true,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
                  physics: const BouncingScrollPhysics(),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: metrics.subviewHorizontalPadding,
                        right: metrics.subviewHorizontalPadding,
                      ),
                      child: CtResponseBox(
                        response: results[index],
                        viewRequestClick: () =>
                            _openCtRequestDetails(results[index]),
                        onAcceptTap: () {
                          setState(() {
                            _pendingCtResponseUuid = results[index].uuid;
                            _pendingCtRestaurantName =
                                results[index].restaurantName;
                            isResponseAcceptConfirmOnClick = true;
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
    final metrics = _CateringInqueryMetrics.fromContext(context);

    if (!_isCtSearchActive) {
      return GestureDetector(
        onTap: () => setState(() => _isCtSearchActive = true),
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
              text: "Search by coupon code or restaurant name",
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
              _ctSearchController.clear();
              _ctSearchDebounceTimer?.cancel();

              setState(() {
                _isCtSearchActive = false;
                _ctSearchQuery = "";
              });

              _fetchCtResponses();
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
              text: "Search by coupon code or restaurant name",
              controller: _ctSearchController,
              backgroundColor: Colors.white,
              height: metrics.searchHeight,
              fieldBorderRadius: metrics.searchActiveRadius,
              textColor: appTextColor5,
              size: metrics.searchTextSize,
              boxShadow: const [],
              onChanged: (val) {
                _queueCtSearch(val);
              },
              inputContentPadding: EdgeInsets.symmetric(
                vertical: metrics.searchVerticalPadding,
                horizontal: metrics.searchFieldHorizontalPadding,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Search by coupon code",
                hintStyle: TextStyle(
                  fontSize: metrics.searchTextSize,
                  color: appTextColor3,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: metrics.searchVerticalPadding,
                  horizontal: metrics.searchFieldHorizontalPadding,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewCtDeclineWidget() {
    final metrics = _CateringInqueryMetrics.fromContext(context);
    final declined = _filteredCtDeclinedResponses;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: metrics.subviewHorizontalPadding,
                right: metrics.subviewHorizontalPadding,
                top: metrics.subviewTopPadding,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                      () => viewCtDeclineOnClick = !viewCtDeclineOnClick,
                    ),
                    child: Image.asset(
                      backOrange,
                      height: metrics.backIconSize,
                      width: metrics.backIconSize,
                    ),
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
                            hint: _ctDeclineFilterLabel,
                            imageIconPath: filterIcon,
                            imageIconSize: metrics.filterIconSize,
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
                  ),
                  SizedBox(width: metrics.backIconSize),
                ],
              ),
            ),
            SizedBox(height: metrics.subviewGap),
            Expanded(
              child: RefreshIndicator(
                color: appButtonColor,
                onRefresh: _fetchCtDeclinedResponses,
                child: _ctResponsesLoading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(height: metrics.loadingTopHeight),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : _ctResponsesError.isNotEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(height: metrics.loadingTopHeight),
                          Center(
                            child: AppText(
                              text: _ctResponsesError,
                              size: metrics.emptyTextSize,
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
                          SizedBox(height: metrics.loadingTopHeight),
                          Center(
                            child: AppText(
                              text:
                                  "No declined responses for $_ctDeclineFilterLabel",
                              size: metrics.emptyTextSize,
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
                            padding: EdgeInsets.only(
                              left: metrics.subviewHorizontalPadding,
                              right: metrics.subviewHorizontalPadding,
                            ),
                            child: CtDeclineBox(
                              response: declined[index],
                              onCancelTap: () async {
                                final resp = await InqueryService()
                                    .deleteDeclinedCateringEnquiryResponse(
                                      declined[index].uuid,
                                    );
                                if (!mounted) return;
                                showErrorSnack(context, resp['message'] ?? '');
                                await _fetchCtDeclinedResponses();
                              },
                              onRestoreTap: () async {
                                final resp = await InqueryService()
                                    .restoreCateringEnquiryResponse(
                                      declined[index].uuid,
                                    );
                                if (!mounted) return;
                                showErrorSnack(context, resp['message'] ?? '');
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
    final metrics = _CateringInqueryMetrics.fromContext(context);
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
    final peopleLabel = people == 0
        ? '-'
        : people == 1
        ? '1 Person'
        : '$people Persons';

    return _tabPopupShell(
      onDismiss: () => setState(() {
        viewCtRequest = false;
        _selectedCtResponse = null;
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: "Requested Catering",
                size: metrics.overlayHeaderSize,
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
                  size: metrics.overlayCloseIconSize,
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.overlayRowGap),
          Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              text: requestId,
              size: metrics.overlayTitleSize,
              fontWeight: FontWeight.w700,
              color: appTextColor3,
            ),
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            menuIcon,
            "Your Menu",
            _multilineText(menuItems),
            maxLines: 20,
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            handshakeIcon,
            "Other Services",
            _multilineText(otherServices),
            maxLines: 20,
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(peopleIcon, "Number of Persons", peopleLabel),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            calenderIcon,
            "Date and Time",
            _ctRequestDateTime(response, enquiry),
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            walletIcon,
            "Expected amount per person",
            _ctRequestAmount(response, enquiry),
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            radiusIcon,
            "Enquiry Radius",
            _ctRequestRadius(response, enquiry),
          ),
          SizedBox(height: metrics.overlayRowGap),
        ],
      ),
    );
  }

  Widget _tabPopupShell({
    required Widget child,
    bool scrollable = false,
    VoidCallback? onDismiss,
  }) {
    final metrics = _CateringInqueryMetrics.fromContext(context);
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

  Widget _ctResponseWidget() {
    final metrics = _CateringInqueryMetrics.fromContext(context);
    final responses = _filteredCtResponses;

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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: metrics.filterDropdownMinWidth,
                      maxWidth: metrics.filterDropdownMaxWidth,
                    ),
                    child: IntrinsicWidth(
                      child: AppFilterDropDown(
                        height: metrics.filterHeight,
                        hint: _ctResponseFilterLabel,
                        imageIconPath: filterIcon,
                        imageIconSize: metrics.filterIconSize,
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
              ),
              SizedBox(width: metrics.actionGap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isCtSearchOnClick = true),
                    child: Row(
                      children: [
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
                      setState(() => viewCtDeclineOnClick = true);
                      _fetchCtDeclinedResponses();
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
          child: _ctResponsesLoading
              ? const Center(child: CircularProgressIndicator())
              : _ctResponsesError.isNotEmpty
              ? Center(
                  child: AppText(
                    text: _ctResponsesError,
                    size: metrics.emptyTextSize,
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
                        size: metrics.emptyIconSize,
                        color: appTextColor3.withValues(alpha: 0.4),
                      ),
                      SizedBox(height: metrics.emptyGap),
                      AppText(
                        text: "No responses for $_ctResponseFilterLabel",
                        size: metrics.emptyTextSize,
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
                    padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
                    physics: const BouncingScrollPhysics(),
                    itemCount: responses.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.subviewHorizontalPadding,
                      ),
                      child: CtResponseBox(
                        response: responses[index],
                        viewRequestClick: () =>
                            _openCtRequestDetails(responses[index]),
                        onAcceptTap: () {
                          setState(() {
                            _pendingCtResponseUuid = responses[index].uuid;
                            _pendingCtRestaurantName =
                                responses[index].restaurantName;
                            isResponseAcceptConfirmOnClick = true;
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
    final metrics = _CateringInqueryMetrics.fromContext(context);
    final enquiries = _filteredCtEnquiries;

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
              GestureDetector(
                onTap: () => setState(() => viewCtEnquiryOnClick = false),
                child: Image.asset(
                  backOrange,
                  width: metrics.backIconSize,
                  height: metrics.backIconSize,
                ),
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
                        hint: _ctEnquiryFilterLabel,
                        imageIconPath: filterIcon,
                        imageIconSize: metrics.filterIconSize,
                        toggleDropdown: _showCtEnquiryFilterSheet,
                      ),
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
          child: _ctEnquiriesLoading
              ? const Center(child: CircularProgressIndicator())
              : enquiries.isEmpty
              ? Center(
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
                        text: _ctEnquiries.isEmpty
                            ? "No enquiries found"
                            : "No enquiries for $_ctEnquiryFilterLabel",
                        size: metrics.emptyTextSize,
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
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
                    itemCount: enquiries.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: metrics.subviewHorizontalPadding,
                          right: metrics.subviewHorizontalPadding,
                          bottom: index == enquiries.length - 1
                              ? metrics.listBottomPadding
                              : metrics.actionGap,
                        ),
                        child: CtInqueryBox(
                          enquiry: enquiries[index],
                          onCancelTap: () async {
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
    final metrics = _CateringInqueryMetrics.fromContext(context);

    return _tabPopupShell(
      onDismiss: () {
        _stopCtTimer();
        setState(() => isCtReviewOnClick = false);
      },
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: "C17854",
                size: metrics.overlayTitleSize,
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
                  size: metrics.overlayBodySize,
                  fontWeight: FontWeight.w700,
                  color: appLinkColor,
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            menuIcon,
            "Your Menu",
            (ctEnquiryData['menu'] ?? '')
                .split(RegExp(r'[,\n]'))
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .join(', '),
            maxLines: 20,
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            handshakeIcon,
            "Other Services",
            (ctEnquiryData['otherServices'] ?? '')
                .split(RegExp(r'[,\n]'))
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .join(', '),
            maxLines: 20,
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            peopleIcon,
            "Number of Persons",
            "${ctEnquiryData['people'] ?? ''} Person",
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            calenderIcon,
            "Date and Time",
            _formatReviewDateTime(ctEnquiryData['dateTime'] ?? ''),
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            walletIcon,
            "Expected amount per person",
            "${ctEnquiryData['amount'] ?? ''} Per person",
          ),
          SizedBox(height: metrics.overlayRowGap),
          _reviewRow(
            radiusIcon,
            "Enquiry Radius",
            ctEnquiryData['location'] ?? '',
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
                text: _ctTimerText,
                size: 10,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFED4444),
              ),
            ],
          ),
          SizedBox(height: metrics.overlaySmallGap),
          SizedBox(
            width: metrics.overlayButtonWidth,
            height: metrics.overlayButtonHeight,
            child: AppButton(
              text: "Send",
              isLoading: _isCateringSubmitLoading,
              onPressed: () async {
                if (_isCateringSubmitLoading) return;
                setState(() => _isCateringSubmitLoading = true);
                _stopCtTimer();
                try {
                  await _submitCateringEnquiry();
                } finally {
                  if (mounted) {
                    setState(() => _isCateringSubmitLoading = false);
                  }
                }
              },
              size: metrics.overlayButtonTextSize,
              bgColor1: Colors.green,
              bgColor2: Colors.green,
              borderRadius: metrics.tabRadius,
            ),
          ),
        ],
      ),
    );
  }

  // helper widget for each row
  String _formatReviewDateTime(String raw) {
    if (raw.trim().isEmpty) return '';
    final parts = raw.trim().split(' ');
    try {
      final date = DateFormat('yyyy-MM-dd').parseStrict(parts.first);
      final rest = parts.skip(1).join(' ');
      final formatted = DateFormat('d MMM yyyy').format(date);
      return rest.isEmpty ? formatted : '$formatted $rest';
    } catch (_) {
      return raw;
    }
  }

  Widget _reviewRow(String icon, String label, String value, {int? maxLines}) {
    final metrics = _CateringInqueryMetrics.fromContext(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          icon,
          width: metrics.reviewIconSize,
          height: metrics.reviewIconSize,
          color: appTextColor2,
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
                maxLines: maxLines,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _responseAcceptConfirmBox() {
    final metrics = _CateringInqueryMetrics.fromContext(context);

    return _tabPopupShell(
      onDismiss: () => setState(() {
        isConfirmClicked = false;
        isResponseAcceptConfirmOnClick = false;
      }),
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
                  "After confirmation, your catering order will be booked at $_pendingCtRestaurantName.",
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
                  if (_pendingCtResponseUuid.isEmpty) return;

                  final result = await InqueryService().confirmCateringEnquiry(
                    _pendingCtResponseUuid,
                  );
                  if (!mounted) return;

                  if (result['status'] == true) {
                    setState(() => isConfirmClicked = true);
                    await _fetchCtResponses();
                    await _fetchCtDeclinedResponses();
                    _autoCloseCtConfirmBox();
                  } else {
                    showErrorSnack(
                      context,
                      result['message'] ?? 'Confirmation failed',
                    );
                  }
                },
                bgColor1: Color(0xFF73B256),
                bgColor2: Color(0xFF73B256),
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
    final metrics = _CateringInqueryMetrics.fromContext(context);

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
            text: "Switch Catering Booking?",
            isCentered: true,
            lineSpacing: 1.5,
            size: metrics.overlayBodySize,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD34545),
          ),
          SizedBox(height: metrics.overlaySmallGap),
          AppText(
            softWrap: true,
            text:
                "You already have a catering booked at $_pendingCtRestaurantName. Booking another catering will automatically cancel your previous booking.",
            isCentered: true,
            maxLines: 4,
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
                  color: Color(0xFF3954DB),
                ),
              ),
              SizedBox(
                width: metrics.overlayButtonWidth,
                height: metrics.overlayButtonHeight,
                child: AppButton(
                  text: "Yes, Book",
                  onPressed: () {
                    setState(() {
                      isResponseAcceptOnClick = false;
                      isResponseAcceptConfirmOnClick = true;
                    });
                  },
                  size: metrics.overlayButtonTextSize,
                  bgColor1: Color(0XFF73B256),
                  bgColor2: Color(0XFF73B256),
                  borderRadius: metrics.tabRadius,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectStatus(String text) {
    if (selectedStatus == text) return;

    setState(() {
      _previousStatus = selectedStatus;
      selectedStatus = text;
    });

    // Opening the tab pulls current data, which is also what makes it safe for
    // refresh() to skip while the form tab is showing.
    if (text == "Response") _fetchCtResponses();
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
    final metrics = _CateringInqueryMetrics.fromContext(context);
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
    final metrics = _CateringInqueryMetrics.fromContext(context);
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
            child: TranslatedBuilder(
              text: text,
              builder: (context, label) => Text(
                label,
                style: TextStyle(
                  fontSize: metrics.tabTextSize,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : appTextColor3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Rect _statusTabRect(String text, {required double width}) {
    final metrics = _CateringInqueryMetrics.fromContext(context);
    final double gap = metrics.tabGap;
    final double tabHeight = metrics.tabHeight;
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

class _CateringInqueryMetrics {
  const _CateringInqueryMetrics({
    required this.contentWidth,
    required this.pagePadding,
    required this.headerBottomGap,
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
    required this.filterDropdownMinWidth,
    required this.filterDropdownMaxWidth,
    required this.sheetPadding,
    required this.sheetMaxWidth,
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
  final double headerBottomGap;
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
  final double filterDropdownMinWidth;
  final double filterDropdownMaxWidth;
  final double sheetPadding;
  final double sheetMaxWidth;
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

  factory _CateringInqueryMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final contentWidth = (size.width * 0.82).clamp(700.0, 980.0).toDouble();
      final scale = (contentWidth / 760).clamp(1.0, 1.14).toDouble();
      double s(double value) => value * scale;

      return _CateringInqueryMetrics(
        contentWidth: double.infinity,
        pagePadding: s(28),
        headerBottomGap: 0,
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
        filterDropdownMinWidth: s(132),
        filterDropdownMaxWidth: s(220),
        sheetPadding: s(36),
        sheetMaxWidth: 480,
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
      return const _CateringInqueryMetrics(
        contentWidth: double.infinity,
        pagePadding: 24,
        headerBottomGap: 0,
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
        filterDropdownMinWidth: 120,
        filterDropdownMaxWidth: 190,
        sheetPadding: 26,
        sheetMaxWidth: 420,
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

      return _CateringInqueryMetrics(
        contentWidth: double.infinity,
        pagePadding: s(16),
        headerBottomGap: 0,
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
        filterDropdownMinWidth: s(108),
        filterDropdownMaxWidth: s(172),
        sheetPadding: s(22),
        sheetMaxWidth: 420,
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

    return _CateringInqueryMetrics(
      contentWidth: double.infinity,
      pagePadding: 20.w,
      headerBottomGap: 0,
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
      filterDropdownMinWidth: 120.w,
      filterDropdownMaxWidth: 190.w,
      sheetPadding: 30.w,
      sheetMaxWidth: 440.w,
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
      reviewIconSize: 20.w,
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
