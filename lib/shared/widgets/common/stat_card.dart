import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/responsive_utils.dart';

/// Stat Card Widget - بطاقة إحصائية - ShuttleBee
class StatCard extends StatelessWidget {
  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.trend,
    this.animationDelay = 0,
    this.showShadow = true,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double? trend;
  final int animationDelay;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final isTrendPositive = trend != null && trend! > 0;
    final trendColor = isTrendPositive ? AppColors.success : AppColors.error;

    Widget card = _StatCardContent(
      color: color,
      icon: icon,
      value: value,
      title: title,
      trend: trend,
      isTrendPositive: isTrendPositive,
      trendColor: trendColor,
      showShadow: showShadow,
      onTap: onTap,
    );

    if (animationDelay > 0) {
      card = card
          .animate()
          .fadeIn(duration: 400.ms, delay: (200 + animationDelay).ms, curve: Curves.easeOutCubic)
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
            duration: 400.ms,
            delay: (200 + animationDelay).ms,
            curve: Curves.easeOutCubic,
          );
    }

    return card;
  }
}

/// Internal Stat Card Content with Hover Effects
class _StatCardContent extends StatefulWidget {
  const _StatCardContent({
    required this.color,
    required this.icon,
    required this.value,
    required this.title,
    required this.isTrendPositive,
    required this.trendColor,
    required this.showShadow,
    this.trend,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String value;
  final String title;
  final double? trend;
  final bool isTrendPositive;
  final Color trendColor;
  final bool showShadow;
  final VoidCallback? onTap;

  @override
  State<_StatCardContent> createState() => _StatCardContentState();
}

class _StatCardContentState extends State<_StatCardContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = context.responsive(
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );

    final verticalPadding = context.responsive(
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    final horizontalPadding = context.responsive(
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );

    final iconSize = context.responsive(
      mobile: 22.0,
      tablet: 26.0,
      desktop: 30.0,
    );

    final iconPadding = context.responsive(
      mobile: 10.0,
      tablet: 12.0,
      desktop: 14.0,
    );

    final valueSize = context.responsive(
      mobile: 22.0,
      tablet: 26.0,
      desktop: 32.0,
    );

    final titleSize = context.responsive(
      mobile: 11.0,
      tablet: 12.0,
      desktop: 14.0,
    );

    final trendIconSize = context.responsive(
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );

    final trendTextSize = context.responsive(
      mobile: 10.0,
      tablet: 11.0,
      desktop: 12.0,
    );

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap != null
            ? () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: widget.showShadow
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: _isHovered ? 0.25 : 0.15),
                      blurRadius: _isHovered ? 20 : 12,
                      offset: Offset(0, _isHovered ? 8 : 4),
                    ),
                    if (context.isDesktop)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ]
                : null,
          ),
          transform: _isHovered ? Matrix4.diagonal3Values(1.02, 1.02, 1.0) : Matrix4.identity(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with background
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: _isHovered ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                  boxShadow: _isHovered && context.isDesktop
                      ? [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: iconSize,
                ),
              ),

              SizedBox(
                height: context.responsive(
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                ),
              ),

              // Value with trend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                      fontFamily: 'Cairo',
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (widget.trend != null) ...[
                    SizedBox(
                      width: context.responsive(
                        mobile: 4.0,
                        tablet: 5.0,
                        desktop: 6.0,
                      ),
                    ),
                    Icon(
                      widget.isTrendPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: trendIconSize,
                      color: widget.trendColor,
                    ),
                  ],
                ],
              ),

              // Trend percentage
              if (widget.trend != null) ...[
                SizedBox(
                  height: context.responsive(
                    mobile: 2.0,
                    tablet: 3.0,
                    desktop: 4.0,
                  ),
                ),
                Text(
                  '${widget.isTrendPositive ? '+' : ''}${widget.trend!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: trendTextSize,
                    fontWeight: FontWeight.bold,
                    color: widget.trendColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],

              SizedBox(
                height: context.responsive(
                  mobile: 4.0,
                  tablet: 5.0,
                  desktop: 6.0,
                ),
              ),

              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: titleSize,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w500,
                ),
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

/// KPI Card Widget - بطاقة مؤشرات الأداء - ShuttleBee
class KPICard extends StatelessWidget {
  const KPICard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.subtitle,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? trend;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTrendPositive = trend != null && trend! > 0;
    final trendColor = isTrendPositive ? AppColors.success : AppColors.error;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: color),
                  const SizedBox(width: 8),
                  if (trend != null)
                    Icon(
                      isTrendPositive ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: trendColor,
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                value,
                style: AppTypography.h4.copyWith(color: color),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (trend != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${isTrendPositive ? '+' : ''}${trend!.toStringAsFixed(1)}%',
                  style: AppTypography.caption.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
