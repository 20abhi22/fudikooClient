import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/banquet/banquet_reservation_modal.dart';
import 'package:fudikoclient/screens/catering_tabs/reservation/catering_reservation_box.dart';
import 'package:fudikoclient/service/inquery/catering_reservation_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class CancelCircleX extends StatefulWidget {
  const CancelCircleX({
    super.key,
    this.size = 96,
    this.autoPlay = true,
    this.onCompleted,
  });

  final double size;
  final bool autoPlay;
  final VoidCallback? onCompleted;

  @override
  State<CancelCircleX> createState() => CancelCircleXState();
}

class CancelCircleXState extends State<CancelCircleX>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScale;
  late final Animation<double> _circleOpacity;
  late final Animation<double> _line1Progress;
  late final Animation<double> _line2Progress;

  static const _totalDuration = Duration(milliseconds: 1700);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration);

    _circleScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.0,
              end: 1.08,
            ).chain(CurveTween(curve: Curves.easeOut)),
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
            curve: const Interval(0.0, 750 / 1700),
          ),
        );

    _circleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 150 / 1700, curve: Curves.easeOut),
    );

    _line1Progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(1250 / 1700, 1450 / 1700, curve: Curves.easeOut),
    );

    _line2Progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(1430 / 1700, 1650 / 1700, curve: Curves.easeOut),
    );

    if (widget.autoPlay) {
      _controller.forward();
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
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
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CancelCirclePainter(
              circleScale: _circleScale.value,
              circleOpacity: _circleOpacity.value,
              line1Progress: _line1Progress.value,
              line2Progress: _line2Progress.value,
            ),
          );
        },
      ),
    );
  }
}

class _CancelCirclePainter extends CustomPainter {
  _CancelCirclePainter({
    required this.circleScale,
    required this.circleOpacity,
    required this.line1Progress,
    required this.line2Progress,
  });

  final double circleScale;
  final double circleOpacity;
  final double line1Progress;
  final double line2Progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.49;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(circleScale);
    canvas.translate(-center.dx, -center.dy);

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFF5B55).withValues(alpha: circleOpacity),
          const Color(0xFFE33636).withValues(alpha: circleOpacity),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, gradientPaint);

    canvas.restore();

    final iconRect = Rect.fromCenter(
      center: center,
      width: radius * 2 * 0.84,
      height: radius * 2 * 0.84,
    );

    Offset lerp(Offset a, Offset b, Rect r) =>
        Offset(r.left + a.dx * r.width, r.top + a.dy * r.height);

    const start = 0.28;
    const end = 0.72;

    final line1Start = lerp(const Offset(start, start), Offset.zero, iconRect);
    final line1End = lerp(const Offset(end, end), Offset.zero, iconRect);
    final line2Start = lerp(const Offset(end, start), Offset.zero, iconRect);
    final line2End = lerp(const Offset(start, end), Offset.zero, iconRect);

    final strokeWidth = radius * 2 * 0.22;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    Path? progressiveLinePath(Offset from, Offset to, double t) {
      if (t <= 0) return null;
      final full = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
      final metric = full.computeMetrics().first;
      return metric.extractPath(0, metric.length * t.clamp(0.0, 1.0));
    }

    void drawLineShadow(Path? partial) {
      if (partial == null) return;
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawPath(
        partial.shift(Offset(radius * 0.20, radius * 0.20)),
        Paint()
          ..color = const Color(0xFF990000).withValues(alpha: 0.34)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
      );
      canvas.restore();
    }

    void drawLine(Path? partial) {
      if (partial == null) return;
      canvas.drawPath(partial, strokePaint);
    }

    final line1Path = progressiveLinePath(line1Start, line1End, line1Progress);
    final line2Path = progressiveLinePath(line2Start, line2End, line2Progress);

    drawLineShadow(line1Path);
    drawLineShadow(line2Path);
    drawLine(line1Path);
    drawLine(line2Path);
  }

  @override
  bool shouldRepaint(covariant _CancelCirclePainter oldDelegate) {
    return oldDelegate.circleScale != circleScale ||
        oldDelegate.circleOpacity != circleOpacity ||
        oldDelegate.line1Progress != line1Progress ||
        oldDelegate.line2Progress != line2Progress;
  }
}

class CateringReservation extends StatefulWidget {
  const CateringReservation({super.key});

  @override
  State<CateringReservation> createState() => CateringReservationState();
}

class CateringReservationState extends State<CateringReservation> {
  // ── Overlay visibility flags ─────────────────────────────────────────────
  bool isDeletePressed = false;
  bool isConfirmedPressed = false;
  bool isBookingCanceled = false;
  bool isSearchDeletePressed = false;
  bool isPartyRequestPressed = false;
  bool isCateringRequestPressed = false;

  // ── Selection state ──────────────────────────────────────────────────────
  String selectedStatus = "Entered the wrong details";
  String mainSelectedStatus = "Party";
  String selectedFilter = "All Bookings";
  final List<String> _cancelReasons = const [
    "I changed my mind",
    "I need to reschedule the event",
    "Entered the wrong details",
    "I booked by mistake",
    "Other Reasons",
  ];

  // ── Loading / error / search state ──────────────────────────────────────
  bool _isLoadingReservations = false;
  bool _isReservationSearchActive = false;
  bool _isSearchingReservations = false;
  bool _isCancellingReservation = false;
  String _reservationError = '';
  String _reservationSearchError = '';
  String _selectedReservationId = '';
  BanquetReservationModal? _selectedRequestReservation;
  int _reservationSearchRequestId = 0;

  // ── Data lists ───────────────────────────────────────────────────────────
  List<BanquetReservationModal> _reservations = [];
  List<BanquetReservationModal> _searchedReservations = [];
  final Map<String, String> _reservationPlaceNames = {};

  // ── Controllers & focus nodes ────────────────────────────────────────────
  final TextEditingController _reservationSearchController =
      TextEditingController();
  final TextEditingController _acceptAnotherReasonController =
      TextEditingController();
  final FocusNode _reservationSearchFocusNode = FocusNode();

  // ── Computed getters ─────────────────────────────────────────────────────

  List<BanquetReservationModal> get _filteredBookings {
    final source = _isReservationSearchActive
        ? _searchedReservations
        : _reservations;
    List<BanquetReservationModal> result = selectedFilter == "All Bookings"
        ? List.from(source)
        : source.where((b) => b.status == selectedFilter).toList();
    result.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return result;
  }

  bool get _isActiveListLoading => _isReservationSearchActive
      ? _isSearchingReservations
      : _isLoadingReservations;

