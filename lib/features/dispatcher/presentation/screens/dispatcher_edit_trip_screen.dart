import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../widgets/dispatcher_app_bar.dart';
import '../widgets/dispatcher_add_trip_passenger_sheet.dart';

/// Dispatcher Edit Trip Screen - شاشة تعديل الرحلة للمرسل - ShuttleBee
class DispatcherEditTripScreen extends ConsumerStatefulWidget {
  final int tripId;

  const DispatcherEditTripScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<DispatcherEditTripScreen> createState() =>
      _DispatcherEditTripScreenState();
}

class _DispatcherEditTripScreenState
    extends ConsumerState<DispatcherEditTripScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  TripType _tripType = TripType.pickup;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _arrivalTime;
  int? _selectedGroupId;
  int? _selectedVehicleId;
  int? _selectedDriverId;
  bool _isLoading = false;
  bool _initialized = false;
  Trip? _originalTrip;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFromTrip(Trip trip) {
    if (_initialized) return;
    _initialized = true;
    _originalTrip = trip;

    _nameController.text = trip.name;
    _notesController.text = trip.notes ?? '';
    _tripType = trip.tripType;
    _selectedDate = trip.date;
    _selectedGroupId = trip.groupId;
    _selectedVehicleId = trip.vehicleId;
    _selectedDriverId = trip.driverId;

    if (trip.plannedStartTime != null) {
      _startTime = TimeOfDay.fromDateTime(trip.plannedStartTime!);
    }
    if (trip.plannedArrivalTime != null) {
      _arrivalTime = TimeOfDay.fromDateTime(trip.plannedArrivalTime!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));
    final vehiclesAsync = ref.watch(allVehiclesProvider);
    final groupsAsync = ref.watch(allGroupsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: DispatcherAppBar(
        title: 'تعديل الرحلة',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _initialized = false);
              ref.invalidate(tripDetailProvider(widget.tripId));
            },
            tooltip: 'تحديث',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.info_outline_rounded),
              text: 'المعلومات',
            ),
            Tab(
              icon: Icon(Icons.people_rounded),
              text: 'الركاب',
            ),
          ],
        ),
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return _buildNotFoundState();
          }
          _initFromTrip(trip);
          return TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(groupsAsync, vehiclesAsync),
              _buildPassengersTab(trip),
            ],
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildInfoTab(
    AsyncValue<List<PassengerGroup>> groupsAsync,
    AsyncValue<List<ShuttleVehicle>> vehiclesAsync,
  ) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Info Card
          _buildBasicInfoCard(),
          const SizedBox(height: 16),

          // Trip Type Card
          _buildTripTypeCard(),
          const SizedBox(height: 16),

          // Date & Time Card
          _buildDateTimeCard(),
          const SizedBox(height: 16),

          // Group & Vehicle Card
          _buildGroupVehicleCard(groupsAsync, vehiclesAsync),
          const SizedBox(height: 16),

          // Notes Card
          _buildNotesCard(),
          const SizedBox(height: 24),

          // Save Button
          _buildSaveButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPassengersTab(Trip trip) {
    if (trip.lines.isEmpty) {
      return _buildEmptyPassengersState(trip);
    }
    return _buildPassengersList(trip);
  }

  Widget _buildEmptyPassengersState(Trip trip) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد ركاب في هذه الرحلة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddPassengerDialog(trip),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dispatcherPrimary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text(
              'إضافة راكب',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengersList(Trip trip) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trip.lines.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildPassengersHeader(trip);
        }
        final line = trip.lines[index - 1];
        return _buildPassengerCard(line, trip);
      },
    );
  }

  Widget _buildPassengersHeader(Trip trip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${Formatters.formatSimple(trip.lines.length)} راكب',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: AppColors.dispatcherPrimary,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddPassengerDialog(trip),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dispatcherPrimary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text(
              'إضافة راكب',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(TripLine line, Trip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: line.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    line.status.getLocalizedLabel(context),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: line.status.color,
                    ),
                  ),
                ),
                if (line.pickupLocationName != 'غير محدد')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 10,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            line.pickupLocationName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: _buildPassengerActions(line, trip),
      ),
    );
  }

  Widget _buildPassengerActions(TripLine line, Trip trip) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) => _handlePassengerAction(value, line, trip),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit_location',
          child: Row(
            children: [
              Icon(Icons.edit_location_rounded, size: 20),
              SizedBox(width: 8),
              Text('تعديل الموقع', style: TextStyle(fontFamily: 'Cairo')),
            ],
          ),
        ),
        if (line.status == TripLineStatus.notStarted)
          const PopupMenuItem(
            value: 'mark_boarded',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.success,
                ),
                SizedBox(width: 8),
                Text('تسجيل صعود', style: TextStyle(fontFamily: 'Cairo')),
              ],
            ),
          ),
        if (line.status == TripLineStatus.notStarted)
          const PopupMenuItem(
            value: 'mark_absent',
            child: Row(
              children: [
                Icon(Icons.cancel_rounded, size: 20, color: AppColors.error),
                SizedBox(width: 8),
                Text('تسجيل غياب', style: TextStyle(fontFamily: 'Cairo')),
              ],
            ),
          ),
        if (line.status == TripLineStatus.boarded)
          const PopupMenuItem(
            value: 'mark_dropped',
            child: Row(
              children: [
                Icon(Icons.place_rounded, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text('تسجيل نزول', style: TextStyle(fontFamily: 'Cairo')),
              ],
            ),
          ),
        if (line.status != TripLineStatus.notStarted)
          const PopupMenuItem(
            value: 'reset',
            child: Row(
              children: [
                Icon(Icons.undo_rounded, size: 20),
                SizedBox(width: 8),
                Text('إعادة تعيين', style: TextStyle(fontFamily: 'Cairo')),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 20, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'إزالة من الرحلة',
                style: TextStyle(fontFamily: 'Cairo', color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
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

  Future<void> _handlePassengerAction(
    String action,
    TripLine line,
    Trip trip,
  ) async {
    HapticFeedback.lightImpact();

    switch (action) {
      case 'mark_boarded':
        final success = await ref
            .read(activeTripProvider.notifier)
            .markPassengerBoarded(line.id);
        _showActionResult(success, 'تم تسجيل الصعود', 'فشل تسجيل الصعود');
        break;
      case 'mark_absent':
        final success = await ref
            .read(activeTripProvider.notifier)
            .markPassengerAbsent(line.id);
        _showActionResult(success, 'تم تسجيل الغياب', 'فشل تسجيل الغياب');
        break;
      case 'mark_dropped':
        final success = await ref
            .read(activeTripProvider.notifier)
            .markPassengerDropped(line.id);
        _showActionResult(success, 'تم تسجيل النزول', 'فشل تسجيل النزول');
        break;
      case 'reset':
        final success = await ref
            .read(activeTripProvider.notifier)
            .resetPassengerToPlanned(line.id);
        _showActionResult(success, 'تم إعادة التعيين', 'فشل إعادة التعيين');
        break;
      case 'edit_location':
        _showEditLocationDialog(line);
        break;
      case 'remove':
        _showRemovePassengerDialog(line, trip);
        break;
    }

    // Refresh trip data
    if (action != 'edit_location' && action != 'remove') {
      ref.invalidate(tripDetailProvider(widget.tripId));
    }
  }

  void _showActionResult(bool success, String successMsg, String failMsg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? successMsg : failMsg,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _showAddPassengerDialog(Trip trip) async {
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

  Future<void> _showEditLocationDialog(TripLine line) async {
    // TODO: Implement edit location dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'سيتم تنفيذ تعديل الموقع قريباً',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  Future<void> _showRemovePassengerDialog(TripLine line, Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة راكب', style: TextStyle(fontFamily: 'Cairo')),
        content: Text(
          'هل تريد إزالة ${line.passengerName ?? "هذا الراكب"} من الرحلة؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('إزالة', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.lightImpact();

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
              content: Text(
                'تمت إزالة الراكب بنجاح',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'فشل إزالة الراكب',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildBasicInfoCard() {
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: _buildInputDecoration(
                label: 'اسم الرحلة',
                hint: 'أدخل اسم الرحلة',
                icon: Icons.route_rounded,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال اسم الرحلة';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildTripTypeCard() {
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
                  Icons.swap_vert_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'نوع الرحلة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTripTypeOption(
                    type: TripType.pickup,
                    icon: Icons.arrow_upward_rounded,
                    label: 'صعود',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTripTypeOption(
                    type: TripType.dropoff,
                    icon: Icons.arrow_downward_rounded,
                    label: 'نزول',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildTripTypeOption({
    required TripType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _tripType == type;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _tripType = type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.dispatcherPrimary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.dispatcherPrimary
                : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.dispatcherPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isSelected
                    ? AppColors.dispatcherPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
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
                  Icons.schedule_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'التاريخ والوقت',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Date
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.dispatcherPrimary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'التاريخ',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            Formatters.displayDate(_selectedDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Times Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartTime(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.play_circle_outline_rounded,
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'وقت البداية',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _startTime.format(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectArrivalTime(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'وقت الوصول',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _arrivalTime?.format(context) ?? '--:--',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildGroupVehicleCard(
    AsyncValue<List<PassengerGroup>> groupsAsync,
    AsyncValue<List<ShuttleVehicle>> vehiclesAsync,
  ) {
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
                  'المجموعة والمركبة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Group Dropdown
            groupsAsync.when(
              data: (groups) {
                final activeGroups = groups.where((g) => g.active).toList();
                return DropdownButtonFormField<int>(
                  initialValue: _selectedGroupId,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                    label: 'المجموعة',
                    hint: 'اختر المجموعة',
                    icon: Icons.groups_rounded,
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        'بدون مجموعة',
                        style: TextStyle(fontFamily: 'Cairo'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...activeGroups.map((group) {
                      return DropdownMenuItem<int>(
                        value: group.id,
                        child: Text(
                          group.name,
                          style: const TextStyle(fontFamily: 'Cairo'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedGroupId = value);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            // Vehicle Dropdown
            vehiclesAsync.when(
              data: (vehicles) {
                final activeVehicles =
                    vehicles.where((v) => v.active == true).toList();
                return DropdownButtonFormField<int>(
                  initialValue: _selectedVehicleId,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                    label: 'المركبة',
                    hint: 'اختر المركبة',
                    icon: Icons.directions_bus_rounded,
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        'بدون مركبة',
                        style: TextStyle(fontFamily: 'Cairo'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...activeVehicles.map((vehicle) {
                      return DropdownMenuItem<int>(
                        value: vehicle.id,
                        child: Text(
                          '${vehicle.name} (${vehicle.licensePlate ?? "بدون لوحة"})',
                          style: const TextStyle(fontFamily: 'Cairo'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedVehicleId = value);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
  }

  Widget _buildNotesCard() {
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
                  Icons.notes_rounded,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: _buildInputDecoration(
                label: 'ملاحظات',
                hint: 'أضف ملاحظات للرحلة (اختياري)',
                icon: Icons.notes_rounded,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 500.ms);
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dispatcherPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(
          _isLoading ? 'جاري الحفظ...' : 'حفظ التغييرات',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 600.ms);
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.dispatcherPrimary),
      labelStyle: const TextStyle(fontFamily: 'Cairo'),
      hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.dispatcherPrimary, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectArrivalTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _arrivalTime ?? _startTime,
    );
    if (picked != null) {
      setState(() => _arrivalTime = picked);
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originalTrip == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Build updated trip
      final plannedStartTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      DateTime? plannedArrivalTime;
      if (_arrivalTime != null) {
        plannedArrivalTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _arrivalTime!.hour,
          _arrivalTime!.minute,
        );
      }

      final updatedTrip = _originalTrip!.copyWith(
        name: _nameController.text.trim(),
        tripType: _tripType,
        date: _selectedDate,
        plannedStartTime: plannedStartTime,
        plannedArrivalTime: plannedArrivalTime,
        groupId: _selectedGroupId,
        vehicleId: _selectedVehicleId,
        driverId: _selectedDriverId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Get repository
      final repository = ref.read(tripRepositoryProvider);
      if (repository == null) {
        throw Exception('خطأ في الاتصال');
      }

      final result = await repository.updateTrip(updatedTrip);

      if (mounted) {
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'خطأ: ${failure.message}',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          },
          (trip) {
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم حفظ التغييرات بنجاح',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.success,
              ),
            );

            // Invalidate caches
            ref.invalidate(tripDetailProvider(widget.tripId));

            // Navigate back to trip detail
            context.go('${RoutePaths.dispatcherHome}/trips/${widget.tripId}');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ShimmerCard(height: 100),
        SizedBox(height: 16),
        ShimmerCard(height: 120),
        SizedBox(height: 16),
        ShimmerCard(height: 180),
        SizedBox(height: 16),
        ShimmerCard(height: 150),
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
              setState(() => _initialized = false);
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
            child: const Text(
              'العودة للرحلات',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}
