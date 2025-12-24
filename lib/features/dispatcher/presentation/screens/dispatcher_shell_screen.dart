import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../l10n/app_localizations.dart';

/// Dispatcher Shell Screen
///
/// Provides a persistent bottom navigation experience for Dispatcher workflow:
/// Desktop: Home / Monitor / Trips / Groups / Passengers / Vehicles
/// Mobile: Monitor / Trips / Home / Groups / Vehicles (Passengers accessible from Home)
class DispatcherShellScreen extends StatelessWidget {
  const DispatcherShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Custom glass bar (not using BottomNavigationBar) to avoid its built-in
  // vertical padding/constraints that caused overflows and "fat" UI.
  static const double _barHeight = 90;
  static const double _barBackgroundHeight = 66;
  static const double _barHorizontalPadding = 20;
  static const double _barBottomGap = 10;
  static const double _selectedLift = 22;

  // We want "Home" to be the middle tab visually on mobile.
  // Mobile tabs order: Monitor, Trips, Home, Groups, Vehicles
  // Branch indices (from router): Home=0, Monitor=1, Trips=2, Groups=3, Passengers=4, Vehicles=5
  static const List<int> _branchByTab = <int>[1, 2, 0, 3, 5];

  // For desktop/tablet, Home should be first
  // Desktop tabs order: Home, Monitor, Trips, Groups, Passengers, Vehicles
  static const List<int> _branchByTabDesktop = <int>[0, 1, 2, 3, 4, 5];

  static const _icons = <IconData>[
    Icons.map,
    Icons.route,
    Icons.home,
    Icons.groups,
    Icons.directions_bus,
  ];

  // Desktop icons order (Home first)
  static const _iconsDesktop = <IconData>[
    Icons.home,
    Icons.map,
    Icons.route,
    Icons.groups,
    Icons.people,
    Icons.directions_bus,
  ];

  static const _selectedIcons = <IconData>[
    Icons.map_rounded,
    Icons.route_rounded,
    Icons.home_rounded,
    Icons.groups_rounded,
    Icons.directions_bus_rounded,
  ];

  // Desktop selected icons order (Home first)
  static const _selectedIconsDesktop = <IconData>[
    Icons.home_rounded,
    Icons.map_rounded,
    Icons.route_rounded,
    Icons.groups_rounded,
    Icons.people_rounded,
    Icons.directions_bus_rounded,
  ];

  int _tabIndexForBranch(int branchIndex, bool isMobile) {
    final mapping = isMobile ? _branchByTab : _branchByTabDesktop;
    final idx = mapping.indexOf(branchIndex);
    return idx == -1 ? (isMobile ? 2 : 0) : idx; // fallback to Home
  }

