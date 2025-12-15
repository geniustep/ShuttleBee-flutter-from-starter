import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Settings tile widget
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimensions.xs),
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppDimensions.borderRadiusSm,
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          : null,
      trailing: trailing ??
          (showArrow && onTap != null
              ? const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                )
              : null),
      onTap: onTap,
    );
  }
}