  String get _activeListError =>
      _isReservationSearchActive ? _reservationSearchError : _reservationError;

  String get _emptyListText {
    if (_isReservationSearchActive &&
        _reservationSearchController.text.trim().isEmpty) {
      return "Type a coupon number";
    }
    return "No bookings found";
  }

  bool get _isAnyOverlayOpen =>
      isDeletePressed ||
      isSearchDeletePressed ||
      isPartyRequestPressed ||
      isCateringRequestPressed ||
      isConfirmedPressed ||
      isBookingCanceled;

  void _closeAllOverlays() {
    setState(() {
      isDeletePressed = false;
      isSearchDeletePressed = false;
      isPartyRequestPressed = false;
      isCateringRequestPressed = false;
      isConfirmedPressed = false;
      isBookingCanceled = false;
      _selectedReservationId = '';
      _selectedRequestReservation = null;
    });
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  @override
  void dispose() {
    _reservationSearchRequestId++;
    _reservationSearchController.dispose();
    _acceptAnotherReasonController.dispose();
    _reservationSearchFocusNode.dispose();
    super.dispose();
  }

  // ── API calls ────────────────────────────────────────────────────────────

  Future<void> refreshReservations() {
    if (_isReservationSearchActive) {
      return _searchReservations(_reservationSearchController.text);
    }
    return _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    setState(() {
      _isLoadingReservations = true;
      _reservationError = '';
    });

    final result = await CateringReservationService().fetchReservations();

    if (!mounted) return;
    setState(() {
      _reservations = result.reservations;
      _isLoadingReservations = false;
      _reservationError = result.status
          ? ''
          : result.message.isEmpty
          ? 'Unable to fetch bookings right now.'
          : result.message;
    });
  }

  Future<void> _cancelSelectedReservation() async {
    if (_isCancellingReservation) return;

    setState(() {
      _isCancellingReservation = true;
      isDeletePressed = false;
      isSearchDeletePressed = false;
      isConfirmedPressed = false;
    });

    final result = await CateringReservationService().cancelReservation(
      _selectedReservationId,
    );

    if (!mounted) return;

    final bool isSuccess = result['status'] == true;
    final String message = (result['message'] ?? '').toString().isEmpty
        ? (isSuccess ? 'Reservation cancelled successfully' : 'Cancel failed')
        : result['message'].toString();

    setState(() {
      _isCancellingReservation = false;
      isSearchDeletePressed = false;
      isDeletePressed = false;
      isConfirmedPressed = false;
      if (isSuccess) {
        isBookingCanceled = true;
        _selectedReservationId = '';
      }
    });

    showStatusSnack(context, isSuccess, message);

    if (isSuccess) {
      await _fetchReservations();
      if (_isReservationSearchActive) {
        await _searchReservations(_reservationSearchController.text);
      }
    }
  }

  Future<void> _searchReservations(String value) async {
    final query = value.trim();
    final requestId = ++_reservationSearchRequestId;

    if (query.isEmpty) {
      setState(() {
        _isSearchingReservations = false;
        _reservationSearchError = '';
        _searchedReservations = [];
      });
      return;
    }

    setState(() {
      _isSearchingReservations = true;
      _reservationSearchError = '';
    });

    final result = await CateringReservationService().searchReservations(query);

    if (!mounted || requestId != _reservationSearchRequestId) return;

    setState(() {
      _searchedReservations = result.reservations;
      _isSearchingReservations = false;
      _reservationSearchError = result.status
          ? ''
          : result.message.isEmpty
          ? 'Unable to search bookings right now.'
          : result.message;
    });
  }

  Future<void> _retryActiveListRequest() {
    if (_isReservationSearchActive) {
      return _searchReservations(_reservationSearchController.text);
    }
    return _fetchReservations();
  }

  // ── Search helpers ───────────────────────────────────────────────────────

  void _activateReservationSearch() {
    if (!_isReservationSearchActive) {
      setState(() {
        _isReservationSearchActive = true;
        _reservationSearchError = '';
      });
    }
    _reservationSearchFocusNode.requestFocus();
  }

  void _exitReservationSearch() {
    _reservationSearchRequestId++;
    _reservationSearchFocusNode.unfocus();
    setState(() {
      _isReservationSearchActive = false;
      _isSearchingReservations = false;
      _reservationSearchError = '';
      _searchedReservations = [];
      _reservationSearchController.clear();
    });
  }

  void _onReservationSearchChanged(String value) {
    if (!_isReservationSearchActive) {
      setState(() => _isReservationSearchActive = true);
    }
    _searchReservations(value);
  }

  void _dismissSearchKeyboard() {
    if (_reservationSearchFocusNode.hasFocus) {
      _reservationSearchFocusNode.unfocus();
    }
    FocusScope.of(context).unfocus();
  }

  // ── Dialog helpers ───────────────────────────────────────────────────────

  void _showAcceptAnotherReasonPopup() {
    _dismissSearchKeyboard();
    final metrics = _CateringReservationMetrics.fromContext(context);
    _acceptAnotherReasonController.text = selectedStatus == "Other Reasons"
        ? ''
        : selectedStatus;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: metrics.popupHorizontalPadding,
            vertical: metrics.popupVerticalPadding,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metrics.popupRadius),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: metrics.popupMaxWidth,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.popupContentHorizontalPadding,
                vertical: metrics.popupContentVerticalPadding,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            text: "Reason for accepting another response",
                            size: metrics.popupBodyTextSize,
                            fontWeight: FontWeight.w600,
                            color: appTextColor3,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          child: Icon(
                            Icons.close,
                            size: metrics.popupCloseIconSize,
                            color: appTextColor3,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.popupRowGap),
                    TranslatedBuilder(
                      text: "Type your reason",
                      builder: (context, translatedHint) => TextField(
                        controller: _acceptAnotherReasonController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: translatedHint,
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: metrics.reasonFieldHorizontalPadding,
                            vertical: metrics.reasonFieldVerticalPadding,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              metrics.reasonFieldRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: metrics.popupRowGap),
                    SizedBox(
                      width: double.infinity,
                      height: metrics.popupButtonHeight,
                      child: AppButton(
                        text: "Submit",
                        bgColor1: appButtonColor,
                        bgColor2: appButtonColor,
                        size: metrics.popupButtonTextSize,
                        borderRadius: metrics.popupButtonRadius,
                        onPressed: () {
                          final reason = _acceptAnotherReasonController.text
                              .trim();
                          if (reason.isEmpty) {
                            showErrorSnack(context, "Please type a reason");
                            return;
                          }
                          setState(() => selectedStatus = reason);
                          Navigator.pop(dialogContext);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isAnyOverlayOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isAnyOverlayOpen) {
          _closeAllOverlays();
        }
      },
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Main scrollable content ──────────────────────────────────
              RefreshIndicator(
                color: appButtonColor,
                onRefresh: _fetchReservations,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _buildMainContent(),
                ),
              ),

              // ── Overlays ─────────────────────────────────────────────────
              if (isSearchDeletePressed || isDeletePressed)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _isCancellingReservation
                        ? null
                        : () {
                            setState(() {
                              isSearchDeletePressed = false;
                              isDeletePressed = false;
                              _selectedReservationId = '';
                            });
                          },
                    child: Container(
                      color: Colors.black54,
                      child: _cancelReasonSheet(),
                    ),
                  ),
                ),

