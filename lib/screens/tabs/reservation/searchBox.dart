import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
import 'package:fudikoclient/screens/tabs/reservation/qrcoupon.dart';
import 'package:fudikoclient/screens/tabs/reservation/verifiedModal.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class SearchBox extends StatelessWidget {
  final VoidCallback? onCancelTap;
  final VoidCallback? onRequestTap;
  final BookingModel booking;

  const SearchBox({
    super.key,
    this.onCancelTap,
    this.onRequestTap,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        booking.status == "Confirmed" ? Colors.green : Colors.red;

    final String eventDateStr =
        DateFormat("MMM d").format(booking.eventDate);
    final String eventTimeStr =
        DateFormat("h:mm a").format(booking.eventDate);
    final String bookingDateStr =
        DateFormat("MMM d").format(booking.bookingDate);
    final String bookingTimeStr =
        DateFormat("h:mm a").format(booking.bookingDate);

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QrCoupon()),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10.r,
                offset: Offset(0, 4.r),
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
                    // ── Left content ──
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: booking.couponId,
                            size: 20,
                            fontWeight: FontWeight.bold,
                            color: appTextColor3,
                          ),
                          SizedBox(height: 10.h),
                          _iconRow(Icons.restaurant,
                              booking.restaurantName, appLinkColor2,
                              fontWeight: FontWeight.w900),
                          SizedBox(height: 10.h),
                          _richRow(Icons.wallet, [
                            _span('${booking.pricePerPerson}',
                                FontWeight.w700, appTextColor5),
                            _span(' per person', FontWeight.w500, appTextColor5),
                          ]),
                          SizedBox(height: 10.h),
                          _richRow(Icons.discount, [
                            _span('${booking.discount}% ',
                                FontWeight.w700, appTextColor5),
                            _span('on extra drinks',
                                FontWeight.w500, appTextColor5),
                          ]),
                          SizedBox(height: 10.h),
                          _iconRow(Icons.message, booking.message,
                              appTextColor5,
                              fontWeight: FontWeight.w700),
                          SizedBox(height: 10.h),
                          _richRow(Icons.calendar_today_sharp, [
                            _span('$eventDateStr ',
                                FontWeight.w700, appTextColor2),
                            _span('- $eventTimeStr',
                                FontWeight.w700, appTextColor2),
                          ]),
                          SizedBox(height: 10.h),
                          _richRow(Icons.people, [
                            _span('${booking.persons} ',
                                FontWeight.w700, appTextColor2),
                            _span('Person',
                                FontWeight.w700, appTextColor2),
                          ]),
                          SizedBox(height: 10.h),
                          _richRow(Icons.analytics, [
                            _span(booking.status,
                                FontWeight.w700, statusColor),
                          ]),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // ── Booking date (top-right) ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(
                          text: bookingDateStr,
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                        SizedBox(height: 5.h),
                        AppText(
                          text: bookingTimeStr,
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 40.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: onRequestTap,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.manage_search_sharp,
                                  size: 15.w, color: appLinkColor2),
                              SizedBox(width: 2.w),
                              AppText(
                                text: "View Request",
                                size: 12,
                                fontWeight: FontWeight.w400,
                                color: appLinkColor2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        GestureDetector(
                          onTap: onCancelTap,
                          child: AppText(
                            text: "Cancel",
                            size: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 100.w,
                      height: 35.h,
                      child: AppButton(
                        text: "Coupon",
                        onPressed: () {
                          showModalBottomSheet(
                            backgroundColor: Colors.white,
                            context: context,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(25.r),
                              ),
                            ),
                            builder: (context) => VerifiedModal(),
                          );
                        },
                        size: 12,
                        borderRadius: 5.r,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _iconRow(IconData icon, String text, Color textColor,
      {FontWeight fontWeight = FontWeight.w500}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: appTextColor5, size: 18),
        SizedBox(width: 5.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _richRow(IconData icon, List<TextSpan> spans) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: appTextColor5, size: 18),
        SizedBox(width: 5.w),
        Flexible(
          child: RichText(text: TextSpan(children: spans)),
        ),
      ],
    );
  }

  TextSpan _span(String text, FontWeight weight, Color color) {
    return TextSpan(
      text: text,
      style: TextStyle(fontSize: 15, fontWeight: weight, color: color),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fudikoclient/components/appbutton.dart';
// import 'package:fudikoclient/components/apptext.dart';
// import 'package:fudikoclient/screens/tabs/reservation/qrcoupon.dart';
// import 'package:fudikoclient/screens/tabs/reservation/verifiedModal.dart';
// import 'package:fudikoclient/utils/constants.dart';

// class SearchBox extends StatelessWidget {
//   final VoidCallback? onCancelTap;
//   final VoidCallback? onRequestTap;
//   const SearchBox({super.key, this.onCancelTap,this.onRequestTap});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding:  EdgeInsets.only(bottom: 20.h),
//       child: GestureDetector(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => QrCoupon()),
//           );
//         },
//         child: Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20.r),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.2),
//                 blurRadius: 10.r,
//                 offset: Offset(0, 4.r),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding:  EdgeInsets.all(20.w),
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
//                             text: "P17854",
//                             size: 20,
//                             fontWeight: FontWeight.bold,
//                             color: appTextColor3,
//                           ),
//                           SizedBox(height: 10.h),
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Icon(
//                                 Icons.restaurant,
//                                 color: appTextColor5,
//                                 size: 18,
//                               ),
//                               SizedBox(width: 5.w),
//                               Flexible(
//                                 child: RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: 'Bollywood Restaurant',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w900,
//                                           color: appLinkColor2,
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
//                                 Icons.wallet,
//                                 color: appTextColor5,
//                                 size: 18,
//                               ),
//                               SizedBox(width: 5.w),
//                               Flexible(
//                                 child: RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: '950',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w700,
//                                           color: appTextColor5,
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: ' per person',
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
//                                 Icons.discount,
//                                 color: appTextColor5,
//                                 size: 18,
//                               ),
//                                   SizedBox(width: 5.w),
//                               Flexible(
//                                 child: RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: '5% ',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w700,
//                                           color: appTextColor5,
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: 'on extra drinks',
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
//                                 Icons.message,
//                                 color: appTextColor5,
//                                 size: 18,
//                               ),
//                               SizedBox(width: 5.w),
//                               Flexible(
//                                 child: RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: 'If you have more than 50 people, we can offer you a price of 850 per head.',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w700,
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
//                                 Icons.calendar_today_sharp,
//                                 color: appTextColor5,
//                                 size: 18,
//                               ),
//                               SizedBox(width: 5.w),
//                               Flexible(
//                                 child: RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: 'April 12 ',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w700,
//                                           color: appTextColor2,
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: ' - 2:30 pm',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w700,
//                                           color: appTextColor2,
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
//                                 Icons.people,
//                                 color: appTextColor5,
//                                 size: 18,
//                               ),
//                               SizedBox(width: 5.w),
//                               Flexible(
//                                 child: RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: '12 ',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w700,
//                                           color: appTextColor2,
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: 'Person',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w700,
//                                           color: appTextColor2,
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
//                                 SizedBox(width: 5.w),
//                               Flexible(
//                                 child: RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: 'Confirmed',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w700,
//                                           color: Colors.green,
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
//                           text: "Apr 11",
//                           size: 10,
//                           fontWeight: FontWeight.w600,
//                           color: appTextColor3,
//                         ),
//                         SizedBox(height: 5.h),
//                         AppText(
//                           text: "12:30pm",
//                           size: 10,
//                           fontWeight: FontWeight.w600,
//                           color: appTextColor3,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 40.h),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         GestureDetector(
//                           onTap: onRequestTap,
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.manage_search_sharp,
//                                 size: 15.w,
//                                 color: appLinkColor2,
//                               ),
//                               SizedBox(width: 2.w),
//                               AppText(
//                                 text: "View Request",
//                                 size: 12,
//                                 fontWeight: FontWeight.w400,
//                                 color: appLinkColor2,
//                               ),
//                             ],
//                           ),
//                         ),
//                         SizedBox(height: 10.h),
//                         GestureDetector(
//                           onTap: onCancelTap,
//                           child: AppText(
//                             text: "Cancel",
//                             size: 12,
//                             fontWeight: FontWeight.w400,
//                             color: Colors.red,
//                           ),
//                         ),

//                       ],
//                     ),
//                     SizedBox(
//                       width: 100.w,
//                       height: 35.h,
//                       child: AppButton(
//                         text: "Coupon",
//                         onPressed: () {
//                           showModalBottomSheet(
//                             backgroundColor: Colors.white,
//                             context: context,
//                             isScrollControlled: true,
//                                 shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.vertical(
//                                 top: Radius.circular(25.r),
//                               ),
//                             ),
//                             builder: (context) {
//                               return VerifiedModal();
//                             },
//                           );
//                         },
//                         size: 12,
//                         borderRadius: 5.r,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }





// }
