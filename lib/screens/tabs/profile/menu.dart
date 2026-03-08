import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/screens/tabs/profile/menucard.dart';
import 'package:fudikoclient/utils/constants.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String selectedStatus = "PDF Menu";
  List<String> menuPdfList = List.generate(
    20,
    (index) => 'Menu Item ${index + 1}',
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: Column(
          children: [
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
              child: Row(
                children: [
                  buildStatusButton("PDF Menu",),
                  SizedBox(width: 10.w),
                  buildStatusButton("Single Menu",),
                ],
              ),
            ),
            SizedBox(height: 30.h),
            if (selectedStatus == "PDF Menu")
              Expanded(
                child: ListView.separated(
                  itemCount: menuPdfList.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding:  EdgeInsets.symmetric(horizontal: 30.w),
                      child: _pdfBox(menuPdfList[index]),
                    );
                  },
                ),
              ),
            if (selectedStatus == "Single Menu")
              Expanded(
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding:  EdgeInsets.symmetric(horizontal: 30.w),
                      child: MenuCard(url: 'assets/images/dish.png'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pdfBox(String text) {
    return Container(
      width: double.infinity,
      height: 70.h,
      padding:  EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10.r,
            offset: Offset(0, 4.r),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Image.asset(
              'assets/images/pdfLogo.png',
              height: 40.h,
              width: 40.w,
              fit: BoxFit.contain,
            ),
          ),
          Center(
            child: Text(
              text,
              style:  TextStyle(fontSize: 12.sp),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusButton(String text) {
    final bool isSelected = selectedStatus == text;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStatus = text;
          });
        },
        child: Container(
          height: 35.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ?  LinearGradient(
                    colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6.r,
                offset: Offset(2.r, 2.r),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp ,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor3,
            ),
          ),
        ),
      ),
    );
  }
}