              // if (isPartyRequestPressed)
              //   Positioned.fill(
              //     child: GestureDetector(
              //       behavior: HitTestBehavior.opaque,
              //       onTap: () => setState(() => isPartyRequestPressed = false),
              //       child: Container(
              //         color: Colors.black54,
              //         child: _viewPartyRequestWidget(),
              //       ),
              //     ),
              //   ),
              if (isCateringRequestPressed)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      isCateringRequestPressed = false;
                      _selectedRequestReservation = null;
                    }),
                    child: Container(
                      color: Colors.black54,
                      child: _viewCateringRequestWidget(),
                    ),
                  ),
                ),

              if (isConfirmedPressed)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: _confirmedBox(),
                  ),
                ),

              if (isBookingCanceled)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: _bookingCanceledBox(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // MAIN CONTENT
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMainContent() {
    final metrics = _CateringReservationMetrics.fromContext(context);

    return Column(
      children: [
        // ── Search bar ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(
            left: metrics.contentHorizontalPadding,
            right: metrics.contentHorizontalPadding,
            top: metrics.contentTopPadding,
          ),
          child: AppTextFeild(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 0),
                blurRadius: metrics.searchShadowBlur,
                spreadRadius: metrics.searchShadowSpread,
              ),
            ],
            controller: _reservationSearchController,
            focusNode: _reservationSearchFocusNode,
            text: "Enter the Coupon Number",
            textColor: appTextColor3,
            isTextCenter: true,
            icon: _isReservationSearchActive ? Icons.close : null,
            iconColor: appTextColor3,
            size: metrics.searchTextSize,
            onboxTap: _activateReservationSearch,
            iconOnTap: _isReservationSearchActive
                ? _exitReservationSearch
                : null,
            onChanged: _onReservationSearchChanged,
            fieldBorderRadius: metrics.searchRadius,
          ),
        ),
        SizedBox(height: metrics.sectionGap),

        // ── Filter dropdown ──────────────────────────────────────────
        SizedBox(
          width: metrics.filterWidth,
          child: AppFilterDropDown(
            height: metrics.filterHeight,
            hint: selectedFilter,
            imageIconPath: filterIcon,
            imageIconSize: metrics.filterIconSize,
            textSize: metrics.filterTextSize,
            toggleDropdown: _showFilterBottomSheet,
          ),
        ),
        SizedBox(height: metrics.sectionGap),

        // ── Booking list / states ────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.contentHorizontalPadding,
          ),
          child: _buildListSection(),
        ),

        SizedBox(height: metrics.bottomGap),
      ],
    );
  }

  Widget _buildListSection() {
    final metrics = _CateringReservationMetrics.fromContext(context);

    if (_isActiveListLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: metrics.stateVerticalPadding),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeListError.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: metrics.stateVerticalPadding),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: _activeListError,
                size: metrics.stateTextSize,
                fontWeight: FontWeight.w500,
                color: appTextColor3,
                isCentered: true,
              ),
              SizedBox(height: metrics.stateGap),
              SizedBox(
                width: metrics.retryButtonWidth,
                height: metrics.retryButtonHeight,
                child: AppButton(
                  text: "Retry",
                  size: metrics.retryButtonTextSize,
                  borderRadius: metrics.retryButtonRadius,
                  onPressed: _retryActiveListRequest,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredBookings.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: metrics.stateVerticalPadding),
        child: Center(
          child: AppText(
            text: _emptyListText,
            size: metrics.stateTextSize,
            fontWeight: FontWeight.w500,
            color: appTextColor3,
            isCentered: true,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredBookings.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final booking = _filteredBookings[index];
        return CateringReservationBox(
          reservation: booking,
          onCancelTap: () {
            _dismissSearchKeyboard();
            setState(() {
              _selectedReservationId = booking.uuid;
              isSearchDeletePressed = true;
            });
          },
          onRequestTap: () {
            _dismissSearchKeyboard();
            _openCateringRequest(booking);
          },
          onCouponClosed: refreshReservations,
        );
      },
    );
  }

  Future<void> _openCateringRequest(BanquetReservationModal reservation) async {
    setState(() {
      _selectedRequestReservation = reservation;
      isCateringRequestPressed = true;
    });

    await _ensurePlaceNameFor(reservation);
  }

  Future<void> _ensurePlaceNameFor(BanquetReservationModal? reservation) async {
    if (reservation == null) return;

    final lat = reservation.lat.trim();
    final lng = reservation.lng.trim();
    if (lat.isEmpty || lng.isEmpty) return;

    final key = '$lat,$lng';
    if (_reservationPlaceNames.containsKey(key)) return;

    try {
      final latValue = double.parse(lat);
      final lngValue = double.parse(lng);
      final placemarks = await placemarkFromCoordinates(latValue, lngValue);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final name = [
          place.subLocality,
          place.locality,
          place.country,
        ].where((part) => part != null && part.isNotEmpty).join(', ');
        _reservationPlaceNames[key] = name.isNotEmpty ? name : '$lat, $lng';
      } else {
        _reservationPlaceNames[key] = '$lat, $lng';
      }
    } catch (_) {
      _reservationPlaceNames[key] = '$lat, $lng';
    }

    if (!mounted) return;
    setState(() {});
  }

  // ════════════════════════════════════════════════════════════════════════
  // FILTER BOTTOM SHEET
  // ════════════════════════════════════════════════════════════════════════

  void _showFilterBottomSheet() {
    _dismissSearchKeyboard();
    final metrics = _CateringReservationMetrics.fromContext(context);

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
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
                    _buildFilterOption("All Bookings"),
                    Divider(color: Colors.grey[200]),
                    _buildFilterOption("Confirmed"),
                    Divider(color: Colors.grey[200]),
                    _buildFilterOption("Cancelled"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label) {
    final metrics = _CateringReservationMetrics.fromContext(context);
    final bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = label);
        Navigator.pop(context);
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
          text: label,
          size: metrics.filterOptionTextSize,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CANCEL REASON SHEET  (fixed: Cancel button pinned outside scroll)
  // ════════════════════════════════════════════════════════════════════════

  Widget _cancelReasonSheet() {
    final metrics = _CateringReservationMetrics.fromContext(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.popupHorizontalPadding,
        ),
        child: GestureDetector(
          // prevent backdrop tap from propagating into the card
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: metrics.popupMaxWidth,
              maxHeight: MediaQuery.of(context).size.height * 0.74,
            ),
            padding: EdgeInsets.only(
              left: metrics.popupContentHorizontalPadding,
              right: metrics.popupContentHorizontalPadding,
              top: metrics.popupContentVerticalPadding,
              bottom: metrics.popupContentVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(metrics.popupRadius),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: metrics.popupShadowBlur,
                  offset: Offset(0, 4.r),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    AppText(
                      text: "Reason for Cancel",
                      size: metrics.popupHeaderTextSize,
                      fontWeight: FontWeight.w500,
                      color: menuIconColor,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _isCancellingReservation
                          ? null
                          : () {
                              setState(() {
                                isSearchDeletePressed = false;
                                isDeletePressed = false;
                                _selectedReservationId = '';
                              });
                            },
                      child: Icon(
                        Icons.close,
                        size: metrics.popupCloseIconSize,
                        color: appTextColor3,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: metrics.popupRowGap),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final size = MediaQuery.sizeOf(context);
                            final isLandscape = size.width > size.height;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _cancelReasons.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isLandscape ? 3 : 1,
                                    crossAxisSpacing: metrics.reasonButtonGap,
                                    mainAxisSpacing: metrics.reasonButtonGap,
                                    mainAxisExtent: metrics.reasonButtonHeight,
                                  ),
                              itemBuilder: (_, index) =>
                                  _buildStatusButton(_cancelReasons[index]),
                            );
                          },
                        ),
                        SizedBox(height: metrics.reasonTextTopGap),
                        AppText(
                          text:
                              "Canceling a confirmed booking may negatively impact your reliability rating.",
                          size: metrics.reasonBodyTextSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          isCentered: true,
                        ),
                        SizedBox(height: metrics.reasonSmallGap),
                        AppText(
                          text:
                              "However, if you accept another response instead, the previous booking will be automatically replaced without affecting your rating.",
                          size: metrics.reasonBodyTextSize,
                          fontWeight: FontWeight.w400,
                          color: appTextColor2,
                          isCentered: true,
                        ),
                        SizedBox(height: metrics.reasonLinkTopGap),
                        GestureDetector(
                          onTap: _showAcceptAnotherReasonPopup,
                          child: AppText(
                            text: "Accept another response",
                            size: metrics.reasonLinkTextSize,
                            fontWeight: FontWeight.w400,
                            color: appLinkColor2,
                            isCentered: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: metrics.popupRowGap),
                SizedBox(
                  width: metrics.cancelButtonWidth,
                  height: metrics.cancelButtonHeight,
                  child: AppButton(
                    text: _isCancellingReservation ? "Cancelling..." : "Cancel",
                    bgColor1: const Color(0xFFCE3F3F),
                    bgColor2: const Color(0xFFCE3F3F),
                    size: metrics.cancelButtonTextSize,
                    borderRadius: metrics.cancelButtonRadius,
                    onPressed: _isCancellingReservation
                        ? null
                        : _cancelSelectedReservation,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BOOKING CANCELED CONFIRMATION BOX
  // ════════════════════════════════════════════════════════════════════════

  Widget _bookingCanceledBox() {
    final metrics = _CateringReservationMetrics.fromContext(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.popupHorizontalPadding),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: metrics.popupMaxWidth),
        padding: EdgeInsets.only(
          left: metrics.popupContentHorizontalPadding,
          right: metrics.popupContentHorizontalPadding,
          top: metrics.popupContentVerticalPadding,
          bottom: metrics.popupContentVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(metrics.popupRadius),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: metrics.popupShadowBlur,
              offset: Offset(0, 4.r),
            ),
          ],
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
                      isDeletePressed = false;
                      isBookingCanceled = false;
                    });
                  },
                  child: Icon(
                    Icons.close,
                    size: metrics.popupCloseIconSize,
                    color: appTextColor,
                  ),
                ),
              ],
            ),
            CancelCircleX(size: metrics.popupIconSize),
            SizedBox(height: metrics.popupRowGap),
            AppText(
              text: "Booking Canceled!",
              size: metrics.popupTitleTextSize,
              fontWeight: FontWeight.w500,
              color: Colors.red,
              isCentered: true,
            ),
            SizedBox(height: metrics.popupRowGap),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CONFIRMED BOX  (secondary confirmation dialog)
  // ════════════════════════════════════════════════════════════════════════

  Widget _confirmedBox() {
    final metrics = _CateringReservationMetrics.fromContext(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.popupHorizontalPadding,
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: metrics.popupMaxWidth),
          padding: EdgeInsets.only(
            left: metrics.popupContentHorizontalPadding,
            right: metrics.popupContentHorizontalPadding,
            top: metrics.popupContentVerticalPadding,
            bottom: metrics.popupContentVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(metrics.popupRadius),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: metrics.popupShadowBlur,
                offset: Offset(0, 4.r),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: "Are you sure you want to Cancel this Booking?",
                size: metrics.popupBodyTextSize,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                isCentered: true,
              ),
              SizedBox(height: metrics.reasonSmallGap),
              AppText(
                text:
                    "Cancelling a confirmed order may negatively impact your reliability rating",
                size: metrics.popupBodyTextSize,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                isCentered: true,
              ),
              SizedBox(height: metrics.popupRowGap),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: metrics.confirmButtonHeight,
                      child: AppButton(
                        text: _isCancellingReservation
                            ? "Cancelling..."
                            : "Yes",
                        onPressed: _isCancellingReservation
                            ? null
                            : _cancelSelectedReservation,
                        borderRadius: metrics.confirmButtonRadius,
                        bgColor1: Colors.green,
                        bgColor2: Colors.green,
                        size: metrics.confirmButtonTextSize,
                      ),
                    ),
                  ),
                  SizedBox(width: metrics.confirmButtonGap),
                  Expanded(
                    child: SizedBox(
                      height: metrics.confirmButtonHeight,
                      child: AppButton(
                        text: "No",
                        onPressed: () =>
                            setState(() => isConfirmedPressed = false),
                        size: metrics.confirmButtonTextSize,
                        borderRadius: metrics.confirmButtonRadius,
                        bgColor1: Colors.red,
                        bgColor2: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // REUSABLE BUTTON WIDGETS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildStatusButton(String text) {
    final metrics = _CateringReservationMetrics.fromContext(context);
    final bool isSelected = selectedStatus == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStatus = text;
        });
      },
      child: Container(
        height: metrics.reasonButtonHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFF97A0D), Color(0xFFF97A0D)],
                )
              : null,
          color: isSelected ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(metrics.reasonButtonRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: AppText(
          text: text,
          size: metrics.reasonButtonTextSize,
          fontWeight: FontWeight.w400,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildMainStatusButton(String text) {
    final metrics = _CateringReservationMetrics.fromContext(context);
    final bool isSelected = mainSelectedStatus == text;
    return GestureDetector(
      onTap: () => setState(() => mainSelectedStatus = text),
      child: Container(
        height: metrics.reasonButtonHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(metrics.reasonButtonRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: AppText(
          text: text,
          size: metrics.reasonButtonTextSize,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : appTextColor3,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // REQUEST DETAIL WIDGETS
  // ════════════════════════════════════════════════════════════════════════

  /// Shared row builder for request detail fields
  Widget _buildDetailRow({
    required String icon,
    required String label,
    required String value,
    int? maxLines,
  }) {
    final metrics = _CateringReservationMetrics.fromContext(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          icon,
          width: metrics.detailIconSize,
          height: metrics.detailIconSize,
          color: Color.fromARGB(255, 15, 15, 15),
        ),
        SizedBox(width: metrics.detailIconGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: label,
                size: metrics.detailLabelTextSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              SizedBox(height: metrics.detailLabelGap),
              AppText(
                text: value,
                size: metrics.detailValueTextSize,
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

  // Widget _viewPartyRequestWidget() {
  //   final metrics = _CateringReservationMetrics.fromContext(context);

  //   return Center(
  //     child: Padding(
  //       padding: EdgeInsets.symmetric(
  //         horizontal: metrics.popupHorizontalPadding,
  //       ),
  //       child: GestureDetector(
  //         behavior: HitTestBehavior.opaque,
  //         onTap: () {},
  //         child: Container(
  //           width: double.infinity,
  //           constraints: BoxConstraints(
  //             maxWidth: metrics.popupMaxWidth,
  //             maxHeight: MediaQuery.of(context).size.height * 0.85,
  //           ),
  //           padding: EdgeInsets.symmetric(
  //             horizontal: metrics.popupContentHorizontalPadding,
  //             vertical: metrics.popupContentVerticalPadding,
  //           ),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(metrics.popupRadius),
  //             border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.1),
  //                 blurRadius: metrics.popupShadowBlur,
  //                 offset: Offset(0, 4.r),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // header
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   AppText(
  //                     text: "Requested party",
  //                     size: metrics.popupBodyTextSize,
  //                     fontWeight: FontWeight.w500,
  //                     color: appTextColor2,
  //                   ),
  //                   GestureDetector(
  //                     onTap: () =>
  //                         setState(() => isPartyRequestPressed = false),
  //                     child: Icon(
  //                       Icons.close,
  //                       color: appTextColor3,
  //                       size: metrics.popupCloseIconSize,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               SizedBox(height: metrics.popupRowGap),
  //               Align(
  //                 alignment: Alignment.centerLeft,
  //                 child: AppText(
  //                   text: "P17854",
  //                   size: metrics.popupTitleTextSize,
  //                   fontWeight: FontWeight.w700,
  //                   color: appTextColor3,
  //                 ),
  //               ),
  //               SizedBox(height: metrics.popupRowGap),
  //               Flexible(
  //                 child: SingleChildScrollView(
  //                   child: Column(
  //                     children: [
  //                       _buildDetailRow(
  //                         icon: menuIcon,
  //                         label: "Your Menu",
  //                         value:
  //                             "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream.",
  //                       ),
  //                       SizedBox(height: metrics.detailRowGap),
  //                       _buildDetailRow(
  //                         icon: peopleIcon,
  //                         label: "Number of Persons",
  //                         value: "12 Person",
  //                       ),
  //                       SizedBox(height: metrics.detailRowGap),
  //                       _buildDetailRow(
  //                         icon: calenderIcon,
  //                         label: "Date and Time",
  //                         value: "April 12 - 2:30 pm",
  //                       ),
  //                       SizedBox(height: metrics.detailRowGap),
  //                       _buildDetailRow(
  //                         icon: walletIcon,
  //                         label: "Expected amount per person",
  //                         value: "1000 Per person",
  //                       ),
  //                       SizedBox(height: metrics.detailRowGap),
  //                       _buildDetailRow(
  //                         icon: radiusIcon,
  //                         label: "Enquiry Radius",
  //                         value: "Moscow City - 20km Radius",
  //                       ),
  //                       SizedBox(height: metrics.detailRowGap),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _viewCateringRequestWidget() {
    final metrics = _CateringReservationMetrics.fromContext(context);
    final reservation = _selectedRequestReservation;
    final couponId = reservation?.couponId.trim().isNotEmpty == true
        ? reservation!.couponId
        : 'Request details';
    final menuItems = reservation?.menuItems.trim().isNotEmpty == true
        ? reservation!.menuItems
              .split(RegExp(r'[,\n]'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .join(', ')
        : 'No menu details available';
    final otherServices = reservation?.otherServices.trim().isNotEmpty == true
        ? reservation!.otherServices
              .split(RegExp(r'[,\n]'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .join(', ')
        : 'No other services available';
    final persons = reservation == null
        ? 'No person count available'
        : '${reservation.persons} Person';
    final dateTime = reservation == null
        ? 'No date available'
        : '${DateFormat("MMM d").format(reservation.eventDate)} - ${DateFormat("h:mm a").format(reservation.eventDate)}';
    final amount = reservation == null
        ? 'No amount available'
        : '${reservation.pricePerPerson} Per person';
    final radius = _formatRequestRadius(reservation);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.popupHorizontalPadding,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: metrics.popupMaxWidth,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: metrics.popupContentHorizontalPadding,
              vertical: metrics.popupContentVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(metrics.popupRadius),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: metrics.popupShadowBlur,
                  offset: Offset(0, 4.r),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: "Requested catering",
                      size: metrics.popupBodyTextSize,
                      fontWeight: FontWeight.w500,
                      color: appTextColor2,
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        isCateringRequestPressed = false;
                        _selectedRequestReservation = null;
                      }),
                      child: Icon(
                        Icons.close,
                        color: appTextColor3,
                        size: metrics.popupCloseIconSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: metrics.popupRowGap),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppText(
                    text: couponId,
                    size: metrics.popupTitleTextSize,
                    fontWeight: FontWeight.w700,
                    color: appTextColor3,
                  ),
                ),
                SizedBox(height: metrics.popupRowGap),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: menuIcon,
                          label: "Your Menu",
                          value: menuItems,
                          maxLines: 20,
                        ),
                        SizedBox(height: metrics.detailRowGap),
                        _buildDetailRow(
                          icon: handshakeIcon,
                          label: "Other Services",
                          value: otherServices,
                          maxLines: 20,
                        ),
                        SizedBox(height: metrics.detailRowGap),
                        _buildDetailRow(
                          icon: peopleIcon,
                          label: "Number of Persons",
                          value: persons,
                        ),
                        SizedBox(height: metrics.detailRowGap),
                        _buildDetailRow(
                          icon: calenderIcon,
                          label: "Date and Time",
                          value: dateTime,
                        ),
                        SizedBox(height: metrics.detailRowGap),
                        _buildDetailRow(
                          icon: walletIcon,
                          label: "Expected amount per person",
                          value: amount,
                        ),
                        SizedBox(height: metrics.detailRowGap),
                        _buildDetailRow(
                          icon: radiusIcon,
                          label: "Enquiry Radius",
                          value: radius,
                        ),
                        SizedBox(height: metrics.detailRowGap),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRequestRadius(BanquetReservationModal? reservation) {
    if (reservation == null) return 'No radius available';

    final rawRadius = reservation.searchRadius.trim();
    final lat = reservation.lat.trim();
    final lng = reservation.lng.trim();
    final key = '$lat,$lng';
    final placeName = lat.isNotEmpty && lng.isNotEmpty
        ? _reservationPlaceNames[key]
        : null;

    if (rawRadius.isEmpty && (placeName == null || placeName.isEmpty)) {
      return 'No radius available';
    }

    String radius = rawRadius;
    final parsed = double.tryParse(rawRadius);
    if (parsed != null) {
      radius = parsed % 1 == 0 ? parsed.toInt().toString() : rawRadius;
    }

    final radiusText = radius.isEmpty ? '' : '${radius}km Radius';

    if (placeName != null && placeName.isNotEmpty && radiusText.isNotEmpty) {
      return '$placeName - $radiusText';
    }
    if (placeName != null && placeName.isNotEmpty) return placeName;
    if (lat.isNotEmpty && lng.isNotEmpty && radiusText.isNotEmpty) {
      return '$lat, $lng - $radiusText';
    }
    if (lat.isNotEmpty && lng.isNotEmpty) return '$lat, $lng';
    return radiusText;
  }
}

class _CateringReservationMetrics {
  const _CateringReservationMetrics({
    required this.contentHorizontalPadding,
    required this.contentTopPadding,
    required this.searchShadowBlur,
    required this.searchShadowSpread,
    required this.searchTextSize,
    required this.searchRadius,
    required this.sectionGap,
    required this.filterWidth,
    required this.filterHeight,
    required this.filterIconSize,
    required this.filterTextSize,
    required this.bottomGap,
    required this.stateVerticalPadding,
    required this.stateTextSize,
    required this.stateGap,
    required this.retryButtonWidth,
    required this.retryButtonHeight,
    required this.retryButtonTextSize,
    required this.retryButtonRadius,
    required this.sheetTopRadius,
    required this.sheetPadding,
    required this.sheetHandleWidth,
    required this.sheetHandleHeight,
    required this.sheetHandleRadius,
    required this.sheetGap,
    required this.sheetContainerRadius,
    required this.sheetContainerPadding,
    required this.filterOptionVerticalPadding,
    required this.filterOptionHorizontalPadding,
    required this.filterOptionRadius,
    required this.filterOptionTextSize,
    required this.popupHorizontalPadding,
    required this.popupVerticalPadding,
    required this.popupMaxWidth,
    required this.popupRadius,
    required this.popupContentHorizontalPadding,
    required this.popupContentVerticalPadding,
    required this.popupShadowBlur,
    required this.popupHeaderTextSize,
    required this.popupTitleTextSize,
    required this.popupBodyTextSize,
    required this.popupCloseIconSize,
    required this.popupIconSize,
    required this.popupRowGap,
    required this.popupButtonHeight,
    required this.popupButtonTextSize,
    required this.popupButtonRadius,
    required this.reasonFieldHorizontalPadding,
    required this.reasonFieldVerticalPadding,
    required this.reasonFieldRadius,
    required this.reasonButtonHeight,
    required this.reasonButtonGap,
    required this.reasonButtonRadius,
    required this.reasonButtonTextSize,
    required this.reasonTextTopGap,
    required this.reasonBodyTextSize,
    required this.reasonSmallGap,
    required this.reasonLinkTopGap,
    required this.reasonLinkTextSize,
    required this.cancelButtonWidth,
    required this.cancelButtonHeight,
    required this.cancelButtonTextSize,
    required this.cancelButtonRadius,
    required this.confirmButtonHeight,
    required this.confirmButtonGap,
    required this.confirmButtonRadius,
    required this.confirmButtonTextSize,
    required this.detailIconSize,
    required this.detailIconGap,
    required this.detailLabelTextSize,
    required this.detailLabelGap,
    required this.detailValueTextSize,
    required this.detailRowGap,
  });

  final double contentHorizontalPadding;
  final double contentTopPadding;
  final double searchShadowBlur;
  final double searchShadowSpread;
  final double searchTextSize;
  final double searchRadius;
  final double sectionGap;
  final double filterWidth;
  final double filterHeight;
  final double filterIconSize;
  final double filterTextSize;
  final double bottomGap;
  final double stateVerticalPadding;
  final double stateTextSize;
  final double stateGap;
  final double retryButtonWidth;
  final double retryButtonHeight;
  final double retryButtonTextSize;
  final double retryButtonRadius;
  final double sheetTopRadius;
  final double sheetPadding;
  final double sheetHandleWidth;
  final double sheetHandleHeight;
  final double sheetHandleRadius;
  final double sheetGap;
  final double sheetContainerRadius;
  final double sheetContainerPadding;
  final double filterOptionVerticalPadding;
  final double filterOptionHorizontalPadding;
  final double filterOptionRadius;
  final double filterOptionTextSize;
  final double popupHorizontalPadding;
  final double popupVerticalPadding;
  final double popupMaxWidth;
  final double popupRadius;
  final double popupContentHorizontalPadding;
  final double popupContentVerticalPadding;
  final double popupShadowBlur;
  final double popupHeaderTextSize;
  final double popupTitleTextSize;
  final double popupBodyTextSize;
  final double popupCloseIconSize;
  final double popupIconSize;
  final double popupRowGap;
  final double popupButtonHeight;
  final double popupButtonTextSize;
  final double popupButtonRadius;
  final double reasonFieldHorizontalPadding;
  final double reasonFieldVerticalPadding;
  final double reasonFieldRadius;
  final double reasonButtonHeight;
  final double reasonButtonGap;
  final double reasonButtonRadius;
  final double reasonButtonTextSize;
  final double reasonTextTopGap;
  final double reasonBodyTextSize;
  final double reasonSmallGap;
  final double reasonLinkTopGap;
  final double reasonLinkTextSize;
  final double cancelButtonWidth;
  final double cancelButtonHeight;
  final double cancelButtonTextSize;
  final double cancelButtonRadius;
  final double confirmButtonHeight;
  final double confirmButtonGap;
  final double confirmButtonRadius;
  final double confirmButtonTextSize;
  final double detailIconSize;
  final double detailIconGap;
  final double detailLabelTextSize;
  final double detailLabelGap;
  final double detailValueTextSize;
  final double detailRowGap;

  factory _CateringReservationMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final horizontalScale = (size.width / 768).clamp(1.0, 1.16).toDouble();
      final verticalScale = (size.height / 1024).clamp(1.0, 1.18).toDouble();
      double s(double value) => value * horizontalScale;
      double v(double value) => value * verticalScale;

      return _CateringReservationMetrics(
        contentHorizontalPadding: s(38),
        contentTopPadding: v(30),
        searchShadowBlur: s(12),
        searchShadowSpread: s(4),
        searchTextSize: 15,
        searchRadius: s(18),
        sectionGap: v(22),
        filterWidth: s(170),
        filterHeight: v(38),
        filterIconSize: s(18),
        filterTextSize: 12,
        bottomGap: v(32),
        stateVerticalPadding: v(78),
        stateTextSize: 16,
        stateGap: v(18),
        retryButtonWidth: s(132),
        retryButtonHeight: v(42),
        retryButtonTextSize: 14,
        retryButtonRadius: s(10),
        sheetTopRadius: s(28),
        sheetPadding: s(36),
        sheetHandleWidth: s(48),
        sheetHandleHeight: s(5),
        sheetHandleRadius: s(10),
        sheetGap: v(18),
        sheetContainerRadius: s(22),
        sheetContainerPadding: s(20),
        filterOptionVerticalPadding: v(14),
        filterOptionHorizontalPadding: s(10),
        filterOptionRadius: s(10),
        filterOptionTextSize: 16,
        popupHorizontalPadding: s(40),
        popupVerticalPadding: v(24),
        popupMaxWidth: s(560),
        popupRadius: s(22),
        popupContentHorizontalPadding: s(34),
        popupContentVerticalPadding: v(30),
        popupShadowBlur: s(14),
        popupHeaderTextSize: 16,
        popupTitleTextSize: 22,
        popupBodyTextSize: 16,
        popupCloseIconSize: s(28),
        popupIconSize: s(92),
        popupRowGap: v(20),
        popupButtonHeight: v(44),
        popupButtonTextSize: 15,
        popupButtonRadius: s(10),
        reasonFieldHorizontalPadding: s(16),
        reasonFieldVerticalPadding: v(14),
        reasonFieldRadius: s(10),
        reasonButtonHeight: v(40),
        reasonButtonGap: v(12),
        reasonButtonRadius: s(10),
        reasonButtonTextSize: 14,
        reasonTextTopGap: v(28),
        reasonBodyTextSize: 14,
        reasonSmallGap: v(9),
        reasonLinkTopGap: v(16),
        reasonLinkTextSize: 15,
        cancelButtonWidth: s(132),
        cancelButtonHeight: v(38),
        cancelButtonTextSize: 15,
        cancelButtonRadius: s(8),
        confirmButtonHeight: v(38),
        confirmButtonGap: s(18),
        confirmButtonRadius: s(6),
        confirmButtonTextSize: 13,
        detailIconSize: s(20),
        detailIconGap: s(12),
        detailLabelTextSize: 15,
        detailLabelGap: v(6),
        detailValueTextSize: 15,
        detailRowGap: v(20),
      );
    }

    if (isWideShortPhone) {
      return const _CateringReservationMetrics(
        contentHorizontalPadding: 26,
        contentTopPadding: 18,
        searchShadowBlur: 9,
        searchShadowSpread: 3,
        searchTextSize: 12.5,
        searchRadius: 14,
        sectionGap: 14,
        filterWidth: 132,
        filterHeight: 30,
        filterIconSize: 15,
        filterTextSize: 10,
        bottomGap: 22,
        stateVerticalPadding: 48,
        stateTextSize: 13,
        stateGap: 14,
        retryButtonWidth: 110,
        retryButtonHeight: 34,
        retryButtonTextSize: 12,
        retryButtonRadius: 9,
        sheetTopRadius: 24,
        sheetPadding: 26,
        sheetHandleWidth: 40,
        sheetHandleHeight: 5,
        sheetHandleRadius: 10,
        sheetGap: 14,
        sheetContainerRadius: 18,
        sheetContainerPadding: 15,
        filterOptionVerticalPadding: 11,
        filterOptionHorizontalPadding: 8,
        filterOptionRadius: 9,
        filterOptionTextSize: 13,
        popupHorizontalPadding: 38,
        popupVerticalPadding: 18,
        popupMaxWidth: 430,
        popupRadius: 18,
        popupContentHorizontalPadding: 24,
        popupContentVerticalPadding: 20,
        popupShadowBlur: 10,
        popupHeaderTextSize: 14,
        popupTitleTextSize: 18,
        popupBodyTextSize: 13,
        popupCloseIconSize: 22,
        popupIconSize: 74,
        popupRowGap: 14,
        popupButtonHeight: 34,
        popupButtonTextSize: 13,
        popupButtonRadius: 9,
        reasonFieldHorizontalPadding: 12,
        reasonFieldVerticalPadding: 10,
        reasonFieldRadius: 9,
        reasonButtonHeight: 32,
        reasonButtonGap: 9,
        reasonButtonRadius: 9,
        reasonButtonTextSize: 11.5,
        reasonTextTopGap: 22,
        reasonBodyTextSize: 12,
        reasonSmallGap: 7,
        reasonLinkTopGap: 12,
        reasonLinkTextSize: 13,
        cancelButtonWidth: 108,
        cancelButtonHeight: 32,
        cancelButtonTextSize: 13,
        cancelButtonRadius: 8,
        confirmButtonHeight: 32,
        confirmButtonGap: 12,
        confirmButtonRadius: 5,
        confirmButtonTextSize: 11.5,
        detailIconSize: 16,
        detailIconGap: 9,
        detailLabelTextSize: 12.5,
        detailLabelGap: 4,
        detailValueTextSize: 13,
        detailRowGap: 14,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _CateringReservationMetrics(
        contentHorizontalPadding: s(18),
        contentTopPadding: s(18),
        searchShadowBlur: s(8),
        searchShadowSpread: s(3),
        searchTextSize: s(12),
        searchRadius: s(14),
        sectionGap: s(14),
        filterWidth: s(126),
        filterHeight: s(30),
        filterIconSize: s(14),
        filterTextSize: s(10),
        bottomGap: s(20),
        stateVerticalPadding: s(48),
        stateTextSize: s(13),
        stateGap: s(14),
        retryButtonWidth: s(108),
        retryButtonHeight: s(34),
        retryButtonTextSize: s(12),
        retryButtonRadius: s(9),
        sheetTopRadius: s(22),
        sheetPadding: s(22),
        sheetHandleWidth: s(38),
        sheetHandleHeight: s(4),
        sheetHandleRadius: s(9),
        sheetGap: s(13),
        sheetContainerRadius: s(18),
        sheetContainerPadding: s(14),
        filterOptionVerticalPadding: s(10),
        filterOptionHorizontalPadding: s(8),
        filterOptionRadius: s(9),
        filterOptionTextSize: s(13),
        popupHorizontalPadding: s(22),
        popupVerticalPadding: s(16),
        popupMaxWidth: double.infinity,
        popupRadius: s(17),
        popupContentHorizontalPadding: s(22),
        popupContentVerticalPadding: s(18),
        popupShadowBlur: s(10),
        popupHeaderTextSize: s(13),
        popupTitleTextSize: s(17),
        popupBodyTextSize: s(13),
        popupCloseIconSize: s(22),
        popupIconSize: s(72),
        popupRowGap: s(14),
        popupButtonHeight: s(34),
        popupButtonTextSize: s(13),
        popupButtonRadius: s(9),
        reasonFieldHorizontalPadding: s(12),
        reasonFieldVerticalPadding: s(10),
        reasonFieldRadius: s(9),
        reasonButtonHeight: s(32),
        reasonButtonGap: s(9),
        reasonButtonRadius: s(9),
        reasonButtonTextSize: s(11.5),
        reasonTextTopGap: s(22),
        reasonBodyTextSize: s(12),
        reasonSmallGap: s(7),
        reasonLinkTopGap: s(12),
        reasonLinkTextSize: s(13),
        cancelButtonWidth: s(108),
        cancelButtonHeight: s(32),
        cancelButtonTextSize: s(13),
        cancelButtonRadius: s(8),
        confirmButtonHeight: s(32),
        confirmButtonGap: s(12),
        confirmButtonRadius: s(5),
        confirmButtonTextSize: s(11.5),
        detailIconSize: s(16),
        detailIconGap: s(8),
        detailLabelTextSize: s(12.5),
        detailLabelGap: s(4),
        detailValueTextSize: s(13),
        detailRowGap: s(14),
      );
    }

    return _CateringReservationMetrics(
      contentHorizontalPadding: 20.w,
      contentTopPadding: 20.h,
      searchShadowBlur: 10,
      searchShadowSpread: 5,
      searchTextSize: 13.sp,
      searchRadius: 16,
      sectionGap: 20.h,
      filterWidth: 150.w,
      filterHeight: 30.h,
      filterIconSize: 18.sp,
      filterTextSize: 10.sp,
      bottomGap: 20.h,
      stateVerticalPadding: 60.h,
      stateTextSize: 15,
      stateGap: 16.h,
      retryButtonWidth: 120.w,
      retryButtonHeight: 38.h,
      retryButtonTextSize: 14,
      retryButtonRadius: 10.r,
      sheetTopRadius: 25.r,
      sheetPadding: 30.w,
      sheetHandleWidth: 40.w,
      sheetHandleHeight: 5.h,
      sheetHandleRadius: 10.r,
      sheetGap: 16.h,
      sheetContainerRadius: 20.r,
      sheetContainerPadding: 16.w,
      filterOptionVerticalPadding: 12.h,
      filterOptionHorizontalPadding: 8.w,
      filterOptionRadius: 10,
      filterOptionTextSize: 15,
      popupHorizontalPadding: 30.w,
      popupVerticalPadding: 20.h,
      popupMaxWidth: double.infinity,
      popupRadius: 15.r,
      popupContentHorizontalPadding: 40.w,
      popupContentVerticalPadding: 30.h,
      popupShadowBlur: 10.r,
      popupHeaderTextSize: 14,
      popupTitleTextSize: 20,
      popupBodyTextSize: 15,
      popupCloseIconSize: 25,
      popupIconSize: 96.w,
      popupRowGap: 20.h,
      popupButtonHeight: 40.h,
      popupButtonTextSize: 15,
      popupButtonRadius: 10.r,
      reasonFieldHorizontalPadding: 14.w,
      reasonFieldVerticalPadding: 12.h,
      reasonFieldRadius: 10.r,
      reasonButtonHeight: 35.h,
      reasonButtonGap: 10.h,
      reasonButtonRadius: 10,
      reasonButtonTextSize: 13,
      reasonTextTopGap: 35.h,
      reasonBodyTextSize: 13,
      reasonSmallGap: 8.h,
      reasonLinkTopGap: 15.h,
      reasonLinkTextSize: 15,
      cancelButtonWidth: 120.w,
      cancelButtonHeight: 35.h,
      cancelButtonTextSize: 15,
      cancelButtonRadius: 8,
      confirmButtonHeight: 35.h,
      confirmButtonGap: 20.w,
      confirmButtonRadius: 5.r,
      confirmButtonTextSize: 12,
      detailIconSize: 20.w,
      detailIconGap: 10.w,
      detailLabelTextSize: 15,
      detailLabelGap: 5.h,
      detailValueTextSize: 15,
      detailRowGap: 20.h,
    );
  }
}
