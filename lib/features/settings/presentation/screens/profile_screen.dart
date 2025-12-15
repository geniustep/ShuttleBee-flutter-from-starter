import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Profile screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
      ),
      body: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    _getInitials(user?.name ?? 'U'),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                Text(
                  user?.name ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppDimensions.xxs),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.xl),

          // Profile fields
          _ProfileField(
            label: 'Name',
            value: user?.name ?? '',
            icon: Icons.person_outline,
          ),
          _ProfileField(
            label: 'Email',
            value: user?.email ?? 'Not set',
            icon: Icons.email_outlined,
          ),
          _ProfileField(
            label: 'Username',
            value: user?.login ?? '',
            icon: Icons.account_circle_outlined,
          ),
          _ProfileField(
            label: 'Company',
            value: user?.companyName ?? 'Not set',
            icon: Icons.business_outlined,
          ),
          _ProfileField(
            label: 'Language',
            value: user?.lang ?? 'English',
            icon: Icons.language_outlined,
          ),
          _ProfileField(
            label: 'Timezone',
            value: user?.tz ?? 'UTC',
            icon: Icons.access_time_outlined,
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppDimensions.borderRadiusSm,
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppDimensions.xxs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
