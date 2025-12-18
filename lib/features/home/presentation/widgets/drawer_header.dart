import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Drawer header with user info
class DrawerHeaderWidget extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? companyName;

  const DrawerHeaderWidget({
    super.key,
    required this.userName,
    required this.userEmail,
    this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: context.isDesktop ? 24 : (MediaQuery.of(context).padding.top + AppDimensions.lg),
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with enhanced shadow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: context.responsive(
                mobile: 36.0,
                tablet: 40.0,
                desktop: 42.0,
              ),
              backgroundColor: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: context.responsive(
                    mobile: 34.0,
                    tablet: 38.0,
                    desktop: 40.0,
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    _getInitials(userName),
                    style: TextStyle(
                      fontSize: context.responsive(
                        mobile: 24.0,
                        tablet: 26.0,
                        desktop: 28.0,
                      ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(
            height: context.responsive(
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
          ),

          // User name with enhanced styling
          Text(
            userName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsive(
                    mobile: 18.0,
                    tablet: 19.0,
                    desktop: 20.0,
                  ),
                  fontFamily: 'Cairo',
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Email with icon
          if (userEmail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: context.responsive(
                    mobile: 14.0,
                    tablet: 15.0,
                    desktop: 16.0,
                  ),
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    userEmail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: context.responsive(
                            mobile: 12.0,
                            tablet: 13.0,
                            desktop: 13.0,
                          ),
                          fontFamily: 'Cairo',
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Company badge with enhanced design
          if (companyName != null && companyName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                ),
                vertical: context.responsive(
                  mobile: 6.0,
                  tablet: 7.0,
                  desktop: 8.0,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: context.responsive(
                      mobile: 14.0,
                      tablet: 15.0,
                      desktop: 16.0,
                    ),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      companyName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: context.responsive(
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 13.0,
                            ),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
