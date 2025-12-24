import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common/desktop_sidebar_wrapper.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../widgets/common/dispatcher_app_bar.dart';

/// Dispatcher Group Detail Screen - شاشة تفاصيل المجموعة للمرسل - ShuttleBee
class DispatcherGroupDetailScreen extends ConsumerStatefulWidget {
  final int groupId;

  const DispatcherGroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<DispatcherGroupDetailScreen> createState() =>
      _DispatcherGroupDetailScreenState();
}

class _DispatcherGroupDetailScreenState
    extends ConsumerState<DispatcherGroupDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));

    return DesktopScaffoldWithSidebar(
      backgroundColor: AppColors.dispatcherBackground,
      appBar: DispatcherAppBar(
        title: 'تفاصيل المجموعة',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(
                '${RoutePaths.dispatcherHome}/groups/${widget.groupId}/edit',
              );
            },
            tooltip: 'تعديل المجموعة',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(groupByIdProvider(widget.groupId));
            },
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return _buildNotFoundState();
          }
          return _buildGroupDetails(group);
        },
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildGroupDetails(PassengerGroup group) {
    final tripTypeColor = switch (group.tripType) {
      GroupTripType.pickup => AppColors.primary,
      GroupTripType.dropoff => AppColors.success,
      GroupTripType.both => AppColors.dispatcherPrimary,
    };

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupByIdProvider(widget.groupId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Group Header Card
          _buildHeaderCard(group, tripTypeColor),
          const SizedBox(height: 16),

          // Basic Info Card
          _buildBasicInfoCard(group),
          const SizedBox(height: 16),

          // Driver & Vehicle Card
          _buildDriverVehicleCard(group),
          const SizedBox(height: 16),

          // NEW: Dispatcher Access Card (if user is manager or has dispatcher info)
          if (ref.watch(authStateProvider).asData?.value.user?.isAdmin ??
              false) ...[
            _buildDispatcherAccessCard(group),
            const SizedBox(height: 16),
          ],

          // Destination Card
          if (group.hasDestination) ...[
            _buildDestinationCard(group),
            const SizedBox(height: 16),
          ],

          // Subscription Info Card
          if (group.subscriptionPrice != null) ...[
            _buildSubscriptionCard(group),
            const SizedBox(height: 16),
          ],

          // Schedules Section
          _buildSchedulesSection(group),
          const SizedBox(height: 16),

          // Holidays Section
          if (group.holidays.isNotEmpty) ...[
            _buildHolidaysSection(group),
            const SizedBox(height: 16),
          ],

          // Notes Section
          if (group.notes != null && group.notes!.isNotEmpty) ...[
            _buildNotesCard(group),
            const SizedBox(height: 16),
          ],

          // Actions Section
          _buildActionsSection(group),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(PassengerGroup group, Color tripTypeColor) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              tripTypeColor,
              tripTypeColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Colors.white,
                        ),
                      ),
                      if (group.code != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          group.code!,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Cairo',
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        group.active ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        group.active ? 'نشطة' : 'غير نشطة',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  group.tripType.getLocalizedLabel(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 24),
                Icon(
                  Icons.people_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${Formatters.formatSimple(group.memberCount)} ${AppLocalizations.of(context).passengerSingular}',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildBasicInfoCard(PassengerGroup group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'المعلومات الأساسية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.people_rounded,
              label: 'عدد الركاب',
              value: Formatters.formatSimple(group.memberCount),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.event_seat_rounded,
              label: 'إجمالي المقاعد',
              value: Formatters.formatSimple(group.totalSeats),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.swap_horiz_rounded,
              label: AppLocalizations.of(context).tripType,
              value: group.tripType.getLocalizedLabel(context),
            ),
            if (group.companyName != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.business_rounded,
                label: 'الشركة',
                value: group.companyName!,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildDriverVehicleCard(PassengerGroup group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'السائق والمركبة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.person_rounded,
              label: 'السائق',
              value: group.driverName ?? 'لم يتم التعيين',
              isWarning: !group.hasDriver,
            ),
            // NEW: عرض المرافق إذا كان موجوداً
            if (group.companionName != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.person_add_alt_rounded,
                label: 'المرافق',
                value: group.companionName!,
              ),
            ],
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.directions_bus_rounded,
              label: 'المركبة',
              value: group.vehicleName ?? 'لم يتم التعيين',
              isWarning: !group.hasVehicle,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.event_seat_rounded,
              label: 'سعة المركبة',
              value: '${Formatters.formatSimple(group.totalSeats)} مقعد',
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildDestinationCard(PassengerGroup group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'الوجهة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.place_rounded,
              label: 'الوجهة',
              value: group.destinationStopName ??
                  (group.destinationLatitude != null &&
                          group.destinationLongitude != null
                      ? '${group.destinationLatitude}, ${group.destinationLongitude}'
                      : 'غير محدد'),
            ),
            if (group.useCompanyDestination) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'استخدام وجهة الشركة الافتراضية',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildSubscriptionCard(PassengerGroup group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.payment_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'معلومات الاشتراك',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.attach_money_rounded,
              label: 'سعر الاشتراك',
              value: '${Formatters.formatSimple(group.subscriptionPrice)} ر.س',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.repeat_rounded,
              label: 'دورة الفوترة',
              value: group.billingCycle.arabicLabel,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
  }

  Widget _buildSchedulesSection(PassengerGroup group) {
    final schedules = group.schedules.where((s) => s.active).toList();

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
                  Icons.schedule_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'الجداول الأسبوعية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push(
                      '${RoutePaths.dispatcherHome}/groups/${widget.groupId}/schedules',
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  label: const Text(
                    'إدارة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'لا توجد جداول نشطة',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Cairo',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...schedules.take(5).map((schedule) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dispatcherPrimary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          schedule.weekday.getLocalizedLabel(context),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: AppColors.dispatcherPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            if (schedule.createPickup &&
                                schedule.pickupTimeDisplay != null) ...[
                              const Icon(
                                Icons.arrow_upward_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                schedule.pickupTimeDisplay!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                            if (schedule.createPickup &&
                                schedule.createDropoff &&
                                schedule.pickupTimeDisplay != null &&
                                schedule.dropoffTimeDisplay != null)
                              const Text(' • ', style: TextStyle(fontSize: 12)),
                            if (schedule.createDropoff &&
                                schedule.dropoffTimeDisplay != null) ...[
                              const Icon(
                                Icons.arrow_downward_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                schedule.dropoffTimeDisplay!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (schedules.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'و ${Formatters.formatSimple(schedules.length - 5)} جدول آخر',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Cairo',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 500.ms);
  }

  Widget _buildHolidaysSection(PassengerGroup group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'العطلات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...group.holidays.take(5).map((holiday) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holiday.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatDate(holiday.startDate)} - ${_formatDate(holiday.endDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (group.holidays.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'و ${Formatters.formatSimple(group.holidays.length - 5)} عطلة أخرى',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Cairo',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 600.ms);
  }

  Widget _buildNotesCard(PassengerGroup group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.note_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'ملاحظات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              group.notes!,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Cairo',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 700.ms);
  }

  /// NEW: Build Dispatcher Access Card
  Widget _buildDispatcherAccessCard(PassengerGroup group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'صلاحيات Dispatcher',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (group.dispatcherId != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'منشئ المجموعة: ${group.dispatcherName ?? 'ID: ${group.dispatcherId}'}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (group.dispatcherGroupIds.isNotEmpty) ...[
              const Text(
                'Dispatchers المصرح لهم:',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ref.watch(dispatchersProvider).when(
                    data: (allDispatchers) {
                      final authorizedDispatchers = allDispatchers
                          .where((d) => group.dispatcherGroupIds.contains(d.id))
                          .toList();

                      if (authorizedDispatchers.isEmpty) {
                        return Text(
                          'IDs: ${group.dispatcherGroupIds.join(', ')}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: authorizedDispatchers.map((dispatcher) {
                          return Chip(
                            avatar: const Icon(
                              Icons.person,
                              size: 16,
                            ),
                            label: Text(
                              dispatcher.name,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: AppColors.dispatcherPrimary
                                .withValues(alpha: 0.1),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text(
                      'IDs: ${group.dispatcherGroupIds.join(', ')}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
            ] else ...[
              const Text(
                'لا يوجد Dispatchers مصرح لهم (يمكن للمنشئ فقط الوصول)',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 250.ms);
  }

  Widget _buildActionsSection(PassengerGroup group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.settings_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'الإجراءات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildActionButton(
              icon: Icons.people_alt_rounded,
              label: 'عرض الركاب',
              color: AppColors.dispatcherPrimary,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go(
                  '${RoutePaths.dispatcherHome}/groups/${widget.groupId}/passengers',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.schedule_rounded,
              label: 'إدارة الجداول',
              color: AppColors.primary,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(
                  '${RoutePaths.dispatcherHome}/groups/${widget.groupId}/schedules',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.play_circle_rounded,
              label: 'توليد رحلة جديدة',
              color: AppColors.success,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go(
                  '${RoutePaths.dispatcherHome}/trips/create?groupId=${widget.groupId}',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.edit_rounded,
              label: 'تعديل المجموعة',
              color: AppColors.warning,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go(
                  '${RoutePaths.dispatcherHome}/groups/${widget.groupId}/edit',
                );
              },
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.delete_rounded,
              label: 'حذف المجموعة',
              color: AppColors.error,
              onTap: () {
                HapticFeedback.mediumImpact();
                _confirmDeleteGroup(group);
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 800.ms);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isWarning ? AppColors.warning : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                  color: isWarning ? AppColors.warning : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return Formatters.displayDate(date);
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ShimmerCard(height: 200),
        SizedBox(height: 16),
        ShimmerCard(height: 150),
        SizedBox(height: 16),
        ShimmerCard(height: 150),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              error,
              style: const TextStyle(fontFamily: 'Cairo'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(groupByIdProvider(widget.groupId));
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

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.group_off_rounded,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'المجموعة غير موجودة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'المجموعة رقم ${widget.groupId} غير موجودة أو تم حذفها',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.go(RoutePaths.dispatcherGroups);
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(
                'العودة إلى المجموعات',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteGroup(PassengerGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'حذف المجموعة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف مجموعة "${group.name}"؟\n\nهذه العملية لا يمكن التراجع عنها.',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'حذف',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticFeedback.mediumImpact();

    final success =
        await ref.read(groupActionsProvider.notifier).deleteGroup(group.id);

    if (!mounted) return;

    if (success) {
      // Clear cache and refresh
      final cache = ref.read(dispatcherCacheDataSourceProvider);
      final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
      if (userId != 0) {
        await cache.delete(DispatcherCacheKeys.groups(userId: userId));
      }
      ref.invalidate(dispatcherGroupsProvider);
      ref.invalidate(groupByIdProvider(widget.groupId));

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'تم حذف المجموعة "${group.name}" بنجاح',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.success,
            ),
          );

        // Navigate back to groups list
        context.go(RoutePaths.dispatcherGroups);
      }
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر حذف المجموعة، حاول مرة أخرى',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }
}
