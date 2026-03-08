import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/aboutapp/about.dart';
import 'package:fudikoclient/screens/auth/changepassword.dart';
import 'package:fudikoclient/screens/auth/login.dart';
import 'package:fudikoclient/screens/badge/badgeinfo.dart';
import 'package:fudikoclient/screens/complaint/complaint.dart';
import 'package:fudikoclient/screens/contact/contact.dart';
import 'package:fudikoclient/screens/earnPoints/earnPoints.dart';
import 'package:fudikoclient/screens/feedback/feedback.dart';
import 'package:fudikoclient/screens/home/components/banquetBox.dart';
import 'package:fudikoclient/screens/home/components/cateringBox.dart';
import 'package:fudikoclient/screens/home/components/restaurantBox.dart';
import 'package:fudikoclient/screens/home/components/takeawayBox.dart';
import 'package:fudikoclient/screens/languages/languages.dart';
import 'package:fudikoclient/screens/notification/notification.dart';
import 'package:fudikoclient/screens/notification/notification_setting.dart';
import 'package:fudikoclient/screens/reward/reward.dart';
import 'package:fudikoclient/screens/tabs/mainnav.dart';
import 'package:fudikoclient/utils/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool isDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final double totalWidth = MediaQuery.of(context).size.width * 0.5;
    //final double activewidth=totalwidth*0.35;
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 30.w,
                    vertical: 20.h,
                  ),
                  child: _navBar(),
                ),

                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: 2,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 30,
                                  right: 30,
                                  top: 30,
                                ),
                                child: Column(
                                  children: [
                                    if (index == 0) ...[
                                      GestureDetector(
                                        onTap: () {
                                          slideRightWidget(
                                            newPage: MainNavPage(),
                                            context: context,
                                          );
                                        },
                                        child: RestaurantBox(),
                                      ),
                                      SizedBox(height: 10.h),
                                      BanquetBox(),
                                      SizedBox(height: 10.h),
                                      CateringBox(),
                                      SizedBox(height: 10.h),
                                      TakeAwayBox(),
                                    ] else ...[
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: 5,
                                        itemBuilder: (context, index) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  AppText(
                                                    text: "10 minutes ago",
                                                    size: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: appTextColor2,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 10.h),
                                              Image.asset(
                                                'assets/images/offerimage.png',
                                                height: 500.h,
                                                fit: BoxFit.contain,
                                              ),
                                              SizedBox(height: 10.h),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      //////////////////////////////////////slider///////////////////////////////
                      Center(
                        child: SizedBox(
                          width: totalWidth,
                          height: 8,
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                width: totalWidth,
                                height: 0.5,
                                decoration: BoxDecoration(
                                  color: sliderColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),

                              Container(
                                width: totalWidth / 2,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: sliderColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Padding(
                      //   padding: EdgeInsets.symmetric(vertical: 20.h),
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: List.generate(
                      //       2,
                      //       (index) => AnimatedPositioned(
                      //         duration: const Duration(milliseconds: 300),
                      //         curve: Curves.easeInOut,
                      //         left: 10,
                      //         child: Container(
                      //           width: 50,
                      //           height: 5.h,
                      //           decoration: BoxDecoration(
                      //             color: Colors.orange,
                      //             borderRadius: BorderRadius.circular(20.r),
                      //           ),
                      //         ),
                      //       ),

                      // AnimatedContainer(
                      //   duration: Duration(milliseconds: 300),
                      //   margin: EdgeInsets.symmetric(horizontal: 4.w),
                      //   width: _currentIndex == index ? 12.w : 8.w,
                      //   height: _currentIndex == index ? 12.h : 8.h,
                      //   decoration: BoxDecoration(
                      //     color: _currentIndex == index
                      //         ? Colors.orange
                      //         : Colors.grey,
                      //     shape: BoxShape.circle,
                      //   ),
                      // ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
            if (isDrawerOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isDrawerOpen = false;
                    });
                  },
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: 0,
              bottom: 0,
              left: isDrawerOpen
                  ? 0
                  : -MediaQuery.of(context).size.width * 0.75,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(-4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 100.h),
                          Align(
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/images/logofudikoo.png',
                              width: 150.w,
                            ),
                          ),
                          SizedBox(height: 50.h),
                          AppText(
                            text: "Settings",
                            size: 15,
                            fontWeight: FontWeight.w600,
                            color: appTextColor2,
                          ),
                          SizedBox(height: 10.h),
                          Divider(thickness: 1, color: Colors.grey, height: 1),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                SizedBox(height: 10.h),
                                _drawerItem(
                                  "Change Password",
                                  Icons.lock,
                                  ChangePassword(),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: 10.h),
                                _drawerItem(
                                  "Notifications",
                                  Icons.notifications,
                                  NotificationScreen(),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: 10.h),
                                _drawerItem(
                                  "Languages",
                                  Icons.translate,
                                  Languages(),
                                ),
                                SizedBox(height: 10.h),

                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: 10),
                                _drawerItem(
                                  "Rewards",
                                  Icons.workspace_premium,
                                  Reward(),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: 10.h),
                                _drawerItem(
                                  "Invite a Friend",
                                  Icons.person_add_alt,
                                  EarnPoints(),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: 10.h),
                              ],
                            ),
                          ),

                          SizedBox(height: 50.h),
                          AppText(
                            text: "Information",
                            size: 15,
                            fontWeight: FontWeight.w600,
                            color: appTextColor2,
                          ),
                          SizedBox(height: 10.h),
                          Divider(thickness: 1, color: Colors.grey, height: 1),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                SizedBox(height: 10.h),
                                _drawerItem(
                                  "About the App",
                                  Icons.info,
                                  AboutPage(),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: 10.h),
                                _drawerItem(
                                  "Badge Earnings",
                                  Icons.shield,
                                  BadgeInfo(),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: 10.h),
                                _drawerItem(
                                  "Complaints",
                                  Icons.report,
                                  ComplaintPage(),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: 10.h),
                                _drawerItem(
                                  "Rate the App",
                                  Icons.rate_review,
                                  FeedBack(),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                                SizedBox(height: 10.h),
                                _drawerItem(
                                  "Support",
                                  Icons.support_agent,
                                  ContactPage(),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 50.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                Divider(
                                  thickness: 1,
                                  color: Colors.red,
                                  height: 1,
                                ),
                                SizedBox(height: 10.h),
                                _drawerItem(
                                  "Log Out",
                                  Icons.logout,
                                  Login(),
                                  Colors.red,
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.red,
                                  height: 1,
                                ),
                                SizedBox(height: 10.h),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    String text,
    IconData icon, [
    Widget? routeWidget,
    Color? color,
  ]) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isDrawerOpen = false;
        });

        Future.delayed(Duration(milliseconds: 100), () {
          if (routeWidget != null) {
            if (routeWidget is Login) {
              pushWidgetWhileRemove(newPage: routeWidget, context: context);
            } else {
              slideRightWidget(newPage: routeWidget, context: context);
            }
          }
        });
      },
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? appTextColor2),
          SizedBox(width: 10.w),
          AppText(
            text: text,
            size: 15,
            fontWeight: FontWeight.w500,
            color: color ?? appTextColor2,
          ),
        ],
      ),
    );
  }

  Widget _navBar() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isDrawerOpen = !isDrawerOpen;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Icon(Icons.menu, size: 30.w, color: appTextColor3),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 200.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                children: [
                  AppText(
                    text: "City",
                    size: 10.w,
                    fontWeight: FontWeight.w600,
                    color: appTextColor3,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 15.w,
                          color: appTextColor3,
                        ),
                        AppText(
                          text: "Moscow Center",//shuldnt this be fetched
                          size: 10.w,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
