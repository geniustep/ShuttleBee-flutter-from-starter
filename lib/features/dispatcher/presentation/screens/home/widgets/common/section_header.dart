import 'package:bridgecore_flutter_starter/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

import 'package:bridgecore_flutter_starter/core/utils/responsive_utils.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(
            context.responsive(mobile: 10.0, tablet: 12.0, desktop: 14.0),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              context.responsive(mobile: 12.0, tablet: 14.0, desktop: 16.0),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: context.responsive(mobile: 22.0, tablet: 24.0, desktop: 26.0),
          ),
        ),
        SizedBox(
          width: context.responsive(mobile: 12.0, tablet: 16.0, desktop: 20.0),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsive(
                    mobile: 18.0,
                    tablet: 20.0,
                    desktop: 22.0,
                  ),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF6B7280),
                    fontSize: context.responsive(
                      mobile: 12.0,
                      tablet: 13.0,
                      desktop: 14.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
