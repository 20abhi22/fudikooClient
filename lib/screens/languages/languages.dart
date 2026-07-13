import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/translator_service.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  late String selectedLanguage =
      TranslatorService.currentLanguage == 'ar' ? 'Arabic' : 'English';

  Future<void> _changeLanguage(String language, String langCode) async {
    if (selectedLanguage == language) return;

    setState(() => selectedLanguage = language);
    await TranslatorService.setLanguage(langCode);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final metrics = _LanguageLayoutMetrics.fromConstraints(
                  context: context,
                  constraints: constraints,
                );

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: metrics.backTop,
                            left: metrics.horizontalPadding,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Image.asset(
                                backOrange,
                                width: metrics.backSize,
                                height: metrics.backSize,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: metrics.headerGap),
                        const Divider(thickness: 1, color: Colors.grey, height: 1),
                        _buildLanguageTile(
                          language: 'English',
                          langCode: 'en',
                          metrics: metrics,
                        ),
                        const Divider(thickness: 1, color: Colors.grey, height: 1),
                        _buildLanguageTile(
                          language: 'Arabic',
                          langCode: 'ar',
                          metrics: metrics,
                        ),
                        const Divider(thickness: 1, color: Colors.grey, height: 1),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required String language,
    required String langCode,
    required _LanguageLayoutMetrics metrics,
  }) {
    final isSelected = selectedLanguage == language;

    return GestureDetector(
      onTap: () => _changeLanguage(language, langCode),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected
              ? appTextColor.withValues(alpha: 0.29)
              : Colors.transparent,
        ),
        padding: EdgeInsets.symmetric(vertical: metrics.tileVerticalPadding),
        child: Center(
          child: AppText(
            text: language,
            size: metrics.textSize,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : appTextColor3,
          ),
        ),
      ),
    );
  }
}

class _LanguageLayoutMetrics {
  const _LanguageLayoutMetrics({
    required this.horizontalPadding,
    required this.backTop,
    required this.backSize,
    required this.headerGap,
    required this.tileVerticalPadding,
    required this.textSize,
  });

  final double horizontalPadding;
  final double backTop;
  final double backSize;
  final double headerGap;
  final double tileVerticalPadding;
  final double textSize;

  factory _LanguageLayoutMetrics.fromConstraints({
    required BuildContext context,
    required BoxConstraints constraints,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isCompactLandscape = isLandscape && height < 500;
    final isCompactPhone = width < 390 || height < 640;
    final isTablet = Breakpoints.isTabletDevice(size);

    return _LanguageLayoutMetrics(
      horizontalPadding: isTablet
          ? width * 0.055
        : isCompactLandscape
        ? width * 0.045
          : isCompactPhone
          ? width * 0.06
          : width * 0.075,
      backTop: isTablet
        ? (isLandscape ? 18.0 : 34.0)
        : isCompactLandscape
        ? 10.0
          : isCompactPhone
        ? 18.0
          : 40.0,
      backSize: isTablet
        ? (isLandscape ? 30.0 : 34.0)
        : isCompactLandscape
        ? 24.0
          : isCompactPhone
          ? 28.0
          : 32.0,
      headerGap: isTablet
        ? (isLandscape ? AppDimensions.gap(context) * 0.75 : AppDimensions.margin(context) * 1.5)
        : isCompactLandscape
        ? 18.0
          : isCompactPhone
        ? 32.0
          : 60.0,
      tileVerticalPadding: isTablet
        ? (isLandscape ? AppDimensions.gap(context) * 0.75 : AppDimensions.gap(context) * 1.35)
        : isCompactLandscape
        ? 12.0
          : isCompactPhone
          ? 16.0
          : 20.0,
      textSize: isTablet
          ? AppDimensions.body(context)
        : isCompactLandscape
        ? 13.0
          : isCompactPhone
          ? 14.0
          : 15.0,
    );
  }
}
