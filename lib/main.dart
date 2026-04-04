import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/screens/about/aboutLayout.dart';
import 'package:fudikoclient/screens/auth/info.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/screens/splashscreen/splashscreen.dart';
import 'package:fudikoclient/screens/tabs/main_restaurant_nav.dart';
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
  bool? isFirstUse = false;
  @override
  void initState() {
    super.initState();
  }
  Future<void> setup() async {
    isFirstUse = await getIsFirstUse();
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
      home:
       !isFirstUse! ?  SplashScreen() :  
      AboutLayout(),
    );
  }
}
