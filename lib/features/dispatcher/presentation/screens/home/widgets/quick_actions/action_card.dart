import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/utils/responsive_utils.dart';

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = context.responsive(
      mobile: 30.0,
      tablet: 36.0,
      desktop: 38.0,
    );

    final fontSize = context.responsive(
      mobile: 12.5,
      tablet: 13.5,
      desktop: 14.0,
    );

    final cardPadding = context.responsive(
      mobile: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );

    final iconPadding = context.responsive(
      mobile: 10.0,
      tablet: 11.0,
      desktop: 12.0,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              context.responsive(mobile: 16.0, tablet: 18.0, desktop: 20.0),
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: context.responsive(
                  mobile: 12.0,
                  tablet: 16.0,
                  desktop: 20.0,
                ),
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            vertical: cardPadding,
            horizontal: context.responsive(
              mobile: 10.0,
              tablet: 12.0,
              desktop: 14.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.18),
                      color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize, color: color),
              ),

              SizedBox(
                height: context.responsive(
                  mobile: 6.0,
                  tablet: 7.0,
                  desktop: 8.0,
                ),
              ),

              // Label
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: (200 + delay).ms,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 400.ms,
          delay: (200 + delay).ms,
          curve: Curves.easeOutCubic,
        );
  }
}
