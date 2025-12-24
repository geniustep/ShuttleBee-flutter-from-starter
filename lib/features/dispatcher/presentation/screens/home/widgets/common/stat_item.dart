import 'package:bridgecore_flutter_starter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import 'package:bridgecore_flutter_starter/core/utils/responsive_utils.dart';

class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: context.responsive(mobile: 20.0, tablet: 22.0, desktop: 24.0),
        ),
        SizedBox(
          height: context.responsive(mobile: 6.0, tablet: 8.0, desktop: 10.0),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsive(
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
        SizedBox(
          height: context.responsive(mobile: 2.0, tablet: 4.0, desktop: 6.0),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive(
              mobile: 11.0,
              tablet: 12.0,
              desktop: 13.0,
            ),
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
