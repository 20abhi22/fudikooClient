import 'package:flutter/material.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/features/home/home_content.dart';

class HomeMobile extends StatelessWidget {
  const HomeMobile({super.key, required this.items, required this.orientation});

  final List<HomeItem> items;
  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);

    return ListView.separated(
      padding: padding,
      itemCount: items.length + 1,
      separatorBuilder: (context, index) =>
          SizedBox(height: AppDimensions.gap(context)),
      itemBuilder: (context, index) {
        if (index == 0) {
          return HomeHeader(orientation: orientation);
        }

        return HomeCard(item: items[index - 1]);
      },
    );
  }
}
