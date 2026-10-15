import 'package:flutter/material.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/auth/changepassword_model.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/auth/forgotpassword.dart';
import 'package:fudikoclient/service/auth/changepassword_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ChangePasswordService _service = ChangePasswordService();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
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

    setState(() => _isLoading = true);

    final response = await _service.changePassword(
      ChangePasswordModel(password: newPassword, oldPassword: oldPassword),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.status) {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }

    showStatusSnack(context, response.status, response.message);

    if (response.status) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = AppDimensions.pagePadding(context);
            final size = MediaQuery.sizeOf(context);
            final isTablet = Breakpoints.isTabletDevice(size);
            final isMobile = Breakpoints.isMobileDevice(size);
            final isCompactPhone =
                isMobile && (size.width < 390 || size.height < 720);
            final topPadding = isCompactPhone ? 6.0 : 10.0;

            final formWidth = isTablet ? 500.0 : double.infinity;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - padding.vertical,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: formWidth),
                        child: _UpdatePasswordForm(
                          oldPasswordController: _oldPasswordController,
                          newPasswordController: _newPasswordController,
                          confirmPasswordController: _confirmPasswordController,
                          obscureOldPassword: _obscureOldPassword,
                          obscureNewPassword: _obscureNewPassword,
                          obscureConfirmPassword: _obscureConfirmPassword,
                          isLoading: _isLoading,
                          textSize: isTablet ? 18 : 15,
                          gap: isTablet ? 22 : 18,
                          sectionGap: isTablet ? 48 : 36,
                          fieldHeight: isTablet ? 60 : 56,
                          onSubmit: _updatePassword,
                          onToggleOldPassword: () {
                            setState(() {
                              _obscureOldPassword = !_obscureOldPassword;
                            });
                          },
                          onToggleNewPassword: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                          onToggleConfirmPassword: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: topPadding,
                  left: padding.left,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(backOrange, width: 30, height: 30),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UpdatePasswordForm extends StatelessWidget {
  const _UpdatePasswordForm({
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureOldPassword,
    required this.obscureNewPassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.textSize,
    required this.gap,
    required this.sectionGap,
    required this.fieldHeight,
    required this.onSubmit,
    required this.onToggleOldPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
  });

  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureOldPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final double textSize;
  final double gap;
  final double sectionGap;
  final double fieldHeight;
  final VoidCallback onSubmit;
  final VoidCallback onToggleOldPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: AppText(
            text: 'Set your new password',
            size: textSize + 4,
            fontWeight: FontWeight.w600,
            color: appTextColor2,
          ),
        ),
        SizedBox(height: sectionGap * 0.67),
        _passwordField(
          controller: oldPasswordController,
          label: 'Old Password',
          obscure: obscureOldPassword,
          onToggle: onToggleOldPassword,
        ),
        SizedBox(height: gap),
        _passwordField(
          controller: newPasswordController,
          label: 'New Password',
          obscure: obscureNewPassword,
          onToggle: onToggleNewPassword,
        ),
        SizedBox(height: gap),
        _passwordField(
          controller: confirmPasswordController,
          label: 'Confirm Password',
          obscure: obscureConfirmPassword,
          onToggle: onToggleConfirmPassword,
        ),
        SizedBox(height: sectionGap * .8),
        AppButton(
          text: 'Update',
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
          buttonheight: fieldHeight + 4,
          size: textSize,
        ),
        SizedBox(height: gap),
        Center(
          child: InkWell(
            onTap: () => slideRightWidget(
              context: context,
              newPage: const ForgotPassword(),
            ),
            child: AppText(
              text: 'Forgot Password?',
              size: textSize - 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return AppTextFeild(
      controller: controller,
      text: label,
      iconImagePath: padlockOutlineIcon,
      isObscure: obscure,
      enableInteractiveSelection: false,
      suffixIcon: obscure
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined,
      onSuffixTap: onToggle,
      height: fieldHeight,
      size: textSize,
    );
  }
}
