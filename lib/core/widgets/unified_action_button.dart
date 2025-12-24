import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Unified action button that maintains consistent mobile design across all devices
/// This ensures buttons look the same on mobile, tablet, and desktop
class UnifiedActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isCompact;
  final bool isOutlined;

  const UnifiedActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
    this.isCompact = false,
    this.isOutlined = false,
  });

  /// Create a primary button (filled with color)
  factory UnifiedActionButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    double? width,
    double? height,
    bool isCompact = false,
  }) {
    return UnifiedActionButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      backgroundColor: AppColors.dispatcherPrimary,
      foregroundColor: Colors.white,
      width: width,
      height: height,
      isCompact: isCompact,
    );
  }

  /// Create a secondary button (outlined)
  factory UnifiedActionButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    double? width,
    double? height,
    bool isCompact = false,
  }) {
    return UnifiedActionButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      width: width,
      height: height,
      isCompact: isCompact,
      isOutlined: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? (isCompact ? 36.0 : 40.0);
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: 0,
        );

    if (isOutlined) {
      return SizedBox(
        width: width,
        height: effectiveHeight,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
          label: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: effectivePadding,
            foregroundColor: foregroundColor ?? AppColors.dispatcherPrimary,
            side: BorderSide(
              color: foregroundColor ?? AppColors.dispatcherPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: effectiveHeight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: effectivePadding,
          backgroundColor: backgroundColor ?? AppColors.dispatcherPrimary,
          foregroundColor: foregroundColor ?? Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size(width ?? 0, effectiveHeight),
        ),
      ),
    );
  }
}

/// Icon button that maintains consistent sizing across devices
class UnifiedIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;
  final double? iconSize;

  const UnifiedIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? 40.0;
    final effectiveIconSize = iconSize ?? 20.0;

    if (backgroundColor != null) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: effectiveIconSize),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor ?? Colors.white,
          minimumSize: Size(effectiveSize, effectiveSize),
          maximumSize: Size(effectiveSize, effectiveSize),
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: effectiveIconSize),
      tooltip: tooltip,
      color: foregroundColor,
      constraints: BoxConstraints(
        minWidth: effectiveSize,
        minHeight: effectiveSize,
        maxWidth: effectiveSize,
        maxHeight: effectiveSize,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
