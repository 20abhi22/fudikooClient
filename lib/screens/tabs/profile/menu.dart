import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/menu/menu_model.dart';
import 'package:fudikoclient/screens/tabs/profile/menucard.dart';
import 'package:fudikoclient/service/menu/menu_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class Menu extends StatefulWidget {
  final String restaurantId;
  const Menu({super.key, required this.restaurantId});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String selectedStatus = "PDF Menu";
  bool isLoading = true;
  List<MenuPdfModel> pdfList = [];
  List<MenuItemModel> menuItems = [];

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    final response = await MenuService().getMenu(widget.restaurantId);
    if (!mounted) return;
    setState(() {
      pdfList = response.pdfs;
      menuItems = response.individualMenu;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 30.h),
                    child: Row(
                      children: [
                        buildStatusButton("PDF Menu"),
                        SizedBox(width: 10.w),
                        buildStatusButton("Single Menu"),
                      ],
                    ),
                  ),
                  SizedBox(height: 30.h),

                  // ── PDF Menu ──
                  if (selectedStatus == "PDF Menu")
                    pdfList.isEmpty
                        ? Center(
                            child: Text(
                              'No PDF menus available',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13.sp),
                            ),
                          )
                        : Expanded(
                            child: ListView.separated(
                              itemCount: pdfList.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 10.h),
                              itemBuilder: (context, index) {
                                final pdf = pdfList[index];
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 30.w),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final url = _resolvePdfUri(pdf.pdfPath);
                                      if (url == null) return;

                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    child: _pdfBox(pdf.menuName),
                                  ),
                                );
                              },
                            ),
                          ),

                  // ── Single Menu ──
                  if (selectedStatus == "Single Menu")
                    menuItems.isEmpty
                        ? Center(
                            child: Text(
                              'No menu items available',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13.sp),
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              itemCount: menuItems.length,
                              itemBuilder: (context, index) {
                                final item = menuItems[index];
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 30.w),
                                  child: MenuCard(
                                    url: item.itemImage ??
                                        'assets/images/dish.png',
                                    name: item.itemName,
                                    price: item.itemPrice,
                                    description: item.itemDescription,
                                    category: item.itemCategory,
                                  ),
                                );
                              },
                            ),
                          ),
                ],
              ),
      ),
    );
  }

  Uri? _resolvePdfUri(String rawPath) {
    final trimmedPath = rawPath.trim();
    if (trimmedPath.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(trimmedPath);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }

    final baseOrigin = Uri.parse(DioClient.dio.options.baseUrl).origin;
    final normalizedPath = trimmedPath.startsWith('/') ? trimmedPath : '/$trimmedPath';
    return Uri.parse('$baseOrigin$normalizedPath');
  }

  Widget _pdfBox(String text) {
    return Container(
      width: double.infinity,
      height: 70.h,
      padding: EdgeInsets.all(16.r),
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
              style: TextStyle(fontSize: 12.sp),
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
        onTap: () => setState(() => selectedStatus = text),
        child: Container(
          height: 35.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
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
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor3,
            ),
          ),
        ),
      ),
    );
  }
}