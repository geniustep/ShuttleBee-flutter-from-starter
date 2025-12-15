import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Status Badge Widget - شارة الحالة - ShuttleBee
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.color,
    this.icon,
    this.size = StatusBadgeSize.medium,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final StatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final padding = switch (size) {
      StatusBadgeSize.small => const EdgeInsets.symmetric(
          horizontal: AppDimensions.xxs,
          vertical: 2,
        ),
      StatusBadgeSize.medium => const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.xxs,
        ),
      StatusBadgeSize.large => const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs,
        ),
    };

    final textStyle = switch (size) {
      StatusBadgeSize.small => AppTypography.overline,
      StatusBadgeSize.medium => AppTypography.caption,
      StatusBadgeSize.large => AppTypography.bodySmall,
    };

    final iconSize = switch (size) {
      StatusBadgeSize.small => 12.0,
      StatusBadgeSize.medium => 14.0,
      StatusBadgeSize.large => 16.0,
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: textStyle.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusBadgeSize { small, medium, large }
