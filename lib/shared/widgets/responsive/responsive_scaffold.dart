import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

/// Navigation item for responsive scaffold
class ResponsiveNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final Widget? badge;

  const ResponsiveNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badge,
  });
}

/// A responsive scaffold that adapts navigation based on screen size
/// Mobile: Bottom navigation bar
/// Tablet: Navigation rail
/// Desktop: Navigation drawer
class ResponsiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ResponsiveNavItem> destinations;
  final List<Widget> pages;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final Color? navigationBackgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Widget? drawerHeader;
  final List<Widget>? drawerFooterItems;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.pages,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.navigationBackgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerHeader,
    this.drawerFooterItems,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = context.deviceType;

    switch (deviceType) {
      case DeviceType.desktop:
        return _buildDesktopLayout(context);
      case DeviceType.tablet:
        return _buildTabletLayout(context);
      case DeviceType.mobile:
        return _buildMobileLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: pages[currentIndex],
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: navigationBackgroundColor,
        destinations: destinations
            .map(
              (item) => NavigationDestination(
                icon: item.badge != null
                    ? Badge(
                        label: item.badge,
                        child: Icon(item.icon),
                      )
                    : Icon(item.icon),
                selectedIcon: item.badge != null
                    ? Badge(
                        label: item.badge,
                        child: Icon(item.selectedIcon ?? item.icon),
                      )
                    : Icon(item.selectedIcon ?? item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            backgroundColor: navigationBackgroundColor,
            labelType: NavigationRailLabelType.all,
            destinations: destinations
                .map(
                  (item) => NavigationRailDestination(
                    icon: item.badge != null
                        ? Badge(
                            label: item.badge,
                            child: Icon(item.icon),
                          )
                        : Icon(item.icon),
                    selectedIcon: item.badge != null
                        ? Badge(
                            label: item.badge,
                            child: Icon(item.selectedIcon ?? item.icon),
                          )
                        : Icon(item.selectedIcon ?? item.icon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: pages[currentIndex]),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            backgroundColor: navigationBackgroundColor,
            children: [
              if (drawerHeader != null) ...[
                drawerHeader!,
                const Divider(),
              ] else
                const SizedBox(height: 16),
              ...destinations.map(
                (item) => NavigationDrawerDestination(
                  icon: item.badge != null
                      ? Badge(
                          label: item.badge,
                          child: Icon(item.icon),
                        )
                      : Icon(item.icon),
                  selectedIcon: item.badge != null
                      ? Badge(
                          label: item.badge,
                          child: Icon(item.selectedIcon ?? item.icon),
                        )
                      : Icon(item.selectedIcon ?? item.icon),
                  label: Text(item.label),
                ),
              ),
              if (drawerFooterItems != null) ...[
                const Spacer(),
                const Divider(),
                ...drawerFooterItems!,
              ],
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: pages[currentIndex]),
        ],
      ),
    );
  }
}

/// A simple responsive app bar that adapts title and actions
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;
  final bool centerTitle;
  final double? toolbarHeight;

  const ResponsiveAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.elevation,
    this.backgroundColor,
    this.centerTitle = false,
    this.toolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      elevation: elevation,
      backgroundColor: backgroundColor,
      centerTitle: context.isMobile ? true : centerTitle,
      toolbarHeight: toolbarHeight,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0),
      );
}

/// A responsive sliver app bar
class ResponsiveSliverAppBar extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? flexibleSpace;
  final double? expandedHeight;
  final double? collapsedHeight;
  final bool pinned;
  final bool floating;
  final bool snap;
  final Color? backgroundColor;

  const ResponsiveSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.flexibleSpace,
    this.expandedHeight,
    this.collapsedHeight,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveExpandedHeight = context.responsive(
      mobile: expandedHeight ?? 200,
      tablet: expandedHeight != null ? expandedHeight! * 1.2 : 240,
      desktop: expandedHeight != null ? expandedHeight! * 1.3 : 280,
    );

    return SliverAppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      leading: leading,
      flexibleSpace: flexibleSpace,
      expandedHeight: responsiveExpandedHeight,
      collapsedHeight: collapsedHeight,
      pinned: pinned,
      floating: floating,
      snap: snap,
      backgroundColor: backgroundColor,
      centerTitle: context.isMobile,
    );
  }
}

/// A dialog that adapts its size based on screen size
class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final double? maxWidth;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? actionsPadding;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.maxWidth,
    this.contentPadding,
    this.titlePadding,
    this.actionsPadding,
  });

  @override
  Widget build(BuildContext context) {
    final dialogWidth = maxWidth ?? ResponsiveUtils.dialogWidth(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: context.screenHeight * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: titlePadding ??
                    const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: contentPadding ?? const EdgeInsets.all(24),
                child: child,
              ),
            ),
            if (actions != null)
              Padding(
                padding: actionsPadding ??
                    const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Show a responsive bottom sheet on mobile, dialog on larger screens
Future<T?> showResponsiveModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  String? title,
  bool isDismissible = true,
  bool useRootNavigator = true,
  double? maxWidth,
}) {
  if (context.isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    builder: (context) => ResponsiveDialog(
      title: title,
      maxWidth: maxWidth,
      child: builder(context),
    ),
  );
}
