import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'drawer_header.dart';
import 'drawer_menu_item.dart';

/// App drawer for navigation
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final isOnline = ref.watch(isOnlineProvider).asData?.value ?? true;

    final user = authState.asData?.value.user;

    return Drawer(
      child: Column(
        children: [
          // Drawer header with user info
          DrawerHeaderWidget(
            userName: user?.name ?? 'User',
            userEmail: user?.email ?? '',
            companyName: user?.companyName,
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerMenuItem(
                  icon: Icons.home_outlined,
                  title: l10n.home,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RoutePaths.home);
                  },
                ),
                DrawerMenuItem(
                  icon: Icons.dashboard_outlined,
                  title: l10n.dashboard,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RoutePaths.dashboard);
                  },
                ),
                const Divider(),
                DrawerMenuItem(
                  icon: Icons.notifications_outlined,
                  title: l10n.notifications,
                  badge: '3',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RoutePaths.notifications);
                  },
                ),
                DrawerMenuItem(
                  icon: Icons.cloud_off_outlined,
                  title: l10n.translate('offline_mode'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RoutePaths.offlineStatus);
                  },
                ),
                const Divider(),
                DrawerMenuItem(
                  icon: Icons.settings_outlined,
                  title: l10n.settings,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RoutePaths.settings);
                  },
                ),
                DrawerMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    // Show help
                  },
                ),
              ],
            ),
          ),

          // Bottom section
          Container(
            padding: AppDimensions.paddingMd,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                // Sync status
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.synced : AppColors.offline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        isOnline ? 'All synced' : 'Offline mode',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    if (!isOnline)
                      TextButton(
                        onPressed: () {},
                        child: Text(l10n.sync),
                      ),
                  ],
                ),

                const SizedBox(height: AppDimensions.sm),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.logout),
                          content: Text(l10n.translate('logout_confirm')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.logout),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) {
                          context.go(RoutePaths.login);
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.logout),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
