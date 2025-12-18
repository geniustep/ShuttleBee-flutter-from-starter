import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../l10n/app_localizations.dart';

/// Desktop Sidebar Wrapper
/// يضيف القائمة الجانبية على Desktop لجميع الصفحات
class DesktopSidebarWrapper extends StatelessWidget {
  const DesktopSidebarWrapper({
    super.key,
    required this.child,
    this.showSidebar = true,
  });

  final Widget child;
  final bool showSidebar;

  @override
  Widget build(BuildContext context) {
    // إذا لم تكن desktop أو showSidebar = false، نعرض المحتوى فقط
    if (!context.isDesktop || !showSidebar) {
      return child;
    }

    return _DesktopSidebar(child: child);
  }
}

/// Desktop Scaffold with Sidebar
/// Scaffold مع القائمة الجانبية على Desktop
class DesktopScaffoldWithSidebar extends StatelessWidget {
  const DesktopScaffoldWithSidebar({
    super.key,
    required this.body,
    this.appBar,
    this.backgroundColor,
    this.showSidebar = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final bool showSidebar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    if (!context.isDesktop || !showSidebar) {
      return Scaffold(
        appBar: appBar,
        body: body,
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    }

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: _DesktopSidebar(child: body),
    );
  }
}

/// Internal Desktop Sidebar Implementation
class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // الحصول على المسار الحالي لتحديد العنصر المحدد
    final currentPath = GoRouterState.of(context).uri.path;
    final selectedIndex = _getSelectedIndexFromPath(currentPath);
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.monitor,
      l10n.trips,
      l10n.home,
      l10n.groups,
      l10n.vehicles,
    ];

    // نفس الأيقونات من DispatcherShellScreen
    const icons = <IconData>[
      Icons.map,
      Icons.route,
      Icons.home,
      Icons.groups,
      Icons.directions_bus,
    ];

    const selectedIcons = <IconData>[
      Icons.map_rounded,
      Icons.route_rounded,
      Icons.home_rounded,
      Icons.groups_rounded,
      Icons.directions_bus_rounded,
    ];

    // Branch paths (من DispatcherShellScreen)
    // Monitor=0, Trips=1, Home=2, Groups=3, Vehicles=4
    const branchPaths = [
      RoutePaths.dispatcherMonitor, // 0 - Monitor
      RoutePaths.dispatcherTrips, // 1 - Trips
      RoutePaths.dispatcherHome, // 2 - Home
      RoutePaths.dispatcherGroups, // 3 - Groups
      RoutePaths.dispatcherVehicles, // 4 - Vehicles
    ];

    return Row(
      children: [
        // Sidebar
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.dispatcherBackground,
            border: Border(
              right: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.dispatcherPrimary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              final targetPath = branchPaths[index];
              context.go(targetPath);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.dispatcherGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.dispatcherPrimary
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.dispatcher,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.dispatcherPrimary,
                              fontFamily: 'Cairo',
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 32,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              const SizedBox(height: 8),
              ...List.generate(icons.length, (index) {
                return _CustomNavigationDrawerItem(
                  icon: icons[index],
                  selectedIcon: selectedIcons[index],
                  label: labels[index],
                  isSelected: index == selectedIndex,
                  onTap: () {
                    final targetPath = branchPaths[index];
                    context.go(targetPath);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Divider
        Container(
          width: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.border.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Content
        Expanded(child: child),
      ],
    );
  }

  int _getSelectedIndexFromPath(String path) {
    // Monitor=0, Trips=1, Home=2, Groups=3, Vehicles=4
    // ترتيب الفحص مهم - يجب أن نفحص المسارات الأكثر تحديداً أولاً
    if (path.contains('/monitor')) return 0;
    if (path.contains('/trips')) return 1;
    if (path.contains('/groups')) return 3;
    if (path.contains('/vehicles')) return 4;
    // Default to Home for /dispatcher and paths that don't match above
    if (path == RoutePaths.dispatcherHome ||
        path == '/dispatcher' ||
        (path.startsWith('/dispatcher') &&
            !path.contains('/monitor') &&
            !path.contains('/trips') &&
            !path.contains('/groups') &&
            !path.contains('/vehicles') &&
            !path.contains('/passengers') &&
            !path.contains('/holidays'))) {
      return 2; // Home
    }
    return 2; // Default to Home
  }
}

/// Custom Navigation Drawer Item with Hover Effects
class _CustomNavigationDrawerItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomNavigationDrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CustomNavigationDrawerItem> createState() =>
      _CustomNavigationDrawerItemState();
}

class _CustomNavigationDrawerItemState
    extends State<_CustomNavigationDrawerItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.dispatcherPrimary.withValues(alpha: 0.15),
                      AppColors.dispatcherPrimary.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : _isHovered
                    ? LinearGradient(
                        colors: [
                          AppColors.dispatcherPrimary.withValues(alpha: 0.08),
                          AppColors.dispatcherPrimary.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
            color: widget.isSelected || _isHovered ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: widget.isSelected
                ? Border.all(
                    color: AppColors.dispatcherPrimary.withValues(alpha: 0.4),
                    width: 1.5,
                  )
                : _isHovered
                    ? Border.all(
                        color:
                            AppColors.dispatcherPrimary.withValues(alpha: 0.2),
                        width: 1,
                      )
                    : null,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color:
                          AppColors.dispatcherPrimary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color:
                          AppColors.dispatcherPrimary.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : _isHovered
                    ? [
                        BoxShadow(
                          color: AppColors.dispatcherPrimary
                              .withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.dispatcherPrimary,
                            AppColors.dispatcherPrimaryMid,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.isSelected
                      ? null
                      : _isHovered
                          ? AppColors.dispatcherPrimary.withValues(alpha: 0.12)
                          : AppColors.dispatcherPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.dispatcherPrimary
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.isSelected ? widget.selectedIcon : widget.icon,
                  color: widget.isSelected
                      ? Colors.white
                      : _isHovered
                          ? AppColors.dispatcherPrimary
                          : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isSelected
                        ? AppColors.dispatcherPrimary
                        : _isHovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              if (widget.isSelected)
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: AppColors.dispatcherGradient,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.dispatcherPrimary.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
