import 'package:flutter/material.dart';
import 'package:fudikoclient/utils/constants.dart';

class AgreementPage extends StatelessWidget {
  const AgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: (){
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 30, top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: appTextColor3,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Agreement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(10),
                  thickness: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'By registering on the Fudikoo Vendor App, you agree to enter into a partnership with Fudikoo under the terms and conditions outlined in this Agreement.',
                          style: TextStyle(fontSize: 15, height: 1.6),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Fudikoo is a digital platform that helps users discover restaurants, access real-time offers, place takeaway orders, and send banquet booking requests. The app is designed to make your dining experience more convenient, engaging, and personalized by connecting you with restaurants that match your preferences',
                          style: TextStyle(fontSize: 15, height: 1.6),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'As a user, you are expected to provide accurate and up-to-date information during registration and while using the app. You agree to use the app responsibly and respectfully, especially when communicating with restaurant partners. Misuse of features, inappropriate behavior, or attempts to manipulate the system may result in restrictions or suspension of your account.',
                          style: TextStyle(fontSize: 15, height: 1.6),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Fudikoo allows you to explore a variety of restaurants, view detailed menus, check ratings and reviews, and stay informed about limited-time offers or seasonal promotions. You can also send specific banquet or party requests directly to restaurants and receive timely responses based on your requirements.',
                          style: TextStyle(fontSize: 15, height: 1.6),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'The platform aims to maintain a trustworthy environment for both customers and vendors. Therefore, users are encouraged to report any issues, inappropriate content, or suspicious activity they may encounter while using the app. Fudikoo reserves the right to take necessary actions to protect the quality and integrity of the service.',
                          style: TextStyle(fontSize: 15, height: 1.6),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
