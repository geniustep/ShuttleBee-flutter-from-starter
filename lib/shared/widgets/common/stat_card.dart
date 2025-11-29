import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Stat Card Widget - بطاقة إحصائية - ShuttleBee
class StatCard extends StatelessWidget {
  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: AppDimensions.sm),
              Text(
                value,
                style: AppTypography.h4.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal Stat Card Widget - بطاقة إحصائية أفقية
class HorizontalStatCard extends StatelessWidget {
  const HorizontalStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTypography.h5.copyWith(color: color),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_left, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
