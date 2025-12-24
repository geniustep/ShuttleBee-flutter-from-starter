import 'package:bridgecore_flutter_starter/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';


class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.responsive(
          mobile: 150.0,
          tablet: 180.0,
          desktop: 200.0,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive(
          mobile: 8.0,
          tablet: 10.0,
          desktop: 12.0,
        ),
        vertical: context.responsive(mobile: 4.0, tablet: 6.0, desktop: 8.0),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: context.responsive(mobile: 14.0, tablet: 15.0, desktop: 16.0),
            color: color,
          ),
          SizedBox(
            width: context.responsive(mobile: 4.0, tablet: 6.0, desktop: 8.0),
          ),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.responsive(
                  mobile: 11.0,
                  tablet: 12.0,
                  desktop: 13.0,
                ),
                color: color,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