  void _onDestinationSelected(int tabIndex, bool isMobile) {
    final mapping = isMobile ? _branchByTab : _branchByTabDesktop;
    final branchIndex = mapping[tabIndex];
    navigationShell.goBranch(
      branchIndex,
      // If re-selecting the current tab, reset to its root.
      // If switching tabs, keep each tab's stack intact.
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  Widget _getIcon(IconData icon, int index, bool isMobile) {
    final mapping = isMobile ? _branchByTab : _branchByTabDesktop;
    final branchIndex = mapping[index];
    final isSelected = navigationShell.currentIndex == branchIndex;

    // Use selected icon when item is selected
    final iconToUse = isSelected
        ? (isMobile ? _selectedIcons : _selectedIconsDesktop)[index]
        : icon;

    final iconContent = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.white : Colors.transparent,
          width: 4,
        ),
        color: isSelected
            ? AppColors.dispatcherPrimary.withValues(alpha: 0.28)
            : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(iconToUse, size: 26, color: Colors.white),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: Matrix4.translationValues(
        0,
        isSelected ? -_selectedLift : 0,
        0,
      ),
      curve: Curves.easeOut,
      child: isSelected
          ? ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: iconContent,
              ),
            )
          : iconContent,
    );
  }

  // Navigation labels for desktop/tablet
  List<String> _getLabels(AppLocalizations l10n, bool isMobile) => isMobile
      ? [l10n.monitor, l10n.trips, l10n.home, l10n.groups, l10n.vehicles]
      : [
          l10n.home,
          l10n.monitor,
          l10n.trips,
          l10n.groups,
          l10n.passengers,
          l10n.vehicles,
        ];

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Local theme override to make Dispatcher navigation use Dispatcher palette
    // without affecting the global app theme.
    final themed = baseTheme.copyWith(
      navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
        indicatorColor: AppColors.dispatcherPrimary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return AppTypography.labelSmall.copyWith(
            color: isSelected
                ? AppColors.dispatcherPrimary
                : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? AppColors.dispatcherPrimary
                : AppColors.textSecondary,
          );
        }),
      ),
    );

    final allowExitFromDispatcher = navigationShell.currentIndex == 0;
    final isMobile = context.isMobile;
    final selectedTabIndex = _tabIndexForBranch(
      navigationShell.currentIndex,
      isMobile,
    );

    return Theme(
      data: themed,
      child: PopScope(
        canPop: allowExitFromDispatcher,
        onPopInvoked: (didPop) {
          if (didPop) return;
          if (navigationShell.currentIndex != 0) {
            navigationShell.goBranch(0, initialLocation: true);
          }
        },
        child: isMobile
            ? _buildMobileLayout(context, selectedTabIndex)
            : _buildDesktopLayout(context, l10n, selectedTabIndex),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, int selectedTabIndex) {
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: keyboardOpen
          ? null
          : Theme(
              data: Theme.of(context).copyWith(
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
              child: SizedBox(
                height: _barHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: _barHorizontalPadding,
                      right: _barHorizontalPadding,
                      bottom: _barBottomGap + media.padding.bottom,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            height: _barBackgroundHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.12),
                                  Colors.white.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _barHorizontalPadding,
                      right: _barHorizontalPadding,
                      bottom: _barBottomGap + media.padding.bottom,
                      height: _barBackgroundHeight,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Row(
                          children: List.generate(_icons.length, (index) {
                            final isSelected = index == selectedTabIndex;
                            return Expanded(
                              child: Semantics(
                                button: true,
                                selected: isSelected,
                                label: 'dispatcher_tab_$index',
                                child: InkResponse(
                                  onTap: () =>
                                      _onDestinationSelected(index, true),
                                  radius: 28,
                                  highlightShape: BoxShape.circle,
                                  splashColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: Center(
                                    child: _getIcon(_icons[index], index, true),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations l10n,
    int selectedTabIndex,
  ) {
    final labels = _getLabels(l10n, false);
    final isDesktop = context.isDesktop;
    const icons = _iconsDesktop;
    const selectedIcons = _selectedIconsDesktop;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail or Drawer based on screen size
          if (isDesktop)
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
                selectedIndex: selectedTabIndex,
                onDestinationSelected: (index) =>
                    _onDestinationSelected(index, false),
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
                                color: AppColors.dispatcherPrimary.withValues(
                                  alpha: 0.3,
                                ),
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
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
                      isSelected: index == selectedTabIndex,
                      onTap: () => _onDestinationSelected(index, false),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            )
          else
            SizedBox(
              width: 120,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.dispatcherBackground,
                  border: Border(
                    right: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: NavigationRail(
                  selectedIndex: selectedTabIndex,
                  onDestinationSelected: (index) =>
                      _onDestinationSelected(index, false),
                  backgroundColor: Colors.transparent,
                  labelType: NavigationRailLabelType.all,
                  leading: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.dispatcherGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dispatcherPrimary.withValues(
                            alpha: 0.3,
                          ),
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
                  destinations: List.generate(icons.length, (index) {
                    final isSelected = index == selectedTabIndex;
                    return NavigationRailDestination(
                      icon: Icon(icons[index], color: AppColors.textSecondary),
                      selectedIcon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.dispatcherPrimary.withValues(
                                alpha: 0.2,
                              ),
                              AppColors.dispatcherPrimary.withValues(
                                alpha: 0.1,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.dispatcherPrimary.withValues(
                              alpha: 0.3,
                            ),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dispatcherPrimary.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          selectedIcons[index],
                          color: AppColors.dispatcherPrimary,
                          size: 24,
                        ),
                      ),
                      label: Text(
                        labels[index],
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.dispatcherPrimary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
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
          // Main content
          Expanded(child: navigationShell),
        ],
      ),
    );
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
                    color: AppColors.dispatcherPrimary.withValues(alpha: 0.2),
                    width: 1,
                  )
                : null,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.dispatcherPrimary.withValues(
                        alpha: 0.15,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: AppColors.dispatcherPrimary.withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
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
                      ? const LinearGradient(
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
                            color: AppColors.dispatcherPrimary.withValues(
                              alpha: 0.3,
                            ),
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
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
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
                        color: AppColors.dispatcherPrimary.withValues(
                          alpha: 0.4,
                        ),
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
