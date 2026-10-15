import 'package:flutter/material.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/auth/changepassword_model.dart';
import 'package:fudikoclient/model/forgotpassword/changepassword-model.dart'
    as forgot_password;
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/auth/login.dart';
import 'package:fudikoclient/screens/auth/otp.dart';
import 'package:fudikoclient/service/auth/changepassword_service.dart';
import 'package:fudikoclient/service/auth/forgotpassword-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class ChangePassword extends StatefulWidget {
  final String? token;

  const ChangePassword({super.key, this.token});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final ChangePasswordService _service = ChangePasswordService();
  final ForgotPasswordService _forgotPasswordService = ForgotPasswordService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    final isResetFlow = widget.token != null && widget.token!.isNotEmpty;
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showErrorSnack(context, "Please fill all fields");
      return;
    }

    if (newPassword.length < 6) {
      showErrorSnack(context, "Password must be at least 6 characters");
      return;
    }

    if (newPassword != confirmPassword) {
      showErrorSnack(context, "Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    if (isResetFlow) {
      final response = await _forgotPasswordService.changePassword(
        forgot_password.NewPasswordModel(newPassword: newPassword),
        widget.token,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      showErrorSnack(context, response.message);

      if (response.status) {
        newPasswordController.clear();
        confirmPasswordController.clear();
        pushWidgetWhileRemove(newPage: const Login(), context: context);
      }
      return;
    }

    final response = await _service.changePassword(
      ChangePasswordModel(password: newPassword),
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response.status) {
      newPasswordController.clear();
      confirmPasswordController.clear();
      pushWidgetWhileRemove(newPage: const Login(), context: context);
    }

    showStatusSnack(context, response.status, response.message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final size = MediaQuery.sizeOf(context);
                final height = size.height;
                final isMobileDevice = Breakpoints.isMobileDevice(size);
                final isTablet = Breakpoints.isTabletDevice(size);
                final isWideShortPhone =
                    isMobileDevice &&
                    orientation == Orientation.landscape &&
                    width >= 500 &&
                    height <= 760;
                final isCompactPhone =
                    isMobileDevice && (width < 390 || height < 720);
                final horizontalPadding = isTablet
                    ? width * 0.08
                    : isCompactPhone
                    ? width * 0.06
                    : width * 0.075;
                final formWidthFactor = isTablet
                    ? orientation == Orientation.landscape
                          ? 0.46
                          : 0.58
                    : 1.0;
                final formMaxWidth = isWideShortPhone ? 380.0 : double.infinity;
                final fieldHeight = isTablet
                    ? 60.0
                    : isWideShortPhone
                    ? 48.0
                    : isCompactPhone
                    ? 54.0
                    : 56.0;
                final textSize = isTablet
                    ? AppDimensions.body(context)
                    : isWideShortPhone
                    ? 13.0
                    : isCompactPhone
                    ? 14.0
                    : 15.0;
                final gap = isTablet
                    ? AppDimensions.gap(context) * 1.25
                    : isWideShortPhone
                    ? 10.0
                    : isCompactPhone
                    ? 18.0
                    : 20.0;
                final sectionGap = isTablet
                    ? AppDimensions.margin(context) * 0.95
                    : isWideShortPhone
                    ? 22.0
                    : isCompactPhone
                    ? 42.0
                    : 60.0;
                final backTop = isTablet
                    ? 36.0
                    : isWideShortPhone
                    ? 16.0
                    : isCompactPhone
                    ? 22.0
                    : 40.0;
                final backSize = isTablet
                    ? 34.0
                    : isWideShortPhone
                    ? 24.0
                    : isCompactPhone
                    ? 26.0
                    : 30.0;
                final scrollPadding = EdgeInsets.only(
                  top: backTop + backSize + gap,
                  bottom: AppDimensions.margin(context),
                );
                final minContentHeight =
                    (constraints.maxHeight - scrollPadding.vertical)
                        .clamp(0.0, double.infinity)
                        .toDouble();

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          padding: scrollPadding,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minContentHeight,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: formMaxWidth,
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: formWidthFactor,
                                  child: _ChangePasswordForm(
                                    newPasswordController:
                                        newPasswordController,
                                    confirmPasswordController:
                                        confirmPasswordController,
                                    obscurePassword: _obscurePassword,
                                    obscureConfirmPassword:
                                        _obscureConfirmPassword,
                                    isLoading: isLoading,
                                    textSize: textSize,
                                    gap: gap,
                                    sectionGap: sectionGap,
                                    fieldHeight: fieldHeight,
                                    onSubmit: changePassword,
                                    onForgotPassword: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const Otp(),
                                        ),
                                      );
                                    },
                                    onTogglePassword: () {
                                      setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      );
                                    },
                                    onToggleConfirmPassword: () {
                                      setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: backTop,
                        left: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Image.asset(
                            backOrange,
                            height: backSize,
                            width: backSize,
                          ),
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
    );
  }
}

class _ChangePasswordForm extends StatelessWidget {
  const _ChangePasswordForm({
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.textSize,
    required this.gap,
    required this.sectionGap,
    required this.fieldHeight,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final double textSize;
  final double gap;
  final double sectionGap;
  final double fieldHeight;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AppText(
            text: "Set your new password",
            size: textSize,
            fontWeight: FontWeight.w400,
            color: appTextColor2,
          ),
        ),
        SizedBox(height: sectionGap * 0.67),
        AppTextFeild(
          controller: newPasswordController,
          text: "New Password",
          iconImagePath: padlockOutlineIcon,
          isObscure: obscurePassword,
          enableInteractiveSelection: false,
          suffixIcon: obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onSuffixTap: onTogglePassword,
          height: fieldHeight,
          size: textSize,
        ),
        SizedBox(height: gap),
        AppTextFeild(
          controller: confirmPasswordController,
          text: "Confirm Password",
          iconImagePath: padlockOutlineIcon,
          isObscure: obscureConfirmPassword,
          enableInteractiveSelection: false,
          suffixIcon: obscureConfirmPassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onSuffixTap: onToggleConfirmPassword,
          height: fieldHeight,
          size: textSize,
        ),
        SizedBox(height: sectionGap),
        AppButton(
          text: 'Update',
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
          buttonheight: fieldHeight + 4,
          size: textSize,
        ),
        SizedBox(height: gap),
        // Center(
        //   child: InkWell(
        //     onTap: onForgotPassword,
        //     child: AppText(
        //       text: "Forgot Password?",
        //       size: textSize - 1,
        //       fontWeight: FontWeight.w400,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
