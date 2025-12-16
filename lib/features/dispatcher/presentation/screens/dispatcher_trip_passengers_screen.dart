import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../widgets/dispatcher_app_bar.dart';
import '../widgets/dispatcher_search_field.dart';
import '../widgets/dispatcher_add_trip_passenger_sheet.dart';

/// Manage passengers inside a specific trip.
class DispatcherTripPassengersScreen extends ConsumerStatefulWidget {
  final int tripId;

  const DispatcherTripPassengersScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<DispatcherTripPassengersScreen> createState() =>
      _DispatcherTripPassengersScreenState();
}

class _DispatcherTripPassengersScreenState
    extends ConsumerState<DispatcherTripPassengersScreen> {
  String _searchQuery = '';
  TripLineStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));
    final actionsState = ref.watch(activeTripProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: DispatcherAppBar(
        title: 'ركّاب الرحلة',
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(tripDetailProvider(widget.tripId));
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: Stack(
              children: [
                tripAsync.when(
                  data: (trip) {
                    if (trip == null) {
                      return _buildNotFoundState();
                    }
                    return _buildPassengersList(context, trip: trip);
                  },
                  loading: () => _buildLoadingState(),
                  error: (e, _) => _buildErrorState(e.toString()),
                ),
                if (actionsState.isLoading)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.08),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 12),
                        child: const LinearProgressIndicator(minHeight: 3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: tripAsync.whenOrNull(
        data: (trip) {
          if (trip == null) return null;
          // Only show FAB if trip is not completed/cancelled and has a group
          if (trip.state == TripState.done ||
              trip.state == TripState.cancelled) {
            return null;
          }
          return FloatingActionButton.extended(
            heroTag: 'dispatcher_trip_passengers_fab_${widget.tripId}',
            onPressed: () => _openAddPassengerSheet(context, trip),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label:
                const Text('إضافة راكب', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.dispatcherPrimary,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: DispatcherSearchField(
        hintText: 'ابحث عن راكب...',
        value: _searchQuery,
        onChanged: (value) => setState(() => _searchQuery = value),
        onClear: () => setState(() => _searchQuery = ''),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'الكل',
              isSelected: _statusFilter == null,
              onTap: () => setState(() => _statusFilter = null),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'في الانتظار',
              icon: Icons.hourglass_empty_rounded,
              color: AppColors.warning,
              isSelected: _statusFilter == TripLineStatus.notStarted,
              onTap: () =>
                  setState(() => _statusFilter = TripLineStatus.notStarted),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'صعدوا',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              isSelected: _statusFilter == TripLineStatus.boarded,
              onTap: () =>
                  setState(() => _statusFilter = TripLineStatus.boarded),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'غائبون',
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              isSelected: _statusFilter == TripLineStatus.absent,
              onTap: () =>
                  setState(() => _statusFilter = TripLineStatus.absent),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'نزلوا',
              icon: Icons.place_rounded,
              color: AppColors.primary,
              isSelected: _statusFilter == TripLineStatus.dropped,
              onTap: () =>
                  setState(() => _statusFilter = TripLineStatus.dropped),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: 50.ms);
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color ?? AppColors.textPrimary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color ?? AppColors.dispatcherPrimary,
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
      checkmarkColor: Colors.white,
      showCheckmark: false,
    );
  }

  Widget _buildPassengersList(BuildContext context, {required Trip trip}) {
    var filtered = trip.lines;

    // Apply search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered
          .where(
            (e) =>
                (e.passengerName?.toLowerCase().contains(q) ?? false) ||
                (e.passengerPhone?.toLowerCase().contains(q) ?? false) ||
                (e.guardianPhone?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    // Apply status filter
    if (_statusFilter != null) {
      filtered = filtered.where((e) => e.status == _statusFilter).toList();
    }

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.people_alt_rounded,
        title: 'لا يوجد ركّاب',
        message: _searchQuery.isNotEmpty || _statusFilter != null
            ? 'لا توجد نتائج مطابقة للبحث أو الفلتر'
            : 'هذه الرحلة لا تحتوي على ركّاب',
      );
    }

    final occupiedSeats = filtered.fold<int>(0, (sum, e) => sum + e.seatCount);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tripDetailProvider(widget.tripId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: filtered.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryCard(
              trip: trip,
              filteredCount: filtered.length,
              occupiedSeats: occupiedSeats,
            );
          }

          final line = filtered[index - 1];
          return _buildPassengerCard(
            context,
            trip: trip,
            line: line,
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required Trip trip,
    required int filteredCount,
    required int occupiedSeats,
  }) {
    final vehicleSeats = trip.seatCapacity;
    final availableSeats = vehicleSeats - trip.bookedSeats;
    final isOverCapacity = trip.bookedSeats > vehicleSeats && vehicleSeats > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Trip info header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  trip.tripType == TripType.pickup
                      ? Icons.arrow_circle_up_rounded
                      : Icons.arrow_circle_down_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      trip.tripType.arabicLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Cairo',
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(trip.state),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(Icons.people_rounded, 'الركّاب', '${trip.totalPassengers}'),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _stat(
                Icons.event_seat_rounded,
                'مقاعد المركبة',
                vehicleSeats > 0 ? '$vehicleSeats' : '-',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _stat(
                isOverCapacity
                    ? Icons.warning_rounded
                    : Icons.chair_alt_rounded,
                'المتاح',
                vehicleSeats > 0 ? '$availableSeats' : '-',
                valueColor: isOverCapacity
                    ? const Color(0xFFFFCDD2)
                    : const Color(0xFFC8E6C9),
              ),
            ],
          ),
          if (vehicleSeats > 0) ...[
            const SizedBox(height: 12),
            // Progress bar showing occupancy
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (trip.bookedSeats / vehicleSeats).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverCapacity
                      ? const Color(0xFFFF8A80)
                      : const Color(0xFFA5D6A7),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isOverCapacity
                  ? '⚠️ تجاوز السعة بـ ${-availableSeats} مقعد'
                  : 'مشغول: ${trip.bookedSeats} من $vehicleSeats مقعد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Status counts
          Row(
            children: [
              Expanded(
                child: _buildMiniStatChip(
                  icon: Icons.check_circle_rounded,
                  label: 'صعدوا',
                  count: trip.boardedCount,
                  color: const Color(0xFFA5D6A7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatChip(
                  icon: Icons.cancel_rounded,
                  label: 'غائبون',
                  count: trip.absentCount,
                  color: const Color(0xFFFFCDD2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatChip(
                  icon: Icons.place_rounded,
                  label: 'نزلوا',
                  count: trip.droppedCount,
                  color: const Color(0xFFBBDEFB),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildStatusBadge(TripState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        state.arabicLabel,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMiniStatChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.85),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerCard(
    BuildContext context, {
    required Trip trip,
    required TripLine line,
  }) {
    final subtitleParts = <String>[];

    final pickup = line.pickupLocationName;
    final dropoff = line.dropoffLocationName;
    if (pickup != 'غير محدد') {
      subtitleParts.add('📍 صعود: $pickup');
    }
    if (dropoff != 'غير محدد') {
      subtitleParts.add('🏁 نزول: $dropoff');
    }

    final note = line.notes?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          if (line.passengerId != null) {
            context.push(
              '${RoutePaths.dispatcherPassengers}/p/${line.passengerId}',
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: line.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(line.status),
                      color: line.status.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.passengerName ?? 'راكب #${line.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _chip(
                              icon: _getStatusIcon(line.status),
                              label: line.status.arabicLabel,
                              color: line.status.color,
                            ),
                            _chip(
                              icon: Icons.event_seat_rounded,
                              label: 'مقاعد: ${line.seatCount}',
                              color: AppColors.primary,
                            ),
                            if (line.passengerPhone?.isNotEmpty ?? false)
                              _chip(
                                icon: Icons.call_rounded,
                                label: line.passengerPhone!,
                                color: AppColors.textSecondary,
                              ),
                            if (line.guardianPhone?.isNotEmpty ?? false)
                              _chip(
                                icon: Icons.phone_in_talk_rounded,
                                label: 'ولي: ${line.guardianPhone}',
                                color: AppColors.textSecondary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildActionsMenu(trip, line),
                ],
              ),
              if (subtitleParts.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  subtitleParts.join('\n'),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'ملاحظة: $note',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 220.ms);
  }

  Widget _buildActionsMenu(Trip trip, TripLine line) {
    final canModify =
        trip.state != TripState.done && trip.state != TripState.cancelled;

    return PopupMenuButton<String>(
      tooltip: 'إجراءات',
      onSelected: (v) async {
        switch (v) {
          case 'boarded':
            await _markAsBoarded(line.id);
            break;
          case 'absent':
            await _markAsAbsent(line.id);
            break;
          case 'dropped':
            await _markAsDropped(line.id);
            break;
          case 'edit':
            await _openEditLineDialog(context, trip: trip, line: line);
            break;
          case 'remove':
            await _confirmRemovePassenger(context, trip: trip, line: line);
            break;
        }
      },
      itemBuilder: (context) => [
        // Status actions - only for ongoing trips
        if (trip.state.isOngoing) ...[
          if (line.status != TripLineStatus.boarded)
            const PopupMenuItem(
              value: 'boarded',
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success),
                  SizedBox(width: 10),
                  Text('تسجيل صعود', style: TextStyle(fontFamily: 'Cairo')),
                ],
              ),
            ),
          if (line.status != TripLineStatus.absent)
            const PopupMenuItem(
              value: 'absent',
              child: Row(
                children: [
                  Icon(Icons.cancel_rounded, color: AppColors.error),
                  SizedBox(width: 10),
                  Text('تسجيل غياب', style: TextStyle(fontFamily: 'Cairo')),
                ],
              ),
            ),
          if (line.status == TripLineStatus.boarded)
            const PopupMenuItem(
              value: 'dropped',
              child: Row(
                children: [
                  Icon(Icons.place_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('تسجيل نزول', style: TextStyle(fontFamily: 'Cairo')),
                ],
              ),
            ),
        ],
        // Edit/Remove actions - for modifiable trips
        if (canModify) ...[
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, color: AppColors.dispatcherPrimary),
                SizedBox(width: 10),
                Text('تعديل', style: TextStyle(fontFamily: 'Cairo')),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.person_remove_alt_1_rounded, color: AppColors.error),
                SizedBox(width: 10),
                Text('إزالة من الرحلة',
                    style:
                        TextStyle(fontFamily: 'Cairo', color: AppColors.error)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _markAsBoarded(int lineId) async {
    HapticFeedback.lightImpact();
    final success = await ref
        .read(activeTripProvider.notifier)
        .markPassengerBoarded(lineId);
    if (mounted) {
      if (success) {
        ref.invalidate(tripDetailProvider(widget.tripId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('تم تسجيل الصعود', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('فشل تسجيل الصعود', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markAsAbsent(int lineId) async {
    HapticFeedback.lightImpact();
    final success =
        await ref.read(activeTripProvider.notifier).markPassengerAbsent(lineId);
    if (mounted) {
      if (success) {
        ref.invalidate(tripDetailProvider(widget.tripId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('تم تسجيل الغياب', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('فشل تسجيل الغياب', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markAsDropped(int lineId) async {
    HapticFeedback.lightImpact();
    final success = await ref
        .read(activeTripProvider.notifier)
        .markPassengerDropped(lineId);
    if (mounted) {
      if (success) {
        ref.invalidate(tripDetailProvider(widget.tripId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('تم تسجيل النزول', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('فشل تسجيل النزول', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openAddPassengerSheet(BuildContext context, Trip trip) async {
    HapticFeedback.lightImpact();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DispatcherAddTripPassengerSheet(
        tripId: trip.id,
        tripName: trip.name,
        currentPassengers: trip.lines,
      ),
    );

    // Refresh after closing
    ref.invalidate(tripDetailProvider(widget.tripId));
  }

  Future<void> _openEditLineDialog(
    BuildContext context, {
    required Trip trip,
    required TripLine line,
  }) async {
    final seatController = TextEditingController(text: '${line.seatCount}');
    final notesController = TextEditingController(text: line.notes ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title:
              const Text('تعديل الراكب', style: TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: seatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد المقاعد',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dispatcherPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final seat = int.tryParse(seatController.text.trim());
    final notes = notesController.text.trim();

    final success = await ref.read(activeTripProvider.notifier).updateTripLine(
          tripId: trip.id,
          tripLineId: line.id,
          seatCount: seat,
          notes: notes.isEmpty ? null : notes,
        );

    if (mounted) {
      if (success) {
        ref.invalidate(tripDetailProvider(widget.tripId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('تم التعديل بنجاح', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل التعديل', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmRemovePassenger(
    BuildContext context, {
    required Trip trip,
    required TripLine line,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo')),
          content: Text(
            'هل تريد إزالة "${line.passengerName ?? 'هذا الراكب'}" من الرحلة؟',
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
              child: const Text('إزالة', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final success =
        await ref.read(activeTripProvider.notifier).removePassengerFromTrip(
              tripId: trip.id,
              tripLineId: line.id,
            );

    if (mounted) {
      if (success) {
        ref.invalidate(tripDetailProvider(widget.tripId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('تمت إزالة الراكب', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('فشل إزالة الراكب', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => const ShimmerCard(height: 120),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(fontFamily: 'Cairo'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
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
