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
/// Home / Monitor / Trips / Groups / Vehicles
class DispatcherShellScreen extends StatelessWidget {
  const DispatcherShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  // Custom glass bar (not using BottomNavigationBar) to avoid its built-in
  // vertical padding/constraints that caused overflows and "fat" UI.
  static const double _barHeight = 90;
  static const double _barBackgroundHeight = 66;
  static const double _barHorizontalPadding = 20;
  static const double _barBottomGap = 10;
  static const double _selectedLift = 22;

  // We want "Home" to be the middle tab visually.
  // Tabs order: Monitor, Trips, Home, Groups, Vehicles
  // Branch indices (from router): Home=0, Monitor=1, Trips=2, Groups=3, Vehicles=4
  static const List<int> _branchByTab = <int>[1, 2, 0, 3, 4];

  static const _icons = <IconData>[
    Icons.map,
    Icons.route,
    Icons.home,
    Icons.groups,
    Icons.directions_bus,
  ];

  int _tabIndexForBranch(int branchIndex) {
    final idx = _branchByTab.indexOf(branchIndex);
    return idx == -1 ? 2 : idx; // fallback to middle (Home)
  }

  void _onDestinationSelected(int tabIndex) {
    final branchIndex = _branchByTab[tabIndex];
    navigationShell.goBranch(
      branchIndex,
      // If re-selecting the current tab, reset to its root.
      // If switching tabs, keep each tab's stack intact.
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  Widget _getIcon(IconData icon, int index) {
    final branchIndex = _branchByTab[index];
    final isSelected = navigationShell.currentIndex == branchIndex;

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
      child: Icon(icon, size: 26, color: Colors.white),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform:
          Matrix4.translationValues(0, isSelected ? -_selectedLift : 0, 0),
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
  List<String> _getLabels(AppLocalizations l10n) => [
        l10n.monitor,
        l10n.trips,
        l10n.home,
        l10n.groups,
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
    final selectedTabIndex = _tabIndexForBranch(navigationShell.currentIndex);

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
        child: context.isMobile
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
                                  onTap: () => _onDestinationSelected(index),
                                  radius: 28,
                                  highlightShape: BoxShape.circle,
                                  splashColor:
                                      Colors.white.withValues(alpha: 0.08),
                                  child: Center(
                                    child: _getIcon(_icons[index], index),
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
    final labels = _getLabels(l10n);
    final isDesktop = context.isDesktop;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail or Drawer based on screen size
          if (isDesktop)
            NavigationDrawer(
              selectedIndex: selectedTabIndex,
              onDestinationSelected: _onDestinationSelected,
              backgroundColor: AppColors.dispatcherPrimary.withValues(alpha: 0.05),
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.dispatcherGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.dispatcher,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.dispatcherPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...List.generate(_icons.length, (index) {
                  return NavigationDrawerDestination(
                    icon: Icon(_icons[index]),
                    selectedIcon: Icon(_icons[index]),
                    label: Text(labels[index]),
                  );
                }),
              ],
            )
          else
            NavigationRail(
              selectedIndex: selectedTabIndex,
              onDestinationSelected: _onDestinationSelected,
              backgroundColor: AppColors.dispatcherPrimary.withValues(alpha: 0.05),
              labelType: NavigationRailLabelType.all,
              leading: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.dispatcherGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              destinations: List.generate(_icons.length, (index) {
                return NavigationRailDestination(
                  icon: Icon(_icons[index]),
                  selectedIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.dispatcherPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _icons[index],
                      color: AppColors.dispatcherPrimary,
                    ),
                  ),
                  label: Text(labels[index]),
                );
              }),
            ),
          const VerticalDivider(width: 1, thickness: 1),
          // Main content
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
