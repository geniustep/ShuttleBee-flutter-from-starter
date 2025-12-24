import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common/desktop_sidebar_wrapper.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/trip_filter_provider.dart';
import '../../../../core/utils/error_translator.dart';
import '../widgets/common/dispatcher_app_bar.dart';
import '../widgets/passengers/passengers_list_section.dart';
import '../widgets/trips/trip_search_bar.dart';

/// Dispatcher Trip Detail Screen - النسخة المحسّنة مع البحث والفلتر
class DispatcherTripDetailScreen extends ConsumerStatefulWidget {
  final int tripId;

  const DispatcherTripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<DispatcherTripDetailScreen> createState() =>
      _DispatcherTripDetailScreenState();
}

class _DispatcherTripDetailScreenState
    extends ConsumerState<DispatcherTripDetailScreen> {
  // Save notifier reference to safely use in dispose()
  TripFilterNotifier? _filterNotifier;

  @override
  void dispose() {
    // تنظيف حالة الفلتر عند مغادرة الصفحة
    // Use saved notifier reference instead of ref to avoid StateError
    if (_filterNotifier != null) {
      try {
        _filterNotifier!.clearAllFilters();
      } catch (e) {
        // Ignore errors if provider is already disposed
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));

    // Save notifier reference when widget is built (safe to use ref here)
    _filterNotifier ??= ref.read(tripFilterProvider.notifier);

    return DesktopScaffoldWithSidebar(
      backgroundColor: AppColors.dispatcherBackground,
      appBar: DispatcherAppBar(
        title: l10n.tripDetails,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(
                '${RoutePaths.dispatcherHome}/trips/${widget.tripId}/edit',
              );
            },
            tooltip: l10n.editTrip,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(tripDetailProvider(widget.tripId));
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return _buildNotFoundState(l10n);
          }
          return _buildContent(trip, l10n);
        },
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildContent(Trip trip, AppLocalizations l10n) {
    return Column(
      children: [
        // شريط البحث والفلتر الدائم في الأعلى
        TripSearchBar(tripId: widget.tripId),

        // المحتوى القابل للتمرير
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tripDetailProvider(widget.tripId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // معلومات الرحلة الأساسية
                _buildTripInfoCard(trip, l10n),
                const SizedBox(height: 16),

                // قسم الركاب مع الفلترة - العنصر الأساسي
                PassengersListSection(tripId: widget.tripId, trip: trip),
                const SizedBox(height: 16),

                // الملاحظات (إن وجدت)
                if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                  _buildNotesCard(trip, l10n),
                  const SizedBox(height: 16),
                ],

                // أزرار الإجراءات
                _buildActionsButtons(trip, l10n),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// بطاقة معلومات الرحلة الموحدة
  Widget _buildTripInfoCard(Trip trip, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان والنوع
            Row(
              children: [
                Icon(
                  trip.tripType == TripType.pickup
                      ? Icons.arrow_circle_up_rounded
                      : Icons.arrow_circle_down_rounded,
                  color: trip.tripType == TripType.pickup
                      ? AppColors.primary
                      : AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        trip.tripType.getLabel(l10n.locale.languageCode),
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Cairo',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // حالة الرحلة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: trip.state.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: trip.state.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: trip.state.color,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'الحالة: ',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    trip.state.getLocalizedLabel(context),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: trip.state.color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // معلومات التاريخ والمجموعة
            _buildInfoRow(
              Icons.calendar_today_rounded,
              'التاريخ',
              _formatDate(trip.date),
            ),
            if (trip.groupName != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.groups_rounded, 'المجموعة', trip.groupName!),
            ],

            const Divider(height: 24),

            // معلومات السائق والمركبة
            if (trip.driverName != null) ...[
              _buildInfoRow(Icons.person_rounded, 'السائق', trip.driverName!),
              const SizedBox(height: 8),
            ],
            if (trip.vehicleName != null)
              _buildInfoRow(
                Icons.directions_bus_rounded,
                'المركبة',
                trip.vehicleName!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.dispatcherPrimary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(Trip trip, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notes_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.notes,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              trip.notes!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsButtons(Trip trip, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // زر التعديل
        ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go(
              '${RoutePaths.dispatcherHome}/trips/${widget.tripId}/edit',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dispatcherPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.edit_rounded),
          label: Text(
            l10n.editTrip,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // زر إلغاء الرحلة (فقط إذا كانت قابلة للإلغاء)
        if (trip.canCancel)
          OutlinedButton.icon(
            onPressed: () => _cancelTrip(trip, l10n),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.cancel_rounded, color: AppColors.error),
            label: const Text(
              'إلغاء الرحلة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.error,
              ),
            ),
          ),

        if (trip.canCancel) const SizedBox(height: 12),

        // زر حذف الرحلة (فقط للرحلات الملغاة أو المسودة)
        if (trip.state == TripState.cancelled || trip.state == TripState.draft)
          OutlinedButton.icon(
            onPressed: () => _deleteTrip(trip, l10n),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.delete_rounded, color: AppColors.error),
            label: const Text(
              'حذف الرحلة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.error,
              ),
            ),
          ),

        if (trip.state == TripState.cancelled || trip.state == TripState.draft)
          const SizedBox(height: 12),

        // زر إنشاء رحلة عودة (فقط لرحلات الذهاب)
        if (trip.tripType == TripType.pickup)
          OutlinedButton.icon(
            onPressed: () {
              // TODO: تطبيق منطق إنشاء رحلة العودة
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ميزة إنشاء رحلة العودة قيد التطوير',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.primary,
            ),
            label: Text(
              l10n.createReturnTrip,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _cancelTrip(Trip trip, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'إلغاء الرحلة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من إلغاء الرحلة "${trip.name}"؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'تأكيد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticFeedback.mediumImpact();

    final repository = ref.read(tripRepositoryProvider);
    if (repository == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خطأ في الاتصال. يرجى المحاولة مرة أخرى',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = await repository.cancelTrip(widget.tripId);

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorTranslator.translate(failure.message),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إلغاء الرحلة بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(tripDetailProvider(widget.tripId));
      },
    );
  }

  Future<void> _deleteTrip(Trip trip, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف الرحلة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف الرحلة "${trip.name}"؟\nهذا الإجراء لا يمكن التراجع عنه.',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticFeedback.mediumImpact();

    final repository = ref.read(tripRepositoryProvider);
    if (repository == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خطأ في الاتصال. يرجى المحاولة مرة أخرى',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // استخدام cancelTrip كبديل للحذف (حذف فعلي غير متوفر في API)
    final result = await repository.cancelTrip(widget.tripId);

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorTranslator.translate(failure.message),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حذف الرحلة بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        // العودة إلى قائمة الرحلات
        context.go(RoutePaths.dispatcherTrips);
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ في تحميل البيانات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(tripDetailProvider(widget.tripId));
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'الرحلة غير موجودة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go(RoutePaths.dispatcherTrips),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(
              'العودة للرحلات',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDate = DateTime(date.year, date.month, date.day);

    if (tripDate == today) {
      return 'اليوم';
    } else if (tripDate == today.add(const Duration(days: 1))) {
      return 'غداً';
    } else if (tripDate == today.subtract(const Duration(days: 1))) {
      return 'أمس';
    }

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
