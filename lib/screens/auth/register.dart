import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/auth/registration-model.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/auth/login.dart';
import 'package:fudikoclient/screens/auth/otp.dart';
import 'package:fudikoclient/service/auth/registration-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final RegistrationAuthService registrationAuthService =
      RegistrationAuthService();
  bool isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> register() async {
    setState(() => isLoading = true);

    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text.trim();
    final confirmPassword = _confirmPassword.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showErrorSnack(context, 'Please fill out all fields');
      return;
    }

    if (name.contains(' ')) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showErrorSnack(context, 'Username must not contain spaces');
      return;
    }

    if (!EmailValidator.validate(email)) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showErrorSnack(context, 'Please enter a valid email');
      return;
    }

    if (password.length < 8) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showErrorSnack(context, 'Password must be at least 8 characters long');
      return;
    }

    if (password != confirmPassword) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showErrorSnack(context, 'Passwords do not match');
      return;
    }

    final user = RegistrationModel(
      username: name,
      email: email,
      password: password,
    );

    final RegistrationResponseModel response = await registrationAuthService
        .registerUser(user);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response.status) {
      final token = response.token;
      if (token == null || token.isEmpty) {
        showErrorSnack(context, 'Registration failed: missing access token');
        return;
      }

      await removeToken();
      if (!mounted) return;
      showSuccessSnack(context, response.message);
      slideRightWidget(
        newPage: Otp(authToken: token),
        context: context,
      );
      return;
    }

    final errors = response.fieldErrors;
    if (errors != null) {
      if (errors.containsKey('email')) {
        showErrorSnack(context, errors['email']!);
      }

      if (errors.containsKey('username')) {
        showErrorSnack(context, errors['username']!);
      }
      return;
    }

    showErrorSnack(context, response.message);
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
                final isTabletDevice = Breakpoints.isTabletDevice(size);
                final isDesktopLayout = Breakpoints.isDesktop(width);
                final isMobile = isMobileDevice && Breakpoints.isMobile(width);
                final isWideShortPhone =
                    isMobileDevice &&
                    orientation == Orientation.landscape &&
                    width >= 500 &&
                    height <= 760;

                final form = _RegisterForm(
                  name: _name,
                  email: _email,
                  password: _password,
                  confirmPassword: _confirmPassword,
                  obscurePassword: _obscurePassword,
                  obscureConfirmPassword: _obscureConfirmPassword,
                  isLoading: isLoading,
                  isMobile: isMobile,
                  isWideShortPhone: isWideShortPhone,
                  onRegister: register,
                  onTogglePassword: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  onToggleConfirmPassword: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                );

                if (isWideShortPhone) {
                  return _CompactLandscapeRegisterLayout(form: form);
                }

                if (orientation == Orientation.landscape &&
                    (isTabletDevice || isDesktopLayout)) {
                  return _TabletLandscapeRegisterLayout(form: form);
                }

                return _StackedRegisterLayout(
                  form: form,
                  isMobile: isMobile,
                  isWideShortPhone: isWideShortPhone,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StackedRegisterLayout extends StatelessWidget {
  const _StackedRegisterLayout({
    required this.form,
    required this.isMobile,
    required this.isWideShortPhone,
  });

  final Widget form;
  final bool isMobile;
  final bool isWideShortPhone;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);
    final safeHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;
    final size = MediaQuery.sizeOf(context);
    final isCompactPhone = isMobile && (size.width < 390 || size.height < 700);
    final logoWidth = isWideShortPhone
        ? 0.44
        : isMobile
        ? 0.68
        : 0.34;
    final formWidth = isWideShortPhone
        ? 0.58
        : isMobile
        ? 0.84
        : 0.52;
    final logoFormGap = isWideShortPhone
        ? 10.0
        : isMobile
        ? 18.0
        : AppDimensions.margin(context);
    final logoYOffset = isWideShortPhone
        ? -10.0
        : isCompactPhone
        ? -18.0
        : isMobile
        ? -30.0
        : 0.0;

    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (safeHeight - padding.vertical)
              .clamp(0.0, double.infinity)
              .toDouble(),
          minWidth: double.infinity,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, logoYOffset),
                child: FractionallySizedBox(
                  widthFactor: logoWidth,
                  child: const _LogoBlock(useMobileTreatment: false),
                ),
              ),
            ),
            SizedBox(height: logoFormGap),
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(widthFactor: formWidth, child: form),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLandscapeRegisterLayout extends StatelessWidget {
  const _CompactLandscapeRegisterLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);
    final size = MediaQuery.sizeOf(context);
    final safeHeight = size.height - MediaQuery.paddingOf(context).vertical;
    final compactPadding = padding.copyWith(
      top: padding.top * 0.55,
      bottom: padding.bottom * 0.55,
    );

    return SingleChildScrollView(
      padding: compactPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (safeHeight - compactPadding.vertical)
              .clamp(0.0, double.infinity)
              .toDouble(),
          minWidth: double.infinity,
        ),
        child: Row(
          children: [
            const Expanded(
              flex: 4,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.70,
                  child: _LogoBlock(useMobileTreatment: false),
                ),
              ),
            ),
            SizedBox(width: AppDimensions.gap(context)),
            Expanded(
              flex: 7,
              child: Center(
                child: FractionallySizedBox(widthFactor: 0.92, child: form),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletLandscapeRegisterLayout extends StatelessWidget {
  const _TabletLandscapeRegisterLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);

    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              (MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      padding.vertical)
                  .clamp(0.0, double.infinity)
                  .toDouble(),
          minWidth: double.infinity,
        ),
        child: Row(
          children: [
            const Expanded(
              flex: 5,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.62,
                  child: _LogoBlock(useMobileTreatment: false),
                ),
              ),
            ),
            SizedBox(width: AppDimensions.margin(context)),
            Expanded(
              flex: 5,
              child: Center(
                child: FractionallySizedBox(widthFactor: 0.8, child: form),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoBlock extends StatelessWidget {
  const _LogoBlock({required this.useMobileTreatment});

  final bool useMobileTreatment;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: useMobileTreatment
          ? Offset(-MediaQuery.sizeOf(context).width * 0.05, 0)
          : Offset.zero,
      child: Transform.scale(
        scale: useMobileTreatment ? 1.2 : 1,
        child: Image.asset(
          'assets/images/fudikoLogo2.png',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.isMobile,
    required this.isWideShortPhone,
    required this.onRegister,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final bool isMobile;
  final bool isWideShortPhone;
  final VoidCallback onRegister;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  @override
  Widget build(BuildContext context) {
    final gap = isWideShortPhone
        ? 8.0
        : isMobile
        ? 20.0
        : AppDimensions.gap(context) * 1.25;
    final sectionGap = isWideShortPhone
        ? 12.0
        : isMobile
        ? 40.0
        : AppDimensions.margin(context) * 0.9;
    final fieldHeight = isWideShortPhone
        ? 44.0
        : isMobile
        ? 55.0
        : 60.0;
    final textSize = isWideShortPhone
        ? 12.5
        : isMobile
        ? 15.0
        : AppDimensions.body(context);
    final buttonHeight = isWideShortPhone
        ? 48.0
        : isMobile
        ? 60.0
        : 62.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextFeild(
          text: "Username",
          iconImagePath: userIcon,
          controller: name,
          height: fieldHeight,
          size: textSize,
        ),
        SizedBox(height: gap),
        AppTextFeild(
          text: "Email",
          iconImagePath: emailIcon,
          controller: email,
          height: fieldHeight,
          size: textSize,
        ),
        SizedBox(height: gap),
        AppTextFeild(
          text: "Password",
          iconImagePath: padlockOutlineIcon,
          controller: password,
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
          text: "Confirm Password",
          iconImagePath: padlockOutlineIcon,
          controller: confirmPassword,
          isObscure: obscureConfirmPassword,
          enableInteractiveSelection: false,
          suffixIcon: obscureConfirmPassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onSuffixTap: onToggleConfirmPassword,
          height: fieldHeight,
          size: textSize,
        ),
        SizedBox(height: gap),
        AppButton(
          text: 'Register',
          isLoading: isLoading,
          onPressed: isLoading ? null : onRegister,
          buttonheight: buttonHeight,
          size: textSize,
        ),
        SizedBox(height: sectionGap),
        // Row(
        //   children: [
        //     Expanded(child: Divider(color: appTextColor, thickness: 1)),
        //     Padding(
        //       padding: EdgeInsets.symmetric(horizontal: gap * 0.7),
        //       child: AppText(
        //         text: "or login with",
        //         size: textSize,
        //         fontWeight: FontWeight.w400,
        //       ),
        //     ),
        //     Expanded(child: Divider(color: appTextColor, thickness: 1)),
        //   ],
        // ),
        SizedBox(height: gap),
        // Center(
        //   child: SizedBox(
        //     width: googleIconSize,
        //     height: googleIconSize,
        //     child: Image.asset(
        //       'assets/images/googleiconfudiko.png',
        //       fit: BoxFit.contain,
        //     ),
        //   ),
        // ),
        SizedBox(height: sectionGap),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppText(
              text: "Already have an Account?  ",
              size: textSize,
              fontWeight: FontWeight.normal,
              color: appTextColor2,
            ),
            GestureDetector(
              onTap: () {
                pushWidgetWhileRemove(newPage: const Login(), context: context);
              },
              child: AppText(
                text: "Sign In",
                size: textSize,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        SizedBox(
          height: isWideShortPhone
              ? 8
              : isMobile
              ? 20
              : AppDimensions.gap(context),
        ),
      ],
    );
  }
}
