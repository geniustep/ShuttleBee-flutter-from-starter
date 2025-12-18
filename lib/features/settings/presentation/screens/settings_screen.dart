import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/global_providers.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

/// Settings screen with responsive layout
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final useArabicNumerals = ref.watch(arabicNumeralsProvider);
    final dateFormat = ref.watch(dateFormatProvider);

    // Responsive layout
    final maxWidth = context.formMaxWidth;
    final padding = context.responsivePadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: context.isMobile,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: padding,
            children: [
              // Account section
              SettingsSection(
                title: l10n.account,
                children: [
                  SettingsTile(
                    icon: Icons.person_outline,
                    title: l10n.profile,
                    subtitle:
                        l10n.translate('manage_profile') != 'manage_profile'
                            ? l10n.translate('manage_profile')
                            : 'Manage your profile information',
                    onTap: () => context.push(RoutePaths.profile),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.lg),

              // Appearance section
              SettingsSection(
                title: l10n.appearance,
                children: [
                  SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: l10n.theme,
                    subtitle: _getThemeModeText(themeMode, l10n),
                    onTap: () => _showThemeDialog(context, ref, l10n),
                  ),
                  SettingsTile(
                    icon: Icons.language_outlined,
                    title: l10n.language,
                    subtitle: _getLanguageName(locale.languageCode),
                    onTap: () => _showLanguageDialog(context, ref, l10n),
                  ),
                  // Only show numeral system setting for Arabic language
                  if (locale.languageCode == 'ar')
                    SettingsTile(
                      icon: Icons.pin_outlined,
                      title: l10n.translate('numeral_system'),
                      subtitle: useArabicNumerals
                          ? l10n.translate('arabic_numerals')
                          : l10n.translate('western_numerals'),
                      onTap: () => _showNumeralSystemDialog(context, ref, l10n),
                    ),
                  SettingsTile(
                    icon: Icons.calendar_today_outlined,
                    title: l10n.translate('date_format'),
                    subtitle: _getDateFormatText(dateFormat, l10n),
                    onTap: () => _showDateFormatDialog(context, ref, l10n),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.lg),

              // Data & Sync section
              SettingsSection(
                title: l10n.offlineMode,
                children: [
                  SettingsTile(
                    icon: Icons.cloud_sync_outlined,
                    title: l10n.syncStatus,
                    subtitle:
                        l10n.translate('manage_offline') != 'manage_offline'
                            ? l10n.translate('manage_offline')
                            : 'Manage offline settings',
                    onTap: () => context.push(RoutePaths.offlineSettings),
                  ),
                  SettingsTile(
                    icon: Icons.delete_outline,
                    title: l10n.clearCache,
                    subtitle: l10n.translate('free_storage') != 'free_storage'
                        ? l10n.translate('free_storage')
                        : 'Free up storage space',
                    onTap: () => _showClearCacheDialog(context, l10n),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.lg),

              // About section
              SettingsSection(
                title: l10n.about,
                children: [
                  SettingsTile(
                    icon: Icons.info_outline,
                    title: l10n.version,
                    subtitle: '1.0.0 (Build 1)',
                    showArrow: false,
                  ),
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacyPolicy,
                    onTap: () {},
                  ),
                  SettingsTile(
                    icon: Icons.description_outlined,
                    title: l10n.termsOfService,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  String _getThemeModeText(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
      case ThemeMode.system:
        return l10n.system;
    }
  }

  String _getDateFormatText(DateFormatType format, AppLocalizations l10n) {
    switch (format) {
      case DateFormatType.short:
        return l10n.translate('date_format_short');
      case DateFormatType.medium:
        return l10n.translate('date_format_medium');
      case DateFormatType.long:
        return l10n.translate('date_format_long');
      case DateFormatType.full:
        return l10n.translate('date_format_full');
    }
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.theme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(l10n.light),
              value: ThemeMode.light,
              groupValue: ref.read(themeModeProvider),
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.dark),
              value: ThemeMode.dark,
              groupValue: ref.read(themeModeProvider),
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.system),
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

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              subtitle: const Text('English'),
              value: 'en',
              groupValue: ref.read(localeProvider).languageCode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(Locale(value!));
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('العربية'),
              subtitle: const Text('Arabic'),
              value: 'ar',
              groupValue: ref.read(localeProvider).languageCode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(Locale(value!));
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Français'),
              subtitle: const Text('French'),
              value: 'fr',
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

  void _showNumeralSystemDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('numeral_system')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: Text(l10n.translate('western_numerals')),
              subtitle: const Text('0-9'),
              value: false,
              groupValue: ref.read(arabicNumeralsProvider),
              onChanged: (value) {
                ref
                    .read(arabicNumeralsProvider.notifier)
                    .setUseArabicNumerals(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool>(
              title: Text(l10n.translate('arabic_numerals')),
              subtitle: const Text('٠-٩'),
              value: true,
              groupValue: ref.read(arabicNumeralsProvider),
              onChanged: (value) {
                ref
                    .read(arabicNumeralsProvider.notifier)
                    .setUseArabicNumerals(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDateFormatDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('date_format')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<DateFormatType>(
              title: Text(l10n.translate('date_format_short')),
              subtitle: Text(l10n.translate('date_format_short_example')),
              value: DateFormatType.short,
              groupValue: ref.read(dateFormatProvider),
              onChanged: (value) {
                ref.read(dateFormatProvider.notifier).setDateFormat(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<DateFormatType>(
              title: Text(l10n.translate('date_format_medium')),
              subtitle: Text(l10n.translate('date_format_medium_example')),
              value: DateFormatType.medium,
              groupValue: ref.read(dateFormatProvider),
              onChanged: (value) {
                ref.read(dateFormatProvider.notifier).setDateFormat(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<DateFormatType>(
              title: Text(l10n.translate('date_format_long')),
              subtitle: Text(l10n.translate('date_format_long_example')),
              value: DateFormatType.long,
              groupValue: ref.read(dateFormatProvider),
              onChanged: (value) {
                ref.read(dateFormatProvider.notifier).setDateFormat(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<DateFormatType>(
              title: Text(l10n.translate('date_format_full')),
              subtitle: Text(l10n.translate('date_format_full_example')),
              value: DateFormatType.full,
              groupValue: ref.read(dateFormatProvider),
              onChanged: (value) {
                ref.read(dateFormatProvider.notifier).setDateFormat(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearCache),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.success)),
              );
            },
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }
}
