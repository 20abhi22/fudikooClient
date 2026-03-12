import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/profile/customer-profile-model.dart';
import 'package:fudikoclient/screens/badge/badgeinfo.dart';
import 'package:fudikoclient/screens/customerProfile/donutPercentage.dart';
import 'package:fudikoclient/screens/reliability/reliabilityinfo.dart';
import 'package:fudikoclient/service/profile/customer-profile-service.dart';
import 'package:fudikoclient/utils/constants.dart';

class CustomerProfile extends StatefulWidget {
  const CustomerProfile({super.key});

  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {
  CustomerProfileService profileService = CustomerProfileService();
  CustomerProfileModel? profile;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => isLoading = true);
    try {
      final data = await profileService.getProfile();
      if (!mounted) return;
      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  'assets/images/banner1.png',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: -screenWidth / 5,
                  left: screenWidth / 2 - 95,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: profile?.profilePicture != '-' &&
                              profile?.profilePicture != null
                          ? Image.network(
                              profile!.profilePicture,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/avatar2.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/avatar2.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 120),
            AppText(
              text: profile?.name ?? '-',
              size: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              isCentered: true,
            ),
            const SizedBox(height: 5),
            AppText(
              text: profile?.email ?? '-',
              size: 15,
              fontWeight: FontWeight.w200,
              color: Colors.black,
              isCentered: true,
            ),
            const SizedBox(height: 30),

            // Badge + Rating card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BadgeInfo()),
                              ),
                              child: Image.asset(
                                'assets/images/badge1.png',
                                height: 80,
                                width: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 5),
                            AppText(
                              text: profile?.badge == '-'
                                  ? "No Badge"
                                  : profile?.badge ?? '-',
                              size: 12,
                              fontWeight: FontWeight.w400,
                              color: appButtonColor2,
                              isCentered: true,
                            ),
                            AppText(
                              text: "Badge",
                              size: 12,
                              fontWeight: FontWeight.w400,
                              color: appButtonColor2,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 100, color: appTextColor3),
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ReliabilityInfo()),
                              ),
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: DonutChart(
                                  percentage: (profile?.rating ?? 0) / 100,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            AppText(
                              text: "Reliability",
                              size: 12,
                              fontWeight: FontWeight.w400,
                              color: appButtonColor2,
                            ),
                            AppText(
                              text: "Rating",
                              size: 12,
                              fontWeight: FontWeight.w400,
                              color: appButtonColor2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Info card
            Padding(
              padding: const EdgeInsets.only(
                left: 30, right: 30, top: 60, bottom: 20,
              ),
              child: Container(
                padding: const EdgeInsets.all(30),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.edit_square, size: 20, color: appTextColor2),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoRow("Place", profile?.place ?? '-'),
                    const SizedBox(height: 10),
                    _infoRow("Contact Info", profile?.contactInfo ?? '-'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  'assets/images/inviteimage.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 150,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText(
              text: label,
              size: 12,
              fontWeight: FontWeight.w600,
              color: appTextColor2,
            ),
            const SizedBox(width: 15),
            Expanded(child: Container(height: 0.5, color: appTextColor3)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 30, bottom: 5),
          child: AppText(
            text: value,
            size: 12,
            fontWeight: FontWeight.w400,
            color: appTextColor2,
          ),
        ),
      ],
    );
  }
}