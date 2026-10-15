import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/model/reservation/new-reservation-model.dart';
import 'package:fudikoclient/service/reservation/reservation-service.dart';
import 'package:fudikoclient/utils/constants.dart';
// `intl` exports its own `TextDirection` class, which shadows the Flutter
// enum used for `RichText.textDirection`.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:fudikoclient/utils/snackbar.dart';
import 'package:fudikoclient/utils/translator_service.dart';

enum ModalStep { selectSlot, selectPeople, confirmation }

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

    _circleScale = TweenSequence<double>([
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

class NumberOfPeopleModal extends StatefulWidget {
  final String uuid;
  final String? offerId; // ← add
  final OfferModel? offer;
  final DateTime? reservationDate;
  final int initialPeopleCount;
  final int minPeople;
  final int maxPeople;
  final VoidCallback? onBookingComplete;
  // False when the caller (Home) already picked a specific date/time via its
  // own filter — in that case the "Select a Time Slot" step is skipped
  // entirely and that date/time is booked directly. True (default) for
  // Favorites/Restaurant Profile, where there's no such prior selection and
  // the customer picks a slot for the offer here.
  final bool allowSlotSelection;

  const NumberOfPeopleModal({
    super.key,
    required this.uuid,
    this.reservationDate,
    this.offerId, // ← add
    this.offer,
    this.initialPeopleCount = 2,
    this.minPeople = 1,
    this.maxPeople = 20,
    this.onBookingComplete,
    this.allowSlotSelection = true,
  });

  @override
  State<NumberOfPeopleModal> createState() => _NumberOfPeopleModalState();
}

class _NumberOfPeopleModalState extends State<NumberOfPeopleModal>
    with SingleTickerProviderStateMixin {
  late int _peopleCount;
  late List<ModalStep> _steps;
  late ModalStep _currentStep;
  OfferSlotModel? _selectedSlot;
  ReservationService reservationService = ReservationService();
  String? _selectedDate;
  String? _selectedTime;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool get _hasSelectableSlots =>
      widget.allowSlotSelection && (widget.offer?.slots.length ?? 0) > 1;

  @override
  void initState() {
    super.initState();
    _peopleCount = widget.initialPeopleCount;
    // Only ask the customer to pick a slot when the offer actually has more
    // than one AND the caller allows it — otherwise (single slot, or the
    // caller already supplied a specific date/time, e.g. Home's own filter)
    // an extra step would just be friction.
    _steps = _hasSelectableSlots
        ? const [
            ModalStep.selectSlot,
            ModalStep.selectPeople,
            ModalStep.confirmation,
          ]
        : const [ModalStep.selectPeople, ModalStep.confirmation];
    _currentStep = _steps.first;

    final offerSlots = widget.offer?.slots ?? const <OfferSlotModel>[];
    // The tapped slot is carried on offer.startTime (offerForBooking); only
    // fall back to the first slot when it is missing.
    final tappedStart = widget.offer?.startTime.trim() ?? '';
    _selectedSlot = offerSlots.isEmpty
        ? null
        : offerSlots.firstWhere(
            (slot) => slot.startTime.trim() == tappedStart,
            orElse: () => offerSlots.first,
          );
    // Book the slot's own time and its matching date — never the Home
    // filter's date/time. The filter value is only a last-resort fallback
    // when the offer has no usable slot time.
    _selectedTime = tappedStart.isNotEmpty
        ? tappedStart
        : (_selectedSlot?.startTime ?? _resolveOfferTime());
    _selectedDate = _formatDate(_dateForSlot(_selectedTime!));

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _incrementPeople() {
    if (_peopleCount < widget.maxPeople) {
      setState(() {
        _peopleCount++;
      });
    }
  }

  void _decrementPeople() {
    if (_peopleCount > widget.minPeople) {
      setState(() {
        _peopleCount--;
      });
    }
  }

  void _selectSlot(OfferSlotModel slot) {
    setState(() {
      _selectedSlot = slot;
      _selectedTime = slot.startTime;
      _selectedDate = _formatDate(_dateForSlot(slot.startTime));
    });
  }

  void _nextStep() {
    switch (_currentStep) {
      case ModalStep.selectSlot:
        final index = _steps.indexOf(_currentStep);
        setState(() => _currentStep = _steps[index + 1]);
        break;
      case ModalStep.selectPeople:
        _processBooking();
        break;
      case ModalStep.confirmation:
        _closeModal();
        break;
    }
  }

  void _previousStep() {
    final index = _steps.indexOf(_currentStep);
    if (index <= 0) {
      _closeModal();
      return;
    }
    setState(() => _currentStep = _steps[index - 1]);
  }

  // api call
  Future<void> _processBooking() async {
    setState(() {
      _isLoading = true;
    });

    if (_selectedDate == null || _selectedTime == null) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("Please select date and time.");
      return;
    }
    NewReservationModel reservationdata = NewReservationModel(
      people: _peopleCount.toString(),
      id: widget.uuid,
      time: _selectedTime!,
      date: _selectedDate!,
      offerId: widget.offerId, // ← add
    );
    NewReservationModelResponse response =
        await reservationService.createReservation(reservationdata);
    if (response.status) {
      setState(() {
        _currentStep = ModalStep.confirmation;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(response.message);
    }
  }

  void _showErrorSnackBar(String message) {
    showErrorSnack(context, message);
  }

  void _closeModal() {
    Navigator.of(context).pop();
    widget.onBookingComplete?.call();
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case ModalStep.selectSlot:
        return 'Select a Time Slot';
      case ModalStep.selectPeople:
        return 'Number of People';
      case ModalStep.confirmation:
        return 'Booking Confirmed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics(context);

    // Same structural pattern as FilterBottomModal/TimeBottomModal: a
    // Column with mainAxisSize.min shrink-wraps to its content even under
    // the bounded full-screen height showModalBottomSheet(isScrollControlled:
    // true) hands it. Wrapping in Align/Center here (as this used to) always
    // fills that bounded box regardless of content size, which is why the
    // sheet used to cover the full screen. Width capping for tablets is
    // handled the same way Filter/Time do it — via the `constraints:`
    // parameter on showModalBottomSheet at the call site, not internally.
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: metrics.maxHeight),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: metrics.outerHorizontalPadding,
              right: metrics.outerHorizontalPadding,
              top: metrics.outerTopPadding,
              bottom: metrics.outerBottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProgressIndicator(metrics),
                _buildContent(metrics),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _BookingModalMetrics _metrics(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    final isTablet = Breakpoints.isTabletDevice(size);
    final isLandscape = width > height;
    final isPhoneLandscape = !isTablet && isLandscape;

    // Scale UI based on available height:
    // portrait phone => 1.0, short portrait phone => down to 0.75,
    // phone in landscape (shortest side, always more height-constrained)
    // gets a lower floor so it compacts further instead of scrolling.
    final heightFactor = isTablet
        ? 1.0
        : (height / 700).clamp(isPhoneLandscape ? 0.6 : 0.75, 1.0);

    return _BookingModalMetrics(
      isTablet: isTablet,
      maxHeight: isTablet
          ? height * (isLandscape ? 0.88 : 0.72)
          : height * (isPhoneLandscape ? 0.92 : 0.82),
      outerHorizontalPadding: isTablet ? 24.0 : 20.w,
      outerTopPadding: isTablet ? 20.0 : 16.h,
      outerBottomPadding: isTablet ? 28.0 : (isPhoneLandscape ? 20.h : 40.h),
      progressCurrentWidth: isTablet ? 42 : 30 * heightFactor,
      progressDotWidth: isTablet ? 10 : 8 * heightFactor,
      progressHeight: isTablet ? 10 : 8 * heightFactor,
      progressGap: isTablet ? 6 : 4 * heightFactor,
      contentRadius: isTablet ? 24.0 : 20.r,
      contentPadding: isTablet ? 32.0 : 24 * heightFactor,
      sectionGap: isTablet ? (isLandscape ? 24.0 : 36.0) : 30 * heightFactor,
      largeGap: isTablet ? (isLandscape ? 32.0 : 48.0) : 40 * heightFactor,
      titleSize: isTablet ? AppDimensions.body(context) + 2 : 14.0,
      counterButtonWidth:
          isTablet ? (isLandscape ? 72.0 : 84.0) : 70 * heightFactor,
      counterButtonHeight:
          isTablet ? (isLandscape ? 72.0 : 84.0) : 70 * heightFactor,
      counterDisplayWidth: isTablet ? 96.0 : 80 * heightFactor,
      counterTextSize: isTablet ? 30.0 : 24 * heightFactor,
      headerIconContainerPadding: isTablet ? 10.0 : 8.w,
      headerIconSize: isTablet ? 24.0 : 20.sp,
      confirmationIconSize: isTablet ? 82.0 : 78 * heightFactor,
      confirmationImageSize: isTablet ? 56.0 : 50.sp,
      confirmationTitleSize: isTablet ? 26.0 : 22.0,
      confirmationBodySize: isTablet ? AppDimensions.body(context) : 14.sp,
      closeIconSize: isTablet ? 28.0 : 25.w,
      actionButtonWidth: isTablet ? 220.0 : 150 * heightFactor,
      actionButtonHeight: isTablet ? 54.0 : 50 * heightFactor,
      actionButtonTextSize: isTablet ? 18.0 : 16.0,
      actionButtonRadius: isTablet ? 14.0 : 12.r,
      slotListMaxHeight: isTablet
          ? 220.0
          : (height * (isPhoneLandscape ? 0.3 : 0.28)).clamp(120.0, 200.0),
      slotChipGap: isTablet ? 10.0 : 8 * heightFactor,
      slotChipHorizontalPadding: isTablet ? 14.0 : 12 * heightFactor,
      slotChipVerticalPadding: isTablet ? 9.0 : 7 * heightFactor,
      slotChipRadius: isTablet ? 10.0 : 8.r,
      slotChipTextSize: isTablet ? 13.0 : 11.5 * heightFactor,
    );
  }

  Widget _buildProgressIndicator(_BookingModalMetrics metrics) {
    final currentIndex = _steps.indexOf(_currentStep);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length, (index) {
        bool isActive = index <= currentIndex;
        bool isCurrent = index == currentIndex;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: metrics.progressGap),
          width: isCurrent
              ? metrics.progressCurrentWidth
              : metrics.progressDotWidth,
          height: metrics.progressHeight,
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).primaryColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(metrics.progressHeight / 2),
          ),
        );
      }),
    );
  }

  Widget _buildContent(_BookingModalMetrics metrics) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.contentRadius),
      ),
      padding: EdgeInsets.all(metrics.contentPadding),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _buildCurrentStepContent(),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case ModalStep.selectSlot:
        return _buildSlotSelector();
      case ModalStep.selectPeople:
        return _buildPeopleSelector();
      case ModalStep.confirmation:
        return _buildConfirmation();
    }
  }

  Widget _buildSlotSelector() {
    final metrics = _metrics(context);
    final slots = widget.offer?.slots ?? const <OfferSlotModel>[];

    return Column(
      key: const ValueKey('slot_selector'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeader(),
        SizedBox(height: metrics.sectionGap),
        AppText(
          text: _getStepTitle(),
          size: metrics.titleSize,
          fontWeight: FontWeight.w600,
          color: appTextColor2,
        ),
        SizedBox(height: metrics.sectionGap * 0.5),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: metrics.slotListMaxHeight),
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: metrics.slotChipGap,
              runSpacing: metrics.slotChipGap,
              children: slots.map((slot) {
                final isSelected = slot.startTime == _selectedSlot?.startTime &&
                    slot.endTime == _selectedSlot?.endTime;
                return GestureDetector(
                  onTap: () => _selectSlot(slot),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.slotChipHorizontalPadding,
                      vertical: metrics.slotChipVerticalPadding,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(
                        metrics.slotChipRadius,
                      ),
                    ),
                    child: Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : appTextColor2,
                        fontSize: metrics.slotChipTextSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: metrics.largeGap),
        SizedBox(
          width: metrics.actionButtonWidth,
          height: metrics.actionButtonHeight,
          child: AppButton(
            text: 'Next',
            onPressed: _selectedSlot == null ? null : _nextStep,
            borderRadius: metrics.actionButtonRadius,
            size: metrics.actionButtonTextSize,
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleSelector() {
    final metrics = _metrics(context);
    return Column(
      key: const ValueKey('people_selector'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeader(),
        SizedBox(height: metrics.sectionGap),
        AppText(
          text: _getStepTitle(),
          size: metrics.titleSize,
          fontWeight: FontWeight.w600,
          color: appTextColor2,
        ),
        SizedBox(height: metrics.sectionGap * 0.5),
        _buildPeopleCounter(),
        SizedBox(height: metrics.largeGap),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    final metrics = _metrics(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_steps.indexOf(_currentStep) > 0)
          GestureDetector(
            onTap: _previousStep,
            child: Container(
              padding: EdgeInsets.all(metrics.headerIconContainerPadding),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: appTextColor,
                size: metrics.headerIconSize,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        GestureDetector(
          onTap: _closeModal,
          child: Container(
            padding: EdgeInsets.all(metrics.headerIconContainerPadding),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.close,
              color: appTextColor,
              size: metrics.headerIconSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleCounter() {
    final metrics = _metrics(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(metrics.contentRadius + 5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCounterButton(
            icon: Icons.remove,
            onTap: _decrementPeople,
            isEnabled: _peopleCount > widget.minPeople,
            isLeft: true,
          ),
          _buildCounterDisplay(),
          _buildCounterButton(
            icon: Icons.add,
            onTap: _incrementPeople,
            isEnabled: _peopleCount < widget.maxPeople,
            isLeft: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
    required bool isLeft,
  }) {
    final metrics = _metrics(context);
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: metrics.counterButtonWidth,
        height: metrics.counterButtonHeight,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.grey[300] : Colors.grey[50],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isLeft ? metrics.contentRadius + 5 : 0),
            bottomLeft: Radius.circular(isLeft ? metrics.contentRadius + 5 : 0),
            topRight: Radius.circular(isLeft ? 0 : metrics.contentRadius + 5),
            bottomRight: Radius.circular(
              isLeft ? 0 : metrics.contentRadius + 5,
            ),
          ),
        ),
        child: Icon(
          icon,
          size: metrics.counterTextSize,
          color: isEnabled ? appTextColor2 : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildCounterDisplay() {
    final metrics = _metrics(context);
    return Container(
      width: metrics.counterDisplayWidth,
      height: metrics.counterButtonHeight,
      decoration: const BoxDecoration(color: Colors.white),
      child: Center(
        child: AppText(
          text: _peopleCount.toString(),
          size: metrics.counterTextSize,
          fontWeight: FontWeight.w600,
          color: appTextColor2,
        ),
      ),
    );
  }

  Widget _buildConfirmation() {
    final metrics = _metrics(context);
    final discountText = _offerDiscountText();
    final applicableFor = _offerApplicableForText();
    final dateText = _selectedDateText();
    final timeText = _selectedTime ?? '';

    return Column(
      key: const ValueKey('confirmation'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _closeModal,
            child: Container(
              padding: EdgeInsets.all(metrics.headerIconContainerPadding),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.close,
                color: appTextColor,
                size: metrics.closeIconSize,
              ),
            ),
          ),
        ),
        SizedBox(height: metrics.sectionGap * 0.4),
        BookingSuccessTick(size: metrics.confirmationIconSize),
        SizedBox(height: metrics.sectionGap * 0.8),
        AppText(
          text: "Booking Successful!",
          size: metrics.confirmationTitleSize,
          fontWeight: FontWeight.w600,
          color: appTextColor3,
        ),
        SizedBox(height: metrics.sectionGap * 0.45),
        _CouponMessage(
          discount: discountText,
          applicableFor: applicableFor,
          date: dateText,
          time: timeText,
          fontSize: metrics.confirmationBodySize,
        ),
      ],
    );
  }

  String _offerDiscountText() {
    final discount = widget.offer?.discountPercentage;
    if (discount == null || discount <= 0) return 'discount';
    final label = discount % 1 == 0
        ? discount.toStringAsFixed(0)
        : discount.toStringAsFixed(1);
    return '$label% discount';
  }

  String _offerApplicableForText() {
    final value = widget.offer?.applicableFor.trim();
    if (value == null || value.isEmpty) return 'selected offer';
    return value;
  }

  String _selectedDateText() {
    if (_selectedDate == null) return 'Today';

    final selectedDate = DateTime.tryParse(_selectedDate!);
    if (selectedDate == null) return _selectedDate!;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (selectedDay == today) {
      return 'Today';
    }

    return DateFormat('dd-MMM-yy').format(selectedDate);
  }

  Widget _buildActionButtons() {
    final metrics = _metrics(context);
    if (_isLoading) {
      return SizedBox(
        height: metrics.actionButtonHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      width: metrics.actionButtonWidth,
      height: metrics.actionButtonHeight,
      child: AppButton(
        text: _getButtonText(),
        onPressed: _nextStep,
        borderRadius: metrics.actionButtonRadius,
        size: metrics.actionButtonTextSize,
      ),
    );
  }

  String _getButtonText() {
    switch (_currentStep) {
      case ModalStep.selectSlot:
        return 'Next';
      case ModalStep.selectPeople:
        return 'Book';
      case ModalStep.confirmation:
        return 'Done';
    }
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  // Next date (today or later) on which the offer is active and the slot's
  // start time is still ahead.
  DateTime _dateForSlot(String slotTime) {
    // The caller picked a specific date (Home filter) — book exactly that day.
    final picked = widget.reservationDate;
    if (picked != null) return DateTime(picked.year, picked.month, picked.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? parsed;
    for (final pattern in const ['hh:mm a', 'h:mm a', 'HH:mm', 'HH:mm:ss']) {
      try {
        parsed = DateFormat(pattern).parseStrict(slotTime.trim());
        break;
      } catch (_) {}
    }
    if (parsed == null) return _resolvedReservationDate;

    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final activeDays = (widget.offer?.activeDays ?? '')
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toSet();
    for (var i = 0; i < 8; i++) {
      final day = today.add(Duration(days: i));
      if (activeDays.isNotEmpty &&
          !activeDays.contains(names[day.weekday - 1])) {
        continue;
      }
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        parsed.hour,
        parsed.minute,
      );
      if (start.isAfter(now)) return day;
    }
    return today;
  }

  String _resolveOfferTime() {
    final startTime = widget.offer?.startTime.trim();
    if (startTime != null && startTime.isNotEmpty) return startTime;
    return _formatTimeOfDay(_resolvedReservationDate);
  }

  String _formatTimeOfDay(DateTime value) {
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute $suffix';
  }

  DateTime get _resolvedReservationDate =>
      widget.reservationDate ?? DateTime.now();
}

class _BookingModalMetrics {
  const _BookingModalMetrics({
    required this.isTablet,
    required this.maxHeight,
    required this.outerHorizontalPadding,
    required this.outerTopPadding,
    required this.outerBottomPadding,
    required this.progressCurrentWidth,
    required this.progressDotWidth,
    required this.progressHeight,
    required this.progressGap,
    required this.contentRadius,
    required this.contentPadding,
    required this.sectionGap,
    required this.largeGap,
    required this.titleSize,
    required this.counterButtonWidth,
    required this.counterButtonHeight,
    required this.counterDisplayWidth,
    required this.counterTextSize,
    required this.headerIconContainerPadding,
    required this.headerIconSize,
    required this.confirmationIconSize,
    required this.confirmationImageSize,
    required this.confirmationTitleSize,
    required this.confirmationBodySize,
    required this.closeIconSize,
    required this.actionButtonWidth,
    required this.actionButtonHeight,
    required this.actionButtonTextSize,
    required this.actionButtonRadius,
    required this.slotListMaxHeight,
    required this.slotChipGap,
    required this.slotChipHorizontalPadding,
    required this.slotChipVerticalPadding,
    required this.slotChipRadius,
    required this.slotChipTextSize,
  });

  final bool isTablet;
  final double maxHeight;
  final double outerHorizontalPadding;
  final double outerTopPadding;
  final double outerBottomPadding;
  final double progressCurrentWidth;
  final double progressDotWidth;
  final double progressHeight;
  final double progressGap;
  final double contentRadius;
  final double contentPadding;
  final double sectionGap;
  final double largeGap;
  final double titleSize;
  final double counterButtonWidth;
  final double counterButtonHeight;
  final double counterDisplayWidth;
  final double counterTextSize;
  final double headerIconContainerPadding;
  final double headerIconSize;
  final double confirmationIconSize;
  final double confirmationImageSize;
  final double confirmationTitleSize;
  final double confirmationBodySize;
  final double closeIconSize;
  final double actionButtonWidth;
  final double actionButtonHeight;
  final double actionButtonTextSize;
  final double actionButtonRadius;
  final double slotListMaxHeight;
  final double slotChipGap;
  final double slotChipHorizontalPadding;
  final double slotChipVerticalPadding;
  final double slotChipRadius;
  final double slotChipTextSize;
}

/// The booking-confirmation sentence, translated.
///
/// It cannot be an [AppText]: the discount is bold and the offer details are
/// per-booking data, so the copy was assembled from raw [TextSpan]s and never
/// went through [TranslatorService] — the title above it switched language
/// while this line stayed English.
///
/// So one placeholder template is translated as a whole sentence (word order
/// differs per language, and translating the fragments separately would give
/// nonsense), then the values are substituted back into the translated result.
/// The discount label is translated too, since it carries the word "discount".
/// A date is translated only when it is a word ("Today"); a formatted date is
/// left as-is and, like the time, isolated so bidi reordering cannot scramble
/// it inside a right-to-left sentence.
class _CouponMessage extends StatefulWidget {
  const _CouponMessage({
    required this.discount,
    required this.applicableFor,
    required this.date,
    required this.time,
    required this.fontSize,
  });

  final String discount;
  final String applicableFor;
  final String date;
  final String time;
  final double fontSize;

  @override
  State<_CouponMessage> createState() => _CouponMessageState();
}

class _CouponMessageState extends State<_CouponMessage> {
  /// Kept in `assets/i18n/source_phrases.json` so the warm-up pass covers it
  /// and the line never renders in English first.
  static const String _template =
      'You have received a coupon for a {discount} on the {applicable} for {date} at {time}';

  static final RegExp _placeholder = RegExp(
    r'\{(discount|applicable|date|time)\}',
  );

  late String _templateText;
  late String _discountText;
  late String _applicableText;
  late String _dateText;

  /// A word-shaped date ("Today", "Tomorrow") is copy and should follow the
  /// language; "26-Aug-25" is a formatted value and must not be sent through
  /// the translator, which would happily reword or reorder it.
  bool get _dateIsCopy => !RegExp(r'[0-9]').hasMatch(widget.date);

  @override
  void initState() {
    super.initState();
    _resetToSource();
    _resolve();
  }

  @override
  void didUpdateWidget(_CouponMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discount != widget.discount ||
        oldWidget.applicableFor != widget.applicableFor ||
        oldWidget.date != widget.date) {
      _resetToSource();
      _resolve();
    }
  }

  void _resetToSource() {
    _templateText = _template;
    _discountText = widget.discount;
    _applicableText = widget.applicableFor;
    _dateText = widget.date;
  }

  Future<void> _resolve() async {
    final sources = <String>[
      _template,
      widget.discount,
      widget.applicableFor,
      if (_dateIsCopy) widget.date,
    ];

    // A cached hit paints in the first frame, so a pre-warmed language never
    // shows English and then swaps it out mid-view.
    final cached = sources.map(TranslatorService.cached).toList();
    if (cached.every((value) => value != null)) {
      _apply(cached.cast<String>());
      return;
    }

    final results = await Future.wait(sources.map(TranslatorService.translate));
    if (!mounted ||
        widget.discount != sources[1] ||
        widget.applicableFor != sources[2] ||
        (_dateIsCopy && widget.date != sources[3])) {
      return;
    }
    setState(() => _apply(results));
  }

  void _apply(List<String> values) {
    _templateText = values[0];
    _discountText = values[1];
    _applicableText = values[2];
    _dateText = values.length > 3 ? values[3] : widget.date;
  }

  /// Wraps [value] in a first-strong isolate so the bidi algorithm treats it as
  /// one directional run.
  ///
  /// Without it, "26-Aug-25" dropped into an Arabic sentence has its
  /// hyphen-separated parts reordered by the surrounding right-to-left context
  /// and renders as "Aug-26-25" — the same characters, a different date.
  static const String _firstStrongIsolate = '\u2068';
  static const String _popDirectionalIsolate = '\u2069';

  static String _isolate(String value) =>
      '$_firstStrongIsolate$value$_popDirectionalIsolate';

  List<TextSpan> _buildSpans() {
    // If a translation came back without the placeholders intact there is
    // nothing to fill, so fall back to the English template rather than
    // rendering a sentence with the booking details missing.
    final template =
        _placeholder.hasMatch(_templateText) ? _templateText : _template;

    final spans = <TextSpan>[];
    var cursor = 0;

    for (final match in _placeholder.allMatches(template)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: template.substring(cursor, match.start)));
      }

      switch (match.group(1)) {
        case 'discount':
          spans.add(
            TextSpan(
              text: _discountText,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        case 'applicable':
          spans.add(TextSpan(text: _applicableText));
        case 'date':
          spans.add(
            TextSpan(text: _dateIsCopy ? _dateText : _isolate(_dateText)),
          );
        default:
          spans.add(TextSpan(text: _isolate(widget.time)));
      }

      cursor = match.end;
    }

    if (cursor < template.length) {
      spans.add(TextSpan(text: template.substring(cursor)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      // Follows the translated copy rather than the app locale, so an
      // Arabic sentence lays out right-to-left instead of starting its
      // punctuation on the wrong side.
      textDirection: Bidi.detectRtlDirectionality(_templateText)
          ? TextDirection.rtl
          : TextDirection.ltr,
      text: TextSpan(
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w400,
          color: appTextColor2,
          height: 1.3,
        ),
        children: _buildSpans(),
      ),
    );
  }
}
