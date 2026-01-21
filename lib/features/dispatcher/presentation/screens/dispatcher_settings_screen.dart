import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../l10n/app_localizations.dart';

/// Dispatcher Settings Screen - شاشة الإعدادات للمرسل - ShuttleBee
/// تجمع العناصر الإضافية: المرافقون، السائقون
class DispatcherSettingsScreen extends StatelessWidget {
  const DispatcherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RoutePaths.dispatcherHome);
      },
      child: Scaffold(
        backgroundColor: AppColors.dispatcherBackground,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 16,
                  20,
                  24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.dispatcherPrimary,
                      AppColors.dispatcherPrimaryMid,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dispatcherPrimary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.settings,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'إدارة الموارد والموظفين والعطل',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Settings Categories
                  _buildSettingsSection(
                    context,
                    title: 'إدارة الموظفين',
                    items: [
                      _SettingsItem(
                        icon: Icons.person_add_alt_rounded,
                        title: l10n.attendants,
                        subtitle: 'إدارة المرافقين',
                        route: RoutePaths.dispatcherAttendants,
                        color: AppColors.primary,
                      ),
                      _SettingsItem(
                        icon: Icons.person_rounded,
                        title: l10n.drivers,
                        subtitle: 'إدارة السائقين',
                        route: RoutePaths.dispatcherDrivers,
                        color: AppColors.success,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // إدارة الموارد
                  _buildSettingsSection(
                    context,
                    title: 'إدارة الموارد',
                    items: [
                      _SettingsItem(
                        icon: Icons.location_on_rounded,
                        title: 'المحطات',
                        subtitle: 'إدارة نقاط التوقف',
                        route: RoutePaths.dispatcherStops,
                        color: AppColors.primary,
                      ),
                      _SettingsItem(
                        icon: Icons.directions_bus_rounded,
                        title: l10n.vehicles,
                        subtitle: 'إدارة المركبات',
                        route: RoutePaths.dispatcherVehicles,
                        color: AppColors.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // إدارة العطل والتقويم
                  _buildSettingsSection(
                    context,
                    title: 'إدارة العطل والتقويم',
                    items: [
                      _SettingsItem(
                        icon: Icons.calendar_today_rounded,
                        title: l10n.holidays,
                        subtitle: 'إدارة العطل الرسمية',
                        route: RoutePaths.dispatcherHolidays,
                        color: AppColors.info,
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        ...items.map((item) => _buildSettingsCard(context, item)),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context, _SettingsItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go(item.route);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
                width: 1,
              ),
              gradient: LinearGradient(
                colors: [
                  item.color.withValues(alpha: 0.05),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        item.color,
                        item.color.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.1, end: 0, duration: 300.ms),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
}

