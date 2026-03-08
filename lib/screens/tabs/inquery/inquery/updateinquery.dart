import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/model/inquery/create-inquery-model.dart';
import 'package:fudikoclient/model/inquery/update-inquery-model.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';
import 'package:intl/intl.dart';

class UpdateInquery extends StatefulWidget {
  final Function(bool) onEnquiryTap;
  final Function(bool) onReviewTap;
  final VoidCallback onEdit;
  final String uuid;
  final String enquiryId;
  final String userId;
  final String lat;
  final String lng;
  final String menuItems;
  final int people;
  final String date;
  final String time;
  final String estimatedAmount;
  final String searchRadius;
  final String expirationDate;
  final String expirationTime;
  final String status;
  final String placeName;
  const UpdateInquery({
    super.key,
    required this.onEnquiryTap,
    required this.onReviewTap,
    required this.uuid,
    required this.enquiryId,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.menuItems,
    required this.people,
    required this.date,
    required this.time,
    required this.estimatedAmount,
    required this.searchRadius,
    required this.expirationDate,
    required this.expirationTime,
    required this.status, required this.placeName, required this.onEdit,
  });

  @override
  State<UpdateInquery> createState() => _UpdateInqueryState();
}

class _UpdateInqueryState extends State<UpdateInquery> {
  String? radius;
  String? longitude;
  String? latitude;
  String? date;
  String? time;
  String? place;

  final TextEditingController nofopeoplecontroller = TextEditingController();
  final TextEditingController descriptioncontoller = TextEditingController();
  final TextEditingController estimatedamountcontoller =
      TextEditingController();
  final TextEditingController datetimecontroller = TextEditingController();
  final TextEditingController validdatetimecontroller = TextEditingController();

  MapService mapService = MapService();
  InqueryService inqueryService = InqueryService();

  @override
  void initState() {
    super.initState();
    nofopeoplecontroller.text = widget.people.toString();
    descriptioncontoller.text = widget.menuItems;
    estimatedamountcontoller.text = double.parse(widget.estimatedAmount).toInt().toString();
    datetimecontroller.text = "${widget.date} &  ${widget.time}";
    validdatetimecontroller.text = "${widget.expirationDate} &  ${widget.expirationTime}";
    radius = double.parse(widget.searchRadius).toInt().toString();
    longitude = widget.lng;
    latitude = widget.lat;
    place = widget.placeName;
  }
  Future<void> updateInquery() async {
    debugPrint(await getToken());
    try {
      UpdateInqueryModel inquerydata = UpdateInqueryModel(
        enquiryId: widget.uuid,
        lat: latitude!,
        lng: longitude!,
        menuItems: descriptioncontoller.text,
        people: nofopeoplecontroller.text,
        time: datetimecontroller.text.split(" & ")[1].trim(),
        date: datetimecontroller.text.split(" & ")[0].trim(),
        estimatedAmount: estimatedamountcontoller.text,
        searchRadius: radius!,
        expirationDate: validdatetimecontroller.text.split(" & ")[0].trim(),
        expirationTime: validdatetimecontroller.text.split(" & ")[1].trim(),
      );

      print(inquerydata.toJson());

      UpdateInqueryModelResponse response = await inqueryService.updateInquery(
        inquerydata,
      );

      if (response.status) {
        SnackBar(
          content: Text(
            "Inquery updated successfully",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        );
        widget.onEdit();
        Navigator.pop(context);
        debugPrint("Inquery updated successfully");
      } else {
        SnackBar(
          content: Text(
            "Error in updating inquery",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        );
        debugPrint("Error successfully");
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 10.h),
          DescriptionTextArea(
            hintText:
                "Example: Chicken Biriyani , Porotta ,Rotti  , Payasam, Butter Chicken , Ice cream,.Salad",
            topHintText: "Your Menu",
            iconColor: appTextColor2,
            icon: Icons.dashboard,
            maxLength: 300,
            controller: descriptioncontoller,
          ),
          SizedBox(height: 10.h),
          AppTextFeild(
            text: "Number of  People",
            icon: Icons.people,
            iconColor: appTextColor2,
            controller: nofopeoplecontroller,
          ),
          SizedBox(height: 10.h),
          AppTextFeild(
            text: "Date & Time",
            icon: Icons.calendar_today_sharp,
            iconColor: appTextColor2,
            isreadonly: true,
            onboxTap: () => _selectDateTime(context, datetimecontroller),
            controller: datetimecontroller,
          ),
          SizedBox(height: 10.h),
          AppTextFeild(
            text: "Expected amount per person",
            icon: Icons.wallet,
            iconColor: appTextColor2,
            controller: estimatedamountcontoller,
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationSelect(
                  returndata: (lat, lng, distance) async {
                    setState(() {
                      latitude = lat;
                      longitude = lng;
                      radius = distance;
                    });
                    print('from main');
                    print(latitude);
                    print(longitude);
                    print(radius);

                    final placename = await mapService.getPlaceName(lat, lng);
                    setState(() {
                      place = placename!.split(',')[1];
                    });
                  },
                ),
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Color(0xFF798FFF),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.r,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: AppText(
                  text:
                      "${place ?? "Select Location"} - ${radius ?? "0"} km Radius",
                  size: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 30.h),
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
              GestureDetector(
                onTap: () => _selectDateTime(context, validdatetimecontroller),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: appSecondaryBackgroundColor,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: Colors.black54),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20.w,
                        color: Colors.black54,
                      ),
                      SizedBox(width: 8.w),
                      AppText(
                        text: validdatetimecontroller.text,
                        size: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: 150.w,
            height: 50.h,
            child: AppButton(
              text: "Update",
              onPressed: () {
                if (descriptioncontoller.text.isEmpty ||
                    nofopeoplecontroller.text.isEmpty ||
                    datetimecontroller.text.isEmpty ||
                    estimatedamountcontoller.text.isEmpty ||
                    place == null ||
                    radius == null ||
                    latitude == null ||
                    longitude == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Please fill all the fields before proceeding!",
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }else{
                  updateInquery();
                }
              },
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

  Future<void> _selectDateTime(
    BuildContext context,
    TextEditingController contoller,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        String formattedDate = DateFormat('yyyy-MM-dd').format(fullDateTime);
        String formattedTime = DateFormat('hh:mm a').format(fullDateTime);

        setState(() {
          date = formattedDate;
          time = formattedTime;
          contoller.text = '$formattedDate & $formattedTime';
        });
      }
    }
  }
}

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
