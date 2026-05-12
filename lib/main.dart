import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/screens/about/aboutLayout.dart';
import 'package:fudikoclient/screens/splashscreen/splashscreen.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/rendering.dart';
import 'package:fudikoclient/utils/tokens.dart';

void main() async{
  debugPaintSizeEnabled = false;
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    
  ]);
  DioClient.addInterceptor();
  runApp(
    ScreenUtilInit(
      designSize: const Size(402, 874),
      minTextAdapt: true,
      builder: (context, child) => const MyApp(),
    ),
  );
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
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: appTextColor),
        fontFamily: 'Inter',
      ),
      home: isFirstUse == null
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : isFirstUse!
              ? const AboutLayout()
              : const SplashScreen(),
    );
  }
}
