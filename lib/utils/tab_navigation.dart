import 'package:flutter/material.dart';

class TabStackObserver extends NavigatorObserver {
  TabStackObserver({required this.onStackChanged});

  final VoidCallback onStackChanged;

  void _notify() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onStackChanged());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _notify();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notify();
  }
}

class TabNavigator extends StatelessWidget {
  const TabNavigator({
    super.key,
    required this.navigatorKey,
    required this.child,
    this.observers = const <NavigatorObserver>[],
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  final List<NavigatorObserver> observers;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      observers: observers,
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => child,
        );
      },
    );
  }
}

Widget buildNestedTabNavigators({
  required int currentIndex,
  required List<GlobalKey<NavigatorState>> navigatorKeys,
  required List<Widget> children,
  required List<TabStackObserver> observers,
}) {
  return IndexedStack(
    index: currentIndex,
    children: List.generate(children.length, (index) {
      return TabNavigator(
        navigatorKey: navigatorKeys[index],
        observers: [observers[index]],
        child: children[index],
      );
    }),
  );
}
