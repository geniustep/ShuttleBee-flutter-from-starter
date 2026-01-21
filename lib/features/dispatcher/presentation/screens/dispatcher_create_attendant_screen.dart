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

/// Dispatcher Create/Edit Attendant Screen - شاشة إنشاء/تعديل مرافق - ShuttleBee
/// ملاحظة: المرافقون هم مستخدمون في Odoo، لذا لا يمكن إنشاؤهم مباشرة من التطبيق
class DispatcherCreateAttendantScreen extends ConsumerStatefulWidget {
  final int? attendantId;

  const DispatcherCreateAttendantScreen({
    super.key,
    this.attendantId,
  });

  @override
  ConsumerState<DispatcherCreateAttendantScreen> createState() =>
      _DispatcherCreateAttendantScreenState();
}

class _DispatcherCreateAttendantScreenState
    extends ConsumerState<DispatcherCreateAttendantScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditMode = widget.attendantId != null;

    return DesktopScaffoldWithSidebar(
      backgroundColor: AppColors.dispatcherBackground,
      appBar: DispatcherAppBar(
        title: isEditMode ? l10n.editAttendant : l10n.addAttendant,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Info Banner ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.locale.languageCode == 'ar'
                              ? 'ملاحظة مهمة'
                              : 'Important Note',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditMode
                              ? (l10n.locale.languageCode == 'ar'
                                  ? 'المرافقون هم مستخدمون في Odoo. لتعديل معلومات المرافق، يرجى استخدام واجهة Odoo الإدارية.'
                                  : 'Attendants are users in Odoo. To edit attendant information, please use the Odoo administrative interface.')
                              : (l10n.locale.languageCode == 'ar'
                                  ? 'لا يمكن إنشاء مرافقين مباشرة من التطبيق. يجب إنشاء المستخدمين في Odoo أولاً وتعيين دور "مرافق" (companion) لهم.'
                                  : 'Attendants cannot be created directly from the app. Users must be created in Odoo first and assigned the "companion" role.'),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === Instructions ===
            _buildSectionHeader(
              l10n.locale.languageCode == 'ar'
                  ? 'كيفية إضافة مرافق'
                  : 'How to Add an Attendant',
              Icons.help_outline_rounded,
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructionStep(
                      step: 1,
                      title: l10n.locale.languageCode == 'ar'
                          ? 'افتح Odoo'
                          : 'Open Odoo',
                      description: l10n.locale.languageCode == 'ar'
                          ? 'سجل الدخول إلى واجهة Odoo الإدارية'
                          : 'Log in to the Odoo administrative interface',
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionStep(
                      step: 2,
                      title: l10n.locale.languageCode == 'ar'
                          ? 'انتقل إلى المستخدمين'
                          : 'Go to Users',
                      description: l10n.locale.languageCode == 'ar'
                          ? 'اذهب إلى Settings > Users & Companies > Users'
                          : 'Go to Settings > Users & Companies > Users',
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionStep(
                      step: 3,
                      title: l10n.locale.languageCode == 'ar'
                          ? 'أنشئ مستخدم جديد'
                          : 'Create a New User',
                      description: l10n.locale.languageCode == 'ar'
                          ? 'اضغط على "Create" وأنشئ مستخدم جديد'
                          : 'Click "Create" and create a new user',
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionStep(
                      step: 4,
                      title: l10n.locale.languageCode == 'ar'
                          ? 'عيّن الدور'
                          : 'Assign Role',
                      description: l10n.locale.languageCode == 'ar'
                          ? 'في حقل "Shuttle Role"، اختر "Companion" (مرافق)'
                          : 'In the "Shuttle Role" field, select "Companion"',
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionStep(
                      step: 5,
                      title: l10n.locale.languageCode == 'ar'
                          ? 'احفظ'
                          : 'Save',
                      description: l10n.locale.languageCode == 'ar'
                          ? 'احفظ المستخدم وسيظهر تلقائياً في قائمة المرافقين'
                          : 'Save the user and they will automatically appear in the attendants list',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // === Current Attendants ===
            _buildSectionHeader(
              l10n.locale.languageCode == 'ar'
                  ? 'المرافقون الحاليون'
                  : 'Current Attendants',
              Icons.person_add_alt_rounded,
            ),
            const SizedBox(height: 12),
            ref.watch(companionsProvider).when(
              data: (attendants) {
                if (attendants.isEmpty) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_add_alt_rounded,
                              size: 48,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noAttendants,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendants.length,
                    itemBuilder: (context, index) {
                      final attendant = attendants[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_rounded,
                            size: 20,
                            color: AppColors.dispatcherPrimary,
                          ),
                        ),
                        title: Text(
                          attendant.name,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        subtitle: attendant.email != null
                            ? Text(
                                attendant.email!,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded),
                          onPressed: () {
                            context.go(
                              '${RoutePaths.dispatcherHome}/attendants/${attendant.id}',
                            );
                          },
                        ),
                        onTap: () {
                          context.go(
                            '${RoutePaths.dispatcherHome}/attendants/${attendant.id}',
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${l10n.error}: $error',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.error,
                          ),
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
              ),
            ),
            const SizedBox(height: 32),
          ],
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

  Widget _buildInstructionStep({
    required int step,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.dispatcherPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

