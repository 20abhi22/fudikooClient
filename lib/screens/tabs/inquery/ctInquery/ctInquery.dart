import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/model/inquery/create-catering-inquery-model.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CtInquery extends StatefulWidget { 
  // final VoidCallback onReviewTap;
  final Function(Map<String, String> data) onReviewTap;
  final VoidCallback viewEnquiryOnTap;
  const CtInquery({
    super.key,
    required this.onReviewTap,
    required this.viewEnquiryOnTap,
  });

  @override
  State<CtInquery> createState() => _CtInqueryState();
}

class _CtInqueryState extends State<CtInquery> {
  // bool isReviewOnClick = false;
  // ── service ──────────────────────────────────────────
  final InqueryService _cateringInqueryService = InqueryService();

  // ── state ────────────────────────────────────────────
  bool isLoading = false;

  // ── controllers ──────────────────────────────────────
  final TextEditingController menuController = TextEditingController();
  final TextEditingController otherServicesController = TextEditingController();
  final TextEditingController peopleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  // ── date & time ──────────────────────────────────────
  DateTime? selectedDateTime; // for "Date & Time" field
  DateTime? expirationDate; // for "Enquiry valid for" date
  TimeOfDay? expirationTime; // for "Enquiry valid for" time

  // ── location ─────────────────────────────────────────
  String lat = '';
  String lng = '';
  String searchRadius = '20';
  String locationLabel = 'Select Location';

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

