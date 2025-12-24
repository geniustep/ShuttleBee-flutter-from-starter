import 'package:bridgecore_flutter_starter/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';


class LiveIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const LiveIndicator({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: context.responsive(mobile: 24.0, tablet: 26.0, desktop: 28.0),
        ),
        SizedBox(
          height: context.responsive(mobile: 6.0, tablet: 8.0, desktop: 10.0),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsive(
              mobile: 18.0,
              tablet: 20.0,
              desktop: 22.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive(
              mobile: 11.0,
              tablet: 12.0,
              desktop: 13.0,
            ),
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
