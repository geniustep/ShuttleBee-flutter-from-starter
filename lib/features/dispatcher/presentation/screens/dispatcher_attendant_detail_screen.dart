import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common/desktop_sidebar_wrapper.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../widgets/common/dispatcher_app_bar.dart';

/// Dispatcher Attendant Detail Screen - شاشة تفاصيل المرافق - ShuttleBee
class DispatcherAttendantDetailScreen extends ConsumerStatefulWidget {
  final int attendantId;

  const DispatcherAttendantDetailScreen({
    super.key,
    required this.attendantId,
  });

  @override
  ConsumerState<DispatcherAttendantDetailScreen> createState() =>
      _DispatcherAttendantDetailScreenState();
}

class _DispatcherAttendantDetailScreenState
    extends ConsumerState<DispatcherAttendantDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final attendantsAsync = ref.watch(companionsProvider);

    return DesktopScaffoldWithSidebar(
      backgroundColor: AppColors.dispatcherBackground,
      appBar: DispatcherAppBar(
        title: l10n.attendantDetails,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: l10n.edit,
            onPressed: () {
              context.go(
                '${RoutePaths.dispatcherHome}/attendants/${widget.attendantId}/edit',
              );
            },
          ),
        ],
      ),
      body: attendantsAsync.when(
        data: (attendants) {
          final attendant = attendants.firstWhere(
            (a) => a.id == widget.attendantId,
            orElse: () => attendants.first,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Header Card ===
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_rounded,
                            size: 40,
                            color: AppColors.dispatcherPrimary,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attendant.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              if (attendant.email != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_rounded,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      attendant.email!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (attendant.role != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    attendant.role!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dispatcherPrimary,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () {
                            context.go(
                              '${RoutePaths.dispatcherHome}/attendants/${widget.attendantId}/edit',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // === Information Section ===
                _buildSectionHeader(l10n.information, Icons.info_outline_rounded),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.person_rounded,
                          label: l10n.name,
                          value: attendant.name,
                        ),
                        const Divider(),
                        if (attendant.email != null) ...[
                          _buildInfoRow(
                            icon: Icons.email_rounded,
                            label: l10n.email,
                            value: attendant.email!,
                          ),
                          const Divider(),
                        ],
                        if (attendant.role != null) ...[
                          _buildInfoRow(
                            icon: Icons.badge_rounded,
                            label: l10n.role,
                            value: attendant.role!,
                          ),
                          const Divider(),
                        ],
                        _buildInfoRow(
                          icon: Icons.numbers_rounded,
                          label: l10n.id,
                          value: attendant.id.toString(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // === Note ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.locale.languageCode == 'ar'
                              ? 'المرافقون هم مستخدمون في النظام. لتعديل معلومات المرافق، يرجى استخدام واجهة Odoo.'
                              : 'Attendants are users in the system. To edit attendant information, please use the Odoo interface.',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                '${l10n.error}: $error',
                style: const TextStyle(fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(companionsProvider);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.dispatcherPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: AppColors.dispatcherPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
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

