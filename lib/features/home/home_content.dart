import 'package:flutter/material.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';

class HomeItem {
  const HomeItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

const List<HomeItem> homeItems = [
  HomeItem(
    title: 'Restaurants',
    subtitle: 'Discover nearby dining experiences and current offers.',
    icon: Icons.restaurant_outlined,
    color: Color(0xFFF97A0D),
  ),
  HomeItem(
    title: 'Banquets',
    subtitle: 'Find venues for celebrations, events, and gatherings.',
    icon: Icons.celebration_outlined,
    color: Color(0xFF485599),
  ),
  HomeItem(
    title: 'Catering',
    subtitle: 'Plan food service for private and corporate occasions.',
    icon: Icons.room_service_outlined,
    color: Color(0xFF00A52C),
  ),
  HomeItem(
    title: 'Takeaway',
    subtitle: 'Order quick meals and collect when they are ready.',
    icon: Icons.shopping_bag_outlined,
    color: Color(0xFFC95F05),
  ),
  HomeItem(
    title: 'Rewards',
    subtitle: 'Track points, badges, and loyalty benefits.',
    icon: Icons.workspace_premium_outlined,
    color: Color(0xFF253AA2),
  ),
  HomeItem(
    title: 'Reservations',
    subtitle: 'Manage upcoming bookings in one organized place.',
    icon: Icons.event_available_outlined,
    color: Color(0xFF987743),
  ),
];

class HomeCard extends StatelessWidget {
  const HomeCard({super.key, required this.item});

  final HomeItem item;

  @override
  Widget build(BuildContext context) {
    final gap = AppDimensions.gap(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.padding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: item.color, size: 32),
            SizedBox(height: gap),
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: AppDimensions.title(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: gap / 2),
            Text(
              item.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppDimensions.body(context),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.gap(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Home',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: AppDimensions.headline(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppDimensions.gap(context) / 2),
          Text(
            orientation == Orientation.landscape
                ? 'Browse Fudiko services across a wider workspace.'
                : 'Browse Fudiko services and manage your activity.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: AppDimensions.body(context),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
