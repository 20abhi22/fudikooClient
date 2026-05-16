import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/inquery/list-catering-inquery-model.dart';
import 'package:fudikoclient/screens/tabs/inquery/ctInquery/updatectinquery.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/model/inquery/delete-inquery-model.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class CtInqueryBox extends StatefulWidget {
  final CateringInqueryModel enquiry;
  final VoidCallback onCancelTap;
  final VoidCallback onEdit;

  const CtInqueryBox({
    super.key,
    required this.enquiry,
    required this.onCancelTap,
    required this.onEdit,
  });

  @override
  State<CtInqueryBox> createState() => _CtInqueryBoxState();
}

class _CtInqueryBoxState extends State<CtInqueryBox> {
  final MapService mapService = MapService();
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

    final dateTimeString =
        "${widget.enquiry.expirationDate} ${widget.enquiry.expirationTime}";
    expiryDateTime = DateFormat("yyyy-MM-dd hh:mm a").parse(dateTimeString);
    isExpired = DateTime.now().isAfter(expiryDateTime);
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
          isExpired = true;
        });
        timer?.cancel();
      } else {
        final h = remaining.inHours.toString().padLeft(2, '0');
        final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
        final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        setState(() => countdown = "$h:$m:$s");
      }
    });
  }

  void onEdit() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: UpdateCtInquery(
          enquiry: widget.enquiry,
          placeName: placeName,
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

  // Future<void> fetchPlace() async {
  //   final response = await mapService.getPlaceName(
  //     widget.enquiry.lat,
  //     widget.enquiry.lng,
  //   );
  //   setState(() {
  //     placeName = (response != null && response.isNotEmpty)
  //         ? response.split(',')[1]
  //         : "Unknown Location";
  //   });
  // }


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
  // Future<void> fetchPlace() async {
  //   final response = await mapService.getPlaceName(
  //     widget.enquiry.lat,
  //     widget.enquiry.lng,
  //   );
  //   setState(() {
  //     if (response != null && response.isNotEmpty) {
  //       final parts = response.split(',');
  //       placeName = parts.length > 1
  //           ? parts[1]
  //                 .trim() // "City" part
  //           : parts[0].trim(); // fallback to first part if no comma
  //     } else {
  //       placeName =
  //           "${widget.enquiry.lat}, ${widget.enquiry.lng}"; // raw coords as fallback
  //     }
  //   });
  // }

  Future<void> deleteEnquiry() async {
    final response = await inqueryService.deleteCateringInquery(
      DeleteInqueryModel(enquiryId: widget.enquiry.uuid),
    );

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.status
              ? "Enquiry withdrawn successfully"
              : "Something went wrong",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: response.status ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (response.status) widget.onCancelTap();
  }

  Widget _infoRow(
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
  bool isConfirmed =
      widget.enquiry.status.toLowerCase() == "confirmed";

  final amount =
      double.tryParse(widget.enquiry.estimatedAmount)?.toInt() ??
      widget.enquiry.estimatedAmount;

  final radius =
      double.tryParse(widget.enquiry.searchRadius)?.toInt() ??
      widget.enquiry.searchRadius;

  return Padding(
    padding: EdgeInsets.only(bottom: 20.h),
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

                      _infoRow(
                        Icons.wallet,
                        "$amount Per Person",
                        fontWeight: FontWeight.w900,
                      ),

                      _infoRow(
                        Icons.calendar_today_sharp,
                        "${widget.enquiry.date} & ${widget.enquiry.time}",
                        fontWeight: FontWeight.w700,
                      ),

                      _infoRow(
                        Icons.people,
                        "${widget.enquiry.people} Person",
                        fontWeight: FontWeight.w700,
                      ),

                      _infoRow(
                        Icons.dashboard,
                        widget.enquiry.menuItems
                            .split(',')
                            .join(" , "),
                      ),

                      _infoRow(
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

                    SizedBox(height: 5.h),

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

            // ✅ Same as InqueryBox
            Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        Icon(
          widget.enquiry.status.toLowerCase() == "confirmed"
              ? Icons.check_circle
              : Icons.timer,
          size: 15.w,
          color: widget.enquiry.status.toLowerCase() == "confirmed"
              ? Colors.green
              : Colors.red,
        ),
        SizedBox(width: 5.w),

        AppText(
          text: widget.enquiry.status.toLowerCase() == "confirmed"
              ? "Confirmed"
              : countdown,
          size: 11,
          fontWeight: FontWeight.w600,
          color: widget.enquiry.status.toLowerCase() == "confirmed"
              ? Colors.green
              : Colors.red,
        ),
      ],
    ),

    // Hide buttons if confirmed OR expired
    if (widget.enquiry.status.toLowerCase() != "confirmed" &&
        !isExpired)
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
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 30.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            text:
                                "Are you sure you want to withdraw this enquiry?",
                            isCentered: true,
                            lineSpacing: 1.5,
                            size: 12,
                            fontWeight: FontWeight.w500,
                            color: appTextColor2,
                          ),

                          SizedBox(height: 20.h),

                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 30.h,
                                  child: AppButton(
                                    text: "Yes",
                                    onPressed: deleteEnquiry,
                                    size: 11,
                                    bgColor1: Colors.green,
                                    bgColor2: Colors.green,
                                    borderRadius: 10,
                                  ),
                                ),
                              ),

                              SizedBox(width: 10.w),

                              Expanded(
                                child: SizedBox(
                                  height: 30.h,
                                  child: AppButton(
                                    text: "No",
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    size: 11,
                                    bgColor1: Colors.red,
                                    bgColor2: Colors.red,
                                    borderRadius: 10,
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






































