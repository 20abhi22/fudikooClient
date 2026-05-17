import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    super.key,
    required this.city,
    required this.isExpanded,
    required this.onFilterTap,
  });

  final String city;
  final bool isExpanded;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF222222)),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF1D1D1F),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isExpanded)
                      const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 8,
              shadowColor: const Color(0x26000000),
              child: IconButton(
                onPressed: onFilterTap,
                icon: const Icon(Icons.tune_rounded),
                color: const Color(0xFF1D1D1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
