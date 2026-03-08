import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/screens/tabs/reservation/reservationBox.dart';
import 'package:fudikoclient/screens/tabs/reservation/searchBox.dart';
import 'package:fudikoclient/utils/constants.dart';

class Reservation extends StatefulWidget {
  const Reservation({super.key});

  @override
  State<Reservation> createState() => _ReservationState();
}

class _ReservationState extends State<Reservation> {
  bool isDeletePressed = false;
  bool isConfirmedPressed = false;
  bool isBookingCanceled = false;
  bool isPartySearchPressed = false;
  bool isCateringSearchPressed = false;
  bool isSearchDeletePressed = false;
  bool isPartyRequestPressed = false;
  bool isCateringRequestPressed = false;
  String selectedStatus = "Entered the wrong details";
  String mainSelectedStatus = "Party";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: mainSelectedStatus == "Party" ? isPartySearchPressed ? _viewSearchWidget() : _buildMain()
                  : isCateringSearchPressed ? _viewCateringSearchWidget() : _buildCateringMain(),
          ),
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Row(
              children: [
                Expanded(child: buildMainStatusButton("Party")),
                SizedBox(width: 10.w),
                Expanded(child: buildMainStatusButton("Catering")),
              ],
            ),
          ),
          if (isDeletePressed)
            Positioned.fill(
              child: Container(color: Colors.black38, child: _deleteBox()),
            ),
          if (isPartyRequestPressed)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: _viewPartyRequestWidget(),
              ),
            ),
          if (isCateringRequestPressed)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: _viewCateringRequestWidget(),
              ),
            ),
          if (isSearchDeletePressed)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: _deleteSearchBox(),
              ),
            ),
          if (isConfirmedPressed)
            Positioned.fill(
              child: Container(color: Colors.black38, child: _confirmedBox()),
            ),
          if (isBookingCanceled)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: _bookingCanceledBox(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _viewCateringSearchWidget(){
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isCateringSearchPressed = !isCateringSearchPressed;
            });
          },
          child: Padding(
            padding:  EdgeInsets.only(left: 20.w, right: 20.w, top: 80.h),
            child: AppTextFeild(
              text: "Enter the Coupon Number",
              textColor: appTextColor3,
              isTextCenter: true,
              icon: Icons.close,
              iconColor: appTextColor3,
              size: 13.sp,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: 200,
          child: AppFilterDropDown(
            hint: "filter",
            icon: Icons.tune_outlined,
            toggleDropdown: () {
              showModalBottomSheet(
                backgroundColor: Colors.white,
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (context) {
                  return Padding(
                    padding:  EdgeInsets.all(30.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding:  EdgeInsets.all(16.w),
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
          ),
        ),
        SizedBox(height: 20.h),
        Padding(
          padding:  EdgeInsets.symmetric(horizontal: 20.w),
          child: ListView.builder(
            itemCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return SearchBox(
                onCancelTap: () {
                  setState(() {
                    isSearchDeletePressed = !isSearchDeletePressed;
                  });
                },
                onRequestTap: () {
                  setState(() {
                    isCateringRequestPressed = !isCateringRequestPressed;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCateringMain(){
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isCateringSearchPressed = !isCateringSearchPressed;
            });
          },
          child: Padding(
            padding:  EdgeInsets.only(left: 30.w, right: 30.w, top: 80.h),
            child: Container(
              padding:  EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "Search Restaurant",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: appTextColor3,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: 200,
          child: AppFilterDropDown(
            hint: "filter",
            icon: Icons.tune_outlined,
            toggleDropdown: () {
              showModalBottomSheet(
                backgroundColor: Colors.white,
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (context) {
                  return Padding(
                    padding:  EdgeInsets.all(30.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding:  EdgeInsets.all(16.w),
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
          ),
        ),
        SizedBox(height: 20.h),
        Padding(
          padding:  EdgeInsets.symmetric(horizontal: 20.w),
          child: ListView.builder(
            itemCount: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return ReservationBox(
                onCancelTap: () {
                  setState(() {
                    isDeletePressed = !isDeletePressed;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMain() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isPartySearchPressed = !isPartySearchPressed;
            });
          },
          child: Padding(
            padding:  EdgeInsets.only(left: 20.w, right: 20.w, top: 80.h),
            child: Container(
              padding:  EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "Search Restaurant",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: appTextColor3,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: 200,
          child: AppFilterDropDown(
            hint: "filter",
            icon: Icons.tune_outlined,
            toggleDropdown: () {
              showModalBottomSheet(
                backgroundColor: Colors.white,
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (context) {
                  return Padding(
                    padding:  EdgeInsets.all(30.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding:  EdgeInsets.all(16.w),
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
          ),
        ),
        SizedBox(height: 20.h),
        Padding(
          padding:  EdgeInsets.symmetric(horizontal: 20.w),
          child: ListView.builder(
            itemCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return ReservationBox(
                onCancelTap: () {
                  setState(() {
                    isDeletePressed = !isDeletePressed;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _viewSearchWidget() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isPartySearchPressed = !isPartySearchPressed;
            });
          },
          child: Padding(
            padding:  EdgeInsets.only(left: 20.w, right: 20.w, top: 80.h),
            child: AppTextFeild(
              text: "Enter the Coupon Number",
              textColor: appTextColor3,
              isTextCenter: true,
              icon: Icons.close,
              iconColor: appTextColor3,
              size: 13.sp,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: 200,
          child: AppFilterDropDown(
            hint: "filter",
            icon: Icons.tune_outlined,
            toggleDropdown: () {
              showModalBottomSheet(
                backgroundColor: Colors.white,
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (context) {
                  return Padding(
                    padding:  EdgeInsets.all(30.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding:  EdgeInsets.all(16.w),
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
          ),
        ),
        SizedBox(height: 20.h),
        Padding(
              padding:  EdgeInsets.symmetric(horizontal: 20.w),
          child: ListView.builder(
            itemCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return SearchBox(
                onCancelTap: () {
                  setState(() {
                    isSearchDeletePressed = !isSearchDeletePressed;
                  });
                },
                onRequestTap: () {
                  setState(() {
                    isPartyRequestPressed = !isPartyRequestPressed;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _deleteSearchBox() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
        ),
        Center(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding:  EdgeInsets.only(
                left: 40.w,
                right: 40.w,
                top: 30.h,
                bottom: 30.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.r),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AppText(
                        text: "Reason for Cancel",
                        size: 13,
                        fontWeight: FontWeight.w500,
                        color: appTextColor3,
                        isCentered: true,
                      ),
                      Spacer(),
                      Icon(Icons.close, size: 25, color: appTextColor3),
                    ],
                  ),

                  SizedBox(height: 20.h),
                  SizedBox(
                    height: 40.h,
                    child: buildStatusButton("I changed my mind"),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 40.h,
                    child: buildStatusButton("I need to reschedule the event"),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 40.h,
                    child: buildStatusButton("Entered the wrong details"),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 40.h,
                    child: buildStatusButton("I booked by mistake"),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 40.h,
                    child: buildStatusButton("Other Reasons"),
                  ),
                  SizedBox(height: 40.h),
                  AppText(
                    text:
                        "Canceling a confirmed booking may negatively impact your reliability rating.",
                    size: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    isCentered: true,
                  ),
                  SizedBox(height: 10.h),
                  AppText(
                    text:
                        "However, if you accept another response instead, the previous booking will be automatically replaced without affecting your rating.",
                    size: 13,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                    isCentered: true,
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Accept another response",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: appLinkColor2,
                    isCentered: true,
                  ),
                  SizedBox(height: 20.h ),
                  SizedBox(
                    width: 150,
                    height: 40,
                    child: AppButton(
                      text: "Cancel",
                      bgColor1: Colors.red,
                      bgColor2: Colors.red,
                      size: 15,
                      borderRadius: 10,
                      onPressed: () {
                        setState(() {
                          isSearchDeletePressed = !isSearchDeletePressed;
                          isBookingCanceled = !isBookingCanceled;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildStatusButton(String text) {
    final bool isSelected = selectedStatus == text;

    return GestureDetector(
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
          color: isSelected ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget buildMainStatusButton(String text) {
    final bool isSelected = mainSelectedStatus == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          mainSelectedStatus = text;
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
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : appTextColor3,
          ),
        ),
      ),
    );
  }

  Widget _bookingCanceledBox() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
          ),
        Center(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding:  EdgeInsets.only(
                left: 40.w,
                right: 40.w,
                top: 30.h,
                bottom: 30.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.r),
                  ),
                ],
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
                            if (isDeletePressed) {
                              isDeletePressed = !isDeletePressed;
                            }
                            isBookingCanceled = !isBookingCanceled;
                          });
                        },
                        child: Icon(Icons.close, size: 30, color: appTextColor),
                      ),
                    ],
                  ),
                  Image.asset(
                    'assets/images/cancel.png',
                    height: 60.h,
                    width: 60.w,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Booking Canceled!",
                    size: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                    isCentered: true,
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirmedBox() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
        ),
        Center(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding:  EdgeInsets.only(
                left: 40.w,
                right: 40.w,
                top: 30.h,
                bottom: 30.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.r),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    text: "Are you sure you want to Cancel this Booking?",
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    isCentered: true,
                  ),
                  SizedBox(height: 10.h),
                  AppText(
                    text:
                        "Cancelling a confirmed order may negatively impact your reliability rating",
                    size: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    isCentered: true,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 35.h,
                          child: AppButton(
                            text: "Yes",
                            onPressed: () {
                              setState(() {
                                isDeletePressed = !isDeletePressed;
                                isConfirmedPressed = !isConfirmedPressed;
                                isBookingCanceled = !isBookingCanceled;
                              });
                            },
                              borderRadius: 5.r,
                            bgColor1: Colors.green,
                            bgColor2: Colors.green,
                            size: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: SizedBox(
                          height: 35.h,
                          child: AppButton(
                            text: "No",
                            onPressed: () {
                              setState(() {
                                isDeletePressed = !isDeletePressed;
                              });
                            },
                                size: 12,
                            borderRadius: 5.r,
                            bgColor1: Colors.red,
                            bgColor2: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deleteBox() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
        ),
        Center(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding:  EdgeInsets.only(
                left: 40.w,
                right: 40.w,
                top: 30.h,
                bottom: 30.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.r),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    text: "Are you sure you want to Cancel this Booking?",
                    size: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    isCentered: true,
                    lineSpacing: 1.2,
                  ),
                  SizedBox(height: 10.h ),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 35.h,
                          child: AppButton(
                            text: "Yes",
                            onPressed: () {
                              setState(() {
                                isDeletePressed = !isDeletePressed;
                                isConfirmedPressed = !isConfirmedPressed;
                              });
                            },
                            borderRadius: 5.r,
                            bgColor1: Colors.green,
                            bgColor2: Colors.green,
                            size: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: SizedBox(
                          height: 35.h,
                          child: AppButton(
                            text: "No",
                            onPressed: () {
                              setState(() {
                                isDeletePressed = !isDeletePressed;
                              });
                            },
                              size: 12,
                            borderRadius: 5.r,
                            bgColor1: Colors.red,
                            bgColor2: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _viewCateringRequestWidget(){
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding:  EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                            isCateringRequestPressed = !isCateringRequestPressed;
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: appTextColor3,
                          size: 25,
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
                      Icon(Icons.dashboard, size: 20, color: appTextColor2),
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
                      Icon(Icons.handshake, size: 20, color: appTextColor2),
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
                      Icon(Icons.people, size: 20, color: appTextColor2),
                      SizedBox(width: 10.w  ),
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
                        size: 20,
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
                  SizedBox(height: 20.h ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _viewPartyRequestWidget() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 30.w),
            child: Container(
              width: double.infinity,
              padding:  EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
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
                            isPartyRequestPressed = !isPartyRequestPressed;
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: appTextColor3,
                          size: 25,
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
                      Icon(Icons.dashboard, size: 20, color: appTextColor2),
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
                      Icon(Icons.people, size: 20, color: appTextColor2),
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
                        size: 20,
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
                            SizedBox(height: 5.h  ),
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
}
