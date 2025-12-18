import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/dispatcher_holiday.dart';
import '../providers/dispatcher_holiday_providers.dart';

class DispatcherHolidayDetailScreen extends ConsumerStatefulWidget {
  const DispatcherHolidayDetailScreen({
    super.key,
    required this.holidayId,
  });

  final int holidayId;

  @override
  ConsumerState<DispatcherHolidayDetailScreen> createState() =>
      _DispatcherHolidayDetailScreenState();
}

class _DispatcherHolidayDetailScreenState
    extends ConsumerState<DispatcherHolidayDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  bool _initialized = false;
  bool _active = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFromHoliday(DispatcherHoliday holiday) {
    if (_initialized) return;
    _initialized = true;

    _nameController.text = holiday.name;
    _notesController.text = (holiday.notes ?? '').trim();
    _active = holiday.active;

    _startDate = DateTime(
      holiday.startDate.year,
      holiday.startDate.month,
      holiday.startDate.day,
    );
    _endDate = DateTime(
      holiday.endDate.year,
      holiday.endDate.month,
      holiday.endDate.day,
    );
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
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final ok =
        await ref.read(dispatcherHolidayActionsProvider.notifier).updateHoliday(
              holidayId: widget.holidayId,
              name: _nameController.text.trim(),
              startDate: _startDate,
              endDate: _endDate,
              notes: _notesController.text.trim(),
              active: _active,
            );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'تم حفظ التعديلات' : 'فشل حفظ التعديلات',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );

    if (ok) {
      ref.invalidate(dispatcherHolidayByIdProvider(widget.holidayId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final holidayAsync =
        ref.watch(dispatcherHolidayByIdProvider(widget.holidayId));
    final actionState = ref.watch(dispatcherHolidayActionsProvider);
    final isBusy = actionState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'تفاصيل العطلة',
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
                : () => ref.invalidate(
                      dispatcherHolidayByIdProvider(widget.holidayId),
                    ),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'حفظ',
            onPressed: isBusy ? null : _save,
            icon: const Icon(Icons.save_rounded),
          ),
        ],
      ),
      body: holidayAsync.when(
        data: (holiday) {
          if (holiday == null) {
            return _buildNotFound();
          }

          _initFromHoliday(holiday);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeaderCard(holiday),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: !isBusy,
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
                          enabled: !isBusy,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات (اختياري)',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _active,
                          onChanged: isBusy
                              ? null
                              : (v) => setState(() => _active = v),
                          title: const Text(
                            'مفعّلة',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isBusy ? null : _pickStartDate,
                                icon: const Icon(Icons.date_range_rounded),
                                label: Text(
                                  'من: ${_formatDate(_startDate)}',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isBusy ? null : _pickEndDate,
                                icon: const Icon(Icons.event_rounded),
                                label: Text(
                                  'إلى: ${_formatDate(_endDate)}',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isBusy ? null : _save,
                            icon: isBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: const Text(
                              'حفظ التعديلات',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(e.toString()),
      ),
    );
  }

  Widget _buildHeaderCard(DispatcherHoliday holiday) {
    final isActiveNow = holiday.includesDate(DateTime.now());
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isActiveNow
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.event_busy_rounded,
                color: isActiveNow ? Colors.red : Colors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holiday.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(holiday.startDate)} - ${_formatDate(holiday.endDate)}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isActiveNow)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'نشط',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          const Text(
            'العطلة غير موجودة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'قد تكون حُذفت أو ليس لديك صلاحية الوصول إليها.',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'حدث خطأ',
              style:
                  TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return Formatters.displayDate(date);
  }
}
