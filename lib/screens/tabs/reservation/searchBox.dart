import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';
import 'package:fudikoclient/screens/tabs/reservation/qrcoupon.dart';
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
    final Color statusColor = booking.status == "Confirmed"
        ? Color(0xFF32BA7C).withOpacity(.9)
        : booking.status == "Processing"
        ? Color(0xFF3954DB).withOpacity(.9)
        : Colors.red;

    final String eventDateStr = DateFormat("MMM d").format(booking.eventDate);
    final String eventTimeStr = DateFormat("h:mm a").format(booking.eventDate);
    final String bookingDateStr = DateFormat(
      "MMM d",
    ).format(booking.bookingDate);
    final String bookingTimeStr = DateFormat(
      "h:mm a",
    ).format(booking.bookingDate);

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QrCoupon(booking: booking)),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8.r,
                offset: Offset(0, 2.r),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: Coupon ID + Booking Date ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: booking.couponId,
                      size: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEC7B2D),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(
                          text: bookingDateStr,
                          size: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        SizedBox(height: 2.h),
                        AppText(
                          text: bookingTimeStr,
                          size: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // ── Restaurant name ──
                _iconRow(
                  shopIcon,
                  booking.restaurantName,
                  Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                SizedBox(height: 10.h),

                // ── Discount info ──
                _iconRow(
                  offerIcon,
                  '${booking.discount.toStringAsFixed(0)}% offer for ${booking.applicableFor ?? 'entire menu'}',
                  Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                SizedBox(height: 10.h),

                // ── Event date and time ──
                _iconRow(
                  calenderIcon,
                  '$eventDateStr - $eventTimeStr',
                  Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                SizedBox(height: 10.h),

                // ── Number of persons ──
                _iconRow(
                  peopleIcon,
                  '${booking.persons} Person',
                  Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                SizedBox(height: 12.h),

                // ── Status ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(statusIcon, width: 18, height: 18),
                    SizedBox(width: 5.w),
                    AppText(
                      text: booking.status,
                      size: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // ── Action buttons ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: onCancelTap,
                      child: AppText(
                        text: "Cancel",
                        size: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFCE3F3F).withOpacity(.9),
                      ),
                    ),
                    SizedBox(
                      width: 110.w,
                      height: 38.h,
                      child: AppButton(
                        text: "Coupon",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QrCoupon(booking: booking),
                            ),
                          );
                        },
                        size: 13,
                        borderRadius: 10.r,
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

  Widget _iconRow(
    String imageIconPath,
    String text,
    Color textColor, {
    FontWeight fontWeight = FontWeight.w500,
    double fontSize = 14,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(imageIconPath, width: 18, height: 18),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ),
      ],
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
//                             color: Colors.black,
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
//                           color: Colors.black,
//                         ),
//                         SizedBox(height: 5.h),
//                         AppText(
//                           text: "12:30pm",
//                           size: 10,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
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
