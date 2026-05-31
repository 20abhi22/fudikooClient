import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

class AboutBadgePage extends StatefulWidget {
  const AboutBadgePage({super.key});

  @override
  State<AboutBadgePage> createState() => _AboutBadgePageState();
}

class _AboutBadgePageState extends State<AboutBadgePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Image.asset(backOrange, width: 30.w, height: 30.w),
          ),
        ),
        title: const AppText(
          text: '',
          size: 22,
          color: Color(0xFFF97A0D),
          fontWeight: FontWeight.w600,
        ),
        titleSpacing: 0,
      ),
      body: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFF1E88E5)),
          trackColor: WidgetStateProperty.all(Colors.transparent),
          trackBorderColor: WidgetStateProperty.all(const Color(0xFF1E88E5)),
          trackVisibility: WidgetStateProperty.all(true),
          thickness: WidgetStateProperty.all(4),
          radius: const Radius.circular(4),
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          scrollbarOrientation: ScrollbarOrientation.right,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 34, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                AppText(
                  text: 'About Badges',
                  size: 22,
                  fontWeight: FontWeight.w600,
                  color: appTextColor2,
                  isCentered: true,
                  maxLines: 1,
                ),
                const SizedBox(height: 28),
                AppText(
                  text:
                      'In App, users can earn special badges based on their activity, engagement, and points collected through the app. These badges are a fun and rewarding way to recognize loyal customers who regularly explore new restaurants, place orders, send banquet requests, or participate in offers and promotions. For example, the Food Explorer badge is given to users who try a wide variety of restaurants, while the Quick Booker badge is awarded to those who frequently make banquet or party bookings. Other badges may highlight consistent takeaway ordering, early access to deals, or providing helpful reviews. As you continue to use the app and earn more points, you unlock more badges and exclusive benefits, such as special discounts or early access to top deals.',
                  size: 14,
                  fontWeight: FontWeight.w400,
                  color: appTextColor2,
                  lineSpacing: 1.75,
                  textAlign: TextAlign.justify,
                  maxLines: 30,
                ),
                const SizedBox(height: 40),
                _BadgeTile(
                  shieldIcon: badgeChamp,
                  // shieldColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  title: 'Champ',
                  description:
                      'Unlock an Exclusive Discount Pack and a Thank You Kit from Fudikoo.',
                ),
                const SizedBox(height: 28),
                _BadgeTile(
                  shieldIcon: badgeClimber,
                  // shieldColors: const [Color(0xFF22C55E), Color(0xFF15803D)],
                  title: 'Climber',
                  description:
                      'Enjoy a Free Takeaway Coupon and an Official Digital Badge.',
                ),
                const SizedBox(height: 28),
                _BadgeTile(
                  shieldIcon: badgeZylo,
                  // shieldColors: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
                  title: 'Zylo',
                  description:
                      'Get a Fudikoo Appreciation Certificate and early access to new app features.',
                ),
                const SizedBox(height: 28),
                _BadgeTile(
                  shieldIcon: badgeNerivo,
                  // shieldColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  title: 'Nerivo',
                  description:
                      'Receive priority access to banquet deals and a Free Banquet Booking Voucher.',
                ),
                const SizedBox(height: 28),
                _BadgeTile(
                  shieldIcon: badgeLumina,
                  // shieldColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  title: 'Lumina',
                  description:
                      'Get a Special Feature Article about your restaurant inside the app.',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String shieldIcon;
  // final List<Color> shieldColors;
  final String title;
  final String description;

  const _BadgeTile({
    required this.shieldIcon,
    // required this.shieldColors,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shield icon
        SizedBox(
          width: 35.w,
          height: 35.w,
          // decoration: BoxDecoration(
          //   // gradient: LinearGradient(
          //   //   colors: shieldColors,
          //   //   begin: Alignment.topCenter,
          //   //   end: Alignment.bottomCenter,
          //   // ),
          //   borderRadius: BorderRadius.circular(10),
          // ),
          child: Image.asset(
            shieldIcon,
            width: 30.w,
            height: 30.w,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 16),
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: title,
                size: 17,
                fontWeight: FontWeight.w600,
                color: appTextColor3,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              AppText(
                text: description,
                size: 14,
                fontWeight: FontWeight.w400,
                color: appTextColor,
                lineSpacing: 1.5,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
