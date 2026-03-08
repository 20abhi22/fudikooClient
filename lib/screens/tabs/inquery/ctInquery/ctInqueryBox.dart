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
                          "${widget.enquiry.date} - ${widget.enquiry.time}",
                          fontWeight: FontWeight.w700,
                        ),
                        _infoRow(
                          Icons.people,
                          "${widget.enquiry.people} Person",
                          fontWeight: FontWeight.w700,
                        ),
                        _infoRow(Icons.dashboard, widget.enquiry.menuItems),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer, size: 15.w, color: Colors.red),
                      SizedBox(width: 5.w),
                      AppText(
                        text: countdown,
                        size: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  if (!isExpired)
                    Row(
                      children: [
                        SizedBox(
                          width: 50.w,
                          height: 30.h,
                          child: AppButton(
                            text: "Edit",
                            onPressed:
                                onEdit, // ← fires callback to parent
                            size: 11,
                            borderRadius: 5,
                            bgColor1: Colors.green,
                            bgColor2: Colors.green,
                          ),
                        ),
                        SizedBox(width: 5.w),

                        SizedBox(
                          width: 90.w,
                          height: 32.h,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}






































// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fudikoclient/components/appbutton.dart';
// import 'package:fudikoclient/components/apptext.dart';
// import 'package:fudikoclient/model/inquery/list-catering-inquery-model.dart';
// import 'package:fudikoclient/utils/constants.dart';

// class CtInqueryBox extends StatelessWidget {
//   final VoidCallback onCancelTap;
//   final CateringInqueryModel enquiry;
//   const  CtInqueryBox({
//     super.key,
//     required this.onCancelTap,
//     required this.enquiry,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 20.h),
//       child: GestureDetector(
//         onTap: () {
//           // Navigator.push(
//           //   context,
//           //   MaterialPageRoute(builder: (context) => QrCoupon()),
//           // );
//         },
//         child: Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20.r),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.2),
//                 blurRadius: 10,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: EdgeInsets.all(20.w),
//             child: Column(
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       flex: 4,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           AppText(
//                             text: enquiry.enquiryId,
//                             size: 20,
//                             fontWeight: FontWeight.bold,
//                             color: appTextColor3,
//                           ),
//                           SizedBox(height: 10.h),
//                           // Row(
//                           //   crossAxisAlignment: CrossAxisAlignment.start,
//                           //   children: [
//                           //     Icon(
//                           //       Icons.wallet,
//                           //       color: appTextColor5,
//                           //       size: 18,
//                           //     ),
//                           //     SizedBox(width: 5.w),
//                           //     Flexible(
//                           //       child: RichText(
//                           //         text: TextSpan(
//                           //           children: [
//                           //             TextSpan(
//                           //               text: '1000',
//                           //               style: TextStyle(
//                           //                 fontSize: 15,
//                           //                 fontWeight: FontWeight.w900,
//                           //                 color: appTextColor5,
//                           //               ),
//                           //             ),
//                           //             TextSpan(
//                           //               text: ' Per Person',
//                           //               style: TextStyle(
//                           //                 fontSize: 15,
//                           //                 fontWeight: FontWeight.w500,
//                           //                 color: appTextColor5,
//                           //               ),
//                           //             ),
//                           //           ],
//                           //         ),
//                           //       ),
//                           //     ),
//                           //   ],
//                           // ),
//                           SizedBox(height: 10.h),
//                         _infoRow(
//                           Icons.wallet,
//                           '${enquiry.estimatedAmount}',
//                           ' Per Person',
//                         ),
//                           SizedBox(height: 10.h),
//                           // Row(
//                           //   crossAxisAlignment: CrossAxisAlignment.start,
//                           //   children: [
//                           //     Icon(
//                           //       Icons.calendar_today_sharp,
//                           //       color: appTextColor5,
//                           //       size: 18,
//                           //     ),
//                           //     SizedBox(width: 5.w),
//                           //     Flexible(
//                           //       child: RichText(
//                           //         text: TextSpan(
//                           //           children: [
//                           //             TextSpan(
//                           //               text: 'April 12',
//                           //               style: TextStyle(
//                           //                 fontSize: 15,
//                           //                 fontWeight: FontWeight.w700,
//                           //                 color: appTextColor5,
//                           //               ),
//                           //             ),
//                           //             TextSpan(
//                           //               text: ' - 2:30 pm',
//                           //               style: TextStyle(
//                           //                 fontSize: 15,
//                           //                 fontWeight: FontWeight.w500,
//                           //                 color: appTextColor5,
//                           //               ),
//                           //             ),
//                           //           ],
//                           //         ),
//                           //       ),
//                           //     ),
//                           //   ],
//                           // ),
//                           _infoRow(
//                           Icons.calendar_today_sharp,
//                           enquiry.date,
//                           ' - ${enquiry.time}',
//                         ),
//                           SizedBox(height: 10.h),
//                           // Row(
//                           //   crossAxisAlignment: CrossAxisAlignment.start,
//                           //   children: [
//                           //     Icon(
//                           //       Icons.people,
//                           //       color: appTextColor5,
//                           //       size: 18,
//                           //     ),
//                           //     SizedBox(width: 5.w),
//                           //     Flexible(
//                           //       child: RichText(
//                           //         text: TextSpan(
//                           //           children: [
//                           //             TextSpan(
//                           //               text: '12 ',
//                           //               style: TextStyle(
//                           //                 fontSize: 15,
//                           //                 fontWeight: FontWeight.w700,
//                           //                 color: appTextColor5,
//                           //               ),
//                           //             ),
//                           //             TextSpan(
//                           //               text: 'Person',
//                           //               style: TextStyle(
//                           //                 fontSize: 15,
//                           //                 fontWeight: FontWeight.w500,
//                           //                 color: appTextColor5,
//                           //               ),
//                           //             ),
//                           //           ],
//                           //         ),
//                           //       ),
//                           //     ),
//                           //   ],
//                           // ),

//                            _infoRow(
//                           Icons.people,
//                           '${enquiry.people} ',
//                           'Person',
//                         ),
//                           SizedBox(height: 10.h),
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Icon(
//                                 Icons.dashboard,
//                                 color: appTextColor5,
//                                 size: 18,
//                               ),
//                               SizedBox(width: 5.w),
//                               Expanded(
//                                 child: RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: enquiry.menuItems,
//                                             // 'Chicken Biriyani , Porotta ,Rotti ,Salad , Payasam, Butter Chicken , Ice cream.',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w500,
//                                           color: appTextColor5,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 10.h),
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Icon(
//                                 Icons.handshake,
//                                 color: appTextColor5,
//                                 size: 18,
//                               ),
//                               SizedBox(width: 5.w),
//                               Flexible(
//                                 child: RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: '7 Service boys needed.',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w700,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 10.h),
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Icon(
//                                 Icons.analytics,
//                                 color: appTextColor5,
//                                 size: 18,
//                               ),
//                               SizedBox(width: 5.w),
//                               Flexible(
//                                 child: RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text:'${enquiry.lat}, ${enquiry.lng} - ${enquiry.searchRadius}km Radius',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w700,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(width: 10.w),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         AppText(
//                           text:enquiry.expirationDate,
//                           //  "Apr 11",
//                           size: 10,
//                           fontWeight: FontWeight.w600,
//                           color: appTextColor3,
//                         ),
//                         SizedBox(height: 5.h),
//                         AppText(
//                           text: enquiry.expirationTime,
//                           // "12:30pm",
//                           size: 10,
//                           fontWeight: FontWeight.w600,
//                           color: appTextColor3,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 20.h),
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 20.w),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       GestureDetector(
//                         onTap: onCancelTap,
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Icon(Icons.timer, size: 15.w, color: Colors.red),
//                             SizedBox(width: 5.w),
//                             AppText(
//                               text: "02:53:49",
//                               size: 12,
//                               fontWeight: FontWeight.w400,
//                               color: Colors.red,
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(width: 20.w),
//                       SizedBox(
//                         width: 100.w,
//                         height: 40.h,
//                         child: AppButton(
//                           text: "Withdraw",
//                           onPressed: onCancelTap,
//                           size: 12,
//                           borderRadius: 10,
//                           bgColor1: Colors.red,
//                           bgColor2: Colors.red,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//   //new widget

//  Widget _infoRow(IconData icon, String boldText, String normalText) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, color: appTextColor5, size: 18),
//         SizedBox(width: 5.w),
//         Flexible(
//           child: RichText(
//             text: TextSpan(
//               children: [
//                 TextSpan(
//                   text: boldText,
//                   style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w700,
//                     color: appTextColor5,
//                   ),
//                 ),
//                 TextSpan(
//                   text: normalText,
//                   style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w500,
//                     color: appTextColor5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }


