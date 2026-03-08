import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/model/auth/changepassword_model.dart';
import 'package:fudikoclient/service/auth/changepassword_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class ChangePassword extends StatefulWidget {
   ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
  }

class _ChangePasswordState extends State<ChangePassword> {
  bool isLoading=false;
  final TextEditingController currentPasswordController=TextEditingController();
  
  final TextEditingController newPasswordController=TextEditingController();
  final TextEditingController confirmPasswordController=TextEditingController();
Future<void> changePassword() async {

  final currentPassword = currentPasswordController.text.trim();
  final newPassword = newPasswordController.text.trim();
  final confirmPassword = confirmPasswordController.text.trim();

  if (currentPassword.isEmpty ||
      newPassword.isEmpty ||
      confirmPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all fields")),
    );
    return;
  }

  if (newPassword.length < 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password must be at least 6 characters")),
    );
    return;
  }

  if (newPassword != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwords do not match")),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  final service = ChangePasswordService();

  final response = await service.changePassword(
    ChangePasswordModel(password: newPassword),
  );

  setState(() {
    isLoading = false;
  });
if (response.status) {

    // ✅ CLEAR TEXTFIELDS HERE
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message),
        backgroundColor: Colors.green,
      ),
    );

  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
// Future<void> changePassword() async {
//   final newPassword = newPasswordController.text;
// final service = ChangePasswordService();
//   final response = await service.changePassword(
//     ChangePasswordModel(password: newPassword),
//   );

//   if (response.status) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(response.message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(response.message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 30.w, right: 30.w),
        child: Stack(
          children: [
            Positioned(
              top: 40.h,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_outlined,
                      size: 30.r,
                      color: appTextColor3,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                AppText(
                  text: "Set your new password",
                  size: 15,
                  fontWeight: FontWeight.w400,
                  color: appTextColor2,
                ),

                SizedBox(height: 40.h),
                AppTextFeild(controller:currentPasswordController,text: "Current Password", icon: Icons.lock),
                SizedBox(height: 20.h),
                AppTextFeild(controller:newPasswordController,text: "New Password", icon: Icons.lock),
                SizedBox(height: 20.h),
                AppTextFeild(controller:confirmPasswordController,text: "Confirm Password", icon: Icons.lock),
                SizedBox(height: 60.h),
                AppButton(
  text: isLoading ? 'Updating...' : 'Update',
  onPressed: isLoading ? null : () {
    changePassword();
  },
),
SizedBox(height: 20.h),
                AppText(
                  text: "Forgot Password?",
                  size: 14,
                  fontWeight: FontWeight.w400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
