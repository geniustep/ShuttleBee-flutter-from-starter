import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';

/// Offline settings screen
class OfflineSettingsScreen extends ConsumerStatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  ConsumerState<OfflineSettingsScreen> createState() =>
      _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends ConsumerState<OfflineSettingsScreen> {
  bool _offlineModeEnabled = true;
  bool _autoSync = true;
  bool _syncOnWifiOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('offline_mode')),
      ),
      body: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          // Offline mode toggle
          Card(
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppDimensions.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.cloud_off,
                  color: AppColors.primary,
                ),
              ),
              title: const Text('Enable Offline Mode'),
              subtitle: const Text('Save data for offline access'),
              value: _offlineModeEnabled,
              onChanged: (value) {
                setState(() => _offlineModeEnabled = value);
              },
            ),
          ),

          const SizedBox(height: AppDimensions.md),

          // Auto sync
          Card(
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: AppDimensions.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.sync,
                  color: AppColors.success,
                ),
              ),
              title: const Text('Auto Sync'),
              subtitle: const Text('Automatically sync when online'),
              value: _autoSync,
              onChanged: _offlineModeEnabled
                  ? (value) {
                      setState(() => _autoSync = value);
                    }
                  : null,
            ),
          ),

          const SizedBox(height: AppDimensions.md),

          // Sync on WiFi only
          Card(
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: const BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: AppDimensions.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.wifi,
                  color: AppColors.info,
                ),
              ),
              title: const Text('Sync on WiFi Only'),
              subtitle: const Text('Save mobile data'),
              value: _syncOnWifiOnly,
              onChanged: _autoSync
                  ? (value) {
                      setState(() => _syncOnWifiOnly = value);
                    }
                  : null,
            ),
          ),

          const SizedBox(height: AppDimensions.xl),

          // Sync status info
          Card(
            child: Padding(
              padding: AppDimensions.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  const _StatusRow(
                    icon: Icons.cloud_done,
                    label: 'Last sync',
                    value: '5 minutes ago',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  const _StatusRow(
                    icon: Icons.pending_actions,
                    label: 'Pending operations',
                    value: '0',
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  const _StatusRow(
                    icon: Icons.storage,
                    label: 'Cached data',
                    value: '2.5 MB',
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.lg),

          // Sync now button
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync started...')),
              );
            },
            icon: const Icon(Icons.sync),
            label: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
