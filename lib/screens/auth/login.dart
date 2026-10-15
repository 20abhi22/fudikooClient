import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/auth/login-model.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/auth/forgotpassword.dart';
import 'package:fudikoclient/screens/auth/info.dart';
import 'package:fudikoclient/screens/auth/otp.dart';
import 'package:fudikoclient/screens/auth/register.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/service/auth/login-service.dart';
import 'package:fudikoclient/service/notification/device_token_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/snackbar.dart';
import 'package:fudikoclient/utils/tokens.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final LoginAuthService loginService = LoginAuthService();
  bool isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    setState(() => isLoading = true);

    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showErrorSnack(context, 'Please fill out all fields');
      return;
    }

    if (password.length < 6) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showErrorSnack(context, 'Password must be at least 6 characters long');
      return;
    }

    final user = UserLoginModel(username: email, password: password);
    final LoginResponseModel response = await loginService.loginUser(user);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response.status) {
      final token = response.token;
      if (token == null || token.isEmpty) {
        showErrorSnack(context, 'We could not sign you in. Please try again.');
        return;
      }

      if (!response.otpVerified) {
        await removeToken();
        if (!mounted) return;
        slideRightWidget(
          newPage: Otp(authToken: token),
          context: context,
          // clearStack: true,
        );
        return;
      }

      if (!response.isRegistered) {
        await removeToken();
        if (!mounted) return;
        slideRightWidget(
          newPage: InfoPage(authToken: token),
          context: context,
          // clearStack: true,
        );
        return;
      }

      await saveToken(token);
      await clearCachedLocation();
      // Not awaited: push-permission/registration failures must never block
      // navigation into the app.
      unawaited(DeviceTokenService().registerDeviceToken());
      if (!mounted) return;

      slideRightWidget(
        newPage: const HomePage(),
        context: context,
        clearStack: true,
      );
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

                final form = _LoginForm(
                  email: _email,
                  password: _password,
                  isLoading: isLoading,
                  onLogin: loginUser,
                  isMobile: isMobile,
                  isWideShortPhone: isWideShortPhone,
                );

                if (isWideShortPhone) {
                  return _CompactLandscapeLoginLayout(form: form);
                }

                if (orientation == Orientation.landscape &&
                    (isTabletDevice || isDesktopLayout)) {
                  return _TabletLandscapeLoginLayout(form: form);
                }

                return _StackedLoginLayout(
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

class _StackedLoginLayout extends StatelessWidget {
  const _StackedLoginLayout({
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
    final size = MediaQuery.sizeOf(context);
    final safeHeight = size.height - MediaQuery.paddingOf(context).vertical;
    final isCompactPhone = isMobile && (size.width < 390 || size.height < 700);
    final logoWidth = isWideShortPhone
        ? 0.50
        : isMobile
        ? 0.68
        : 0.34;
    final formWidth = isWideShortPhone
        ? 0.58
        : isMobile
        ? 0.84
        : 0.52;
    final logoFormGap = isWideShortPhone
        ? 14.0
        : isMobile
        ? 18.0
        : AppDimensions.margin(context);
    final logoYOffset = isWideShortPhone
        ? -12.0
        : isCompactPhone
        ? -22.0
        : isMobile
        ? -34.0
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

class _CompactLandscapeLoginLayout extends StatelessWidget {
  const _CompactLandscapeLoginLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);
    final size = MediaQuery.sizeOf(context);
    final safeHeight = size.height - MediaQuery.paddingOf(context).vertical;
    final compactPadding = padding.copyWith(
      top: padding.top * 0.65,
      bottom: padding.bottom * 0.65,
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
              flex: 5,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.74,
                  child: _LogoBlock(useMobileTreatment: false),
                ),
              ),
            ),
            SizedBox(width: AppDimensions.gap(context)),
            Expanded(
              flex: 6,
              child: Center(
                child: FractionallySizedBox(widthFactor: 0.88, child: form),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletLandscapeLoginLayout extends StatelessWidget {
  const _TabletLandscapeLoginLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);
    final size = MediaQuery.sizeOf(context);
    final safeHeight = size.height - MediaQuery.paddingOf(context).vertical;

    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (safeHeight - padding.vertical)
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
                child: FractionallySizedBox(widthFactor: 0.78, child: form),
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

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.email,
    required this.password,
    required this.isLoading,
    required this.onLogin,
    required this.isMobile,
    required this.isWideShortPhone,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool isLoading;
  final VoidCallback onLogin;
  final bool isMobile;
  final bool isWideShortPhone;

  @override
  Widget build(BuildContext context) {
    final gap = isWideShortPhone
        ? 10.0
        : isMobile
        ? 20.0
        : AppDimensions.gap(context) * 1.25;
    final sectionGap = isWideShortPhone
        ? 16.0
        : isMobile
        ? 40.0
        : AppDimensions.margin(context) * 0.9;
    final fieldHeight = isWideShortPhone
        ? 48.0
        : isMobile
        ? 55.0
        : 60.0;
    final textSize = isWideShortPhone
        ? 13.0
        : isMobile
        ? 15.0
        : AppDimensions.body(context);
    final buttonHeight = isWideShortPhone
        ? 50.0
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
          controller: email,
          isTextCenter: true,
          height: fieldHeight,
          size: textSize,
        ),
        SizedBox(height: gap),
        AppTextFeild(
          text: "Password",
          iconImagePath: padlockOutlineIcon,
          isObscure: true,
          controller: password,
          isTextCenter: true,
          height: fieldHeight,
          size: textSize,
        ),
        SizedBox(height: gap),
        AppButton(
          text: 'Login',
          isLoading: isLoading,
          onPressed: isLoading ? null : onLogin,
          buttonheight: buttonHeight,
          size: textSize,
        ),
        SizedBox(height: gap),
        Center(
          child: GestureDetector(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const Otp()),
              // );
              slideRightWidget(
                newPage: const ForgotPassword(),
                context: context,
              );
            },
            child: AppText(
              text: "Forget Password?",
              size: textSize,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(height: sectionGap),
        // Row(
        //   children: [
        //     Expanded(child: Divider(thickness: 1, color: appTextColor)),
        //     Padding(
        //       padding: EdgeInsets.symmetric(horizontal: gap * 0.7),
        //       child: AppText(
        //         text: "or login with",
        //         size: textSize,
        //         fontWeight: FontWeight.w400,
        //       ),
        //     ),
        //     Expanded(child: Divider(thickness: 1, color: appTextColor)),
        //   ],
        // ),
        SizedBox(height: gap),
        // Center(
        //   child: SizedBox(
        //     width: googleIconSize,
        //     height: googleIconSize,
        //     child: Image.asset('assets/images/googleiconfudiko.png'),
        //   ),
        // ),
        SizedBox(height: sectionGap),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppText(
              text: "Don't have an Account?  ",
              size: textSize,
              fontWeight: FontWeight.normal,
              color: appTextColor2,
            ),
            GestureDetector(
              onTap: () {
                slideRightWidget(newPage: const Register(), context: context);
              },
              child: AppText(
                text: "Sign Up",
                size: textSize,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
