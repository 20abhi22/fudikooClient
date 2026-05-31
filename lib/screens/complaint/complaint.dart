import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/descriptionBox.dart';
import 'package:fudikoclient/service/complaint/complaint_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _complaintController = TextEditingController();
  final ComplaintService _complaintService = ComplaintService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    final String complaint = _complaintController.text.trim();
    if (complaint.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final bool success = await _complaintService.registerComplaint(complaint);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Complaint submitted successfully.'
              : 'Unable to submit complaint. Please try again.',
        ),
      ),
    );

    if (success) {
      _complaintController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding:  EdgeInsets.only(left: 30.w,right: 30.w,top: 20.h),
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(backOrange, width: 30.w, height: 30.w),
                  ),
                ),
                SizedBox(height: 30.h),
                AppText(
                  text:
                      "If you encounter any issues or have a complaint, please register it below. Provide as much detail as possible so we can assist you promptly and effectively. Your feedback helps us improve your experience with Fudikoo.",
                  size: 15,
                  fontWeight: FontWeight.w400,
                  color: appTextColor2,
                  lineSpacing: 1.5,
                  softWrap: true,
                  maxLines: 8,
                ),
                SizedBox(height: 50.h),
                DescriptionTextArea(
                  hintText: "Write your complaint briefly",
                  maxLength: 300,
                  maxLines: 15,
                  controller: _complaintController,
                ),
                SizedBox(height: 30.h),
                Padding(
                      padding: EdgeInsets.symmetric(horizontal: 80.w,),
                  child: SizedBox(
                    height: 40.h,
                    child: AppButton(
                      text: "Submit",
                      onPressed: _submitComplaint,
                      size: 15,
                      borderRadius: 10.r,
                      isLoading: _isSubmitting,
                    ),
                  )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
