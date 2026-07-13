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
import 'package:intl/intl.dart';

enum ModalStep { selectPeople, confirmation }

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
  });

  @override
  State<NumberOfPeopleModal> createState() => _NumberOfPeopleModalState();
}

class _NumberOfPeopleModalState extends State<NumberOfPeopleModal>
    with SingleTickerProviderStateMixin {
  late int _peopleCount;
  ModalStep _currentStep = ModalStep.selectPeople;
  ReservationService reservationService = ReservationService();
  String? _selectedDate;
  String? _selectedTime;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _peopleCount = widget.initialPeopleCount;
    // ← Initialize with current date/time so picker has a default value
    _selectedDate = _formatDate(_resolvedReservationDate);
    _selectedTime = _resolveOfferTime();

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

  void _nextStep() {
    switch (_currentStep) {
      case ModalStep.selectPeople:
        _processBooking();
        break;
      case ModalStep.confirmation:
        _closeModal();
        break;
    }
  }

  void _previousStep() {
    setState(() {
      switch (_currentStep) {
        case ModalStep.confirmation:
          _currentStep = ModalStep.selectPeople;
          break;
        case ModalStep.selectPeople:
          _closeModal();
          break;
      }
    });
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
    NewReservationModelResponse response = await reservationService
        .createReservation(reservationdata);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _closeModal() {
    Navigator.of(context).pop();
    widget.onBookingComplete?.call();
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case ModalStep.selectPeople:
        return 'Number of People';
      case ModalStep.confirmation:
        return 'Booking Confirmed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics(context);
    
    final size = MediaQuery.sizeOf(context);
final isShortLandscape =
    size.width > size.height && size.height < 450;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SafeArea(
        top: false,
        child: Align(
          // alignment: Alignment.bottomCenter,
          // heightFactor: 1,
          alignment: isShortLandscape
          ? Alignment.center
          : Alignment.bottomCenter,
          child: ConstrainedBox(
            // constraints: BoxConstraints(
            //   maxWidth: metrics.modalWidth,
            //   maxHeight: metrics.maxHeight,
            // ),
            constraints: BoxConstraints(
  maxWidth: metrics.modalWidth,
  minHeight: 280,
  maxHeight: MediaQuery.of(context).size.height * 0.82,
),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              // curve: Curves.easeInOut,\
              transitionBuilder: (child, animation) =>
      FadeTransition(opacity: animation, child: child),
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
          ),
        ),
      ),
    );
  }

  _BookingModalMetrics _metrics(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    // // final isTablet = Breakpoints.isTablet(width);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isLandscape = size.width > size.height;
    // Scale UI based on available height.
// Portrait => 1.0
// Short landscape phones => ~0.75
final heightFactor =
    isTablet ? 1.0 : (height / 700).clamp(0.75, 1.0);
    
    // final isShortLandscape =
    // !isTablet &&
    // isLandscape &&
    // height < 450;

    return _BookingModalMetrics(
      isTablet: isTablet,
      // modalWidth: isTablet ? width * (isLandscape ? 0.48 : 0.66) : width,
    //   modalWidth: isTablet
    // ? (isLandscape
    //       ? (width * 0.42).clamp(420.0, 520.0)
    //       : (width * 0.62).clamp(420.0, 560.0))
    // : width,
    //   // maxHeight: height * (isTablet ? 0.72 : 0.8),
    //   maxHeight: height *
    // (isTablet
    //     ? (isLandscape ? 0.88 : 0.72)
    //     : 0.85),
//     modalWidth: isTablet
//     ? (isLandscape
//         ? (width * 0.42).clamp(420.0, 520.0)
//         : (width * 0.62).clamp(420.0, 560.0))
//     : isShortLandscape
//         ? width * 0.75
//         : width,

// maxHeight: isShortLandscape
//     ? height * 0.95
//     : height * (isTablet
//         ? (isLandscape ? 0.88 : 0.72)
//         : 0.85),
modalWidth: isTablet
    ? (isLandscape
          ? (width * 0.42).clamp(420.0, 520.0)
          : (width * 0.62).clamp(420.0, 560.0))
    : width,

maxHeight: isTablet
    ? height * (isLandscape ? 0.88 : 0.72)
    : height * 0.82,
      outerHorizontalPadding: isTablet ? 24.0 : 20.w,
      outerTopPadding: isTablet ? 20.0 : 16.h,
      outerBottomPadding: isTablet ? 28.0 : 40.h,
      // progressCurrentWidth: isTablet ? 42.0 : 30.w,
      // progressDotWidth: isTablet ? 10.0 : 8.w,
      // progressHeight: isTablet ? 10.0 : 8.h,
      // progressGap: isTablet ? 6.0 : 4.w,
      progressCurrentWidth:
    isTablet ? 42 : 30 * heightFactor,

progressDotWidth:
    isTablet ? 10 : 8 * heightFactor,

progressHeight:
    isTablet ? 10 : 8 * heightFactor,

progressGap:
    isTablet ? 6 : 4 * heightFactor,
      contentRadius: isTablet ? 24.0 : 20.r,
      // contentPadding: isTablet ? 32.0 : 24.w,
    //   contentPadding: isShortLandscape
    // ? 16
    // : isTablet
    //     ? 32
    //     : 24.w,
    contentPadding:
    isTablet ? 32 : 24 * heightFactor,
      // sectionGap: isTablet ? 36.0 : 30.h,
      // largeGap: isTablet ? 48.0 : 40.h,
    //  sectionGap: isShortLandscape
    // ? 14
    // : isTablet
    //     ? (isLandscape ? 24 : 36)
    //     : 30.h,

// largeGap: isShortLandscape
//     ? 18
//     : isTablet
//         ? (isLandscape ? 32 : 48)
//         : 40.h,
sectionGap: isTablet
    ? (isLandscape ? 24 : 36)
    : 30 * heightFactor,

largeGap: isTablet
    ? (isLandscape ? 32 : 48)
    : 40 * heightFactor,
      titleSize: isTablet ? AppDimensions.body(context) + 2 : 14.0,
      // counterButtonWidth: isTablet ? 84.0 : 70.w,
      // counterButtonHeight: isTablet ? 84.0 : 70.h,
//       counterButtonWidth: isTablet
//     ? (isLandscape ? 72.0 : 84.0)
//     : 70.w,

// counterButtonHeight: isTablet
//     ? (isLandscape ? 72.0 : 84.0)
//     : 70.h,
//       counterDisplayWidth: isTablet ? 96.0 : 80.w,
// counterButtonWidth: isShortLandscape
//     ? 56
//     : isTablet
//         ? (isLandscape ? 72 : 84)
//         : 70.w,

// counterButtonHeight: isShortLandscape
//     ? 56
//     : isTablet
//         ? (isLandscape ? 72 : 84)
//         : 70.h,

// counterDisplayWidth: isShortLandscape
//     ? 64
//     : isTablet
//         ? 96
//         : 80.w,
counterButtonWidth:
    isTablet ? (isLandscape ? 72 : 84) : 70 * heightFactor,

counterButtonHeight:
    isTablet ? (isLandscape ? 72 : 84) : 70 * heightFactor,

counterDisplayWidth:
    isTablet ? 96 : 80 * heightFactor,
      // counterTextSize: isTablet ? 30.0 : 24.0,
      counterTextSize:
    isTablet ? 30 : 24 * heightFactor,
      headerIconContainerPadding: isTablet ? 10.0 : 8.w,
      headerIconSize: isTablet ? 24.0 : 20.sp,
      // confirmationIconSize: isTablet ? 82.0 : 78.w,
    //   confirmationIconSize: isShortLandscape
    // ? 56
    // : isTablet
    //     ? 82
    //     : 78.w,
    confirmationIconSize:
    isTablet ? 82 : 78 * heightFactor,
      confirmationImageSize: isTablet ? 56.0 : 50.sp,
      confirmationTitleSize: isTablet ? 26.0 : 22.0,
      confirmationBodySize: isTablet ? AppDimensions.body(context) : 14.sp,
      closeIconSize: isTablet ? 28.0 : 25.w,
      // actionButtonWidth: isTablet ? 190.0 : 150.w,
      // actionButtonWidth: isTablet ? 220.0 : 150.w,
      // actionButtonHeight: isTablet ? 54.0 : 50.h,
      actionButtonWidth:
    isTablet ? 220 : 150 * heightFactor,

actionButtonHeight:
    isTablet ? 54 : 50 * heightFactor,
      actionButtonTextSize: isTablet ? 18.0 : 16.0,
      actionButtonRadius: isTablet ? 14.0 : 12.r,
    );
  }

  Widget _buildProgressIndicator(_BookingModalMetrics metrics) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(ModalStep.values.length, (index) {
        bool isActive = index <= _currentStep.index;
        bool isCurrent = index == _currentStep.index;

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
      child: SizedBox(
        height: metrics.maxHeight * 0.72,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
            },
          child: _buildCurrentStepContent(),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case ModalStep.selectPeople:
        return _buildPeopleSelector();
      case ModalStep.confirmation:
        return _buildConfirmation();
    }
  }

  Widget _buildPeopleSelector() {
    final metrics = _metrics(context);
    return Column(
      key: const ValueKey('people_selector'),
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
        if (_currentStep != ModalStep.selectPeople)
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
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: metrics.confirmationBodySize,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
              height: 1.3,
            ),
            children: [
              const TextSpan(text: 'You have received a coupon for a '),
              TextSpan(
                text: discountText,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: ' on the $applicableFor for $dateText at $timeText',
              ),
            ],
          ),
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

  String _resolveOfferTime() {
    final startTime = widget.offer?.startTime.trim();
    if (startTime != null && startTime.isNotEmpty) return startTime;

    final value = _resolvedReservationDate;
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
    required this.modalWidth,
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
  });

  final bool isTablet;
  final double modalWidth;
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
}
