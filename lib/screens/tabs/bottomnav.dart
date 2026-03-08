import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Bottomnav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const Bottomnav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Home', 'icon': 'assets/images/homeiconfudiko.png', 'badge': 2},
      {'label': 'Inquiry', 'icon': 'assets/images/homeiconfudiko.png', 'badge': 2},
      {'label': 'Reservation', 'icon': 'assets/images/reservationiconfudiko.png', 'badge': 1},
      {'label': 'Favorite', 'icon': 'assets/images/likeiconfudiko.png', 'badge': 0},
      {'label': 'Profile', 'icon': 'assets/images/profileiconfudiko.png', 'badge': 0},
    ];

    return Container(
      padding:  EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 50, offset: Offset.zero),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      '${item['icon']}',
                      width: 25.w,
                    ),
                    if ((item['badge'] as int) > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding:  EdgeInsets.all(4.w),
                            decoration:  BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints:  BoxConstraints(
                            minWidth: 20.w,
                            minHeight: 20.h,
                          ),
                          child: Center(
                            child: Text(
                              '${item['badge']}',
                              style:  TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                  SizedBox(height: 4.h),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey[700],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