  // ── submit ───────────────────────────────────────────
  Future<void> _submitEnquiry() async {
    // if (menuController.text.isEmpty ||
    //     peopleController.text.isEmpty ||
    //     amountController.text.isEmpty ||
    //     selectedDateTime == null ||
    //     expirationDate == null ||
    //     expirationTime == null ||
    //     lat.isEmpty) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
    //   return;
    // }
    if (menuController.text.isEmpty) {
      ScaffoldMessenger.of( 
        context,
      ).showSnackBar(const SnackBar(content: Text('Menu is empty')));
      return;
    }
    if (peopleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('People is empty')));
      return;
    }
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amount is empty')));
      return;
    }
    if (selectedDateTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Date & Time not selected')));
      return;
    }
    if (expirationDate == null || expirationTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiration date/time not selected')),
      );
      return;
    }
    if (lat.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location not selected')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enquiry expiry must be before the event date & time'),
        ),
      );
      return;
    }

    if (expirationDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry expiry cannot be in the past')),
      );
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

  // ── date & time picker ───────────────────────────────
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        children: [
          // ── view enquiries link ──
          GestureDetector(
            onTap: widget.viewEnquiryOnTap,
            child: Row(
              children: [
                Icon(
                  Icons.content_paste_search_sharp,
                  size: 20.w,
                  color: appLinkColor2,
                ),
                SizedBox(width: 5.w),
                AppText(
                  text: "View Enquiries",
                  size: 15,
                  fontWeight: FontWeight.w400,
                  color: appLinkColor2,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // DescriptionTextArea(
          //   hintText:
          //       "Example: Chicken Biriyani , Porotta ,Rotti  , Payasam, Butter Chicken , Ice cream,.Salad",
          //   topHintText: "Your Menu",
          //   iconColor: appTextColor2,
          //   icon: Icons.dashboard,
          //   maxLength: 300,
          // ),
          // ── menu ──
          DescriptionTextArea(
            hintText:
                "Example: Chicken Biriyani , Porotta ,Rotti  , Payasam, Butter Chicken , Ice cream, Salad",
            topHintText: "Your Menu",
            iconColor: appTextColor2,
            icon: Icons.dashboard,
            maxLength: 300,
            controller: menuController,
          ),
          SizedBox(height: 20.h),
          // AppTextFeild(
          //   text: "Other Services",
          //   icon: Icons.handshake,
          //   iconColor: appTextColor2,
          // ),
          // ── other services ──
          AppTextFeild(
            text: "Other Services",
            icon: Icons.handshake,
            iconColor: appTextColor2,
            controller: otherServicesController,
          ),
          SizedBox(height: 20.h),

          // AppTextFeild(
          //   text: "Number of  People",
          //   icon: Icons.people,
          //   iconColor: appTextColor2,
          // ),
          //---people----
          AppTextFeild(
            text: "Number of People",
            icon: Icons.people,
            iconColor: appTextColor2,
            controller: peopleController,
          ),
          SizedBox(height: 20.h),
          // GestureDetector(
          //   onTap: () => _selectDateTime(context),
          //   child: AppTextFeild(
          //     text: "Date & Time",
          //     icon: Icons.calendar_today_sharp,
          //     iconColor: appTextColor2,
          //   ),
          // ),
          // ── date & time ──
          GestureDetector(
            onTap: () => _selectDateTime(context),
            child: AppTextFeild(
              text: selectedDateTime != null
                  ? "${_formatDate(selectedDateTime!)} ${_formatTime(selectedDateTime!.hour, selectedDateTime!.minute)}"
                  : "Date & Time",
              icon: Icons.calendar_today_sharp,
              iconColor: appTextColor2,
              isreadonly: true,
            ),
          ),
          SizedBox(height: 20.h),

          // AppTextFeild(
          //   text: "Expected amount per person",
          //   icon: Icons.wallet,
          //   iconColor: appTextColor2,
          // ),
          AppTextFeild(
            text: "Expected amount per person",
            icon: Icons.wallet,
            iconColor: appTextColor2,
            controller: amountController,
          ),
          SizedBox(height: 20.h),
          // GestureDetector(
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (context) => LocationSelect(
          //       returndata: (lat, lng, distance) {

          //           print(lat);
          //           print(lng);
          //           print(distance);
          //         },
          //     )),
          //   ),
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
                        locationLabel = '$newLat, $newLng - ${distance}km Radius';
                      });
                    }
                  },
                ),
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(16.w),
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
                // child: AppText(
                //   text: "Moscow City - 20km Radius",
                //   size: 15,
                //   fontWeight: FontWeight.w400,
                //   color: Colors.white,
                // ),
                child: Center(
                  child: AppText(
                    text: locationLabel,
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 40.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 4.h),
                child: Text(
                  'Enquiry valid for',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: appSecondaryBackgroundColor,
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: Colors.black54),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // _IconTextButton(
                    //   icon: Icons.calendar_today,
                    //   label: 'Date',
                    //   onTap: () => showDatePicker(
                    //     context: context,
                    //     initialDate: DateTime.now(),
                    //     firstDate: DateTime(2020),
                    //     lastDate: DateTime(2101),
                    //   ),
                    // ),
                    _IconTextButton(
                      icon: Icons.calendar_today,
                      label: expirationDate != null
                          ? _formatDate(expirationDate!)
                          : 'Date',
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null)
                          setState(() => expirationDate = picked);
                      },
                    ),
                    // _IconTextButton(
                    //   icon: Icons.access_time,
                    //   label: 'Time',
                    //   onTap: () {},
                    // ),
                    _IconTextButton(
                      icon: Icons.access_time,
                      label: expirationTime != null
                          ? _formatTime(
                              expirationTime!.hour,
                              expirationTime!.minute,
                            )
                          : 'Time',
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null)
                          setState(() => expirationTime = picked);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 30.h),
          // SizedBox(
          //   width: 150.w,
          //   height: 50.h,
          //   child: AppButton(
          //     text: "Review",
          //     onPressed: widget.onReviewTap,
          //     size: 15,
          //     borderRadius: 10,
          //     bgColor1: Colors.green,
          //     bgColor2: Colors.green,
          //   ),
          // ),
          // SizedBox(height: 30.h),
          // ── submit button ──
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

class _IconTextButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconTextButton({
    required this.icon,
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
          Icon(icon, size: 20.w, color: Colors.black),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: appTextColor2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _selectDateTime(BuildContext context) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2101),
  );

  if (pickedDate != null) {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      // Combine date & time
      DateTime fullDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }
  }
}
