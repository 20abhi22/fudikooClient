import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geocoding/geocoding.dart';

class PlanAParty extends StatefulWidget {
  final Function(Map<String, String> data) onReviewTap;
  final VoidCallback viewEnquiryOnTap;

  const PlanAParty({
    super.key,
    required this.onReviewTap,
    required this.viewEnquiryOnTap,
  });

  @override
  State<PlanAParty> createState() => _PlanAPartyState();
}

class _PlanAPartyState extends State<PlanAParty> {
  // ── state ────────────────────────────────────────────
  bool isLoading = false;

  // ── controllers ──────────────────────────────────────
  final TextEditingController menuController = TextEditingController();
  final TextEditingController otherServicesController = TextEditingController();
  final TextEditingController peopleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  // ── date & time ──────────────────────────────────────
  DateTime? selectedDateTime;
  DateTime? expirationDate;
  TimeOfDay? expirationTime;

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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── validation + submit ──────────────────────────────
  Future<void> _submitEnquiry() async {
    if (menuController.text.isEmpty) {
      _showSnack('Menu is empty');
      return;
    }
    if (peopleController.text.isEmpty) {
      _showSnack('Number of people is empty');
      return;
    }
    if (amountController.text.isEmpty) {
      _showSnack('Expected amount is empty');
      return;
    }
    if (selectedDateTime == null) {
      _showSnack('Date & Time not selected');
      return;
    }
    if (expirationDate == null || expirationTime == null) {
      _showSnack('Expiration date/time not selected');
      return;
    }
    if (lat.isEmpty) {
      _showSnack('Location not selected');
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
      _showSnack('Enquiry expiry must be before the event date & time');
      return;
    }

    if (expirationDateTime.isBefore(DateTime.now())) {
      _showSnack('Enquiry expiry cannot be in the past');
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
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xfff87b0d),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xfff87b0d),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        ),
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

          // ── other services ──
          // AppTextFeild(
          //   text: "Other Services",
          //   icon: Icons.handshake,
          //   iconColor: appTextColor2,
          //   controller: otherServicesController,
          // ),
          // SizedBox(height: 20.h),

          // ── people ──
          AppTextFeild(
            text: "Number of People",
            icon: Icons.people,
            iconColor: appTextColor2,
            controller: peopleController,
          ),
          SizedBox(height: 20.h),

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

          // ── expected amount ──
          AppTextFeild(
            text: "Expected amount per person",
            icon: Icons.wallet,
            iconColor: appTextColor2,
            controller: amountController,
          ),
          SizedBox(height: 20.h),

          // ── location ──
          // GestureDetector(
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => LocationSelect(
          //         returndata: (newLat, newLng, distance) {
          //           setState(() {
          //             lat = newLat.toString();
          //             lng = newLng.toString();
          //             searchRadius = distance.toString();
          //             locationLabel = "$newLat, $newLng - ${distance}km Radius";
          //           });
          //         },
          //       ),
          //     ),
          //   ),
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
                        locationLabel =
                            '$newLat, $newLng - ${distance}km Radius';
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
                child: AppText(
                  text: locationLabel,
                  size: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 40.h),

          // ── enquiry valid for ──
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
                    _IconTextButton(
                      icon: Icons.calendar_today,
                      label: expirationDate != null
                          ? _formatDate(expirationDate!)
                          : 'Date',
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                          builder: (context, child) => Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xfff87b0d),
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                              dialogBackgroundColor: Colors.white,
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null)
                          setState(() => expirationDate = picked);
                      },
                    ),
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
                          builder: (context, child) => Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xfff87b0d),
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                              dialogBackgroundColor: Colors.white,
                            ),
                            child: child!,
                          ),
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

          // ── review button ──
          SizedBox(
            width: 150.w,
            height: 50.h,
            child: AppButton(
              text: isLoading ? "Submitting..." : "Review Party",
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

// ── shared helper widget ─────────────────────────────
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
















































// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fudikoclient/components/appbutton.dart';
// import 'package:fudikoclient/components/apptext.dart';
// import 'package:fudikoclient/components/apptextfeild.dart';
// import 'package:fudikoclient/components/descriptionBox.dart';
// import 'package:fudikoclient/model/inquery/create-inquery-model.dart';
// import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
// import 'package:fudikoclient/service/auth/map-service.dart';
// import 'package:fudikoclient/service/inquery/inquery-service.dart';
// import 'package:fudikoclient/utils/constants.dart';
// import 'package:fudikoclient/utils/tokens.dart';
// import 'package:intl/intl.dart';

// class PlanAParty extends StatefulWidget {
//   final Function(bool) onEnquiryTap;
//   final Function(bool) onReviewTap; 
//   const PlanAParty({
//     super.key,
//     required this.onEnquiryTap,
//     required this.onReviewTap,
//   });

//   @override
//   State<PlanAParty> createState() => _PlanAPartyState();
// }

// class _PlanAPartyState extends State<PlanAParty> {
//   String? radius;
//   String? longitude;
//   String? latitude;
//   String? date;
//   String? time;
//   String? place;

//   final TextEditingController nofopeoplecontroller = TextEditingController();
//   final TextEditingController descriptioncontoller = TextEditingController();
//   final TextEditingController estimatedamountcontoller =
//       TextEditingController();
//   final TextEditingController datetimecontroller = TextEditingController();
//   final TextEditingController validdatetimecontroller = TextEditingController();

//   MapService mapService = MapService();

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
//       child: Column(
//         children: [
//           GestureDetector(
//             onTap: () {
//               widget.onEnquiryTap(true);
//             },
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.content_paste_search_sharp,
//                   size: 20.w,
//                   color: appLinkColor2,
//                 ),
//                 SizedBox(width: 5.w),
//                 AppText(
//                   text: "View Enquiries",
//                   size: 15,
//                   fontWeight: FontWeight.w400,
//                   color: appLinkColor2,
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 10.h),
//           DescriptionTextArea(
//             hintText:
//                 "Example: Chicken Biriyani , Porotta ,Rotti  , Payasam, Butter Chicken , Ice cream,.Salad",
//             topHintText: "Your Menu",
//             iconColor: appTextColor2,
//             icon: Icons.dashboard,
//             maxLength: 300,
//             controller: descriptioncontoller,
//           ),
//           SizedBox(height: 10.h),
//           AppTextFeild(
//             text: "Number of  People",
//             icon: Icons.people,
//             iconColor: appTextColor2,
//             controller: nofopeoplecontroller,
//           ),
//           SizedBox(height: 10.h),
//           AppTextFeild(
//             text: "Date & Time",
//             icon: Icons.calendar_today_sharp,
//             iconColor: appTextColor2,
//             isreadonly: true,
//             onboxTap: () => _selectDateTime(context, datetimecontroller),
//             controller: datetimecontroller,
//           ),
//           SizedBox(height: 10.h),
//           AppTextFeild(
//             text: "Expected amount per person",
//             icon: Icons.wallet,
//             iconColor: appTextColor2,
//             controller: estimatedamountcontoller,
//           ),
//           SizedBox(height: 10.h),
//           GestureDetector(
//             onTap: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => LocationSelect(
//                   returndata: (lat, lng, distance) async {
//                     setState(() {
//                       latitude = lat;
//                       longitude = lng;
//                       radius = distance;
//                     });
//                     print('from main');
//                     print(latitude);
//                     print(longitude);
//                     print(radius);

//                     final placename = await mapService.getPlaceName(lat, lng);
//                     setState(() {
//                       place = placename!.split(',')[1];
//                     });
//                   },
//                 ),
//               ),
//             ),
//             child: Container(
//               padding: EdgeInsets.all(16.w),
//               decoration: BoxDecoration(
//                 color: Color(0xFF798FFF),
//                 borderRadius: BorderRadius.circular(10.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10.r,
//                     offset: Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: AppText(
//                   text:
//                       "${place ?? "Select Location"} - ${radius ?? "0"} km Radius",
//                   size: 15,
//                   fontWeight: FontWeight.w400,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 30.h),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: EdgeInsets.only(left: 4.0, bottom: 4.h),
//                 child: Text(
//                   'Enquiry valid for',
//                   style: TextStyle(
//                     color: Colors.red,
//                     fontSize: 12.sp,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () => _selectDateTime(context, validdatetimecontroller),
//                 child: Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 16.w,
//                     vertical: 12.h,
//                   ),
//                   decoration: BoxDecoration(
//                     color: appSecondaryBackgroundColor,
//                     borderRadius: BorderRadius.circular(15.r),
//                     border: Border.all(color: Colors.black54),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       _IconTextButton(
//                         icon: Icons.calendar_today,
//                         label: 'Date',
//                         onTap: () {},
//                       ),
//                       AppText(
//                         text: validdatetimecontroller.text,
//                         size: 12,
//                         fontWeight: FontWeight.w400,
//                         color: Colors.black,
//                       ),
//                       _IconTextButton(
//                         icon: Icons.access_time,
//                         label: 'Time',
//                         onTap: () {},
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 20.h),
//           SizedBox(
//             width: 150.w,
//             height: 50.h,
//             child: AppButton(
//               text: "Review Party",
//               onPressed: () {
//                 // widget.onReviewTap(true);
//                 if (descriptioncontoller.text.isEmpty ||
//                     nofopeoplecontroller.text.isEmpty ||
//                     datetimecontroller.text.isEmpty ||
//                     estimatedamountcontoller.text.isEmpty ||
//                     place == null ||
//                     radius == null ||
//                     latitude == null ||
//                     longitude == null) {
//                   // Show snackbar if fields are missing
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(
//                         "Please fill all the fields before proceeding!",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                       backgroundColor: Colors.red,
//                       behavior: SnackBarBehavior.floating,
//                     ),
//                   );
//                   return;
//                 }
//                 showDialog(
//                   context: context,
//                   barrierDismissible: true,
//                   builder: (context) => ReviewBox(
//                     menu: descriptioncontoller.text,
//                     noOfPersons: nofopeoplecontroller.text,
//                     datetime: datetimecontroller.text,
//                     expectedAmount: estimatedamountcontoller.text,
//                     place: place!,
//                     radius: radius!,
//                     latitiude: latitude!,
//                     longitude: longitude!,
//                     expiredatetime: validdatetimecontroller.text,
//                   ),
//                 );
//               },
//               size: 15,
//               borderRadius: 10,
//               bgColor1: Colors.green,
//               bgColor2: Colors.green,
//             ),
//           ),
//           SizedBox(height: 30.h),
//         ],
//       ),
//     );
//   }

//   Future<void> _selectDateTime(
//     BuildContext context,
//     TextEditingController controller,
//   ) async {
//     final DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2101),
//       builder: (BuildContext context, Widget? child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Color(0xfff87b0d),
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//             dialogBackgroundColor: Colors.white,
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (pickedDate != null) {
//       final TimeOfDay? pickedTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.now(),
//         builder: (BuildContext context, Widget? child) {
//           return Theme(
//             data: ThemeData.light().copyWith(
//               colorScheme: ColorScheme.light(
//                 primary: Color(0xfff87b0d),
//                 onPrimary: Colors.white,
//                 onSurface: Colors.black,
//               ),
//               dialogBackgroundColor: Colors.white,
//             ),
//             child: child!,
//           );
//         },
//       );

//       if (pickedTime != null) {
//         DateTime fullDateTime = DateTime(
//           pickedDate.year,
//           pickedDate.month,
//           pickedDate.day,
//           pickedTime.hour,
//           pickedTime.minute,
//         );

//         String formattedDate = DateFormat('yyyy-MM-dd').format(fullDateTime);
//         String formattedTime = DateFormat('hh:mm a').format(fullDateTime);

//         setState(() {
//           date = formattedDate;
//           time = formattedTime;
//           controller.text = '$formattedDate & $formattedTime';
//         });
//       }
//     }
//   }

// }

// class _IconTextButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   const _IconTextButton({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(16.r),
//       onTap: onTap,
//       child: Row(
//         children: [
//           Icon(icon, size: 20.w, color: Colors.black),
//           SizedBox(width: 8.w),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12.sp,
//               color: appTextColor2,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ReviewBox extends StatefulWidget {
//   final String menu;
//   final String noOfPersons;
//   final String datetime;
//   final String expectedAmount;
//   final String place;
//   final String radius;
//   final String latitiude;
//   final String longitude;
//   final String expiredatetime;
//   const ReviewBox({
//     super.key,
//     required this.menu,
//     required this.noOfPersons,
//     required this.datetime,
//     required this.expectedAmount,
//     required this.place,
//     required this.radius,
//     required this.latitiude,
//     required this.longitude,
//     required this.expiredatetime,
//   });

//   @override
//   State<ReviewBox> createState() => _ReviewBoxState();
// }

// class _ReviewBoxState extends State<ReviewBox> {
//   InqueryService inqueryService = InqueryService();

//   Future<void> createInquery() async {
//       debugPrint(await getToken());
//     try {
//       CreateInqueryModel inquerydata = CreateInqueryModel(
//         lat: widget.latitiude,
//         lng: widget.longitude,
//         menuItems: widget.menu,
//         people: widget.noOfPersons,
//         time: widget.datetime.split(" & ")[1].trim(),
//         date: widget.datetime.split(" & ")[0].trim(),
//         estimatedAmount: widget.expectedAmount,
//         searchRadius: widget.radius,
//         expirationDate: widget.expiredatetime.split(" & ")[0].trim(),
//         expirationTime: widget.expiredatetime.split(" & ")[1].trim(),
//       );


//       CreateInqueryModelResponse response = await inqueryService.createInquery(
//         inquerydata,
//       );

//       if (response.status) {
//         SnackBar(
//           content: Text(
//             "Inquery created successfully",
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//         );
//         Navigator.pop(context);
//         debugPrint("Inquery created successfully");
//       }else{
//         SnackBar(
//           content: Text(
//             "Error in creating inquery",
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         );
//         debugPrint("Error successfully");
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       print(e);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   AppText(
//                     text: "C17854",
//                     size: 20,
//                     fontWeight: FontWeight.w700,
//                     color: appTextColor3,
//                   ),
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: AppText(
//                       text: "Edit",
//                       size: 15,
//                       fontWeight: FontWeight.w700,
//                       color: appLinkColor,
//                     ),
//                   ),
//                 ],
//               ),

//               SizedBox(height: 20.h),

//               _buildRow(
//                 icon: Icons.dashboard,
//                 title: "Your Menu",
//                 value: widget.menu,
//               ),

//               SizedBox(height: 20.h),

//               _buildRow(
//                 icon: Icons.people,
//                 title: "Number of Persons",
//                 value: "${widget.noOfPersons} Person",
//               ),

//               SizedBox(height: 20.h),

//               _buildRow(
//                 icon: Icons.calendar_today_sharp,
//                 title: "Date and Time",
//                 value: widget.datetime,
//               ),

//               SizedBox(height: 20.h),

//               _buildRow(
//                 icon: Icons.wallet,
//                 title: "Expected amount per person",
//                 value: "${widget.expectedAmount} Per person",
//               ),

//               SizedBox(height: 20.h),

//               _buildRow(
//                 icon: Icons.analytics,
//                 title: "Enquiry Radius",
//                 value: "${widget.place} - ${widget.radius} km Radius",
//               ),

//               SizedBox(height: 30.h),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.timer, size: 20.w, color: Colors.red),
//                   SizedBox(width: 5.w),
//                   AppText(
//                     text: "03:00:00",
//                     size: 15,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.red,
//                   ),
//                 ],
//               ),

//               SizedBox(height: 15.h),

//               SizedBox(
//                 width: 150.w,
//                 height: 50.h,
//                 child: AppButton(
//                   text: "Send",
//                   onPressed: () {
//                     createInquery();
//                   },
//                   size: 15,
//                   bgColor1: Colors.green,
//                   bgColor2: Colors.green,
//                   borderRadius: 10,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRow({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, size: 20.w, color: appTextColor2),
//         SizedBox(width: 10.w),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               AppText(
//                 text: title,
//                 size: 15,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey,
//               ),
//               SizedBox(height: 5.h),
//               AppText(
//                 text: value,
//                 size: 15,
//                 fontWeight: FontWeight.w500,
//                 color: appTextColor2,
//                 lineSpacing: 1.5,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
