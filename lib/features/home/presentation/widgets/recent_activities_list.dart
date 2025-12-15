import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Recent activities list widget
class RecentActivitiesList extends StatelessWidget {
  const RecentActivitiesList({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      const _Activity(
        icon: Icons.shopping_cart,
        title: 'New order received',
        subtitle: 'Order #1234 - \$250.00',
        time: '2 min ago',
        color: AppColors.primary,
      ),
      const _Activity(
        icon: Icons.person_add,
        title: 'New customer registered',
        subtitle: 'John Doe - john@example.com',
        time: '15 min ago',
        color: AppColors.success,
      ),
      const _Activity(
        icon: Icons.payment,
        title: 'Payment received',
        subtitle: 'Invoice #567 - \$1,500.00',
        time: '1 hour ago',
        color: AppColors.secondary,
      ),
      const _Activity(
        icon: Icons.local_shipping,
        title: 'Order shipped',
        subtitle: 'Order #1230 - Tracking available',
        time: '3 hours ago',
        color: AppColors.info,
      ),
    ];

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _ActivityItem(activity: activity);
        },
      ),
    );
  }
}

class _Activity {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _Activity({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}

class _ActivityItem extends StatelessWidget {
  final _Activity activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimensions.xs),
        decoration: BoxDecoration(
          color: activity.color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          activity.icon,
          color: activity.color,
          size: 20,
        ),
      ),
      title: Text(
        activity.title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        activity.subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      trailing: Text(
        activity.time,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
