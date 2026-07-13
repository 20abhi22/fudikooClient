import 'package:flutter/material.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/features/home/home_content.dart';

class HomeTablet extends StatelessWidget {
  const HomeTablet({
    super.key,
    required this.items,
    required this.orientation,
  });

  final List<HomeItem> items;
  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = AppDimensions.pagePadding(context);
        final availableWidth = constraints.maxWidth - padding.horizontal;
        final columns = AppDimensions.gridColumnsForWidth(
          availableWidth,
        ).clamp(1, 3).toInt();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: padding,
              sliver: SliverToBoxAdapter(
                child: HomeHeader(orientation: orientation),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                0,
                padding.right,
                padding.bottom,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => HomeCard(item: items[index]),
                  childCount: items.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppDimensions.gridGap(context),
                  crossAxisSpacing: AppDimensions.gridGap(context),
                  childAspectRatio: orientation == Orientation.landscape
                      ? 1.55
                      : 1.25,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
