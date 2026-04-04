
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/auth/login.dart';
import 'package:fudikoclient/screens/auth/register.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/screens/tabs/main_restaurant_nav.dart';
import 'package:fudikoclient/utils/tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      check();
    });
  }

  Future<void> check() async{
    final token = await getToken();
    if(token != null) {
      slideRightWidget(newPage: HomePage(), context: context, clearStack: true);
    }
    else {
      slideRightWidget(newPage: Login(), context: context, clearStack: true );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/Splashpage.png', fit: BoxFit.cover);
  }
}
