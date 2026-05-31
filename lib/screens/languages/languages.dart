import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/translator_service.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
String selectedLanguage = TranslatorService.currentLanguage == 'ar' ? "Arabic" : "English";

 void _changeLanguage(String language, String langCode) async {
  setState(() => selectedLanguage = language);
  await TranslatorService.setLanguage(langCode); // ← await now

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const HomePage()),
    (route) => false,
  );
}

  Widget _buildLanguageTile(String language,String langCode) {
    final bool isSelected = selectedLanguage == language;

    return GestureDetector(
      onTap: () => {_changeLanguage(language, langCode),
              setState(() {
          selectedLanguage = language;
        }),
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? appTextColor.withOpacity(.29) : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: AppText(
            text: language,
            size: 15,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white :  appTextColor3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: (){
              Navigator.pop(context);
            },
            child: Padding(
              padding:  EdgeInsets.only(top: 40.h, left: 30.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(backOrange, width: 32.w, height: 32.h),
                ],
              ),
            ),
          ),

          SizedBox(height: 60.h),

          Divider(thickness: 1, color: Colors.grey,height: 1,),
          _buildLanguageTile("English", "en"),

          Divider(thickness: 1, color: Colors.grey,height: 1,),
          _buildLanguageTile("Arabic", "ar"),

          Divider(thickness: 1, color: Colors.grey,height: 1,),
        ],
      ),
    );
  }
}
