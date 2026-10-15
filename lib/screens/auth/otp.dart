import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/auth/changepassword.dart';
import 'package:fudikoclient/screens/auth/info.dart';
import 'package:fudikoclient/service/auth/otp_auth-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class Otp extends StatefulWidget {
  // null = registration flow, provided = forgot password flow.
  final String? token;
  final String? authToken;
  const Otp({super.key, this.token, this.authToken});

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<FocusNode> _keyboardFocusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );
  final OtpAuthService _otpservice = OtpAuthService();

  String? _otpId;
  bool _isSending = true; // true while send-otp call is in flight
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    final result = await _otpservice.sendOtp(tokenOverride: _requestToken);
    if (!mounted) return;
    setState(() => _isSending = false);
    if (result.status) {
      _otpId = result.otpId;
    } else {
      showErrorSnack(context, result.message);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 4) {
      showErrorSnack(context, 'Please enter complete OTP');
      return;
    }
    if (_otpId == null) {
      showErrorSnack(context, 'OTP not ready, please wait');
      return;
    }
    setState(() => _isVerifying = true);
    final result = await _otpservice.verifyOtp(
      _otp,
      _otpId!,
      tokenOverride: _requestToken,
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);
    if (result.status) {
      showSuccessSnack(context, result.message);
      if (widget.token != null) {
        // Forgot password flow goes to ChangePassword.
        replaceWidget(
          newPage: ChangePassword(token: widget.token),
          context: context,
        );
      } else {
        // registration flow → go to InfoPage
        replaceWidget(
          newPage: InfoPage(authToken: widget.authToken),
          context: context,
          // clearStack: widget.authToken != null,
        );
      }
    } else {
      showErrorSnack(context, result.message);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (final focusNode in _keyboardFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((controller) => controller.text).join();

  String? get _requestToken => widget.token ?? widget.authToken;

  void _onChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  void _onKeyPressed(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final size = MediaQuery.sizeOf(context);
            final height = size.height;
            final isMobileDevice = Breakpoints.isMobileDevice(size);
            final isTablet = Breakpoints.isTabletDevice(size);
            final isDesktop = Breakpoints.isDesktop(width);
            final isWideShortPhone =
                isMobileDevice && width >= 500 && height <= 760;
            final isCompactPhone =
                isMobileDevice && (width < 390 || height < 700);
            final padding = AppDimensions.pagePadding(context);
            final contentWidth = isDesktop
                ? 430.0
                : isWideShortPhone
                ? 300.0
                : 340.0;
            final imageWidth = isWideShortPhone
                ? 108.0
                : isCompactPhone
                ? 140.0
                : 180.0;
            final sectionGap = isWideShortPhone
                ? 18.0
                : isCompactPhone
                ? 28.0
                : 40.0;
            final otpBoxWidth = isWideShortPhone
                ? 56.0
                : isCompactPhone
                ? 62.0
                : 68.0;
            final otpBoxHeight = isWideShortPhone
                ? 50.0
                : isCompactPhone
                ? 56.0
                : 61.0;
            final buttonWidth = isWideShortPhone
                ? 280.0
                : isCompactPhone
                ? 300.0
                : 330.81;
            final buttonHeight = isWideShortPhone
                ? 50.0
                : isCompactPhone
                ? 56.0
                : 60.76;
            final bodyTextSize = isWideShortPhone
                ? 13.0
                : isTablet
                ? 16.0
                : 15.0;
            final otpTextSize = isWideShortPhone
                ? 20.0
                : isCompactPhone
                ? 22.0
                : 24.0;

            return SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - padding.vertical)
                      .clamp(0.0, double.infinity)
                      .toDouble(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/otp.png',
                          width: imageWidth,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: sectionGap),
                        AppText(
                          text:
                              'An OTP has been sent to your registered email address. Kindly enter it to continue.',
                          size: bodyTextSize,
                          fontWeight: FontWeight.w400,
                          color: appTextColor2,
                          isCentered: true,
                          lineSpacing: 1.2,
                        ),
                        SizedBox(height: sectionGap),
                        SizedBox(
                          width: buttonWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var index = 0; index < 4; index++)
                                KeyboardListener(
                                  focusNode: _keyboardFocusNodes[index],
                                  onKeyEvent: (event) =>
                                      _onKeyPressed(event, index),
                                  child: AppTextFeild(
                                    width: otpBoxWidth,
                                    height: otpBoxHeight,
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    isTextCenter: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    onChanged: (value) =>
                                        _onChanged(value, index),
                                    padding: EdgeInsets.zero,
                                    size: otpTextSize,
                                    textColor: const Color(0xFF8E8E8E),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        AppButton(
                          text: _isSending
                              ? 'Sending...'
                              : _isVerifying
                              ? 'Verifying...'
                              : 'Verify',
                          isLoading: _isSending || _isVerifying,
                          buttonwidth: buttonWidth,
                          buttonheight: buttonHeight,
                          size: isWideShortPhone
                              ? 14
                              : isTablet
                              ? 17
                              : null,
                          onPressed: (_isSending || _isVerifying)
                              ? null
                              : _verifyOtp,
                        ),
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
