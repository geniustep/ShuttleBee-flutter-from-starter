import 'package:bridgecore_flutter_starter/core/theme/app_colors.dart';
import 'package:bridgecore_flutter_starter/core/theme/app_typography.dart';
import 'package:bridgecore_flutter_starter/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// A unified gradient AppBar for Dispatcher screens.
///
/// This reduces visual inconsistency across dispatcher tabs and gives a more
/// "console-like" look & feel.
///
/// Features:
/// - Responsive design with adaptive sizing
/// - Gradient background matching dispatcher theme
/// - Support for custom actions, bottom widgets, and leading widgets
/// - Optional subtitle for additional context
class DispatcherAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DispatcherAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.elevation = 0,
    this.showShadow = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final double elevation;
  final bool showShadow;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      elevation: elevation,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: subtitle != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: context.responsive(
                      mobile: 18.0,
                      tablet: 20.0,
                      desktop: 22.0,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: context.responsive(
                      mobile: 11.0,
                      tablet: 12.0,
                      desktop: 13.0,
                    ),
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: AppTypography.h6.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: context.responsive(
                  mobile: 18.0,
                  tablet: 20.0,
                  desktop: 22.0,
                ),
              ),
            ),
      actions: actions.map((action) {
        // Wrap actions with responsive padding
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(
              mobile: 2.0,
              tablet: 4.0,
              desktop: 6.0,
            ),
          ),
          child: action,
        );
      }).toList(),
      bottom: bottom,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppColors.dispatcherGradient,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: AppColors.dispatcherPrimary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
