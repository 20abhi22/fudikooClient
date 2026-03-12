import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/model/auth/registration-model.dart';
import 'package:fudikoclient/screens/auth/info.dart';
import 'package:fudikoclient/screens/auth/login.dart';
import 'package:fudikoclient/service/auth/registration-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';

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
  RegistrationAuthService registrationAuthService = RegistrationAuthService();
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
    setState(() {
      isLoading = true;
    });
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text.trim();
    final confirmPassword = _confirmPassword.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    if (!EmailValidator.validate(email)) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (password.length < 8) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final user = RegistrationModel(
      username: name,
      email: email,
      password: password,
    );

    RegistrationResponseModel response = await registrationAuthService
        .registerUser(user);

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    if (response.status) {
      await saveToken(response.token!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InfoPage()),
      );
    } else {
      if (!mounted) return;
      final errors = response.fieldErrors;
      if (errors != null) {
        if (errors.containsKey('email')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errors['email']!),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (errors.containsKey('username')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errors['username']!),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(-20.w, 0),
                  child: Transform.scale(
                    scale: 1.2,
                    child: Image.asset(
                      'assets/images/fudikoLogo2.png',
                      width: 700.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                AppTextFeild(
                  text: "Username",
                  icon: Icons.person,
                  controller: _name,
                ),
                SizedBox(height: 20.h),
                AppTextFeild(
                  text: "Email",
                  icon: Icons.mail,
                  controller: _email,
                ),
                SizedBox(height: 20.h),
                AppTextFeild(
                  text: "Password",
                  icon: Icons.lock,
                  controller: _password,
                  isObscure: _obscurePassword,
                  enableInteractiveSelection: false,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onSuffixTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                SizedBox(height: 20.h),
                AppTextFeild(
                  text: "Confirm Password",
                  icon: Icons.lock,
                  controller: _confirmPassword,
                  isObscure: _obscureConfirmPassword,
                  enableInteractiveSelection: false,
                  suffixIcon: _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onSuffixTap: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                SizedBox(height: 20.h),
                AppButton(
                  text: 'Register',
                  onPressed: () {
                    register();
                  },
                ),
                SizedBox(height: 40.h),
                Row(
                  children: [
                    Expanded(child: Divider(color: appTextColor, thickness: 1)),
                    SizedBox(width: 10.w),
                    AppText(
                      text: "or login with",
                      size: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(child: Divider(color: appTextColor, thickness: 1)),
                  ],
                ),
                SizedBox(height: 20.h),
                Image.asset(
                  'assets/images/googleiconfudiko.png',
                  width: 50.w,
                  height: 50.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 40.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      text: "Already have an Account?  ",
                      size: 15,
                      fontWeight: FontWeight.normal,
                      color: appTextColor2,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Login(),
                          ),
                        );
                      },
                      child: AppText(
                        text: "Sign In",
                        size: 15,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
