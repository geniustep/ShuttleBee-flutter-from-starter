import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/responsive_utils.dart';

/// Responsive drawer system that adapts based on screen size:
/// - Mobile: Standard Drawer (pull from side)
/// - Tablet: NavigationRail (compact side navigation)
/// - Desktop: NavigationRail or permanent Drawer
class ResponsiveDrawer extends ConsumerWidget {
  final Widget mobileDrawer;
  final List<NavigationRailDestination>? railDestinations;
  final int? selectedRailIndex;
  final ValueChanged<int>? onRailDestinationSelected;
  final Widget? railLeading;
  final Widget? railTrailing;

  const ResponsiveDrawer({
    super.key,
    required this.mobileDrawer,
    this.railDestinations,
    this.selectedRailIndex,
    this.onRailDestinationSelected,
    this.railLeading,
    this.railTrailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For mobile: return standard drawer
    if (context.isMobile) {
      return mobileDrawer;
    }

    // For tablet and desktop: we don't need a drawer in the Scaffold
    // because we'll show NavigationRail in the main layout
    return const SizedBox.shrink();
  }

  /// Build NavigationRail for tablet/desktop
  /// This should be placed in the body of the Scaffold
  static Widget buildNavigationRail({
    required BuildContext context,
    required List<NavigationRailDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onDestinationSelected,
    Widget? leading,
    Widget? trailing,
    bool extended = false,
  }) {
    // Only show on tablet and desktop
    if (context.isMobile) {
      return const SizedBox.shrink();
    }

    final isDesktop = context.isDesktop;

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: extended
          ? NavigationRailLabelType.none
          : (isDesktop
                ? NavigationRailLabelType.selected
                : NavigationRailLabelType.all),
      extended: extended,
      leading: leading,
      trailing: trailing,
      destinations: destinations,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 1,
      groupAlignment: -1.0,
      minWidth: isDesktop ? 72 : 64,
      minExtendedWidth: 200,
    );
  }
}

// ResponsiveScaffold has been moved to shared/widgets/responsive/responsive_scaffold.dart
// Use that version instead - it's more complete with multi-page support
