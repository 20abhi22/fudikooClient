import 'package:flutter/material.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/responsive_builder.dart';
import 'package:fudikoclient/features/home/home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.home, this.explore, this.profile});

  final Widget? home;
  final Widget? explore;
  final Widget? profile;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // static const List<_ShellDestination> _destinations = [
  //   _ShellDestination(
  //     label: 'Home',
  //     icon: Icons.home_outlined,
  //     selectedIcon: Icons.home,
  //   ),
  //   _ShellDestination(
  //     label: 'Explore',
  //     icon: Icons.explore_outlined,
  //     selectedIcon: Icons.explore,
  //   ),
  //   _ShellDestination(
  //     label: 'Profile',
  //     icon: Icons.person_outline,
  //     selectedIcon: Icons.person,
  //   ),
  // ];

  void _selectDestination(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  List<Widget> _buildScreens() {
    return [
      widget.home ?? const HomeScreen(),
      widget.explore ??
          const _ShellPlaceholder(
            title: 'Explore',
            subtitle: 'Search, maps, and discovery screens will live here.',
            icon: Icons.explore_outlined,
          ),
      widget.profile ??
          const _ShellPlaceholder(
            title: 'Profile',
            subtitle: 'Account, rewards, and preferences will live here.',
            icon: Icons.person_outline,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();

    return ResponsiveBuilder(
  mobile: (context, constraints, orientation) {
    return _MobileShell(
      selectedIndex: _selectedIndex,
      screens: screens,
    );
  },
  tablet: (context, constraints, orientation) {
    return _TabletShell(
      selectedIndex: _selectedIndex,
      screens: screens,
    );
  },
);
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.selectedIndex, required this.screens});

  final int selectedIndex;
  final List<Widget> screens;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: IndexedStack(index: selectedIndex, children: screens),
      ),
    );
  }
}

class _TabletShell extends StatelessWidget {
  const _TabletShell({
    required this.selectedIndex,
    required this.screens,
  });

  final int selectedIndex;
  final List<Widget> screens;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: screens,
        ),
      ),
    );
  }
}

// class _DesktopShell extends StatelessWidget {
//   const _DesktopShell({
//     required this.selectedIndex,
//     required this.destinations,
//     required this.screens,
//     required this.onSelected,
//   });

//   final int selectedIndex;
//   final List<_ShellDestination> destinations;
//   final List<Widget> screens;
//   final ValueChanged<int> onSelected;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Row(
//           children: [
//             NavigationDrawer(
//               selectedIndex: selectedIndex,
//               onDestinationSelected: onSelected,
//               children: [
//                 Padding(
//                   padding: EdgeInsets.fromLTRB(
//                     AppDimensions.padding(context),
//                     AppDimensions.padding(context),
//                     AppDimensions.padding(context),
//                     AppDimensions.gap(context),
//                   ),
//                   child: Text(
//                     'Fudiko',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontSize: AppDimensions.title(context),
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                 ),
//                 ...destinations.map(
//                   (destination) => NavigationDrawerDestination(
//                     icon: Icon(destination.icon),
//                     selectedIcon: Icon(destination.selectedIcon),
//                     label: Text(destination.label),
//                   ),
//                 ),
//               ],
//             ),
//             VerticalDivider(
//               width: 1,
//               thickness: 1,
//               color: Theme.of(context).colorScheme.outlineVariant,
//             ),
//             Expanded(
//               child: IndexedStack(index: selectedIndex, children: screens),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ShellDestination {
//   const _ShellDestination({
//     required this.label,
//     required this.icon,
//     required this.selectedIcon,
//   });

//   final String label;
//   final IconData icon;
//   final IconData selectedIcon;
// }

class _ShellPlaceholder extends StatelessWidget {
  const _ShellPlaceholder({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppDimensions.pagePadding(context),
        child: FractionallySizedBox(
          widthFactor: 1,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: AppDimensions.headline(context),
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: AppDimensions.gap(context)),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: AppDimensions.headline(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: AppDimensions.gap(context) / 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: AppDimensions.body(context),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
