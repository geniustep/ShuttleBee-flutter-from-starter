import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// A unified gradient AppBar for Dispatcher screens.
///
/// This reduces visual inconsistency across dispatcher tabs and gives a more
/// "console-like" look & feel.
class DispatcherAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DispatcherAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Text(
        title,
        style: AppTypography.h6.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
      bottom: bottom,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.dispatcherGradient,
        ),
      ),
    );
  }
}
