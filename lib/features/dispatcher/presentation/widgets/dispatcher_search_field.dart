import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Unified search field for Dispatcher screens (console-like look).
class DispatcherSearchField extends StatelessWidget {
  const DispatcherSearchField({
    super.key,
    required this.hintText,
    required this.value,
    required this.onChanged,
    this.onClear,
    this.prefixIcon = Icons.search_rounded,
  });

  final String hintText;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(prefixIcon),
        suffixIcon: value.isEmpty
            ? null
            : IconButton(
                tooltip: 'مسح',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear ?? () => onChanged(''),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.9),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      style: AppTypography.bodyMedium,
      onChanged: onChanged,
    );
  }
}
