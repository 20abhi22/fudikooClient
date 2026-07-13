import 'package:flutter/material.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/features/home/home_content.dart';

class HomeDesktop extends StatelessWidget {
  const HomeDesktop({
    super.key,
    required this.items,
    required this.orientation,
  });

  final List<HomeItem> items;
  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 280,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(orientation: orientation),
                  SizedBox(height: AppDimensions.gap(context)),
                  Text(
                    'Service overview',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: AppDimensions.body(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppDimensions.gap(context)),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: AppDimensions.gap(context) / 2),
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(item.icon, color: item.color),
                          title: Text(item.title),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = AppDimensions.gridColumnsForWidth(
                constraints.maxWidth - padding.horizontal,
              );

              return GridView.builder(
                padding: padding,
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppDimensions.gridGap(context),
                  crossAxisSpacing: AppDimensions.gridGap(context),
                  childAspectRatio: 1.7,
                ),
                itemBuilder: (context, index) => HomeCard(item: items[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
