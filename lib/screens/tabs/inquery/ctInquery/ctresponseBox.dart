import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/inquery/response_model.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class CtResponseBox extends StatelessWidget {
  final ResponseModel response;
  final VoidCallback onCancelTap;
  final VoidCallback onAcceptTap;
  final VoidCallback viewRequestClick;
  const CtResponseBox({
    super.key,
    required this.response,
    required this.onCancelTap,
    required this.onAcceptTap,
    required this.viewRequestClick,
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
  final String responseId = response.uuid;

  final result = await InqueryService().declineCateringEnquiry(responseId);

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result['status'] == true
            ? (result['message']?.toString() ??
                'Enquiry response declined successfully')
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

  String _formatDateLabel() {
    if (response.createdAt != null) {
      return DateFormat('MMM d').format(response.createdAt!);
    }
    if (response.date.isNotEmpty) {
      final parsed = DateTime.tryParse(response.date);
      if (parsed != null) {
        return DateFormat('MMM d').format(parsed);
      }
      return response.date;
    }
    return '';
  }

  String _formatTimeLabel() {
    if (response.time.isNotEmpty) return response.time;
    if (response.createdAt != null) {
      return DateFormat('h:mma').format(response.createdAt!).toLowerCase();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool canAct = response.status.trim().toLowerCase() == 'active';

    return Padding(
      padding:  EdgeInsets.only(bottom: 20.h),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding:  EdgeInsets.all(20.w),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(shopIcon, width: 18.w, height: 18.h, color: appTextColor5),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: response.restaurantName.isNotEmpty
                                            ? response.restaurantName
                                            : 'Catering Service',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: appLinkColor2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(walletIcon, width: 18.w, height: 18.h, color: appTextColor5),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${response.pricePerPerson} ',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: appTextColor5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Per Person',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: appTextColor5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(offerIcon, width: 18.w, height: 18.h, color: appTextColor5),
                              SizedBox(width: 5.w),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: response.discount.isNotEmpty
                                            ? response.discount
                                            : 'No offer added',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: appTextColor5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(commentIcon, width: 18.w, height: 18.h, color: appTextColor5),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: response.message.isNotEmpty
                                            ? response.message
                                            : 'No comments provided',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(
                          text: _formatDateLabel(),
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                        SizedBox(height: 5.h),
                        AppText(
                          text: _formatTimeLabel(),
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
                            detailsIcon,
                            width: 20.w,
                            height: 20.h,
                          ),
                          SizedBox(width: 5.w),
                          AppText(
                            text: 'View Request',
                            size: 12,
                            fontWeight: FontWeight.w400,
                            color: appLinkColor2,
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
                            height: 25.h,
                            child: AppButton(
                              text: 'Decline',
                              onPressed: () => _showDeclineDialog(context),
                              size: 12,
                              borderRadius: 5.r,
                              bgColor1: const Color(0xFFCE3F3F),
                              bgColor2: const Color(0xFFCE3F3F),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          SizedBox(
                            width: 80.w,
                            height: 25.h,
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
      ),
    );
  }
}
