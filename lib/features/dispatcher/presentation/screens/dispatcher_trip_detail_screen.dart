import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../widgets/dispatcher_app_bar.dart';

/// Dispatcher Trip Detail Screen - شاشة تفاصيل الرحلة للمرسل - ShuttleBee
class DispatcherTripDetailScreen extends ConsumerStatefulWidget {
  final int tripId;

  const DispatcherTripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<DispatcherTripDetailScreen> createState() =>
      _DispatcherTripDetailScreenState();
}

class _DispatcherTripDetailScreenState
    extends ConsumerState<DispatcherTripDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: DispatcherAppBar(
        title: 'تفاصيل الرحلة',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(
                  '${RoutePaths.dispatcherHome}/trips/${widget.tripId}/edit');
            },
            tooltip: 'تعديل الرحلة',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(tripDetailProvider(widget.tripId));
            },
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return _buildNotFoundState();
          }
          return _buildTripDetails(trip);
        },
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildTripDetails(Trip trip) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tripDetailProvider(widget.tripId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Trip Header Card
          _buildHeaderCard(trip),
          const SizedBox(height: 16),

          // Status & Time Card
          _buildStatusTimeCard(trip),
          const SizedBox(height: 16),

          // Driver & Vehicle Card
          _buildDriverVehicleCard(trip),
          const SizedBox(height: 16),

          // Passengers Section
          _buildPassengersSection(trip),
          const SizedBox(height: 16),

          // Notes Section
          if (trip.notes != null && trip.notes!.isNotEmpty) ...[
            _buildNotesCard(trip),
            const SizedBox(height: 16),
          ],

          // Actions Section
          _buildActionsSection(trip),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Trip trip) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              trip.tripType == TripType.pickup
                  ? AppColors.primary
                  : AppColors.success,
              trip.tripType == TripType.pickup
                  ? AppColors.primary.withValues(alpha: 0.8)
                  : AppColors.success.withValues(alpha: 0.8),
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
                  child: Icon(
                    trip.tripType == TripType.pickup
                        ? Icons.arrow_circle_up_rounded
                        : Icons.arrow_circle_down_rounded,
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
                        trip.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.tripType.arabicLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Cairo',
                          color: Colors.white.withValues(alpha: 0.9),
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
                  Icons.calendar_today_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    DateFormat('EEEE، d MMMM yyyy', 'ar').format(trip.date),
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Cairo',
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (trip.groupName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      trip.groupName!,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Cairo',
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatusTimeCard(Trip trip) {
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
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.dispatcherPrimary),
                const SizedBox(width: 8),
                const Text(
                  'الحالة والوقت',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.flag_rounded,
                    label: 'الحالة',
                    value: trip.state.arabicLabel,
                    valueColor: trip.state.color,
                  ),
                ),
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.access_time_rounded,
                    label: 'وقت البداية',
                    value: trip.plannedStartTime != null
                        ? DateFormat('HH:mm').format(trip.plannedStartTime!)
                        : '--:--',
                  ),
                ),
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.access_time_filled_rounded,
                    label: 'وقت الوصول',
                    value: trip.plannedArrivalTime != null
                        ? DateFormat('HH:mm').format(trip.plannedArrivalTime!)
                        : '--:--',
                  ),
                ),
              ],
            ),
            if (trip.actualStartTime != null ||
                trip.actualArrivalTime != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (trip.actualStartTime != null)
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'بدأت فعلياً',
                        value:
                            DateFormat('HH:mm').format(trip.actualStartTime!),
                        valueColor: AppColors.success,
                      ),
                    ),
                  if (trip.actualArrivalTime != null)
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'انتهت فعلياً',
                        value:
                            DateFormat('HH:mm').format(trip.actualArrivalTime!),
                        valueColor: AppColors.success,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildDriverVehicleCard(Trip trip) {
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
                const Icon(Icons.directions_bus_rounded,
                    color: AppColors.dispatcherPrimary),
                const SizedBox(width: 8),
                const Text(
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
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    icon: Icons.person_rounded,
                    label: 'السائق',
                    value: trip.driverName ?? 'لم يتم التعيين',
                    isWarning: trip.driverName == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    icon: Icons.directions_bus_rounded,
                    label: 'المركبة',
                    value: trip.vehicleName ?? 'لم يتم التعيين',
                    isWarning: trip.vehicleName == null,
                  ),
                ),
              ],
            ),
            if (trip.vehiclePlateNumber != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.confirmation_number_rounded,
                label: 'رقم اللوحة',
                value: trip.vehiclePlateNumber!,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildPassengersSection(Trip trip) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_rounded,
                        color: AppColors.dispatcherPrimary),
                    const SizedBox(width: 8),
                    const Text(
                      'الركاب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${trip.totalPassengers} راكب',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: AppColors.dispatcherPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push(
                          '${RoutePaths.dispatcherTrips}/${trip.id}/passengers',
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      tooltip: 'إدارة الركاب',
                      iconSize: 20,
                      color: AppColors.dispatcherPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatChip(
                        icon: Icons.check_circle_rounded,
                        label: 'صعدوا',
                        count: trip.boardedCount,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatChip(
                        icon: Icons.cancel_rounded,
                        label: 'غائبون',
                        count: trip.absentCount,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatChip(
                        icon: Icons.place_rounded,
                        label: 'نزلوا',
                        count: trip.droppedCount,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Passengers list
          if (trip.lines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 48,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'لا يوجد ركاب في هذه الرحلة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trip.lines.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final line = trip.lines[index];
                return _buildPassengerTile(line);
              },
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildPassengerTile(TripLine line) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: line.status.color.withValues(alpha: 0.1),
        child: Icon(
          _getStatusIcon(line.status),
          color: line.status.color,
          size: 20,
        ),
      ),
      title: Text(
        line.passengerName ?? 'راكب #${line.id}',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (line.passengerPhone != null)
            Text(
              line.passengerPhone!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          Text(
            line.status.arabicLabel,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: line.status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (line.pickupLocationName != 'غير محدد')
            Tooltip(
              message: 'موقع الصعود: ${line.pickupLocationName}',
              child: const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          if (line.hasGuardian)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'لديه ولي أمر',
                child: Icon(
                  Icons.family_restroom_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(TripLineStatus status) {
    switch (status) {
      case TripLineStatus.pending:
        return Icons.hourglass_empty_rounded;
      case TripLineStatus.notStarted:
        return Icons.schedule_rounded;
      case TripLineStatus.boarded:
        return Icons.check_circle_rounded;
      case TripLineStatus.absent:
        return Icons.cancel_rounded;
      case TripLineStatus.dropped:
        return Icons.place_rounded;
    }
  }

  Widget _buildNotesCard(Trip trip) {
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
                const Icon(Icons.notes_rounded,
                    color: AppColors.dispatcherPrimary),
                const SizedBox(width: 8),
                const Text(
                  'ملاحظات',
                  style: TextStyle(
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
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
  }

  Widget _buildActionsSection(Trip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Edit Button
        ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            context
                .go('${RoutePaths.dispatcherHome}/trips/${widget.tripId}/edit');
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
          label: const Text(
            'تعديل الرحلة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // State-based action buttons
        if (trip.canStart)
          OutlinedButton.icon(
            onPressed: () => _handleStartTrip(trip),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.success),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon:
                const Icon(Icons.play_arrow_rounded, color: AppColors.success),
            label: const Text(
              'بدء الرحلة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.success,
              ),
            ),
          ),

        if (trip.canComplete) ...[
          OutlinedButton.icon(
            onPressed: () => _handleCompleteTrip(trip),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.check_circle_rounded,
                color: AppColors.primary),
            label: const Text(
              'إنهاء الرحلة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ],

        if (trip.canCancel) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _handleCancelTrip(trip),
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
        ],
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 500.ms);
  }

  Future<void> _handleStartTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بدء الرحلة', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل تريد بدء هذه الرحلة الآن؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('بدء', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      final success =
          await ref.read(activeTripProvider.notifier).startTrip(trip.id);
      if (mounted) {
        if (success) {
          ref.invalidate(tripDetailProvider(widget.tripId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('تم بدء الرحلة', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('فشل بدء الرحلة', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCompleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            const Text('إنهاء الرحلة', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل تريد إنهاء هذه الرحلة؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('إنهاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      final success =
          await ref.read(activeTripProvider.notifier).completeTrip(trip.id);
      if (mounted) {
        if (success) {
          ref.invalidate(tripDetailProvider(widget.tripId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنهاء الرحلة',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل إنهاء الرحلة',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCancelTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            const Text('إلغاء الرحلة', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل أنت متأكد من إلغاء هذه الرحلة؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('إلغاء الرحلة',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      final success =
          await ref.read(activeTripProvider.notifier).cancelTrip(trip.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء الرحلة',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppColors.warning,
            ),
          );
          context.go('${RoutePaths.dispatcherHome}/trips');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل إلغاء الرحلة',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'Cairo',
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
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
          color: isWarning ? AppColors.warning : AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
              color: isWarning ? AppColors.warning : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'Cairo',
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ShimmerCard(height: 180),
        SizedBox(height: 16),
        ShimmerCard(height: 150),
        SizedBox(height: 16),
        ShimmerCard(height: 120),
        SizedBox(height: 16),
        ShimmerCard(height: 200),
      ],
    );
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
          Text(
            error,
            style: const TextStyle(fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(tripDetailProvider(widget.tripId));
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
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
          ElevatedButton(
            onPressed: () {
              context.go('${RoutePaths.dispatcherHome}/trips');
            },
            child: const Text('العودة للرحلات',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
