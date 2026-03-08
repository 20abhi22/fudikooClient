import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appfilterdropdown.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/inquery/list-party-inquery-modal.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/inqueryBox.dart';
import 'package:fudikoclient/screens/tabs/mainnav.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';

class ViewInquery extends StatefulWidget {
  final Function(bool) onEnquiryTap;
  const ViewInquery({
    super.key,
    required this.onEnquiryTap,
  });

  @override
  State<ViewInquery> createState() => _ViewInqueryState();
}

class _ViewInqueryState extends State<ViewInquery> {
  List<InqueryModel> inqueryList = [];
  bool _loading = true;

  InqueryService inqueryService = InqueryService();

  @override
  void initState() {
    fetchInqueryList();
    super.initState();
  }

  Future<void> fetchInqueryList() async {
    setState(() => _loading = true);
    final response = await inqueryService.fetchInquerys();
    setState(() {
      inqueryList = response.enquiries;
      _loading = false;
    });
    print(inqueryList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── back button + filter dropdown in one row ──
        Padding(
          padding:  EdgeInsets.only(left: 30.w, right: 30.w, top: 30.h),
          child: Row(
            children: [
              // back button
              GestureDetector(
                onTap: () => widget.onEnquiryTap(false),
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
        // ── SINGLE list / loading / empty ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : inqueryList.isEmpty
              ? Center(
                  child: AppText(
                    text: "No enquiries found",
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
                  ),
                )
              : ListView.builder(
                  itemCount: inqueryList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(left: 30.w, right: 30.w),
                      child: InqueryBox(
                        uuid: inqueryList[index].uuid,
                        enquiryId: inqueryList[index].enquiryId,
                        userId: inqueryList[index].userId,
                        lat: inqueryList[index].lat,
                        lng: inqueryList[index].lng,
                        menuItems: inqueryList[index].menuItems,
                        people: inqueryList[index].people,
                        date: inqueryList[index].date,
                        time: inqueryList[index].time,
                        estimatedAmount: inqueryList[index].estimatedAmount,
                        searchRadius: inqueryList[index].searchRadius,
                        expirationDate: inqueryList[index].expirationDate,
                        expirationTime: inqueryList[index].expirationTime,
                        status: inqueryList[index].status,
                        onDeleted: () {
                          fetchInqueryList();
                        },
                        onEdit: () {
                          widget.onEnquiryTap(false);
                        },
                        enquiry: inqueryList[index],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
