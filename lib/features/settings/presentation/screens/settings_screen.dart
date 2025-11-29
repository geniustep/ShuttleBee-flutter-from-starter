import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/global_providers.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          // Account section
          SettingsSection(
            title: 'Account',
            children: [
              SettingsTile(
                icon: Icons.person_outline,
                title: l10n.profile,
                subtitle: 'Manage your profile information',
                onTap: () => context.push(RoutePaths.profile),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),

          // Appearance section
          SettingsSection(
            title: l10n.translate('appearance'),
            children: [
              SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: l10n.translate('theme'),
                subtitle: _getThemeModeText(themeMode),
                onTap: () => _showThemeDialog(context, ref),
              ),
              SettingsTile(
                icon: Icons.language_outlined,
                title: l10n.translate('language'),
                subtitle: locale.languageCode == 'en' ? 'English' : 'العربية',
                onTap: () => _showLanguageDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),

          // Data & Sync section
          SettingsSection(
            title: 'Data & Sync',
            children: [
              SettingsTile(
                icon: Icons.cloud_sync_outlined,
                title: l10n.translate('offline_mode'),
                subtitle: 'Manage offline settings',
                onTap: () => context.push(RoutePaths.offlineSettings),
              ),
              SettingsTile(
                icon: Icons.delete_outline,
                title: 'Clear Cache',
                subtitle: 'Free up storage space',
                onTap: () => _showClearCacheDialog(context),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),

          // About section
          SettingsSection(
            title: l10n.translate('about'),
            children: [
              SettingsTile(
                icon: Icons.info_outline,
                title: l10n.translate('version'),
                subtitle: '1.0.0 (Build 1)',
                showArrow: false,
              ),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: ref.read(themeModeProvider),
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: ref.read(themeModeProvider),
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: ref.read(themeModeProvider),
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: ref.read(localeProvider).languageCode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(Locale(value!));
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: ref.read(localeProvider).languageCode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(Locale(value!));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
  }
}
