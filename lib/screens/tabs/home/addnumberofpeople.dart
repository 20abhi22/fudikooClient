import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/reservation/new-reservation-model.dart';
import 'package:fudikoclient/service/reservation/reservation-service.dart';
import 'package:fudikoclient/utils/constants.dart';

enum ModalStep { selectPeople, selectDateTime, confirmation }

class NumberOfPeopleModal extends StatefulWidget {
  final String uuid;
  final int initialPeopleCount;
  final int minPeople;
  final int maxPeople;
  final VoidCallback? onBookingComplete;

  const NumberOfPeopleModal({
    super.key,
    required this.uuid,
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
    final now = DateTime.now();
    _selectedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final hour = now.hour;
    final minute = now.minute;
    final period = hour >= 12 ? "PM" : "AM";
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    _selectedTime =
        "${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";

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
    setState(() {
      switch (_currentStep) {
        case ModalStep.selectPeople:
          _currentStep = ModalStep.selectDateTime;
          break;
        case ModalStep.selectDateTime:
          _processBooking();
          break;
        case ModalStep.confirmation:
          _closeModal();
          break;
      }
    });
  }

  void _previousStep() {
    setState(() {
      switch (_currentStep) {
        case ModalStep.selectDateTime:
          _currentStep = ModalStep.selectPeople;
          break;
        case ModalStep.confirmation:
          _currentStep = ModalStep.selectDateTime;
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
    print(_selectedDate);
    print(_selectedTime);
    print(widget.uuid);
    print(_peopleCount);
    NewReservationModel reservationdata = NewReservationModel(
      people: _peopleCount.toString(),
      id: widget.uuid,
      time: _selectedTime!,
      date: _selectedDate!,
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
      case ModalStep.selectDateTime:
        return 'Select Date & Time';
      case ModalStep.confirmation:
        return 'Booking Confirmed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildProgressIndicator(), _buildContent()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index <= _currentStep.index;
        bool isCurrent = index == _currentStep.index;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: isCurrent ? 30.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).primaryColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      }),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.all(24.w),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentStepContent(),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case ModalStep.selectPeople:
        return _buildPeopleSelector();
      case ModalStep.selectDateTime:
        return _buildDateTimeSelector();
      case ModalStep.confirmation:
        return _buildConfirmation();
    }
  }

  Widget _buildPeopleSelector() {
    return Column(
      key: const ValueKey('people_selector'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeader(),
        SizedBox(height: 30.h),
        AppText(
          text: _getStepTitle(),
          size: 14,
          fontWeight: FontWeight.w600,
          color: appTextColor2,
        ),
        SizedBox(height: 15.h),
        _buildPeopleCounter(),
        SizedBox(height: 40.h),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep != ModalStep.selectPeople)
          GestureDetector(
            onTap: _previousStep,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: appTextColor,
                size: 20.sp,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        GestureDetector(
          onTap: _closeModal,
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.close, color: appTextColor, size: 20.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleCounter() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 70.w,
        height: 70.h,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.grey[300] : Colors.grey[50],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isLeft ? 25.r : 0),
            bottomLeft: Radius.circular(isLeft ? 25.r : 0),
            topRight: Radius.circular(isLeft ? 0 : 25.r),
            bottomRight: Radius.circular(isLeft ? 0 : 25.r),
          ),
        ),
        child: Icon(
          icon,
          size: 24.sp,
          color: isEnabled ? appTextColor2 : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildCounterDisplay() {
    return Container(
      width: 80.w,
      height: 70.h,
      decoration: const BoxDecoration(color: Colors.white),
      child: Center(
        child: AppText(
          text: _peopleCount.toString(),
          size: 24,
          fontWeight: FontWeight.w600,
          color: appTextColor2,
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      key: const ValueKey('datetime_selector'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeader(),
        SizedBox(height: 30.h),
        AppText(
          text: _getStepTitle(),
          size: 14,
          fontWeight: FontWeight.w600,
          color: appTextColor2,
        ),
        SizedBox(height: 30.h),
        SizedBox(
          height: 100.h,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime,
            initialDateTime: DateTime.now(),
            use24hFormat: false,
            onDateTimeChanged: (DateTime newDateTime) {
              setState(() {
                _selectedDate =
                    "${newDateTime.year}-${newDateTime.month.toString().padLeft(2, '0')}-${newDateTime.day.toString().padLeft(2, '0')}";

                int hour = newDateTime.hour;
                int minute = newDateTime.minute;
                String period = hour >= 12 ? "PM" : "AM";
                int hour12 = hour % 12 == 0 ? 12 : hour % 12;

                _selectedTime =
                    "${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
              });
            },
          ),
        ),

        SizedBox(height: 40.h),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildConfirmation() {
    return Column(
      key: const ValueKey('confirmation'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80.w,
          height: 80.h,
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 50.sp,
            color: Colors.green[600],
          ),
        ),
        SizedBox(height: 24.h),
        AppText(
          text: "Booking Successful!",
          size: 22,
          fontWeight: FontWeight.w600,
          color: appTextColor3,
        ),
        SizedBox(height: 16.h),
        AppText(
          text:
              "Your table for $_peopleCount people has been reserved successfully.",
          size: 14,
          fontWeight: FontWeight.w400,
          color: appTextColor2,
          isCentered: true,
          lineSpacing: 1.3,
        ),
        SizedBox(height: 32.h),
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: AppButton(
            text: "Done",
            onPressed: _closeModal,
            borderRadius: 12.r,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
      return SizedBox(
        height: 50.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      width: 150.w,
      height: 50.h,
      child: AppButton(
        text: _getButtonText(),
        onPressed: _nextStep,
        borderRadius: 12.r,
        size: 16,
      ),
    );
  }

  String _getButtonText() {
    switch (_currentStep) {
      case ModalStep.selectPeople:
        return 'Next';
      case ModalStep.selectDateTime:
        return 'Book';
      case ModalStep.confirmation:
        return 'Done';
    }
  }
}
