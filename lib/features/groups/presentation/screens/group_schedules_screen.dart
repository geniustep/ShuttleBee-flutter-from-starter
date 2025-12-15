import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/passenger_group.dart';
import '../providers/group_providers.dart';

/// شاشة جداول المجموعات الأسبوعية - ShuttleBee
class GroupSchedulesScreen extends ConsumerStatefulWidget {
  final int groupId;
  final String? groupName;

  const GroupSchedulesScreen({
    super.key,
    required this.groupId,
    this.groupName,
  });

  @override
  ConsumerState<GroupSchedulesScreen> createState() =>
      _GroupSchedulesScreenState();
}

class _GroupSchedulesScreenState extends ConsumerState<GroupSchedulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildGroupHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSchedulesTab(),
                _buildHolidaysTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.groupName ?? 'جداول المجموعة',
        style:
            const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_mode_rounded),
          onPressed: () => _showGenerateTripsDialog(),
          tooltip: 'توليد رحلات',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            HapticFeedback.mediumImpact();
            ref.invalidate(groupSchedulesProvider(widget.groupId));
            ref.invalidate(groupHolidaysProvider(widget.groupId));
          },
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  Widget _buildGroupHeader() {
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(
              child: Text(
                'المجموعة غير موجودة',
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              ),
            );
          }

          return Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      '${group.memberCount} راكب • ${group.tripType.arabicLabel}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      group.autoScheduleEnabled ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  group.autoScheduleEnabled ? 'تلقائي' : 'يدوي',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (_, __) => const Center(
          child: Text(
            'خطأ في تحميل البيانات',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            text: 'الجدول الأسبوعي',
            icon: Icon(Icons.calendar_view_week_rounded, size: 20),
          ),
          Tab(
            text: 'العطلات',
            icon: Icon(Icons.event_busy_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesTab() {
    final schedulesAsync = ref.watch(groupSchedulesProvider(widget.groupId));

    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return _buildEmptySchedules();
        }

        // ترتيب الجداول حسب أيام الأسبوع
        final sortedSchedules = List<GroupSchedule>.from(schedules)
          ..sort((a, b) => a.weekday.index.compareTo(b.weekday.index));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: Weekday.values.length,
          itemBuilder: (context, index) {
            final weekday = Weekday.values[index];
            final daySchedules =
                sortedSchedules.where((s) => s.weekday == weekday).toList();

            return _buildDayScheduleCard(weekday, daySchedules, index);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل الجداول',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayScheduleCard(
    Weekday weekday,
    List<GroupSchedule> schedules,
    int index,
  ) {
    final hasSchedule = schedules.isNotEmpty;
    final schedule = hasSchedule ? schedules.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => hasSchedule
            ? _showEditScheduleDialog(schedule!)
            : _showAddScheduleDialog(weekday),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // يوم الأسبوع
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: hasSchedule
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDayAbbreviation(weekday),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasSchedule ? AppColors.primary : Colors.grey,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      weekday.arabicLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: hasSchedule ? AppColors.primary : Colors.grey,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // الأوقات
              Expanded(
                child: hasSchedule
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (schedule!.createPickup)
                            _buildTimeRow(
                              Icons.arrow_upward_rounded,
                              'صعود',
                              schedule.pickupTimeDisplay ?? '--:--',
                              Colors.blue,
                            ),
                          if (schedule.createPickup && schedule.createDropoff)
                            const SizedBox(height: 8),
                          if (schedule.createDropoff)
                            _buildTimeRow(
                              Icons.arrow_downward_rounded,
                              'نزول',
                              schedule.dropoffTimeDisplay ?? '--:--',
                              Colors.green,
                            ),
                        ],
                      )
                    : Text(
                        'لا يوجد جدول',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontFamily: 'Cairo',
                        ),
                      ),
              ),

              // أيقونة الإجراء
              Icon(
                hasSchedule ? Icons.edit_rounded : Icons.add_rounded,
                color: hasSchedule ? Colors.grey[400] : AppColors.primary,
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

  Widget _buildTimeRow(IconData icon, String label, String time, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Cairo',
          ),
        ),
        const Spacer(),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildHolidaysTab() {
    final holidaysAsync = ref.watch(groupHolidaysProvider(widget.groupId));

    return holidaysAsync.when(
      data: (holidays) {
        if (holidays.isEmpty) {
          return _buildEmptyHolidays();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: holidays.length,
          itemBuilder: (context, index) {
            return _buildHolidayCard(holidays[index], index);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل العطلات',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidayCard(GroupHoliday holiday, int index) {
    final isActive = holiday.containsDate(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_busy_rounded,
                color: isActive ? Colors.red : Colors.orange,
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
                      if (isActive)
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
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.red[300],
              onPressed: () => _confirmDeleteHoliday(holiday),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideX(
          begin: 0.05,
          end: 0,
          duration: 300.ms,
          delay: (50 * index).ms,
        );
  }

  Widget _buildEmptySchedules() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_view_week_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد جداول أسبوعية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف جداول لتوليد الرحلات تلقائياً',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHolidays() {
    return Center(
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
          const Text(
            'لا توجد عطلات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف عطلات لاستثنائها من الجدول',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        if (_tabController.index == 0) {
          _showChooseWeekdayDialog();
        } else {
          _showAddHolidayDialog();
        }
      },
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        _tabController.index == 0 ? 'إضافة جدول' : 'إضافة عطلة',
        style:
            const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getDayAbbreviation(Weekday weekday) {
    switch (weekday) {
      case Weekday.sunday:
        return 'أحد';
      case Weekday.monday:
        return 'إثن';
      case Weekday.tuesday:
        return 'ثلا';
      case Weekday.wednesday:
        return 'أرب';
      case Weekday.thursday:
        return 'خمي';
      case Weekday.friday:
        return 'جمع';
      case Weekday.saturday:
        return 'سبت';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddScheduleDialog(Weekday weekday) {
    HapticFeedback.mediumImpact();

    final rootContext = context;
    final formKey = GlobalKey<FormState>();
    final today = DateTime.now();

    bool createPickup = true;
    bool createDropoff = true;
    bool active = true;

    TimeOfDay? pickupTime = const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay? dropoffTime = const TimeOfDay(hour: 14, minute: 45);

    Future<TimeOfDay?> pickTime(TimeOfDay initial) async {
      return await showTimePicker(
        context: context,
        initialTime: initial,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
    }

    DateTime toDateTime(TimeOfDay t) =>
        DateTime(today.year, today.month, today.day, t.hour, t.minute);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(
            'إضافة جدول - ${weekday.arabicLabel}',
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    onChanged: (v) => setLocal(() => active = v),
                    title: const Text('نشط',
                        style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: createPickup,
                    onChanged: (v) => setLocal(() => createPickup = v),
                    title: const Text('توليد رحلة صعود',
                        style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  if (createPickup)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.blue),
                      title: const Text('وقت الصعود',
                          style: TextStyle(fontFamily: 'Cairo')),
                      subtitle: Text(
                        pickupTime?.format(context) ?? '--:--',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      trailing: const Icon(Icons.access_time_rounded),
                      onTap: () async {
                        final picked = await pickTime(
                            pickupTime ?? const TimeOfDay(hour: 7, minute: 0));
                        if (picked != null) setLocal(() => pickupTime = picked);
                      },
                    ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: createDropoff,
                    onChanged: (v) => setLocal(() => createDropoff = v),
                    title: const Text('توليد رحلة نزول',
                        style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  if (createDropoff)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.arrow_downward_rounded,
                          color: Colors.green),
                      title: const Text('وقت النزول',
                          style: TextStyle(fontFamily: 'Cairo')),
                      subtitle: Text(
                        dropoffTime?.format(context) ?? '--:--',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      trailing: const Icon(Icons.access_time_rounded),
                      onTap: () async {
                        final picked = await pickTime(dropoffTime ??
                            const TimeOfDay(hour: 14, minute: 45));
                        if (picked != null)
                          setLocal(() => dropoffTime = picked);
                      },
                    ),
                  if (!createPickup && !createDropoff)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'اختر على الأقل صعود أو نزول',
                        style: TextStyle(
                            fontFamily: 'Cairo', color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (!createPickup && !createDropoff) return;
                Navigator.pop(context);

                final schedule = await ref
                    .read(groupActionsProvider.notifier)
                    .createSchedule(
                      groupId: widget.groupId,
                      weekday: weekday,
                      pickupTime: (createPickup && pickupTime != null)
                          ? toDateTime(pickupTime!)
                          : null,
                      dropoffTime: (createDropoff && dropoffTime != null)
                          ? toDateTime(dropoffTime!)
                          : null,
                      createPickup: createPickup,
                      createDropoff: createDropoff,
                      active: active,
                    );

                if (!mounted) return;
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      schedule != null ? 'تم حفظ الجدول' : 'فشل في حفظ الجدول',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                );
              },
              child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditScheduleDialog(GroupSchedule schedule) {
    HapticFeedback.mediumImpact();

    final rootContext = context;
    final today = DateTime.now();

    TimeOfDay? parseDisplay(String? hhmm) {
      final v = hhmm?.trim();
      if (v == null || v.isEmpty) return null;
      final parts = v.split(':');
      if (parts.length != 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      return TimeOfDay(hour: h, minute: m);
    }

    DateTime toDateTime(TimeOfDay t) =>
        DateTime(today.year, today.month, today.day, t.hour, t.minute);

    bool createPickup = schedule.createPickup;
    bool createDropoff = schedule.createDropoff;
    bool active = schedule.active;

    TimeOfDay? pickupTime = parseDisplay(schedule.pickupTimeDisplay) ??
        (schedule.pickupTime != null
            ? TimeOfDay(
                hour: schedule.pickupTime!.hour,
                minute: schedule.pickupTime!.minute)
            : const TimeOfDay(hour: 7, minute: 0));
    TimeOfDay? dropoffTime = parseDisplay(schedule.dropoffTimeDisplay) ??
        (schedule.dropoffTime != null
            ? TimeOfDay(
                hour: schedule.dropoffTime!.hour,
                minute: schedule.dropoffTime!.minute)
            : const TimeOfDay(hour: 14, minute: 45));

    Future<TimeOfDay?> pickTime(TimeOfDay initial) async {
      return await showTimePicker(
        context: context,
        initialTime: initial,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(
            'تعديل جدول - ${schedule.weekday.arabicLabel}',
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  onChanged: (v) => setLocal(() => active = v),
                  title:
                      const Text('نشط', style: TextStyle(fontFamily: 'Cairo')),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: createPickup,
                  onChanged: (v) => setLocal(() => createPickup = v),
                  title: const Text('توليد رحلة صعود',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
                if (createPickup)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.arrow_upward_rounded,
                        color: Colors.blue),
                    title: const Text('وقت الصعود',
                        style: TextStyle(fontFamily: 'Cairo')),
                    subtitle: Text(
                      pickupTime?.format(context) ?? '--:--',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    trailing: const Icon(Icons.access_time_rounded),
                    onTap: () async {
                      final picked = await pickTime(
                          pickupTime ?? const TimeOfDay(hour: 7, minute: 0));
                      if (picked != null) setLocal(() => pickupTime = picked);
                    },
                  ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: createDropoff,
                  onChanged: (v) => setLocal(() => createDropoff = v),
                  title: const Text('توليد رحلة نزول',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
                if (createDropoff)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.arrow_downward_rounded,
                        color: Colors.green),
                    title: const Text('وقت النزول',
                        style: TextStyle(fontFamily: 'Cairo')),
                    subtitle: Text(
                      dropoffTime?.format(context) ?? '--:--',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    trailing: const Icon(Icons.access_time_rounded),
                    onTap: () async {
                      final picked = await pickTime(
                          dropoffTime ?? const TimeOfDay(hour: 14, minute: 45));
                      if (picked != null) setLocal(() => dropoffTime = picked);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(context);
                final updated = GroupSchedule(
                  id: schedule.id,
                  groupId: schedule.groupId,
                  weekday: schedule.weekday,
                  pickupTime: (createPickup && pickupTime != null)
                      ? toDateTime(pickupTime!)
                      : null,
                  dropoffTime: (createDropoff && dropoffTime != null)
                      ? toDateTime(dropoffTime!)
                      : null,
                  createPickup: createPickup,
                  createDropoff: createDropoff,
                  active: active,
                  // Displays are computed by server; keep as-is.
                  pickupTimeDisplay: schedule.pickupTimeDisplay,
                  dropoffTimeDisplay: schedule.dropoffTimeDisplay,
                );

                final ok = await ref
                    .read(groupActionsProvider.notifier)
                    .updateSchedule(updated);
                if (!mounted) return;
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'تم تحديث الجدول' : 'فشل في تحديث الجدول',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                );
              },
              child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHolidayDialog() {
    HapticFeedback.mediumImpact();

    final rootContext = context;
    final nameController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    Future<DateTime?> pickDate(DateTime? initial) async {
      final now = DateTime.now();
      final init = initial ?? DateTime(now.year, now.month, now.day);
      return await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 2),
        locale: const Locale('ar'),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
    }

    String fmt(DateTime? d) =>
        d == null ? '--/--/----' : '${d.day}/${d.month}/${d.year}';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text(
            'إضافة عطلة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم العطلة',
                    labelStyle: TextStyle(fontFamily: 'Cairo'),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.event_rounded, color: Colors.orange),
                  title: const Text('تاريخ البداية',
                      style: TextStyle(fontFamily: 'Cairo')),
                  subtitle: Text(fmt(startDate),
                      style: const TextStyle(fontFamily: 'Cairo')),
                  trailing: const Icon(Icons.calendar_month_rounded),
                  onTap: () async {
                    final picked = await pickDate(startDate);
                    if (picked != null) {
                      setLocal(() => startDate = picked);
                      if (endDate != null && endDate!.isBefore(picked)) {
                        setLocal(() => endDate = picked);
                      }
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.event_busy_rounded, color: Colors.red),
                  title: const Text('تاريخ النهاية',
                      style: TextStyle(fontFamily: 'Cairo')),
                  subtitle: Text(fmt(endDate),
                      style: const TextStyle(fontFamily: 'Cairo')),
                  trailing: const Icon(Icons.calendar_month_rounded),
                  onTap: () async {
                    final picked = await pickDate(endDate ?? startDate);
                    if (picked != null) {
                      setLocal(() => endDate = picked);
                      if (startDate != null && picked.isBefore(startDate!)) {
                        setLocal(() => startDate = picked);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                Navigator.pop(context);
              },
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty || startDate == null || endDate == null)
                  return;
                nameController.dispose();
                Navigator.pop(context);

                final holiday =
                    await ref.read(groupActionsProvider.notifier).createHoliday(
                          groupId: widget.groupId,
                          name: name,
                          startDate: startDate!,
                          endDate: endDate!,
                        );
                if (!mounted) return;
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      holiday != null
                          ? 'تمت إضافة العطلة'
                          : 'فشل في إضافة العطلة',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                );
              },
              child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  void _showChooseWeekdayDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'اختر يوم الأسبوع',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              ...Weekday.values.map((d) {
                return ListTile(
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: Text(d.arabicLabel,
                      style: const TextStyle(fontFamily: 'Cairo')),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddScheduleDialog(d);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteHoliday(GroupHoliday holiday) {
    final rootContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: Text(
          'هل أنت متأكد من حذف العطلة "${holiday.name}"؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(groupActionsProvider.notifier)
                  .deleteHoliday(holiday.id, widget.groupId);
              if (mounted) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'تم حذف العطلة بنجاح' : 'فشل في حذف العطلة',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showGenerateTripsDialog() {
    final rootContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'توليد رحلات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'سيتم توليد رحلات للأسبوع القادم بناءً على الجدول المحدد.\nهل تريد المتابعة؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final count = await ref
                  .read(groupActionsProvider.notifier)
                  .generateTrips(widget.groupId);
              if (mounted) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? 'تم توليد $count رحلة بنجاح'
                          : 'لم يتم توليد أي رحلات',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('توليد', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
