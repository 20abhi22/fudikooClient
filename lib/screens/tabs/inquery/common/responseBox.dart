import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/inquery/response_model.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class ResponseBox extends StatelessWidget {
  final VoidCallback onCancelTap;
  final VoidCallback onAcceptTap;
  final VoidCallback viewRequestClick;
  final ResponseModel response;

  const ResponseBox({
    super.key,
    required this.onCancelTap,
    required this.onAcceptTap,
    required this.viewRequestClick,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    // Parse "yyyy-MM-dd" for the top-right date label
    final DateTime parsedDate =
        DateTime.tryParse(response.date) ?? DateTime.now();
    final String displayDate = DateFormat('MMM d').format(parsedDate);

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
                  // ── Left content ──────────────────────────
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: response.couponId,
                          size: 20,
                          fontWeight: FontWeight.bold,
                          color: appTextColor3,
                        ),
                        SizedBox(height: 10.h),
                        _richRow(Icons.restaurant, [
                          _span(response.restaurantName,
                              FontWeight.w700, appLinkColor2),
                        ]),
                        SizedBox(height: 10.h),
                        _richRow(Icons.wallet, [
                          _span('${response.pricePerPerson} ',
                              FontWeight.w700, appTextColor5),
                          _span('Per Person',
                              FontWeight.w500, appTextColor5),
                        ]),
                        SizedBox(height: 10.h),
                        _richRow(Icons.discount, [
                          _span(response.discount,
                              FontWeight.w500, appTextColor5),
                        ]),
                        SizedBox(height: 10.h),
                        _richRow(Icons.message, [
                          _span(response.message,
                              FontWeight.w700, Colors.black),
                        ]),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // ── Top-right date ────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: displayDate,
                        size: 10,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 5.h),
                      AppText(
                        text: response.time,
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: viewRequestClick,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.manage_search_sharp,
                            size: 15.w, color: appLinkColor2),
                        SizedBox(width: 5.w),
                        AppText(
                          text: "View Request",
                          size: 12,
                          fontWeight: FontWeight.w400,
                          color: appLinkColor2,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: 100.w,
                        height: 35.h,
                        child: AppButton(
                          text: "Decline",
                          onPressed: onCancelTap,
                          size: 12,
                          borderRadius: 5.r,
                          bgColor1: Colors.red,
                          bgColor2: Colors.red,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        width: 100.w,
                        height: 35.h,
                        child: AppButton(
                          text: "Accept",
                          onPressed: onAcceptTap,
                          size: 12,
                          borderRadius: 5.r,
                          bgColor1: Colors.green,
                          bgColor2: Colors.green,
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

  Widget _richRow(IconData icon, List<TextSpan> spans) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: appTextColor5, size: 18),
        SizedBox(width: 5.w),
        Flexible(child: RichText(text: TextSpan(children: spans))),
      ],
    );
  }

  TextSpan _span(String text, FontWeight weight, Color color) =>
      TextSpan(
        text: text,
        style: TextStyle(fontSize: 15, fontWeight: weight, color: color),
      );
}