import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// User Avatar Widget - صورة المستخدم - ShuttleBee
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    this.name,
    this.imageUrl,
    this.size = UserAvatarSize.medium,
    this.backgroundColor,
    this.onTap,
    super.key,
  });

  final String? name;
  final String? imageUrl;
  final UserAvatarSize size;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = switch (size) {
      UserAvatarSize.small => AppDimensions.avatarSm / 2,
      UserAvatarSize.medium => AppDimensions.avatarMd / 2,
      UserAvatarSize.large => AppDimensions.avatarLg / 2,
      UserAvatarSize.extraLarge => AppDimensions.avatarXl / 2,
    };

    final textStyle = switch (size) {
      UserAvatarSize.small => AppTypography.labelMedium,
      UserAvatarSize.medium => AppTypography.h5,
      UserAvatarSize.large => AppTypography.h4,
      UserAvatarSize.extraLarge => AppTypography.h3,
    };

    final initials = _getInitials(name);
    final bgColor = backgroundColor ?? _getColorFromName(name);

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Text(
                initials,
                style: textStyle.copyWith(color: Colors.white),
              )
            : null,
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getColorFromName(String? name) {
    if (name == null || name.isEmpty) return AppColors.primary;
    
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.info,
    ];
    
    final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }
}

enum UserAvatarSize { small, medium, large, extraLarge }

