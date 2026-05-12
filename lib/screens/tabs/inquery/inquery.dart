import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/model/inquery/create-catering-inquery-model.dart';
import 'package:fudikoclient/model/inquery/create-inquery-model.dart';
import 'package:fudikoclient/model/inquery/list-catering-inquery-model.dart';
import 'package:fudikoclient/model/inquery/list-party-inquery-modal.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/responseBox.dart';
import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctInquery.dart';
import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctInqueryBox.dart';
import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctdecline.dart';
import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctresponseBox.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/declineBox.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/screens/tabs/inquery/inquery/planaparty.dart';
import 'package:fudikoclient/screens/tabs/inquery/inquery/viewinquery.dart';
import 'package:fudikoclient/screens/tabs/main_restaurant_nav.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';

class Inquery extends StatefulWidget {
  const Inquery({super.key});

  @override
  State<Inquery> createState() => _InqueryState();
}

class _InqueryState extends State<Inquery> {
  String selectedStatus = 'Plan a Party';
  DateTime selectedDateTime = DateTime.now();
  bool isReviewOnClick = false;
  bool isCtReviewOnClick = false;
  bool isWithdrawOnClick = false;
  bool viewEnquiryOnClick = false;
  bool viewCtEnquiryOnClick = false;
  bool isResponseAcceptOnClick = false;
  bool viewRequest = false;
  bool viewCtRequest = false;
  bool isResponseAcceptConfirmOnClick = false;
  bool isConfirmClicked = false;
  bool viewDeclineOnClick = false;
  bool viewCtDeclineOnClick = false;
  bool isSearchOnClick = false;
  bool isCtSearchOnClick = false;
  Map<String, String> ctEnquiryData = {};
  List<CateringInqueryModel> _ctEnquiries = [];
  bool _ctEnquiriesLoading = false;
  // for timer in ct review
  Timer? _ctTimer;
  int _ctSeconds = 180; // 3 minutes = 180 seconds

  //for party
  Map<String, String> partyEnquiryData = {};
  Timer? _partyTimer;
  int _partySeconds = 180;

  //----------------------------------Catering Timer--------------------------//
  String get _ctTimerText {
    final m = (_ctSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_ctSeconds % 60).toString().padLeft(2, '0');
    return "00:$m:$s";
  }

