import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/global_providers.dart';

/// Offline status screen
class OfflineStatusScreen extends ConsumerWidget {
  const OfflineStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('offline_mode')),
      ),
      body: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          // Connection status card
          Card(
            child: Padding(
              padding: AppDimensions.paddingLg,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      size: 48,
                      color: isOnline ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    isOnline ? l10n.online : l10n.offline,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOnline ? AppColors.success : AppColors.error,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.xxs),
                  Text(
                    isOnline ? 'All data is synced' : 'Working with local data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.lg),

          // Sync status
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.cloud_done, color: AppColors.success),
                  title: const Text('Last Sync'),
                  subtitle: const Text('5 minutes ago'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.pending, color: AppColors.warning),
                  title: Text(l10n.translate('pending_operations')),
                  subtitle: const Text('0 operations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RoutePaths.pendingOperations),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage, color: AppColors.info),
                  title: const Text('Cached Data'),
                  subtitle: const Text('2.5 MB'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.lg),

          // Sync button
          ElevatedButton.icon(
            onPressed: isOnline
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.translate('syncing'))),
                    );
                  }
                : null,
            icon: const Icon(Icons.sync),
            label: Text(l10n.sync),
          ),

          const SizedBox(height: AppDimensions.sm),

          // Clear cache button
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Cache'),
                  content: const Text(
                    'This will remove all cached data. Are you sure?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared')),
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }
}
