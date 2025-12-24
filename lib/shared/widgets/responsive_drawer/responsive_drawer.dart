import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

/// Responsive drawer system that adapts to different screen sizes
///
/// - Mobile: Standard Drawer (من اليسار/اليمين)
/// - Tablet: NavigationRail مع إمكانية التوسع
/// - Desktop: NavigationRail دائم الظهور
class ResponsiveDrawer extends StatelessWidget {
  final Widget child;
  final Widget drawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool showNavigationRail;

  const ResponsiveDrawer({
    super.key,
    required this.child,
    required this.drawer,
    this.scaffoldKey,
    this.showNavigationRail = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    // للجوال: Drawer عادي
    if (context.isMobile) {
      return child;
    }

    // للتابلت والحاسوب: استخدم NavigationRail
    if (showNavigationRail && (isTablet || isDesktop)) {
      return Row(
        children: [
          // NavigationRail على اليسار (للـ LTR) أو اليمين (للـ RTL)
          drawer,
          // المحتوى الرئيسي
          Expanded(child: child),
        ],
      );
    }

    return child;
  }
}

/// Layout builder للـ ResponsiveDrawer
class ResponsiveDrawerLayout extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? endDrawer;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const ResponsiveDrawerLayout({
    super.key,
    this.appBar,
    required this.body,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    // للجوال: استخدم Scaffold عادي
    if (isMobile) {
      return Scaffold(
        key: scaffoldKey,
        appBar: appBar,
        drawer: drawer,
        endDrawer: endDrawer,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        backgroundColor: backgroundColor,
      );
    }

    // للتابلت والحاسوب: استخدم NavigationRail
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // NavigationRail على اليسار
          if (drawer != null) drawer!,
          // المحتوى الرئيسي
          Expanded(
            child: Scaffold(
              appBar: appBar,
              endDrawer: endDrawer,
              body: body,
              floatingActionButton: floatingActionButton,
              floatingActionButtonLocation: floatingActionButtonLocation,
              backgroundColor: backgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
