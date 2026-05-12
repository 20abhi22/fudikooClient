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

  static const _activeColor = Color(0xFFE8820C);
  static const _inactiveColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Home',        'icon': 'assets/icons/home_inactive 1.png',        'badge': 0},
      {'label': 'Reservation', 'icon': 'assets/icons/reservation_inactive 1.png', 'badge': 1},
      {'label': 'Favorite',    'icon': 'assets/icons/heart_inactive 1.png',       'badge': 0},
      {'label': 'Profile',     'icon': 'assets/icons/user_inactive 1.png',        'badge': 0},
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
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
          final badge = item['badge'] as int;

          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        isSelected ? _activeColor : _inactiveColor,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        item['icon'] as String,
                        width: 25.w,
                        height: 25.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 20.w,
                            minHeight: 20.h,
                          ),
                          child: Center(
                            child: Text(
                              '$badge',
                              style: TextStyle(
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
                    color: isSelected ? _activeColor : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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