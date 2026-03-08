import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/model/inquery/list-catering-inquery-model.dart';
import 'package:fudikoclient/model/inquery/update-catering-inquery-model.dart';
import 'package:fudikoclient/screens/tabs/inquery/common/locationselect.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/service/inquery/inquery-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:intl/intl.dart';

class UpdateCtInquery extends StatefulWidget {
  final CateringInqueryModel enquiry;
  final String placeName;
  final VoidCallback onEdit;

  const UpdateCtInquery({
    super.key,
    required this.enquiry,
    required this.placeName,
    required this.onEdit,
  });

  @override
  State<UpdateCtInquery> createState() => _UpdateCtInqueryState();
}

class _UpdateCtInqueryState extends State<UpdateCtInquery> {
  String? radius;
  String? longitude;
  String? latitude;
  String? place;

  final TextEditingController menuController = TextEditingController();
  final TextEditingController peopleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController datetimeController = TextEditingController();
  final TextEditingController validDatetimeController = TextEditingController();

  final MapService mapService = MapService();
  final InqueryService inqueryService = InqueryService();

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing enquiry — same pattern as UpdateInquery
    menuController.text = widget.enquiry.menuItems;
    peopleController.text = widget.enquiry.people.toString();
    amountController.text =
        double.tryParse(widget.enquiry.estimatedAmount)?.toInt().toString() ??
            widget.enquiry.estimatedAmount;
    datetimeController.text = "${widget.enquiry.date} &  ${widget.enquiry.time}";
    validDatetimeController.text =
        "${widget.enquiry.expirationDate} &  ${widget.enquiry.expirationTime}";
    radius = double.tryParse(widget.enquiry.searchRadius)?.toInt().toString() ??
        widget.enquiry.searchRadius;
    latitude = widget.enquiry.lat;
    longitude = widget.enquiry.lng;
    place = widget.placeName;
  }

  @override
  void dispose() {
    menuController.dispose();
    peopleController.dispose();
    amountController.dispose();
    datetimeController.dispose();
    validDatetimeController.dispose();
    super.dispose();
  }

  Future<void> updateCateringInquery() async {
    try {
      final model = UpdateCateringInqueryModel(
        enquiryId: widget.enquiry.uuid,
        lat: latitude!,
        lng: longitude!,
        menuItems: menuController.text,
        people: peopleController.text,
        date: datetimeController.text.split(" & ")[0].trim(),
        time: datetimeController.text.split(" & ")[1].trim(),
        estimatedAmount: amountController.text,
        searchRadius: radius!,
        expirationDate: validDatetimeController.text.split(" & ")[0].trim(),
        expirationTime: validDatetimeController.text.split(" & ")[1].trim(),
      );

      print(model.toFormData());

      final response = await inqueryService.updateCateringInquery(model);

      if (!mounted) return;

      if (response.status) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Catering enquiry updated successfully",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onEdit();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Error updating enquiry",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _selectDateTime(
    BuildContext context,
    TextEditingController controller,
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
        final fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        final formattedDate = DateFormat('yyyy-MM-dd').format(fullDateTime);
        final formattedTime = DateFormat('hh:mm a').format(fullDateTime);

        setState(() {
          controller.text = '$formattedDate & $formattedTime';
        });
      }
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
                "Example: Chicken Biriyani , Porotta ,Rotti , Payasam, Butter Chicken , Ice cream, Salad",
            topHintText: "Your Menu",
            iconColor: appTextColor2,
            icon: Icons.dashboard,
            maxLength: 300,
            controller: menuController,
          ),
          SizedBox(height: 10.h),
          AppTextFeild(
            text: "Number of People",
            icon: Icons.people,
            iconColor: appTextColor2,
            controller: peopleController,
          ),
          SizedBox(height: 10.h),
          AppTextFeild(
            text: "Date & Time",
            icon: Icons.calendar_today_sharp,
            iconColor: appTextColor2,
            isreadonly: true,
            onboxTap: () => _selectDateTime(context, datetimeController),
            controller: datetimeController,
          ),
          SizedBox(height: 10.h),
          AppTextFeild(
            text: "Expected amount per person",
            icon: Icons.wallet,
            iconColor: appTextColor2,
            controller: amountController,
          ),
          SizedBox(height: 10.h),
          // Location selector — same as UpdateInquery
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
                    final placename = await mapService.getPlaceName(lat, lng);
                    setState(() {
                      if (placename != null && placename.isNotEmpty) {
                        final parts = placename.split(',');
                        place = parts.length > 1
                            ? parts[1].trim()
                            : parts[0].trim();
                      }
                    });
                  },
                ),
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF798FFF),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.r,
                    offset: const Offset(0, 4),
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
          // Expiration date — same "Enquiry valid for" pattern
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
                onTap: () =>
                    _selectDateTime(context, validDatetimeController),
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
                        text: validDatetimeController.text,
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
                if (menuController.text.isEmpty ||
                    peopleController.text.isEmpty ||
                    datetimeController.text.isEmpty ||
                    amountController.text.isEmpty ||
                    place == null ||
                    radius == null ||
                    latitude == null ||
                    longitude == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please fill all the fields before proceeding!",
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                } else {
                  updateCateringInquery();
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
}