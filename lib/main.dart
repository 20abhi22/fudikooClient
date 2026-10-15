import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/components/offline_banner.dart';
import 'package:fudikoclient/screens/about/aboutLayout.dart';
import 'package:fudikoclient/screens/splashscreen/splashscreen.dart';
import 'package:fudikoclient/service/notification/push_notification_service.dart';
import 'package:fudikoclient/utils/connectivity_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/http_overrides.dart';
import 'package:fudikoclient/utils/route_observer.dart';
import 'package:fudikoclient/utils/tokens.dart';
import 'package:fudikoclient/utils/translator_service.dart';

void main() async {
  debugPaintSizeEnabled = false;
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }

  // Android reads its Firebase config from google-services.json via the
  // Google Services Gradle plugin, so no explicit FirebaseOptions are
  // needed here. iOS has no GoogleService-Info.plist configured yet.
  await Firebase.initializeApp();
  PushNotificationService.init();

  // Edge-to-edge so the keyboard arrives as an inset instead of resizing the
  // Android window. Without it a screen that pins something to the bottom
  // (the radius panel on LocationSelect) has its whole view cut off at the
  // top of the keyboard, and `resizeToAvoidBottomInset` has no inset to act
  // on. Screens draw their own SafeArea; the system bars stay transparent so
  // content behind them reads correctly in either theme.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Not awaited: the service reports optimistic-online until its first
  // reading lands, so awaiting it only holds the app on a blank window for
  // up to its own 2s timeout before the splash can even paint.
  unawaited(ConnectivityService().start());

  // Awaited: the first screen needs the saved language and its cached
  // translations to paint in the right language rather than swapping after.
  await TranslatorService.loadSavedLanguage();
  DioClient.addInterceptor();

  runApp(const ProviderScope(child: _ResponsiveAppBootstrap()));
}

class _ResponsiveAppBootstrap extends StatelessWidget {
  const _ResponsiveAppBootstrap();

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final designSize = orientation == Orientation.landscape
            ? const Size(874, 402)
            : const Size(402, 874);

        return ScreenUtilInit(
          designSize: designSize,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => const MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isFirstUse;

  @override
  void initState() {
    super.initState();
    setup();
  }

  Future<void> setup() async {
    final firstUse = await getIsFirstUse() ?? true;
    if (!mounted) return;

    setState(() {
      isFirstUse = firstUse;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fudiko',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: appSecondaryBackgroundColor,
        colorScheme: ColorScheme.fromSeed(seedColor: appTextColor),
        fontFamily: 'Inter',
      ),
      scaffoldMessengerKey: messengerKey,
      navigatorKey: rootNavigatorKey,
      navigatorObservers: [routeObserver],
      // One offline bar for the whole app, so any screen that comes up empty
      // because the network is down still says so.
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox.shrink()),
      home: isFirstUse == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : isFirstUse!
          ? const AboutLayout()
          : const SplashScreen(),
    );
  }
}
