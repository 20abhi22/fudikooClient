import 'package:flutter/material.dart';
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
  late String selectedLanguage = TranslatorService.currentLanguage == 'ar'
      ? 'Arabic'
      : 'English';

  /// True while the new language is being applied across the app.
  bool _isApplying = false;

  /// Warm-up progress, 0..1.
  double _progress = 0;

  Future<void> _changeLanguage(String language, String langCode) async {
    if (_isApplying || selectedLanguage == language) return;

    setState(() {
      selectedLanguage = language;
      _isApplying = true;
      _progress = 0;
    });

    await TranslatorService.setLanguage(langCode);

    // Translate everything up front rather than letting each screen fetch its
    // own copy on first visit, so the app is already in the new language by
    // the time the loader clears.
    await TranslatorService.warmUp(
      langCode,
      onProgress: (value) {
        if (mounted) setState(() => _progress = value);
      },
    );

    if (!mounted) return;
    setState(() => _isApplying = false);

    // Root navigator: a nested reset would leave the surrounding tab shell
    // (and its bottom nav) wrapped around the fresh HomePage.
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Widget _buildApplyingOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: appTextColor,
                    // Indeterminate until the first batch reports, so the ring
                    // never sits frozen at zero.
                    value: _progress == 0 ? null : _progress,
                  ),
                ),
                const SizedBox(height: 18),
                // Plain Text on purpose: this label must not wait on the very
                // translation pass it is reporting on.
                Text(
                  'Applying $selectedLanguage...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: appTextColor5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(_progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Leaving halfway would strand a half-translated cache on screen.
      canPop: !_isApplying,
      child: Stack(
        children: [
          _buildPage(context),
          if (_isApplying) _buildApplyingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
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
                        const Divider(
                          thickness: 1,
                          color: Colors.grey,
                          height: 1,
                        ),
                        _buildLanguageTile(
                          language: 'English',
                          nativeName: 'English',
                          langCode: 'en',
                          metrics: metrics,
                        ),
                        const Divider(
                          thickness: 1,
                          color: Colors.grey,
                          height: 1,
                        ),
                        _buildLanguageTile(
                          language: 'Arabic',
                          nativeName: 'العربية',
                          langCode: 'ar',
                          metrics: metrics,
                        ),
                        const Divider(
                          thickness: 1,
                          color: Colors.grey,
                          height: 1,
                        ),
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

  /// [language] identifies the choice internally; [nativeName] is what the
  /// tile shows.
  Widget _buildLanguageTile({
    required String language,
    required String nativeName,
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
          // Plain Text, not AppText: a language is named in its own script on
          // every screen of this list, so "العربية" must stay "العربية" whether
          // the app is currently in English or in Arabic.
          child: Text(
            nativeName,
            style: TextStyle(
              fontSize: metrics.textSize,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor3,
            ),
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
          ? (isLandscape
                ? AppDimensions.gap(context) * 0.75
                : AppDimensions.margin(context) * 1.5)
          : isCompactLandscape
          ? 18.0
          : isCompactPhone
          ? 32.0
          : 60.0,
      tileVerticalPadding: isTablet
          ? (isLandscape
                ? AppDimensions.gap(context) * 0.75
                : AppDimensions.gap(context) * 1.35)
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