  void _startCtTimer() {
    _ctSeconds = 180;
    _ctTimer?.cancel();
    _ctTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_ctSeconds <= 0) {
        timer.cancel();
        setState(() => isCtReviewOnClick = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review time expired. Please try again.'),
          ),
        );
      } else {
        setState(() => _ctSeconds--);
      }
    });
  }

  void _stopCtTimer() {
    _ctTimer?.cancel();
    _ctSeconds = 180;
  }
  //----------------------------------Catering Timer--------------------------//
  //----------------------------------Party Timer--------------------------//

  String get _partyTimerText {
    final m = (_partySeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_partySeconds % 60).toString().padLeft(2, '0');
    return "00:$m:$s";
  }

  void _startPartyTimer() {
    _partySeconds = 180;
    _partyTimer?.cancel();
    _partyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_partySeconds <= 0) {
        timer.cancel();
        setState(() => isReviewOnClick = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review time expired. Please try again.'),
          ),
        );
      } else {
        setState(() => _partySeconds--);
      }
    });
  }

  void _stopPartyTimer() {
    _partyTimer?.cancel();
    _partySeconds = 180;
  }

  //----------------------------------Party Timer--------------------------//

  //----------------------------------Catering Enquires-------------------------------------//
  Future<void> _fetchCtEnquiries() async {
    setState(() => _ctEnquiriesLoading = true);
    final result = await InqueryService().fetchCateringInquerys();
    setState(() {
      _ctEnquiries = result.enquiries;
      _ctEnquiriesLoading = false;
    });
  }

  Future<void> _submitCateringEnquiry() async {
    final InqueryService service = InqueryService();
    final model = CreateCateringInqueryModel(
      lat: ctEnquiryData['lat'] ?? '',
      lng: ctEnquiryData['lng'] ?? '',
      menuItems: ctEnquiryData['menu'] ?? '',
      people: ctEnquiryData['people'] ?? '',
      // time: ctEnquiryData['dateTime']?.split(' ').last ?? '',
      // date: ctEnquiryData['dateTime']?.split(' ').first ?? '',
      date: ctEnquiryData['dateTime']?.split(' ').first ?? '',
      time: () {
        final parts = ctEnquiryData['dateTime']?.split(' ') ?? [];
        return parts.length >= 3 ? '${parts[1]} ${parts[2]}' : '';
      }(),
      estimatedAmount: ctEnquiryData['amount'] ?? '',
      searchRadius: ctEnquiryData['searchRadius'] ?? '20',
      expirationDate: ctEnquiryData['expirationDate'] ?? '',
      expirationTime: ctEnquiryData['expirationTime'] ?? '',
    );

    final response = await service.createCateringInquery(model);

    if (response.status) {
      setState(() => isCtReviewOnClick = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  //----------------------------------Catering Enquires-------------------------------------//
  //----------------------------------Party Enquires-------------------------------------//

  Future<void> _submitPartyEnquiry() async {
    final InqueryService service = InqueryService();
    final model = CreateInqueryModel(
      lat: partyEnquiryData['lat'] ?? '',
      lng: partyEnquiryData['lng'] ?? '',
      menuItems: partyEnquiryData['menu'] ?? '',
      people: partyEnquiryData['people'] ?? '',
      date: partyEnquiryData['dateTime']?.split(' ').first ?? '',
      time: () {
        final parts = partyEnquiryData['dateTime']?.split(' ') ?? [];
        return parts.length >= 3 ? '${parts[1]} ${parts[2]}' : '';
      }(),
      estimatedAmount: partyEnquiryData['amount'] ?? '',
      searchRadius: partyEnquiryData['searchRadius'] ?? '20',
      expirationDate: partyEnquiryData['expirationDate'] ?? '',
      expirationTime: partyEnquiryData['expirationTime'] ?? '',
    );

    final response = await service.createInquery(model);
    if (response.status) {
      setState(() => isReviewOnClick = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Party enquiry submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  //----------------------------------Party Enquires-------------------------------------//

  @override
  void dispose() {
    _ctTimer?.cancel();
    _partyTimer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: Stack(
        children: [
          if (viewEnquiryOnClick)
            ViewInquery(
              onEnquiryTap: (val) {
                setState(() {
                  viewEnquiryOnClick = val;
                });
              },
            )
          else if (viewCtEnquiryOnClick)
            _viewCtEnquiryWidget()
          else if (viewDeclineOnClick)
            _viewDeclineWidget()
          else if (viewCtDeclineOnClick)
            _viewCtDeclineWidget()
          else if (isSearchOnClick)
            _viewSearchWidget()
          else if (isCtSearchOnClick)
            _viewCtSearchWidget()
          else
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              buildStatusButton("Plan a Party"),
                              SizedBox(width: 10.w),
                              buildStatusButton("Book a Catering"),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              buildStatusButton("Party Response"),
                              SizedBox(width: 10.w),
                              buildStatusButton("Catering Response"),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: selectedStatus == "Plan a Party"
                      // ? PlanAParty(
                      //     onEnquiryTap: (val) {
                      //       setState(() {
                      //         viewEnquiryOnClick = val;
                      //       });
                      //     },
                      //     onReviewTap: (val) {
                      //       setState(() {
                      //         isReviewOnClick = val;
                      //       });
                      //     },
                      //   )
                      ? PlanAParty(
                          onReviewTap: (data) {
                            setState(() {
                              partyEnquiryData = data;
                              isReviewOnClick = true;
                            });
                            _startPartyTimer();
                          },
                          viewEnquiryOnTap: () {
                            setState(
                              () => viewEnquiryOnClick = !viewEnquiryOnClick,
                            );
                          },
                        )
                      : selectedStatus == "Party Response"
                      ? _responseWidget()
                      : selectedStatus == "Book a Catering"
                      // ? CtInquery(
                      //   onReviewTap: (){
                      //     setState(() {
                      //       isCtReviewOnClick = !isCtReviewOnClick;
                      //     });
                      //   },
                      ? CtInquery(
                          onReviewTap: (data) {
                            setState(() {
                              ctEnquiryData = data;
                              isCtReviewOnClick = true;
                            });
                            _startCtTimer();
                          },
                          viewEnquiryOnTap: () {
                            setState(() {
                              viewCtEnquiryOnClick = !viewCtEnquiryOnClick;
                            });
                            _fetchCtEnquiries();
                          },
                        )
                      : _ctResponseWidget(),
                ),
              ],
            ),
          if (isResponseAcceptOnClick) _responseAcceptBox(),
          if (viewRequest) _viewRequestWidget(),
          if (viewCtRequest) _viewCtRequestWidget(),
          if (isResponseAcceptConfirmOnClick) _responseAcceptConfirmBox(),
          if (isCtReviewOnClick) _ctReviewBox(),
          if (isReviewOnClick) _partyReviewBox(), 
        ],
      ),
    );
  }
//---------------------Catering Widgets------------------------------//
  Widget _viewCtSearchWidget() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
              child: AppTextFeild(
                text: "Enter the Coupon Number",
                textColor: appTextColor3,
                icon: Icons.close,
                iconColor: appTextColor3,
                iconOnTap: () {
                  setState(() {
                    isCtSearchOnClick = !isCtSearchOnClick;
                  });
                },
              ),
            ),

            SizedBox(height: 20.h),
            SizedBox(
              width: 180.w,
              child: AppFilterDropDown(
                hint: "Today",
                toggleDropdown: () {
                  showModalBottomSheet(
                    backgroundColor: Colors.white,
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: EdgeInsets.all(30.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40.w,
                              height: 5.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                children: [
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item1",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item2",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item3",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icons.tune,
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 2,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(left: 30.w, right: 30.w),
                    // child: CtResponseBox(
                    //   viewRequestClick: () {
                    //     setState(() {
                    //       viewCtRequest = !viewCtRequest;
                    //     });
                    //   },
                    //   onAcceptTap: () {
                    //     setState(() {
                    //       isResponseAcceptOnClick = !isResponseAcceptOnClick;
                    //     });
                    //   },
                    //   onCancelTap: () {
                    //     setState(() {});
                    //   },
                    // ),
                    child: SizedBox.shrink(),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _viewCtDeclineWidget() {
    return Stack(
      children: [
        Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  viewCtDeclineOnClick = !viewCtDeclineOnClick;
                });
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: appTextColor3,
                    size: 28.w,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 180.w,
              child: AppFilterDropDown(
                hint: "Today",
                toggleDropdown: () {
                  showModalBottomSheet(
                    backgroundColor: Colors.white,
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: EdgeInsets.all(30.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40.w,
                              height: 5.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                children: [
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item1",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item2",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item3",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icons.tune,
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 2,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(left: 30.w, right: 30.w),
                    // child: 
                    child: SizedBox.shrink(),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _viewCtRequestWidget() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        text: "Requested party",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            viewCtRequest = !viewCtRequest;
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: appTextColor3,
                          size: 25.w,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      text: "P17854",
                      size: 20,
                      fontWeight: FontWeight.w700,
                      color: appTextColor3,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Your Menu",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text:
                                  "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.handshake, size: 20.w, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Other Services",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "7 Service boys needed.",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.people, size: 20.w, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Number of Persons",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "12 Person ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.calendar_today_sharp,
                        size: 20.w,
                        color: appTextColor2,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Date and Time ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "April 12 - 2:30 pm",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.wallet, size: 20.w, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Expected amount per person",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "1000 Per person",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.analytics, size: 20.w, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Enquiry Radius ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "Moscow City - 20km Radius",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ctResponseWidget() {
    return Column(
      children: [
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 150.w,
                child: AppFilterDropDown(
                  hint: "Today",
                  icon: Icons.tune,
                  toggleDropdown: () {
                    showModalBottomSheet(
                      backgroundColor: Colors.white,
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.all(30.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40.w,
                                height: 5.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  children: [
                                    Divider(color: Colors.grey[200]),
                                    SizedBox(height: 10.h),
                                    AppText(
                                      text: "item1",
                                      size: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 10.h),
                                    Divider(color: Colors.grey[200]),
                                    SizedBox(height: 10.h),
                                    AppText(
                                      text: "item2",
                                      size: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 10.h),
                                    Divider(color: Colors.grey[200]),
                                    SizedBox(height: 10.h),
                                    AppText(
                                      text: "item3",
                                      size: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 10),
                                    Divider(color: Colors.grey[200]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.search, size: 17.w, color: Colors.black),
                      SizedBox(width: 2.w),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isCtSearchOnClick = !isCtSearchOnClick;
                          });
                        },
                        child: AppText(
                          text: "Search",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.book, size: 17.w, color: appLinkColor2),
                      SizedBox(width: 2.w),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            viewCtDeclineOnClick = !viewCtDeclineOnClick;
                          });
                        },
                        child: AppText(
                          text: "View Declined",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: appLinkColor2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                // child: 
                child: SizedBox.shrink(),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget _viewCtEnquiryWidget() {
  //   return Column(
  //     children: [
  //       GestureDetector(
  //         onTap: () {
  //           setState(() => viewCtEnquiryOnClick = false);
  //  Navigator.pop(context);

  //         },
  //         child: Align(
  //           alignment: Alignment.centerLeft,
  //           child: Padding(
  //             padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
  //             child: Icon(
  //               Icons.arrow_back_ios_new,
  //               color: appTextColor3,
  //               size: 28.w,
  //             ),
  //           ),
  //         ),
  //       ),

  //         SizedBox(height: 20.h),
  //        Expanded(child:   _ctEnquiriesLoading?
  //        Center(child: CircularProgressIndicator())
  //     :(_ctEnquiries.isEmpty)?

  //         Center(
  //           child: AppText(
  //             text: "No enquiries found",
  //             size: 15,
  //             fontWeight: FontWeight.w500,
  //             color: appTextColor3,
  //           ),
  //         )
  //       : ListView.builder(
  //           shrinkWrap: true,
  //           itemCount: _ctEnquiries.length,
  //           itemBuilder: (context, index) {
  //             return Padding(
  //               padding: EdgeInsets.only(left: 30.w, right: 30.w),
  //               child: CtInqueryBox(
  //                 enquiry: _ctEnquiries[index],
  //                 onCancelTap: () {
  //                   setState(() {
  //                     isWithdrawOnClick = !isWithdrawOnClick;
  //                   });
  //                 },
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //       SizedBox(
  //         width: 180.w,
  //         child: AppFilterDropDown(
  //           hint: "Today",
  //           toggleDropdown: () {
  //             showModalBottomSheet(
  //               backgroundColor: Colors.white,
  //               context: context,
  //               isScrollControlled: true,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.vertical(
  //                   top: Radius.circular(25),
  //                 ),
  //               ),
  //               builder: (context) {
  //                 return Padding(
  //                   padding: EdgeInsets.all(30.w),
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Container(
  //                         width: 40.w,
  //                         height: 5.h,
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey[300],
  //                           borderRadius: BorderRadius.circular(10.r),
  //                         ),
  //                       ),
  //                       SizedBox(height: 16.h),
  //                       Container(
  //                         width: MediaQuery.of(context).size.width,
  //                         decoration: BoxDecoration(
  //                           color: Colors.white,
  //                           borderRadius: BorderRadius.circular(20.r),
  //                         ),
  //                         padding: EdgeInsets.all(16.w),
  //                         child: Column(
  //                           children: [
  //                             Divider(color: Colors.grey[200]),
  //                             SizedBox(height: 10.h),
  //                             AppText(
  //                               text: "item1",
  //                               size: 15,
  //                               fontWeight: FontWeight.w500,
  //                               color: Colors.black,
  //                             ),
  //                             SizedBox(height: 10.h),
  //                             Divider(color: Colors.grey[200]),
  //                             SizedBox(height: 10.h),
  //                             AppText(
  //                               text: "item2",
  //                               size: 15,
  //                               fontWeight: FontWeight.w500,
  //                               color: Colors.black,
  //                             ),
  //                             SizedBox(height: 10.h),
  //                             Divider(color: Colors.grey[200]),
  //                             SizedBox(height: 10.h),
  //                             AppText(
  //                               text: "item3",
  //                               size: 15,
  //                               fontWeight: FontWeight.w500,
  //                               color: Colors.black,
  //                             ),
  //                             SizedBox(height: 10),
  //                             Divider(color: Colors.grey[200]),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               },
  //             );
  //           },
  //           icon: Icons.tune,
  //         ),
  //       ),
  //       SizedBox(height: 20.h),
  //       Expanded(
  //         child: ListView.builder(
  //           shrinkWrap: true,
  //           itemCount: 10,
  //           itemBuilder: (context, index) {
  //             return Padding(
  //               padding: EdgeInsets.only(left: 30.w, right: 30.w),
  //              //////////////////////////////
  //               child: CtInqueryBox(
  //                 onCancelTap: () {
  //                   setState(() {
  //                     isWithdrawOnClick = !isWithdrawOnClick;
  //                   });
  //                 }, enquiry: _ctEnquiries[index],
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _viewCtEnquiryWidget() {
    return Column(
      children: [
        // ── back button + filter dropdown in one row ──
        Padding(
          padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
          child: Row(
            children: [
              // back button
              GestureDetector(
                onTap: () => setState(() => viewCtEnquiryOnClick = false),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: appTextColor3,
                  size: 28.w,
                ),
              ),
              // filter dropdown centered
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 180.w,
                    child: AppFilterDropDown(
                      hint: "Today",
                      toggleDropdown: () {
                        showModalBottomSheet(
                          backgroundColor: Colors.white,
                          context: context,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(25),
                            ),
                          ),
                          builder: (context) {
                            return Padding(
                              padding: EdgeInsets.all(30.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40.w,
                                    height: 5.h,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    padding: EdgeInsets.all(16.w),
                                    child: Column(
                                      children: [
                                        Divider(color: Colors.grey[200]),
                                        SizedBox(height: 10.h),
                                        AppText(
                                          text: "item1",
                                          size: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        SizedBox(height: 10.h),
                                        Divider(color: Colors.grey[200]),
                                        SizedBox(height: 10.h),
                                        AppText(
                                          text: "item2",
                                          size: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        SizedBox(height: 10.h),
                                        Divider(color: Colors.grey[200]),
                                        SizedBox(height: 10.h),
                                        AppText(
                                          text: "item3",
                                          size: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        SizedBox(height: 10.h),
                                        Divider(color: Colors.grey[200]),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      icon: Icons.tune,
                    ),
                  ),
                ),
              ),
              // invisible spacer to balance the back button on the left
              SizedBox(width: 28.w),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        // ── SINGLE list/loading/empty ──
        Expanded(
          child: _ctEnquiriesLoading
              ? const Center(child: CircularProgressIndicator())
              : _ctEnquiries.isEmpty
              ? Center(
                  child: AppText(
                    text: "No enquiries found",
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
                  ),
                )
              : ListView.builder(
                  itemCount: _ctEnquiries.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(left: 30.w, right: 30.w),
                      child: CtInqueryBox(
                        enquiry: _ctEnquiries[index],
                        onCancelTap: () {
                          setState(() {
                            isWithdrawOnClick = !isWithdrawOnClick;
                          });
                        }, onEdit: () { 
                           setState(() => viewCtEnquiryOnClick = false);
                         },
                        
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // coorected with api call
  Widget _ctReviewBox() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(30.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          text: "C17854",
                          size: 20,
                          fontWeight: FontWeight.w700,
                          color: appTextColor3,
                        ),
                        GestureDetector(
                          onTap: () {
                            _stopCtTimer();
                            setState(() => isCtReviewOnClick = false);
                          },
                          child: AppText(
                            text: "Edit",
                            size: 15,
                            fontWeight: FontWeight.w700,
                            color: appLinkColor,
                          ),
                          // AppText(
                          //   text: "C17854",
                          //   size: 20,
                          //   fontWeight: FontWeight.w700,
                          //   color: appTextColor3,
                          // ),

                          // AppText(
                          //   text: "Edit",
                          //   size: 15,
                          //   fontWeight: FontWeight.w700,
                          //   color: appLinkColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.dashboard,
                      "Your Menu",
                      ctEnquiryData['menu'] ?? '',
                    ),

                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Your Menu",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text:
                    //                 "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.handshake,
                      "Other Services",
                      ctEnquiryData['otherServices'] ?? '',
                    ),

                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.handshake, size: 20.w, color: appTextColor2),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Other Services",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text: "7 Service boys needed.",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.people,
                      "Number of Persons",
                      "${ctEnquiryData['people'] ?? ''} Person",
                    ),
                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.people, size: 20.w, color: appTextColor2),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Number of Persons",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text: "200 Person ",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.calendar_today_sharp,
                      "Date and Time",
                      ctEnquiryData['dateTime'] ?? '',
                    ),

                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(
                    //       Icons.calendar_today_sharp,
                    //       size: 20.w,
                    //       color: appTextColor2,
                    //     ),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Date and Time ",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text: "April 12 - 2:30 pm",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.wallet,
                      "Expected amount per person",
                      "${ctEnquiryData['amount'] ?? ''} Per person",
                    ),

                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.wallet, size: 20.w, color: appTextColor2),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Expected amount per person",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text: "450 Per person",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.analytics,
                      "Enquiry Radius",
                      ctEnquiryData['location'] ?? '',
                    ),
                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.analytics, size: 20.w, color: appTextColor2),
                    //     SizedBox(width: 10.w),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           AppText(
                    //             text: "Enquiry Radius ",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.grey,
                    //           ),
                    //           SizedBox(height: 5.h),
                    //           AppText(
                    //             text: "Moscow City - 20km Radius",
                    //             size: 15,
                    //             fontWeight: FontWeight.w500,
                    //             color: appTextColor2,
                    //             lineSpacing: 1.5,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 30.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, size: 20.w, color: Colors.red),
                        SizedBox(width: 5.w),
                        AppText(
                          text: _ctTimerText,
                          size: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    SizedBox(
                      width: 150.w,
                      height: 50.h,
                      child: AppButton(
                        text: "Send",
                        onPressed: () {
                          _stopCtTimer(); // add this
                          _submitCateringEnquiry();
                        },
                        // onPressed: () {
                        //   setState(() {
                        //     isCtReviewOnClick = !isCtReviewOnClick;
                        //   });
                        // },
                        size: 15,
                        bgColor1: Colors.green,
                        bgColor2: Colors.green,
                        borderRadius: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
//-----------------------------Catering Widgets--------------------------//
//-----------------------------Party Widgets--------------------------//

 Widget _partyReviewBox() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(30.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          text: "C17854",
                          size: 20,
                          fontWeight: FontWeight.w700,
                          color: appTextColor3,
                        ),
                        GestureDetector(
                          onTap: () {
                            _stopPartyTimer();
                            setState(() => isReviewOnClick = false);
                          },
                          child: AppText(
                            text: "Edit",
                            size: 15,
                            fontWeight: FontWeight.w700,
                            color: appLinkColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.dashboard,
                      "Your Menu",
                      partyEnquiryData['menu'] ?? '',
                    ),


                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.handshake,
                      "Other Services",
                      partyEnquiryData['otherServices'] ?? '',
                    ),

                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.people,
                      "Number of Persons",
                      "${partyEnquiryData['people'] ?? ''} Person",
                    ),
         

                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.calendar_today_sharp,
                      "Date and Time",
                      partyEnquiryData['dateTime'] ?? '',
                    ),


                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.wallet,
                      "Expected amount per person",
                      "${partyEnquiryData['amount'] ?? ''} Per person",
                    ),

                    
                    SizedBox(height: 20.h),
                    _reviewRow(
                      Icons.analytics,
                      "Enquiry Radius",
                      partyEnquiryData['location'] ?? '',
                    ),

                    SizedBox(height: 30.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, size: 20.w, color: Colors.red),
                        SizedBox(width: 5.w),
                        AppText(
                          text: _partyTimerText,
                          size: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    SizedBox(
                      width: 150.w,
                      height: 50.h,
                      child: AppButton(
                        text: "Send",
                        onPressed: () {
                          _stopPartyTimer(); 
                          _submitPartyEnquiry();
                        },
                        size: 15,
                        bgColor1: Colors.green,
                        bgColor2: Colors.green,
                        borderRadius: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
//-----------------------------Party Widgets--------------------------//



  // helper widget for each row
  Widget _reviewRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.w, color: appTextColor2),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: label,
                size: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              SizedBox(height: 5.h),
              AppText(
                text: value,
                size: 15,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
                lineSpacing: 1.5,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _responseAcceptConfirmBox() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isResponseAcceptConfirmOnClick =
                                !isResponseAcceptConfirmOnClick;
                            if (isConfirmClicked) {
                              isConfirmClicked = !isConfirmClicked;
                            }
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: appTextColor3,
                          size: 25.w,
                        ),
                      ),
                    ],
                  ),

                  if (isConfirmClicked)
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/checked.png',
                          height: 50.h,
                          width: 50.w,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 20.h),
                        AppText(
                          text: "Booking Successful!",
                          size: 20,
                          fontWeight: FontWeight.w500,
                          color: appTextColor3,
                          isCentered: true,
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),

                  if (!isConfirmClicked)
                    Column(
                      children: [
                        SizedBox(height: 20.h),
                        AppText(
                          text:
                              "After confirmation, your party order will be booked at Bollywood Restaurant.",
                          size: 15,
                          fontWeight: FontWeight.w500,
                          color: appTextColor2,
                          isCentered: true,
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: 150.w,
                          height: 40.h,
                          child: AppButton(
                            text: "Confirm",
                            onPressed: () {
                              setState(() {
                                isConfirmClicked = !isConfirmClicked;
                              });
                            },
                            bgColor1: Colors.green,
                            bgColor2: Colors.green,
                            size: 15,
                            borderRadius: 10,
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewSearchWidget() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
              child: AppTextFeild(
                text: "Your Current Location",
                textColor: appTextColor3,
                icon: Icons.close,
                iconColor: appTextColor3,
                iconOnTap: () {
                  setState(() {
                    isSearchOnClick = !isSearchOnClick;
                  });
                },
              ),
            ),

            SizedBox(height: 20.h),
            SizedBox(
              width: 180.w,
              child: AppFilterDropDown(
                hint: "Today",
                toggleDropdown: () {
                  showModalBottomSheet(
                    backgroundColor: Colors.white,
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25.r),
                      ),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: EdgeInsets.all(30.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40.w,
                              height: 5.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                children: [
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item1",
                                    size: 15.w,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item2",
                                    size: 15.w,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item3",
                                    size: 15.w,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icons.tune,
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 2,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(left: 30.w, right: 30.w),
                    child: SizedBox.shrink(),

                    // child: ResponseBox(
                    //   viewRequestClick: () {
                    //     setState(() {
                    //       viewRequest = !viewRequest;
                    //     });
                    //   },
                    //   onAcceptTap: () {
                    //     setState(() {
                    //       isResponseAcceptOnClick = !isResponseAcceptOnClick;
                    //     });
                    //   },
                    //   onCancelTap: () {
                    //     setState(() {});
                    //   },
                    // ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _viewDeclineWidget() {
    return Stack(
      children: [
        Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  viewDeclineOnClick = !viewDeclineOnClick;
                });
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: appTextColor3,
                    size: 28,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 180.w,
              child: AppFilterDropDown(
                hint: "Today",
                toggleDropdown: () {
                  showModalBottomSheet(
                    backgroundColor: Colors.white,
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25.r),
                      ),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: EdgeInsets.all(30.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40.w,
                              height: 5.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                children: [
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item1",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item2",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                  SizedBox(height: 10.h),
                                  AppText(
                                    text: "item3",
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 10.h),
                                  Divider(color: Colors.grey[200]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icons.tune,
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 2,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(left: 30.w, right: 30.w),
                      // child: DeclineBox(onCancelTap: () {}),
                      child: SizedBox.shrink(),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  //---------------------------------------------------------------------------
  Widget _viewRequestWidget() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        text: "Requested party",
                        size: 15,
                        fontWeight: FontWeight.w500,
                        color: appTextColor2,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            viewRequest = !viewRequest;
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: appTextColor3,
                          size: 25.w,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      text: "P17854",
                      size: 20,
                      fontWeight: FontWeight.w700,
                      color: appTextColor3,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Your Menu",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text:
                                  "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.people, size: 20.w, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Number of Persons",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "12 Person ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.calendar_today_sharp,
                        size: 20.w,
                        color: appTextColor2,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Date and Time ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "April 12 - 2:30 pm",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.wallet, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Expected amount per person",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "1000 Per person",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.analytics, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: "Enquiry Radius ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 5.h),
                            AppText(
                              text: "Moscow City - 20km Radius",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: appTextColor2,
                              lineSpacing: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _responseAcceptBox() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 50.w,
                    color: Colors.red,
                  ),
                  SizedBox(height: 10.h),
                  AppText(
                    text: "Switch Banquet Booking?",
                    isCentered: true,
                    lineSpacing: 1.5,
                    size: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                  SizedBox(height: 10.h),
                  AppText(
                    text:
                        " You already have a banquet booked at Bollywood Restaurant. Booking another Banquet will automatically cancel your previous booking.",
                    isCentered: true,
                    lineSpacing: 1.5,
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor2,
                  ),

                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        text: "Cancel",
                        size: 15,
                        fontWeight: FontWeight.w400,
                        color: appLinkColor2,
                      ),
                      SizedBox(
                        width: 120.w,
                        height: 40.h,
                        child: AppButton(
                          text: "Yes,Book",
                          onPressed: () {
                            setState(() {
                              isResponseAcceptOnClick =
                                  !isResponseAcceptOnClick;
                              isResponseAcceptConfirmOnClick =
                                  !isResponseAcceptConfirmOnClick;
                            });
                          },
                          size: 15,
                          bgColor1: Colors.green,
                          bgColor2: Colors.green,
                          borderRadius: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _responseWidget() {
    return Column(
      children: [
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 150.w,
                child: AppFilterDropDown(
                  hint: "Today",
                  icon: Icons.tune,
                  toggleDropdown: () {
                    showModalBottomSheet(
                      backgroundColor: Colors.white,
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25.r),
                        ),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.all(30.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40.w,
                                height: 5.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  children: [
                                    Divider(color: Colors.grey[200]),
                                    SizedBox(height: 10.h),
                                    AppText(
                                      text: "item1",
                                      size: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 10.h),
                                    Divider(color: Colors.grey[200]),
                                    SizedBox(height: 10.h),
                                    AppText(
                                      text: "item2",
                                      size: 15.w,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 10.h),
                                    Divider(color: Colors.grey[200]),
                                    SizedBox(height: 10.h),
                                    AppText(
                                      text: "item3",
                                      size: 15.w,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 10.h),
                                    Divider(color: Colors.grey[200]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.search, size: 17.w, color: Colors.black),
                      SizedBox(width: 2.w),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isSearchOnClick = !isSearchOnClick;
                          });
                        },
                        child: AppText(
                          text: "Search",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.book, size: 17.w, color: appLinkColor2),
                      SizedBox(width: 2.w),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            viewDeclineOnClick = !viewDeclineOnClick;
                          });
                        },
                        child: AppText(
                          text: "View Declined",
                          size: 15,
                          fontWeight: FontWeight.w400,
                          color: appLinkColor2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                // child: ResponseBox(
                //   viewRequestClick: () {
                //     setState(() {
                //       viewRequest = !viewRequest;
                //     });
                //   },
                //   onAcceptTap: () {
                //     setState(() {
                //       isResponseAcceptOnClick = !isResponseAcceptOnClick;
                //     });
                //   },
                //   onCancelTap: () {
                //     setState(() {});
                //   },
                // ),
                child:SizedBox.shrink(),

              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildStatusButton(String text) {
    final bool isSelected = selectedStatus == text;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStatus = text;
          });
        },
        child: Container(
          height: 35.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6.r,
                offset: Offset(2.w, 2.w),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.w,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor3,
            ),
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
// import 'package:fudikoclient/components/apptextfeild.dart';
// import 'package:fudikoclient/components/descriptionBox.dart';
// import 'package:fudikoclient/model/inquery/list-inquery-modal.dart';
// import 'package:fudikoclient/screens/tabs/inquery/common/responseBox.dart';
// import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctInquery.dart';
// import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctInqueryBox.dart';
// import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctdecline.dart';
// import 'package:fudikoclient/screens/tabs/inquery/ctInquery/ctresponseBox.dart';
// import 'package:fudikoclient/screens/tabs/inquery/common/declineBox.dart';
// import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
// import 'package:fudikoclient/components/appfilterdropdown.dart';
// import 'package:fudikoclient/screens/tabs/inquery/inquery/planaparty.dart';
// import 'package:fudikoclient/screens/tabs/inquery/inquery/viewinquery.dart';
// import 'package:fudikoclient/screens/tabs/mainnav.dart';
// import 'package:fudikoclient/service/inquery/inquery-service.dart';
// import 'package:fudikoclient/utils/constants.dart';

// class Inquery extends StatefulWidget {
//   const Inquery({super.key});

//   @override
//   State<Inquery> createState() => _InqueryState();
// }

// class _InqueryState extends State<Inquery> {
//   String selectedStatus = 'Plan a Party';
//   DateTime selectedDateTime = DateTime.now();
//   bool isReviewOnClick = false;
//   bool isCtReviewOnClick = false;
//   bool isWithdrawOnClick = false;
//   bool viewEnquiryOnClick = false;
//   bool viewCtEnquiryOnClick = false;
//   bool isResponseAcceptOnClick = false;
//   bool viewRequest = false;
//   bool viewCtRequest = false;
//   bool isResponseAcceptConfirmOnClick = false;
//   bool isConfirmClicked = false;
//   bool viewDeclineOnClick = false;
//   bool viewCtDeclineOnClick = false;
//   bool isSearchOnClick = false;
//   bool isCtSearchOnClick = false;
//   Map<String, String> ctEnquiryData = {};
//   Future<void> _submitCateringEnquiry() async {
//   final InqueryService service = InqueryService();
//   final model = CreateCateringInqueryModel(
//     lat: ctEnquiryData['lat'] ?? '',
//     lng: ctEnquiryData['lng'] ?? '',
//     menuItems: ctEnquiryData['menu'] ?? '',
//     people: ctEnquiryData['people'] ?? '',
//     time: ctEnquiryData['dateTime']?.split(' ').last ?? '',
//     date: ctEnquiryData['dateTime']?.split(' ').first ?? '',
//     estimatedAmount: ctEnquiryData['amount'] ?? '',
//     searchRadius: ctEnquiryData['searchRadius'] ?? '20',
//     expirationDate: ctEnquiryData['expirationDate'] ?? '',
//     expirationTime: ctEnquiryData['expirationTime'] ?? '',
//   );

//   final response = await service.createCateringInquery(model);

//   if (response.status) {
//     setState(() => isCtReviewOnClick = false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Enquiry submitted successfully!')),
//     );
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(response.message)),
//     );
//   }
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: appSecondaryBackgroundColor,
//       body: Stack(
//         children: [
//           if (viewEnquiryOnClick)
//             ViewInquery(
//               onEnquiryTap: (val) {
//                 setState(() {
//                   viewEnquiryOnClick = val;
//                 });
//               },
//             )
//           else if (viewCtEnquiryOnClick)
//             _viewCtEnquiryWidget()
//           else if (viewDeclineOnClick)
//             _viewDeclineWidget()
//           else if (viewCtDeclineOnClick)
//             _viewCtDeclineWidget()
//           else if (isSearchOnClick)
//             _viewSearchWidget()
//           else if (isCtSearchOnClick)
//             _viewCtSearchWidget()
//           else
//             Column(
//               children: [
//                 Padding(
//                   padding: EdgeInsets.all(20.w),
//                   child: Column(
//                     children: [
//                       Column(
//                         children: [
//                           Row(
//                             children: [
//                               buildStatusButton("Plan a Party"),
//                               SizedBox(width: 10.w),
//                               buildStatusButton("Book a Catering"),
//                             ],
//                           ),
//                           SizedBox(height: 10.h),
//                           Row(
//                             children: [
//                               buildStatusButton("Party Response"),
//                               SizedBox(width: 10.w),
//                               buildStatusButton("Catering Response"),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: selectedStatus == "Plan a Party"
//                       ? PlanAParty(
//                           onEnquiryTap: (val) {
//                             setState(() {
//                               viewEnquiryOnClick = val;
//                             });
//                           },
//                           onReviewTap: (val) {
//                             setState(() {
//                               isReviewOnClick = val;
//                             });
//                           },
//                         )
//                       : selectedStatus == "Party Response"
//                       ? _responseWidget()
//                       : selectedStatus == "Book a Catering"
//                       // ? CtInquery(
//                       //   onReviewTap: (){
//                       //     setState(() {
//                       //       isCtReviewOnClick = !isCtReviewOnClick;
//                       //     });
//                       //   },
//                       ? CtInquery(
//                           onReviewTap: (data) {
//                             setState(() {
//                               ctEnquiryData = data;
//                               isCtReviewOnClick = true;
//                             });
//                           },
//                           viewEnquiryOnTap: () {
//                             setState(() {
//                               viewCtEnquiryOnClick = !viewCtEnquiryOnClick;
//                             });
//                           },
//                         )
//                       : _ctResponseWidget(),
//                 ),
//               ],
//             ),
//           if (isResponseAcceptOnClick) _responseAcceptBox(),
//           if (viewRequest) _viewRequestWidget(),
//           if (viewCtRequest) _viewCtRequestWidget(),
//           if (isResponseAcceptConfirmOnClick) _responseAcceptConfirmBox(),
//           if (isCtReviewOnClick) _ctReviewBox(),
//         ],
//       ),
//     );
//   }

//   Widget _viewCtSearchWidget() {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             Padding(
//               padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
//               child: AppTextFeild(
//                 text: "Enter the Coupon Number",
//                 textColor: appTextColor3,
//                 icon: Icons.close,
//                 iconColor: appTextColor3,
//                 iconOnTap: () {
//                   setState(() {
//                     isCtSearchOnClick = !isCtSearchOnClick;
//                   });
//                 },
//               ),
//             ),

//             SizedBox(height: 20.h),
//             SizedBox(
//               width: 180.w,
//               child: AppFilterDropDown(
//                 hint: "Today",
//                 toggleDropdown: () {
//                   showModalBottomSheet(
//                     backgroundColor: Colors.white,
//                     context: context,
//                     isScrollControlled: true,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(25),
//                       ),
//                     ),
//                     builder: (context) {
//                       return Padding(
//                         padding: EdgeInsets.all(30.w),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 40.w,
//                               height: 5.h,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(10.r),
//                               ),
//                             ),
//                             SizedBox(height: 16.h),
//                             Container(
//                               width: MediaQuery.of(context).size.width,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20.r),
//                               ),
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 children: [
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item1",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item2",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item3",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 icon: Icons.tune,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: 2,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.only(left: 30.w, right: 30.w),
//                     child: CtResponseBox(
//                       viewRequestClick: () {
//                         setState(() {
//                           viewCtRequest = !viewCtRequest;
//                         });
//                       },
//                       onAcceptTap: () {
//                         setState(() {
//                           isResponseAcceptOnClick = !isResponseAcceptOnClick;
//                         });
//                       },
//                       onCancelTap: () {
//                         setState(() {});
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _viewCtDeclineWidget() {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             GestureDetector(
//               onTap: () {
//                 setState(() {
//                   viewCtDeclineOnClick = !viewCtDeclineOnClick;
//                 });
//               },
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Padding(
//                   padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
//                   child: Icon(
//                     Icons.arrow_back_ios_new,
//                     color: appTextColor3,
//                     size: 28.w,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 180.w,
//               child: AppFilterDropDown(
//                 hint: "Today",
//                 toggleDropdown: () {
//                   showModalBottomSheet(
//                     backgroundColor: Colors.white,
//                     context: context,
//                     isScrollControlled: true,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(25),
//                       ),
//                     ),
//                     builder: (context) {
//                       return Padding(
//                         padding: EdgeInsets.all(30.w),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 40.w,
//                               height: 5.h,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(10.r),
//                               ),
//                             ),
//                             SizedBox(height: 16.h),
//                             Container(
//                               width: MediaQuery.of(context).size.width,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20.r),
//                               ),
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 children: [
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item1",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item2",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item3",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 icon: Icons.tune,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: 2,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.only(left: 30.w, right: 30.w),
//                     child: CtDeclineBox(onCancelTap: () {}),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _viewCtRequestWidget() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       AppText(
//                         text: "Requested party",
//                         size: 15,
//                         fontWeight: FontWeight.w500,
//                         color: appTextColor2,
//                       ),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             viewCtRequest = !viewCtRequest;
//                           });
//                         },
//                         child: Icon(
//                           Icons.close,
//                           color: appTextColor3,
//                           size: 25.w,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: AppText(
//                       text: "P17854",
//                       size: 20,
//                       fontWeight: FontWeight.w700,
//                       color: appTextColor3,
//                     ),
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Your Menu",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text:
//                                   "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.handshake, size: 20.w, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Other Services",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "7 Service boys needed.",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.people, size: 20.w, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Number of Persons",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "12 Person ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(
//                         Icons.calendar_today_sharp,
//                         size: 20.w,
//                         color: appTextColor2,
//                       ),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Date and Time ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "April 12 - 2:30 pm",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.wallet, size: 20.w, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Expected amount per person",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "1000 Per person",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.analytics, size: 20.w, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Enquiry Radius ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "Moscow City - 20km Radius",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _ctResponseWidget() {
//     return Column(
//       children: [
//         SizedBox(height: 20.h),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 30.w),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SizedBox(
//                 width: 150.w,
//                 child: AppFilterDropDown(
//                   hint: "Today",
//                   icon: Icons.tune,
//                   toggleDropdown: () {
//                     showModalBottomSheet(
//                       backgroundColor: Colors.white,
//                       context: context,
//                       isScrollControlled: true,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.vertical(
//                           top: Radius.circular(25),
//                         ),
//                       ),
//                       builder: (context) {
//                         return Padding(
//                           padding: EdgeInsets.all(30.w),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Container(
//                                 width: 40.w,
//                                 height: 5.h,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[300],
//                                   borderRadius: BorderRadius.circular(10.r),
//                                 ),
//                               ),
//                               SizedBox(height: 16.h),
//                               Container(
//                                 width: MediaQuery.of(context).size.width,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(20.r),
//                                 ),
//                                 padding: EdgeInsets.all(16.w),
//                                 child: Column(
//                                   children: [
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item1",
//                                       size: 15,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item2",
//                                       size: 15,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item3",
//                                       size: 15,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10),
//                                     Divider(color: Colors.grey[200]),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.search, size: 17.w, color: Colors.black),
//                       SizedBox(width: 2.w),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             isCtSearchOnClick = !isCtSearchOnClick;
//                           });
//                         },
//                         child: AppText(
//                           text: "Search",
//                           size: 15,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 5.h),
//                   Row(
//                     children: [
//                       Icon(Icons.book, size: 17.w, color: appLinkColor2),
//                       SizedBox(width: 2.w),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             viewCtDeclineOnClick = !viewCtDeclineOnClick;
//                           });
//                         },
//                         child: AppText(
//                           text: "View Declined",
//                           size: 15,
//                           fontWeight: FontWeight.w400,
//                           color: appLinkColor2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 20.h),
//         Expanded(
//           child: ListView.builder(
//             itemCount: 10,
//             itemBuilder: (context, index) {
//               return Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 30.w),
//                 child: CtResponseBox(
//                   viewRequestClick: () {
//                     setState(() {
//                       viewCtRequest = !viewCtRequest;
//                     });
//                   },
//                   onAcceptTap: () {
//                     setState(() {
//                       isResponseAcceptOnClick = !isResponseAcceptOnClick;
//                     });
//                   },
//                   onCancelTap: () {
//                     setState(() {});
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _viewCtEnquiryWidget() {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//               },
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Padding(
//                   padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
//                   child: Icon(
//                     Icons.arrow_back_ios_new,
//                     color: appTextColor3,
//                     size: 28.w,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 180.w,
//               child: AppFilterDropDown(
//                 hint: "Today",
//                 toggleDropdown: () {
//                   showModalBottomSheet(
//                     backgroundColor: Colors.white,
//                     context: context,
//                     isScrollControlled: true,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(25),
//                       ),
//                     ),
//                     builder: (context) {
//                       return Padding(
//                         padding: EdgeInsets.all(30.w),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 40.w,
//                               height: 5.h,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(10.r),
//                               ),
//                             ),
//                             SizedBox(height: 16.h),
//                             Container(
//                               width: MediaQuery.of(context).size.width,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20.r),
//                               ),
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 children: [
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item1",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item2",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item3",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10),
//                                   Divider(color: Colors.grey[200]),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 icon: Icons.tune,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: 10,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.only(left: 30.w, right: 30.w),
//                     child: CtInqueryBox(
//                       onCancelTap: () {
//                         setState(() {
//                           isWithdrawOnClick = !isWithdrawOnClick;
//                         });
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// // coorected with api call
//   Widget _ctReviewBox() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(30.w),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                           AppText(text: "C17854", size: 20, fontWeight: FontWeight.w700, color: appTextColor3),
//                       GestureDetector(
//                         onTap: () => setState(() => isCtReviewOnClick = false),
//                          child: AppText(text: "Edit", size: 15, fontWeight: FontWeight.w700, color: appLinkColor),
//                         // AppText(
//                         //   text: "C17854",
//                         //   size: 20,
//                         //   fontWeight: FontWeight.w700,
//                         //   color: appTextColor3,
//                         // ),
                        
//                         // AppText(
//                         //   text: "Edit",
//                         //   size: 15,
//                         //   fontWeight: FontWeight.w700,
//                         //   color: appLinkColor,
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 20.h),
//                      _reviewRow(Icons.dashboard, "Your Menu", ctEnquiryData['menu'] ?? ''),
//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.start,
//                     //   children: [
//                     //     Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
//                     //     SizedBox(width: 10.w),
//                     //     Expanded(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           AppText(
//                     //             text: "Your Menu",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: Colors.grey,
//                     //           ),
//                     //           SizedBox(height: 5.h),
//                     //           AppText(
//                     //             text:
//                     //                 "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: appTextColor2,
//                     //             lineSpacing: 1.5,
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
                
//                     SizedBox(height: 20.h),
//                                       _reviewRow(Icons.handshake, "Other Services", ctEnquiryData['otherServices'] ?? ''),
//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.start,
//                     //   children: [
//                     //     Icon(Icons.handshake, size: 20.w, color: appTextColor2),
//                     //     SizedBox(width: 10.w),
//                     //     Expanded(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           AppText(
//                     //             text: "Other Services",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: Colors.grey,
//                     //           ),
//                     //           SizedBox(height: 5.h),
//                     //           AppText(
//                     //             text: "7 Service boys needed.",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: appTextColor2,
//                     //             lineSpacing: 1.5,
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
                
//                     SizedBox(height: 20.h),
//                     _reviewRow(Icons.people, "Number of Persons", "${ctEnquiryData['people'] ?? ''} Person"),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Icon(Icons.people, size: 20.w, color: appTextColor2),
//                         SizedBox(width: 10.w),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               AppText(
//                                 text: "Number of Persons",
//                                 size: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey,
//                               ),
//                               SizedBox(height: 5.h),
//                               AppText(
//                                 text: "200 Person ",
//                                 size: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: appTextColor2,
//                                 lineSpacing: 1.5,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 20.h),
//                     _reviewRow(Icons.calendar_today_sharp, "Date and Time", ctEnquiryData['dateTime'] ?? ''),

//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.start,
//                     //   children: [
//                     //     Icon(
//                     //       Icons.calendar_today_sharp,
//                     //       size: 20.w,
//                     //       color: appTextColor2,
//                     //     ),
//                     //     SizedBox(width: 10.w),
//                     //     Expanded(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           AppText(
//                     //             text: "Date and Time ",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: Colors.grey,
//                     //           ),
//                     //           SizedBox(height: 5.h),
//                     //           AppText(
//                     //             text: "April 12 - 2:30 pm",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: appTextColor2,
//                     //             lineSpacing: 1.5,
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
//                     SizedBox(height: 20.h),
//                   _reviewRow(Icons.wallet, "Expected amount per person", "${ctEnquiryData['amount'] ?? ''} Per person"),
                   
//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.start,
//                     //   children: [
//                     //     Icon(Icons.wallet, size: 20.w, color: appTextColor2),
//                     //     SizedBox(width: 10.w),
//                     //     Expanded(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           AppText(
//                     //             text: "Expected amount per person",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: Colors.grey,
//                     //           ),
//                     //           SizedBox(height: 5.h),
//                     //           AppText(
//                     //             text: "450 Per person",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: appTextColor2,
//                     //             lineSpacing: 1.5,
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
//                     SizedBox(height: 20.h),
//                     _reviewRow(Icons.analytics, "Enquiry Radius", ctEnquiryData['location'] ?? ''),
//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.start,
//                     //   children: [
//                     //     Icon(Icons.analytics, size: 20.w, color: appTextColor2),
//                     //     SizedBox(width: 10.w),
//                     //     Expanded(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           AppText(
//                     //             text: "Enquiry Radius ",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: Colors.grey,
//                     //           ),
//                     //           SizedBox(height: 5.h),
//                     //           AppText(
//                     //             text: "Moscow City - 20km Radius",
//                     //             size: 15,
//                     //             fontWeight: FontWeight.w500,
//                     //             color: appTextColor2,
//                     //             lineSpacing: 1.5,
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
//                     SizedBox(height: 30.h),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.timer, size: 20.w, color: Colors.red),
//                         SizedBox(width: 5.w),
//                         AppText(
//                           text: "03:00:00",
//                           size: 15,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.red,
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 15.h),
//                     SizedBox(
//                       width: 150.w,
//                       height: 50.h,
//                       child: AppButton(
//                         text: "Send",
//                         onPressed: () => _submitCateringEnquiry(),
//                         // onPressed: () {
//                         //   setState(() {
//                         //     isCtReviewOnClick = !isCtReviewOnClick;
//                         //   });
//                         // },
//                         size: 15,
//                         bgColor1: Colors.green,
//                         bgColor2: Colors.green,
//                         borderRadius: 10,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// // helper widget for each row
//   Widget _reviewRow(IconData icon, String label, String value) {
//   return Row(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Icon(icon, size: 20.w, color: appTextColor2),
//       SizedBox(width: 10.w),
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             AppText(text: label, size: 15, fontWeight: FontWeight.w500, color: Colors.grey),
//             SizedBox(height: 5.h),
//             AppText(text: value, size: 15, fontWeight: FontWeight.w500, color: appTextColor2, lineSpacing: 1.5),
//           ],
//         ),
//       ),
//     ],
//   );
// }

//   Widget _responseAcceptConfirmBox() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             isResponseAcceptConfirmOnClick =
//                                 !isResponseAcceptConfirmOnClick;
//                             if (isConfirmClicked) {
//                               isConfirmClicked = !isConfirmClicked;
//                             }
//                           });
//                         },
//                         child: Icon(
//                           Icons.close,
//                           color: appTextColor3,
//                           size: 25.w,
//                         ),
//                       ),
//                     ],
//                   ),

//                   if (isConfirmClicked)
//                     Column(
//                       children: [
//                         Image.asset(
//                           'assets/images/checked.png',
//                           height: 50.h,
//                           width: 50.w,
//                           fit: BoxFit.contain,
//                         ),
//                         SizedBox(height: 20.h),
//                         AppText(
//                           text: "Booking Successful!",
//                           size: 20,
//                           fontWeight: FontWeight.w500,
//                           color: appTextColor3,
//                           isCentered: true,
//                         ),
//                         SizedBox(height: 20.h),
//                       ],
//                     ),

//                   if (!isConfirmClicked)
//                     Column(
//                       children: [
//                         SizedBox(height: 20.h),
//                         AppText(
//                           text:
//                               "After confirmation, your party order will be booked at Bollywood Restaurant.",
//                           size: 15,
//                           fontWeight: FontWeight.w500,
//                           color: appTextColor2,
//                           isCentered: true,
//                         ),
//                         SizedBox(height: 20.h),
//                         SizedBox(
//                           width: 150.w,
//                           height: 40.h,
//                           child: AppButton(
//                             text: "Confirm",
//                             onPressed: () {
//                               setState(() {
//                                 isConfirmClicked = !isConfirmClicked;
//                               });
//                             },
//                             bgColor1: Colors.green,
//                             bgColor2: Colors.green,
//                             size: 15,
//                             borderRadius: 10,
//                           ),
//                         ),
//                         SizedBox(height: 20.h),
//                       ],
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _viewSearchWidget() {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             Padding(
//               padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
//               child: AppTextFeild(
//                 text: "Your Current Location",
//                 textColor: appTextColor3,
//                 icon: Icons.close,
//                 iconColor: appTextColor3,
//                 iconOnTap: () {
//                   setState(() {
//                     isSearchOnClick = !isSearchOnClick;
//                   });
//                 },
//               ),
//             ),

//             SizedBox(height: 20.h),
//             SizedBox(
//               width: 180.w,
//               child: AppFilterDropDown(
//                 hint: "Today",
//                 toggleDropdown: () {
//                   showModalBottomSheet(
//                     backgroundColor: Colors.white,
//                     context: context,
//                     isScrollControlled: true,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(25.r),
//                       ),
//                     ),
//                     builder: (context) {
//                       return Padding(
//                         padding: EdgeInsets.all(30.w),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 40.w,
//                               height: 5.h,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(10.r),
//                               ),
//                             ),
//                             SizedBox(height: 16.h),
//                             Container(
//                               width: MediaQuery.of(context).size.width,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20.r),
//                               ),
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 children: [
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item1",
//                                     size: 15.w,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item2",
//                                     size: 15.w,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item3",
//                                     size: 15.w,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 icon: Icons.tune,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: 2,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.only(left: 30.w, right: 30.w),
//                     child: ResponseBox(
//                       viewRequestClick: () {
//                         setState(() {
//                           viewRequest = !viewRequest;
//                         });
//                       },
//                       onAcceptTap: () {
//                         setState(() {
//                           isResponseAcceptOnClick = !isResponseAcceptOnClick;
//                         });
//                       },
//                       onCancelTap: () {
//                         setState(() {});
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _viewDeclineWidget() {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             GestureDetector(
//               onTap: () {
//                 setState(() {
//                   viewDeclineOnClick = !viewDeclineOnClick;
//                 });
//               },
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Padding(
//                   padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
//                   child: Icon(
//                     Icons.arrow_back_ios_new,
//                     color: appTextColor3,
//                     size: 28,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 180.w,
//               child: AppFilterDropDown(
//                 hint: "Today",
//                 toggleDropdown: () {
//                   showModalBottomSheet(
//                     backgroundColor: Colors.white,
//                     context: context,
//                     isScrollControlled: true,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(25.r),
//                       ),
//                     ),
//                     builder: (context) {
//                       return Padding(
//                         padding: EdgeInsets.all(30.w),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 40.w,
//                               height: 5.h,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(10.r),
//                               ),
//                             ),
//                             SizedBox(height: 16.h),
//                             Container(
//                               width: MediaQuery.of(context).size.width,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20.r),
//                               ),
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 children: [
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item1",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item2",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                   SizedBox(height: 10.h),
//                                   AppText(
//                                     text: "item3",
//                                     size: 15,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Divider(color: Colors.grey[200]),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 icon: Icons.tune,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: 2,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: EdgeInsets.only(left: 30.w, right: 30.w),
//                     child: DeclineBox(onCancelTap: () {}),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   //---------------------------------------------------------------------------
//   Widget _viewRequestWidget() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       AppText(
//                         text: "Requested party",
//                         size: 15,
//                         fontWeight: FontWeight.w500,
//                         color: appTextColor2,
//                       ),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             viewRequest = !viewRequest;
//                           });
//                         },
//                         child: Icon(
//                           Icons.close,
//                           color: appTextColor3,
//                           size: 25.w,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: AppText(
//                       text: "P17854",
//                       size: 20,
//                       fontWeight: FontWeight.w700,
//                       color: appTextColor3,
//                     ),
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.dashboard, size: 20.w, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Your Menu",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text:
//                                   "Chicken Biriyani , Porotta, Rotti ,Salad, Payasam, Butter Chicken , Ice cream. ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.people, size: 20.w, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Number of Persons",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "12 Person ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(
//                         Icons.calendar_today_sharp,
//                         size: 20.w,
//                         color: appTextColor2,
//                       ),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Date and Time ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "April 12 - 2:30 pm",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.wallet, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Expected amount per person",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "1000 Per person",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.analytics, size: 20, color: appTextColor2),
//                       SizedBox(width: 10.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: "Enquiry Radius ",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 5.h),
//                             AppText(
//                               text: "Moscow City - 20km Radius",
//                               size: 15,
//                               fontWeight: FontWeight.w500,
//                               color: appTextColor2,
//                               lineSpacing: 1.5,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20.h),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _responseAcceptBox() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.warning_amber_outlined,
//                     size: 50.w,
//                     color: Colors.red,
//                   ),
//                   SizedBox(height: 10.h),
//                   AppText(
//                     text: "Switch Banquet Booking?",
//                     isCentered: true,
//                     lineSpacing: 1.5,
//                     size: 15,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.red,
//                   ),
//                   SizedBox(height: 10.h),
//                   AppText(
//                     text:
//                         " You already have a banquet booked at Bollywood Restaurant. Booking another Banquet will automatically cancel your previous booking.",
//                     isCentered: true,
//                     lineSpacing: 1.5,
//                     size: 15,
//                     fontWeight: FontWeight.w500,
//                     color: appTextColor2,
//                   ),

//                   SizedBox(height: 20.h),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       AppText(
//                         text: "Cancel",
//                         size: 15,
//                         fontWeight: FontWeight.w400,
//                         color: appLinkColor2,
//                       ),
//                       SizedBox(
//                         width: 120.w,
//                         height: 40.h,
//                         child: AppButton(
//                           text: "Yes,Book",
//                           onPressed: () {
//                             setState(() {
//                               isResponseAcceptOnClick =
//                                   !isResponseAcceptOnClick;
//                               isResponseAcceptConfirmOnClick =
//                                   !isResponseAcceptConfirmOnClick;
//                             });
//                           },
//                           size: 15,
//                           bgColor1: Colors.green,
//                           bgColor2: Colors.green,
//                           borderRadius: 10,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _responseWidget() {
//     return Column(
//       children: [
//         SizedBox(height: 20.h),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 30.w),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SizedBox(
//                 width: 150.w,
//                 child: AppFilterDropDown(
//                   hint: "Today",
//                   icon: Icons.tune,
//                   toggleDropdown: () {
//                     showModalBottomSheet(
//                       backgroundColor: Colors.white,
//                       context: context,
//                       isScrollControlled: true,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.vertical(
//                           top: Radius.circular(25.r),
//                         ),
//                       ),
//                       builder: (context) {
//                         return Padding(
//                           padding: EdgeInsets.all(30.w),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Container(
//                                 width: 40.w,
//                                 height: 5.h,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[300],
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                               SizedBox(height: 16.h),
//                               Container(
//                                 width: MediaQuery.of(context).size.width,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(20.r),
//                                 ),
//                                 padding: EdgeInsets.all(16.w),
//                                 child: Column(
//                                   children: [
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item1",
//                                       size: 15,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item2",
//                                       size: 15.w,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     Divider(color: Colors.grey[200]),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "item3",
//                                       size: 15.w,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     Divider(color: Colors.grey[200]),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.search, size: 17.w, color: Colors.black),
//                       SizedBox(width: 2.w),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             isSearchOnClick = !isSearchOnClick;
//                           });
//                         },
//                         child: AppText(
//                           text: "Search",
//                           size: 15,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 5.h),
//                   Row(
//                     children: [
//                       Icon(Icons.book, size: 17.w, color: appLinkColor2),
//                       SizedBox(width: 2.w),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             viewDeclineOnClick = !viewDeclineOnClick;
//                           });
//                         },
//                         child: AppText(
//                           text: "View Declined",
//                           size: 15,
//                           fontWeight: FontWeight.w400,
//                           color: appLinkColor2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 20.h),
//         Expanded(
//           child: ListView.builder(
//             itemCount: 10,
//             itemBuilder: (context, index) {
//               return Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 30.w),
//                 child: ResponseBox(
//                   viewRequestClick: () {
//                     setState(() {
//                       viewRequest = !viewRequest;
//                     });
//                   },
//                   onAcceptTap: () {
//                     setState(() {
//                       isResponseAcceptOnClick = !isResponseAcceptOnClick;
//                     });
//                   },
//                   onCancelTap: () {
//                     setState(() {});
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget buildStatusButton(String text) {
//     final bool isSelected = selectedStatus == text;

//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           setState(() {
//             selectedStatus = text;
//           });
//         },
//         child: Container(
//           height: 35.h,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             gradient: isSelected
//                 ? const LinearGradient(
//                     colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
//                   )
//                 : null,
//             color: isSelected ? null : Colors.white,
//             borderRadius: BorderRadius.circular(10.r),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.2),
//                 blurRadius: 6.r,
//                 offset: Offset(2.w, 2.w),
//               ),
//             ],
//           ),
//           child: Text(
//             text,
//             style: TextStyle(
//               fontSize: 13.w,
//               fontWeight: FontWeight.w500,
//               color: isSelected ? Colors.white : appTextColor3,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
