import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/notification/notification_setting.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      appBar: AppBar(
      backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: null,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: width * 0.04),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsPage(),
                  ),
                );

                
              },
              child: Icon(
                Icons.settings,
                color: Colors.black,
                size: width * 0.065,
              ),
            ),
          ),
        ],
      ),

     
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.02,
          ),
          children: [

            // Label
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "10 minutes ago",
                style: TextStyle(
                  fontSize: width * 0.035,
                  color: Colors.grey,
                ),
              ),
            ),

            SizedBox(height: height * 0.01),

            //Notification  Card
            _posterNotification(context, "assets/images/notification.png"),

            SizedBox(height: height * 0.03),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "1 day ago",
                style: TextStyle(
                  fontSize: width * 0.035,
                  color: Colors.grey,
                ),
              ),
            ),

            SizedBox(height: height * 0.01),

            _posterNotification(context, "assets/images/notification.png"),
          ],
        ),
      ),
    );
  }
//********************************************************************************************* */
  Widget _posterNotification(BuildContext context, String imagePath) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.04),
        child: Image.asset(
          imagePath,
          width: double.infinity,
          height: height * 0.5, 
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}