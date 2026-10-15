import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/forgotpassword/finduser-model.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/auth/otp.dart';
import 'package:fudikoclient/service/auth/forgotpassword-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  bool isLoading = false;
  final ForgotPasswordService forgotPasswordService = ForgotPasswordService();

  double _contentMaxWidth(Size size) {
    final width = size.width;
    if (Breakpoints.isDesktop(width)) return 460;
    if (Breakpoints.isTabletDevice(size)) return 440;
    return double.infinity;
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> forgotPasswordFindUser() async {
    final username = _username.text.trim();
    final email = _email.text.trim();

    if (username.isEmpty || email.isEmpty) {
      if (!mounted) return;
      showErrorSnack(context, "Enter username and email");
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final FindUserModel user = FindUserModel(username, email);
    final FindUserResponseModel response = await forgotPasswordService.findUser(
      user,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (response.status &&
        response.token != null &&
        response.token!.isNotEmpty) {
      showSuccessSnack(context, "User found!");
      slideRightWidget(
        newPage: Otp(token: response.token),
        context: context,
      );
    } else {
      showErrorSnack(context, response.message ?? "No user found");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isMobileDevice = Breakpoints.isMobileDevice(size);
    final isMobile = isMobileDevice && Breakpoints.isMobile(width);
    final isWideShortPhone =
        isMobileDevice && width >= 500 && size.height <= 760;
    final horizontalPadding = isWideShortPhone
        ? 28.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(context);
    final topBottomPadding = isWideShortPhone
        ? 18.0
        : isMobile
        ? 24.h
        : AppDimensions.margin(context);
    final contentMaxWidth = isWideShortPhone ? 380.0 : _contentMaxWidth(size);
    final lineGap = isWideShortPhone
        ? 4.0
        : isMobile
        ? 8.h
        : 8.0;
    final titleGap = isWideShortPhone
        ? 22.0
        : isMobile
        ? 40.h
        : 40.0;
    final fieldGap = isWideShortPhone
        ? 10.0
        : isMobile
        ? 20.h
        : 20.0;
    final buttonGap = isWideShortPhone
        ? 24.0
        : isMobile
        ? 60.h
        : 52.0;
    final fieldHeight = isWideShortPhone ? 46.0 : null;
    final buttonHeight = isWideShortPhone ? 46.0 : null;
    final bodyTextSize = isWideShortPhone ? 13.0 : 15.0;
    final fieldTextSize = isWideShortPhone
        ? 13.0
        : isMobile
        ? 16.0
        : 14.0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentPadding = EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: topBottomPadding,
            );
            final minContentHeight =
                (constraints.maxHeight - contentPadding.vertical)
                    .clamp(0.0, double.infinity)
                    .toDouble();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: contentPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minContentHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          text: "Enter your username and",
                          size: bodyTextSize,
                          fontWeight: FontWeight.w400,
                          color: appTextColor2,
                          isCentered: true,
                        ),
                        SizedBox(height: lineGap),
                        AppText(
                          text: "registered email ID",
                          size: bodyTextSize,
                          fontWeight: FontWeight.w400,
                          color: appTextColor2,
                          isCentered: true,
                        ),
                        SizedBox(height: titleGap),
                        AppTextFeild(
                          text: "Username",
                          icon: Icons.person,
                          controller: _username,
                          size: fieldTextSize,
                          height: fieldHeight,
                        ),
                        SizedBox(height: fieldGap),
                        AppTextFeild(
                          text: "Email",
                          icon: Icons.mail,
                          controller: _email,
                          size: fieldTextSize,
                          height: fieldHeight,
                        ),
                        SizedBox(height: buttonGap),
                        AppButton(
                          text: isLoading ? 'Please wait...' : 'Continue',
                          onPressed: () {
                            if (!isLoading) {
                              forgotPasswordFindUser();
                            }
                          },
                          buttonheight: buttonHeight,
                          size: fieldTextSize,
                        ),
                        SizedBox(height: fieldGap),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
