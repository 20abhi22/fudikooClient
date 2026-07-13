import 'package:flutter/widgets.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';

typedef ResponsiveWidgetBuilder =
    Widget Function(
      BuildContext context,
      BoxConstraints constraints,
      Orientation orientation,
    );

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
  });

  final ResponsiveWidgetBuilder mobile;
  final ResponsiveWidgetBuilder tablet;

  @override
@override
Widget build(BuildContext context) {
  return OrientationBuilder(
    builder: (context, orientation) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final size = MediaQuery.sizeOf(context);

          if (Breakpoints.isTabletDevice(size)) {
            return tablet(context, constraints, orientation);
          }

          return mobile(context, constraints, orientation);
        },
      );
    },
  );
}
}
