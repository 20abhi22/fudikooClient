import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/inquery/response_model.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class CtDeclineBox extends StatelessWidget {
  final Future<void> Function() onCancelTap;
  final Future<void> Function() onRestoreTap;
  final ResponseModel response;
  // final VoidCallback onAcceptTap;
  // final VoidCallback viewRequestClick;
  const CtDeclineBox({
    super.key,
    required this.onCancelTap,
    required this.onRestoreTap,
    required this.response,
    // required this.onAcceptTap,
    // required this.viewRequestClick,
  });

  Future<void> _showDeleteDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: 'Are you sure you want to delete this enquiry?',
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
                        text: 'Yes',
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await onCancelTap();
                        },
                        size: 11,
                        bgColor1: const Color(0xFF73B256),
                        bgColor2: const Color(0xFF73B256),
                        borderRadius: 10,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: SizedBox(
                      height: 30.h,
                      child: AppButton(
                        text: 'No',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        size: 11,
                        bgColor1: const Color(0xFFCE3F3F),
                        bgColor2: const Color(0xFFCE3F3F),
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
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: 'Are you sure you want to restore this enquiry?',
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
                        text: 'Yes',
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await onRestoreTap();
                        },
                        size: 11,
                        bgColor1: const Color(0xFF73B256),
                        bgColor2: const Color(0xFF73B256),
                        borderRadius: 10,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: SizedBox(
                      height: 30.h,
                      child: AppButton(
                        text: 'No',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        size: 11,
                        bgColor1: const Color(0xFFCE3F3F),
                        bgColor2: const Color(0xFFCE3F3F),
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
  }

  @override
  Widget build(BuildContext context) {
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
                        _richRow(shopIcon, [
                          _span(
                            response.restaurantName,
                            FontWeight.w700,
                            appLinkColor2,
                          ),
                        ]),
                        SizedBox(height: 10.h),
                        _richRow(walletIcon, [
                          _span(
                            '${response.pricePerPerson} ',
                            FontWeight.w700,
                            appTextColor5,
                          ),
                          _span('Per Person', FontWeight.w500, appTextColor5),
                        ]),
                        SizedBox(height: 10.h),
                        _richRow(offerIcon, [
                          _span(
                            response.discount,
                            FontWeight.w500,
                            appTextColor5,
                          ),
                        ]),
                        SizedBox(height: 10.h),
                        _richRow(commentIcon, [
                          _span(
                            response.message,
                            FontWeight.w700,
                            Colors.black,
                          ),
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
                        size: 11,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 5.h),
                      AppText(
                        text: response.time,
                        size: 11,
                        fontWeight: FontWeight.w400,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 80.w,
                        height: 25.h,
                        child: AppButton(
                          text: "Delete",
                          onPressed: () => _showDeleteDialog(context),
                          size: 12,
                          borderRadius: 5,
                          bgColor1: Color(0xFFCE3F3F),
                          bgColor2: Color(0xFFCE3F3F),
                        ),
                      ),
                      SizedBox(width: 5.w),
                      SizedBox(
                        width: 80.w,
                        height: 25.h,
                        child: AppButton(
                          text: "Restore",
                          onPressed: () => _showRestoreDialog(context),
                          size: 12,
                          borderRadius: 5,
                          bgColor1: Color(0xFF4662EC),
                          bgColor2: Color(0xFF4662EC),
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

  Widget _richRow(String imageicon, List<TextSpan> spans) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(imageicon, width: 18.w, height: 18.h),
        SizedBox(width: 5.w),
        Expanded(
          child: RichText(
            softWrap: true,
            overflow: TextOverflow.visible,
            text: TextSpan(children: spans),
          ),
        ),
      ],
    );
  }

  TextSpan _span(String text, FontWeight weight, Color color) => TextSpan(
    text: text,
    style: TextStyle(fontSize: 15, fontWeight: weight, color: color),
  );
}
