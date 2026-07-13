import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/auth/login.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _navigationTimer = Timer(const Duration(seconds: 2), () {
      check();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> check() async {
    final token = await getToken();
    if (!mounted) return;

    if (token != null) {
      pushWidgetWhileRemove(newPage: const HomePage(), context: context);
    } else {
      pushWidgetWhileRemove(newPage: const Login(), context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: OrientationBuilder(
        builder: (context, orientation) {
          return SizedBox.expand(
            child: Image.asset(
              'assets/images/Splashpage.png',
              fit: orientation == Orientation.landscape
                  ? BoxFit.fitWidth
                  : BoxFit.cover,
              alignment: Alignment.center,
            ),
          );
        },
      ),
    );
  }
}
