import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/dispatcher_holiday.dart';
import '../providers/dispatcher_holiday_providers.dart';

enum _HolidayFilter { active, inactive, all }

final _holidayFilterProvider =
    StateProvider.autoDispose<_HolidayFilter>((ref) => _HolidayFilter.active);

final _holidaySearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Dispatcher Holidays Screen
///
/// Manage global holidays (Odoo: `shuttle.holiday`).
class DispatcherHolidaysScreen extends ConsumerWidget {
  const DispatcherHolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_holidayFilterProvider);
    final query = ref.watch(_holidaySearchQueryProvider);

    // We only fetch "active only" from backend when user chooses active view.
    // For inactive/all we fetch all then filter locally.
    final fetchActiveOnly = filter == _HolidayFilter.active;
    final holidaysAsync =
        ref.watch(dispatcherHolidaysProvider(fetchActiveOnly));
    final actionsState = ref.watch(dispatcherHolidayActionsProvider);
    final isBusy = actionsState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'إدارة العطل',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: isBusy
                ? null
                : () {
                    ref.invalidate(dispatcherHolidaysProvider(true));
                    ref.invalidate(dispatcherHolidaysProvider(false));
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isBusy
            ? null
            : () {
                HapticFeedback.mediumImpact();
                _showAddHolidayDialog(context, ref);
              },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'إضافة عطلة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(context, ref, isBusy),
          Expanded(
            child: holidaysAsync.when(
              data: (holidays) {
                final displayed = _applyFilters(
                  holidays,
                  filter: filter,
                  query: query,
                );

                if (displayed.isEmpty) {
                  return _buildEmptyState(
                    filter: filter,
                    query: query,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        isMobile ? 96 : 16, // مساحة إضافية للـ FAB على الهاتف
                      ),
                      itemCount: displayed.length,
                      itemBuilder: (context, index) => _buildHolidayCard(
                        context,
                        ref,
                        displayed[index],
                        index,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  _buildErrorState(context, ref, error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    WidgetRef ref,
    bool isBusy,
  ) {
    final filter = ref.watch(_holidayFilterProvider);
    final query = ref.watch(_holidaySearchQueryProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            enabled: !isBusy,
            onChanged: (v) =>
                ref.read(_holidaySearchQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: 'بحث بالسبب أو الملاحظات...',
              hintStyle: const TextStyle(fontFamily: 'Cairo'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'مسح',
                      onPressed: isBusy
                          ? null
                          : () => ref
                              .read(_holidaySearchQueryProvider.notifier)
                              .state = '',
                      icon: const Icon(Icons.clear_rounded),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFilterChip(
                label: 'المفعّلة',
                selected: filter == _HolidayFilter.active,
                onTap: isBusy
                    ? null
                    : () => ref.read(_holidayFilterProvider.notifier).state =
                        _HolidayFilter.active,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'غير المفعّلة',
                selected: filter == _HolidayFilter.inactive,
                onTap: isBusy
                    ? null
                    : () => ref.read(_holidayFilterProvider.notifier).state =
                        _HolidayFilter.inactive,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'الكل',
                selected: filter == _HolidayFilter.all,
                onTap: isBusy
                    ? null
                    : () => ref.read(_holidayFilterProvider.notifier).state =
                        _HolidayFilter.all,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Cairo')),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap(),
      selectedColor: Colors.orange.withValues(alpha: 0.2),
      side: BorderSide(
        color: selected ? Colors.orange : Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }

  List<DispatcherHoliday> _applyFilters(
    List<DispatcherHoliday> holidays, {
    required _HolidayFilter filter,
    required String query,
  }) {
    Iterable<DispatcherHoliday> out = holidays;

    switch (filter) {
      case _HolidayFilter.active:
        out = out.where((h) => h.active);
        break;
      case _HolidayFilter.inactive:
        out = out.where((h) => !h.active);
        break;
      case _HolidayFilter.all:
        break;
    }

    final q = query.trim();
    if (q.isNotEmpty) {
      final qLower = q.toLowerCase();
      out = out.where((h) {
        final name = h.name.toLowerCase();
        final notes = (h.notes ?? '').toLowerCase();
        return name.contains(qLower) || notes.contains(qLower);
      });
    }

    return out.toList();
  }

  Widget _buildHolidayCard(
    BuildContext context,
    WidgetRef ref,
    DispatcherHoliday holiday,
    int index,
  ) {
    final isCurrentlyActive = holiday.includesDate(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          HapticFeedback.lightImpact();
          final result = await context
              .push<bool>('${RoutePaths.dispatcherHolidays}/${holiday.id}');
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم حذف العطلة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: !holiday.active
                      ? Colors.grey.withValues(alpha: 0.12)
                      : isCurrentlyActive
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_busy_rounded,
                  color: !holiday.active
                      ? Colors.grey
                      : isCurrentlyActive
                          ? Colors.red
                          : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            holiday.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        if (!holiday.active)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'غير مفعّلة',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          )
                        else if (isCurrentlyActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'نشط',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(holiday.startDate)} - ${_formatDate(holiday.endDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontFamily: 'Cairo',
                      ),
                    ),
                    if ((holiday.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        holiday.notes!.trim(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red[300],
                onPressed: () => _confirmDeleteHoliday(context, ref, holiday),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideX(
          begin: 0.05,
          end: 0,
          duration: 300.ms,
          delay: (50 * index).ms,
        );
  }

  Widget _buildEmptyState({
    _HolidayFilter? filter,
    String? query,
  }) {
    final q = (query ?? '').trim();
    final hasQuery = q.isNotEmpty;

    String title = 'لا توجد عطل';
    String subtitle = 'أضف عطل عامة لاستثنائها من إنشاء الرحلات';

    if (hasQuery) {
      title = 'لا توجد نتائج';
      subtitle = 'جرّب تغيير كلمة البحث أو الفلتر.';
    } else if (filter == _HolidayFilter.inactive) {
      title = 'لا توجد عطل غير مفعّلة';
      subtitle = 'لن تظهر هنا إلا العطل التي تم تعطيلها.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_outlined,
                size: 64,
                color: Colors.orange.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ في تحميل العطل',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(dispatcherHolidaysProvider(true));
                ref.invalidate(dispatcherHolidaysProvider(false));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteHoliday(
    BuildContext context,
    WidgetRef ref,
    DispatcherHoliday holiday,
  ) async {
    HapticFeedback.lightImpact();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حذف عطلة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف العطلة "${holiday.name}"؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await ref
        .read(dispatcherHolidayActionsProvider.notifier)
        .deleteHoliday(holiday.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'تم حذف العطلة' : 'فشل حذف العطلة',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _showAddHolidayDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final created = await showDialog<DispatcherHoliday?>(
      context: context,
      builder: (_) => const _AddGlobalHolidayDialog(),
    );

    if (created == null) return;
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم إضافة العطلة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return Formatters.displayDate(date);
  }
}

class _AddGlobalHolidayDialog extends ConsumerStatefulWidget {
  const _AddGlobalHolidayDialog();

  @override
  ConsumerState<_AddGlobalHolidayDialog> createState() =>
      _AddGlobalHolidayDialogState();
}

class _AddGlobalHolidayDialogState
    extends ConsumerState<_AddGlobalHolidayDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  late DateTime _startDate;
  late DateTime _endDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'عطلة');
    _notesController = TextEditingController();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final created = await ref
          .read(dispatcherHolidayActionsProvider.notifier)
          .createHoliday(
            name: _nameController.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
            notes: _notesController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop(created);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'إضافة عطلة',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'السبب',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'الرجاء إدخال سبب العطلة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickStartDate,
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(
                        'من: ${DispatcherHolidaysScreen._formatDate(_startDate)}',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickEndDate,
                      icon: const Icon(Icons.event_rounded),
                      label: Text(
                        'إلى: ${DispatcherHolidaysScreen._formatDate(_endDate)}',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(null),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
