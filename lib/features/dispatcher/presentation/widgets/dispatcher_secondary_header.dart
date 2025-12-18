import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'dispatcher_search_field.dart';

// تأكد من أن responsive_utils.dart يحتوي على extension ResponsiveExtension

/// Secondary header for Dispatcher screens with search, filters, and actions.
///
/// هايدر ثانوي موحد لصفحات المنسق يحتوي على:
/// - شريط البحث
/// - أزرار الفلترة
/// - إحصائيات سريعة
/// - أزرار الإجراءات
class DispatcherSecondaryHeader extends StatelessWidget {
  const DispatcherSecondaryHeader({
    super.key,
    this.searchHint,
    this.searchValue = '',
    this.onSearchChanged,
    this.onSearchClear,
    this.showSearch = true,
    this.filters = const [],
    this.actions = const [],
    this.stats = const [],
    this.customContent,
    this.backgroundColor,
    this.padding,
  });

  /// نص البحث الافتراضي
  final String? searchHint;

  /// قيمة البحث الحالية
  final String searchValue;

  /// دالة يتم استدعاؤها عند تغيير قيمة البحث
  final ValueChanged<String>? onSearchChanged;

  /// دالة يتم استدعاؤها عند مسح البحث
  final VoidCallback? onSearchClear;

  /// إظهار شريط البحث
  final bool showSearch;

  /// أزرار الفلترة
  final List<Widget> filters;

  /// أزرار الإجراءات (على اليمين)
  final List<Widget> actions;

  /// إحصائيات سريعة
  final List<DispatcherStatChip> stats;

  /// محتوى مخصص (يظهر بدلاً من البحث والفلاتر)
  final Widget? customContent;

  /// لون الخلفية (افتراضي: أبيض)
  final Color? backgroundColor;

  /// Padding مخصص
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        EdgeInsets.all(
          context.responsive(
            mobile: 12.0,
            tablet: 16.0,
            desktop: 20.0,
          ),
        );

    return Container(
      color: backgroundColor ?? Colors.white,
      padding: effectivePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom content or search/filters
          if (customContent != null)
            customContent!
          else ...[
            // Search bar and actions row
            if (showSearch || actions.isNotEmpty)
              _buildSearchAndActionsRow(context),

            // Filters row
            if (filters.isNotEmpty) ...[
              SizedBox(
                height: context.responsive(
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                ),
              ),
              _buildFiltersRow(context),
            ],
          ],

          // Stats chips
          if (stats.isNotEmpty) ...[
            SizedBox(
              height: context.responsive(
                mobile: 10.0,
                tablet: 12.0,
                desktop: 14.0,
              ),
            ),
            _buildStatsRow(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndActionsRow(BuildContext context) {
    return Row(
      children: [
        // Search field
        if (showSearch)
          Expanded(
            child: DispatcherSearchField(
              hintText: searchHint ?? 'ابحث...',
              value: searchValue,
              onChanged: onSearchChanged ?? (_) {},
              onClear: onSearchClear,
            ),
          ),

        // Actions
        if (actions.isNotEmpty) ...[
          if (showSearch)
            SizedBox(
              width: context.responsive(
                mobile: 8.0,
                tablet: 10.0,
                desktop: 12.0,
              ),
            ),
          ...actions.map((action) => Padding(
                padding: EdgeInsets.only(
                  left: context.responsive(
                    mobile: 4.0,
                    tablet: 6.0,
                    desktop: 8.0,
                  ),
                ),
                child: action,
              )),
        ],
      ],
    );
  }

  Widget _buildFiltersRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (filter) => Padding(
                padding: EdgeInsets.only(
                  right: context.responsive(
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  ),
                ),
                child: filter,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats
            .map(
              (stat) => Padding(
                padding: EdgeInsets.only(
                  right: context.responsive(
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  ),
                ),
                child: stat,
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Filter chip for dispatcher secondary header
class DispatcherFilterChip extends StatelessWidget {
  const DispatcherFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.color,
    this.badge,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.dispatcherPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        context.responsive(
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(
            mobile: 10.0,
            tablet: 12.0,
            desktop: 14.0,
          ),
          vertical: context.responsive(
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor
              : effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            context.responsive(
              mobile: 10.0,
              tablet: 12.0,
              desktop: 14.0,
            ),
          ),
          border: Border.all(
            color: isSelected
                ? effectiveColor
                : effectiveColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: context.responsive(
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
                color: isSelected ? Colors.white : effectiveColor,
              ),
              SizedBox(
                width: context.responsive(
                  mobile: 4.0,
                  tablet: 5.0,
                  desktop: 6.0,
                ),
              ),
            ],
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : effectiveColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: context.responsive(
                  mobile: 12.0,
                  tablet: 13.0,
                  desktop: 14.0,
                ),
              ),
            ),
            if (badge != null) ...[
              SizedBox(
                width: context.responsive(
                  mobile: 4.0,
                  tablet: 5.0,
                  desktop: 6.0,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(
                    mobile: 4.0,
                    tablet: 5.0,
                    desktop: 6.0,
                  ),
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : effectiveColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: context.responsive(
                      mobile: 9.0,
                      tablet: 10.0,
                      desktop: 11.0,
                    ),
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : effectiveColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stat chip for dispatcher secondary header
class DispatcherStatChip extends StatelessWidget {
  const DispatcherStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.dispatcherPrimary;

    final widget = Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive(
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        ),
        vertical: context.responsive(
          mobile: 6.0,
          tablet: 8.0,
          desktop: 10.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            effectiveColor.withValues(alpha: 0.15),
            effectiveColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          context.responsive(
            mobile: 10.0,
            tablet: 12.0,
            desktop: 14.0,
          ),
        ),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: context.responsive(
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
            color: effectiveColor,
          ),
          SizedBox(
            width: context.responsive(
              mobile: 6.0,
              tablet: 7.0,
              desktop: 8.0,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: context.responsive(
                    mobile: 14.0,
                    tablet: 15.0,
                    desktop: 16.0,
                  ),
                  fontWeight: FontWeight.bold,
                  color: effectiveColor,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.responsive(
                    mobile: 10.0,
                    tablet: 11.0,
                    desktop: 12.0,
                  ),
                  color: effectiveColor.withValues(alpha: 0.7),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          context.responsive(
            mobile: 10.0,
            tablet: 12.0,
            desktop: 14.0,
          ),
        ),
        child: widget,
      );
    }

    return widget;
  }
}
