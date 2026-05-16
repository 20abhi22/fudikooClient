import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/inquery/delete-inquery-model.dart';
import 'package:fudikoclient/model/inquery/list-party-inquery-modal.dart';
import 'package:fudikoclient/screens/tabs/inquery/inquery/updateinquery.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class InqueryBox extends StatefulWidget {
  final VoidCallback onDeleted;
  final VoidCallback onEdit;
  final String uuid;
  final String enquiryId;
  final String userId;
  final String lat;
  final String lng;
  final String menuItems;
  final int people;
  final String date;
  final String time;
  final String estimatedAmount;
  final String searchRadius;
  final String expirationDate;
  final String expirationTime;
  final String status;
  final InqueryModel enquiry;

  const InqueryBox({
    super.key,
    required this.uuid,
    required this.enquiryId,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.menuItems,
    required this.people,
    required this.date,
    required this.time,
    required this.estimatedAmount,
    required this.searchRadius,
    required this.expirationDate,
    required this.expirationTime,
    required this.status,
    required this.onDeleted,
    required this.onEdit,
    required this.enquiry,
  });

  @override
  State<InqueryBox> createState() => _InqueryBoxState();
}

class _InqueryBoxState extends State<InqueryBox> {
  final InqueryService inqueryService = InqueryService();

  String placeName = '';
  late DateTime expiryDateTime;
  String countdown = '';
  Timer? timer;
  bool isExpired = false;

  @override
  void initState() {
    super.initState();
    fetchPlace();

    // Combine date + time
    final dateTimeString = "${widget.enquiry.expirationDate} ${widget.enquiry.expirationTime}";
    expiryDateTime = DateFormat("yyyy-MM-dd hh:mm a").parse(dateTimeString);

    // Initial check
    isExpired = DateTime.now().isAfter(expiryDateTime);

    // Start countdown
    startCountdown();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = expiryDateTime.difference(DateTime.now());

      if (remaining.isNegative) {
        setState(() {
          countdown = "Expired";
          isExpired = true; // ✅ mark expired
        });
        timer?.cancel();
      } else {
        final hours = remaining.inHours.toString().padLeft(2, '0');
        final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        setState(() {
          countdown = "$hours:$minutes:$seconds";
        });
      }
    });
  }

  Future<void> fetchPlace() async {
    try {
      final lat = double.parse(widget.enquiry.lat);
      final lng = double.parse(widget.enquiry.lng);
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          placeName = [
            place.subLocality,
            place.locality,
          ].where((p) => p != null && p.isNotEmpty).join(', ');
          if (placeName.isEmpty) {
            placeName = place.country ?? "${widget.enquiry.lat}, ${widget.enquiry.lng}";
          }
        });
      } else {
        setState(() {
          placeName = "${widget.enquiry.lat}, ${widget.enquiry.lng}";
        });
      }
    } catch (_) {
      setState(() {
        placeName = "${widget.enquiry.lat}, ${widget.enquiry.lng}";
      });
    }
  }

  void onEdit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600),
          child: UpdateInquery(
            uuid: widget.enquiry.uuid,
            enquiryId: widget.enquiry.enquiryId,
            userId: widget.enquiry.userId,
            lat: widget.enquiry.lat,
            lng: widget.enquiry.lng,
            menuItems: widget.enquiry.menuItems,
            people: widget.enquiry.people,
            date: widget.enquiry.date,
            time: widget.enquiry.time,
            estimatedAmount: widget.enquiry.estimatedAmount,
            searchRadius: widget.enquiry.searchRadius,
            expirationDate: widget.enquiry.expirationDate,
            expirationTime: widget.enquiry.expirationTime,
            status: widget.enquiry.status,
            placeName: placeName,
            onEnquiryTap: (_) {},
            onReviewTap: (_) {},
            onEdit: widget.onEdit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteInquery() async {
    final response = await inqueryService.deleteInquery(
      DeleteInqueryModel(enquiryId: widget.enquiry.uuid),
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.status
              ? "Inquery deleted successfully"
              : "Something went wrong",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: response.status ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (response.status) widget.onDeleted();
  }

  Widget buildInfoRow(
    IconData icon,
    String text, {
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: appTextColor5, size: 18),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: fontWeight,
                color: color ?? appTextColor5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isConfirmed = widget.enquiry.status.toLowerCase() == "confirmed";
    final estimatedAmount = double.parse(widget.enquiry.estimatedAmount).toInt();
    final radius = double.parse(widget.enquiry.searchRadius).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: widget.enquiry.enquiryId,
                          size: 20,
                          fontWeight: FontWeight.bold,
                          color: appTextColor3,
                        ),
                        SizedBox(height: 10.h),
                        buildInfoRow(
                          Icons.wallet,
                          "$estimatedAmount Per Person",
                          fontWeight: FontWeight.w900,
                        ),
                        buildInfoRow(
                          Icons.calendar_today_sharp,
                          "${widget.enquiry.date} & ${widget.enquiry.time}",
                          fontWeight: FontWeight.w700,
                        ),
                        buildInfoRow(
                          Icons.people,
                          "${widget.enquiry.people} Person",
                          fontWeight: FontWeight.w700,
                        ),
                        buildInfoRow(
                          Icons.dashboard,
                          widget.enquiry.menuItems.split(',').join(" , "),
                        ),
                        buildInfoRow(
                          Icons.analytics,
                          placeName.isEmpty
                              ? "${widget.enquiry.lat}, ${widget.enquiry.lng} - ${widget.enquiry.searchRadius}km Radius"
                              : "$placeName - ${widget.enquiry.searchRadius}km Radius",
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: widget.enquiry.expirationDate,
                        size: 10,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      const SizedBox(height: 5),
                      AppText(
                        text: widget.enquiry.expirationTime,
                        size: 10,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.h),
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        Icon(
          isConfirmed ? Icons.check_circle : Icons.timer,
          size: 15.w,
          color: isConfirmed ? Colors.green : Colors.red,
        ),
        SizedBox(width: 5.w),

        AppText(
          text: isConfirmed ? "Confirmed" : countdown,
          size: 11,
          fontWeight: FontWeight.w600,
          color: isConfirmed ? Colors.green : Colors.red,
        ),
      ],
    ),

    // Hide buttons if confirmed OR expired
    if (!isConfirmed && !isExpired)
      Row(
        children: [
          SizedBox(
            width: 50.w,
            height: 30.h,
            child: AppButton(
              text: "Edit",
              onPressed: onEdit,
              size: 11,
              borderRadius: 5,
              bgColor1: Colors.green,
              bgColor2: Colors.green,
            ),
          ),

          SizedBox(width: 5.w),

          SizedBox(
            width: 80.w,
            height: 30.h,
            child: AppButton(
              text: "Withdraw",
              onPressed: () {
                // existing dialog
              },
              size: 11,
              borderRadius: 5,
              bgColor1: Colors.red,
              bgColor2: Colors.red,
            ),
          ),
        ],
      ),
  ],
)
            ],
          ),
        ),
      ),
    );
  }
}
