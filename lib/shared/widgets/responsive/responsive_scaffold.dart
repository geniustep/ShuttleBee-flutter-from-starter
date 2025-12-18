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
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: navigationBackgroundColor ?? theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: NavigationDrawer(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              backgroundColor: Colors.transparent,
              elevation: 0,
              children: [
                if (drawerHeader != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: drawerHeader!,
                  ),
                  const Divider(height: 1),
                ] else
                  const SizedBox(height: 16),
                const SizedBox(height: 8),
                ...destinations.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                    child: _DesktopNavItem(
                      item: entry.value,
                      isSelected: entry.key == currentIndex,
                      onTap: () => onDestinationSelected(entry.key),
                    ),
                  ),
                ),
                if (drawerFooterItems != null) ...[
                  const Spacer(),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...drawerFooterItems!,
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Container(
            width: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.withValues(alpha: 0.1),
                  Colors.grey.withValues(alpha: 0.2),
                  Colors.grey.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          Expanded(child: pages[currentIndex]),
        ],
      ),
    );
  }
}

/// Custom Desktop Navigation Item with Hover Effects
class _DesktopNavItem extends StatefulWidget {
  final ResponsiveNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DesktopNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DesktopNavItem> createState() => _DesktopNavItemState();
}

class _DesktopNavItemState extends State<_DesktopNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colorScheme.primaryContainer
                : _isHovered
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.isSelected
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : _isHovered
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.item.badge != null
                    ? Badge(
                        label: widget.item.badge,
                        child: Icon(
                          widget.isSelected
                              ? (widget.item.selectedIcon ?? widget.item.icon)
                              : widget.item.icon,
                          color: widget.isSelected
                              ? colorScheme.primary
                              : _isHovered
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      )
                    : Icon(
                        widget.isSelected
                            ? (widget.item.selectedIcon ?? widget.item.icon)
                            : widget.item.icon,
                        color: widget.isSelected
                            ? colorScheme.primary
                            : _isHovered
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: widget.isSelected
                        ? colorScheme.onPrimaryContainer
                        : _isHovered
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              if (widget.isSelected)
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
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
    final responsiveExpandedHeight = context.responsive<double>(
      mobile: expandedHeight ?? 200.0,
      tablet: expandedHeight != null ? (expandedHeight! * 1.2) : 240.0,
      desktop: expandedHeight != null ? (expandedHeight! * 1.3) : 280.0,
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
                padding:
                    titlePadding ?? const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
                padding:
                    actionsPadding ?? const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
