import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Quick actions grid widget
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_shopping_cart,
        label: 'New Order',
        color: AppColors.primary,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.person_add,
        label: 'Add Customer',
        color: AppColors.success,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.inventory,
        label: 'Products',
        color: AppColors.secondary,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.receipt_long,
        label: 'Invoices',
        color: AppColors.info,
        onTap: () {},
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppDimensions.sm,
        crossAxisSpacing: AppDimensions.sm,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _QuickActionCard(action: action);
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: AppDimensions.borderRadiusMd,
      child: Container(
        padding: AppDimensions.paddingXs,
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.1),
          borderRadius: AppDimensions.borderRadiusMd,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: action.color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: action.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
