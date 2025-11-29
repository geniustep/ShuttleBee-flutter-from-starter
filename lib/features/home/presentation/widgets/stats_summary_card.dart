import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Stats summary card widget
class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingMd,
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.shopping_cart_outlined,
                label: 'Orders',
                value: '156',
                color: AppColors.primary,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _StatItem(
                icon: Icons.people_outline,
                label: 'Customers',
                value: '1,247',
                color: AppColors.success,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _StatItem(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                value: '85',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
