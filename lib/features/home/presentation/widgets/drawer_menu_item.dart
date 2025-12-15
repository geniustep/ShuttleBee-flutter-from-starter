import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Drawer menu item
class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final VoidCallback onTap;
  final bool isSelected;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.badge,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryContainer : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: AppDimensions.xxs,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  borderRadius: AppDimensions.borderRadiusCircle,
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
