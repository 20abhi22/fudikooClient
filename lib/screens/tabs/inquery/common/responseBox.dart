import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/inquery/response_model.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
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

  Future<void> _showDeclineDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: 'Are you sure you want to decline this enquiry?',
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
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _declineResponse(context);
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

  Future<void> _declineResponse(BuildContext context) async {
    final String responseId = response.uuid.isNotEmpty
        ? response.uuid
        : response.enquiryId;
    final result = await InqueryService().declineEnquiry(responseId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['status'] == true
              ? (result['message']?.toString() ??
                    'Enquiry declined successfully')
              : (result['message']?.toString() ?? 'Something went wrong'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: result['status'] == true ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (result['status'] == true) {
      onCancelTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse "yyyy-MM-dd" for the top-right date label
    final DateTime parsedDate =
        DateTime.tryParse(response.date) ?? DateTime.now();
    final String displayDate = DateFormat('MMM d').format(parsedDate);
    final bool canAct = response.status.toLowerCase() == 'active';

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
                            appLinkColor2.withOpacity(.9),
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
                            appTextColor5,
                          ),
                        ]),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
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
                        Image.asset(
                          fit: BoxFit.cover,
                          detailsIcon,
                          width: 15.w,
                          height: 15.h,
                        ),
                        SizedBox(width: 5.w),
                        AppText(
                          text: 'View Request',
                          size: 12,
                          fontWeight: FontWeight.w400,
                          color: requestLinkColor,
                        ),
                      ],
                    ),
                  ),
                  if (canAct)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 80.w,
                          height: 28.h,
                          child: AppButton(
                            text: 'Decline',
                            onPressed: () => _showDeclineDialog(context),
                            size: 12,
                            borderRadius: 5.r,
                            bgColor1: const Color(0xFFCE3F3F),
                            bgColor2: const Color(0xFFCE3F3F),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        SizedBox(
                          width: 80.w,
                          height: 28.h,
                          child: AppButton(
                            text: 'Accept',
                            onPressed: onAcceptTap,
                            size: 12,
                            borderRadius: 5.r,
                            bgColor1: const Color(0xFFF73B256),
                            bgColor2: const Color(0xFFF73B256),
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

  Widget _richRow(String imageIcon, List<TextSpan> spans) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(imageIcon, width: 18.w, height: 18.h, color: appTextColor5),
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
