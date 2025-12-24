import 'package:bridgecore_flutter_starter/core/enums/trip_line_status.dart';
import 'package:bridgecore_flutter_starter/core/enums/trip_state.dart';
import 'package:bridgecore_flutter_starter/core/enums/trip_type.dart';
import 'package:bridgecore_flutter_starter/core/theme/app_colors.dart';
import 'package:bridgecore_flutter_starter/core/utils/formatters.dart';
import 'package:bridgecore_flutter_starter/features/trips/domain/entities/trip.dart';
import 'package:bridgecore_flutter_starter/features/trips/presentation/providers/trip_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of selecting a trip for absence
class AbsenceSelectionResult {
  final int tripId;
  final int tripLineId;
  final String tripName;

  const AbsenceSelectionResult({
    required this.tripId,
    required this.tripLineId,
    required this.tripName,
  });
}

/// Bottom sheet to select a trip for marking passenger absent
class SelectTripForAbsenceSheet extends ConsumerStatefulWidget {
  final int passengerId;
  final String passengerName;

  const SelectTripForAbsenceSheet({
    super.key,
    required this.passengerId,
    required this.passengerName,
  });

  /// Show the sheet and return selected trip info
  static Future<AbsenceSelectionResult?> show(
    BuildContext context, {
    required int passengerId,
    required String passengerName,
  }) {
    return showModalBottomSheet<AbsenceSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelectTripForAbsenceSheet(
        passengerId: passengerId,
        passengerName: passengerName,
      ),
    );
  }

  @override
  ConsumerState<SelectTripForAbsenceSheet> createState() =>
      _SelectTripForAbsenceSheetState();
}

class _SelectTripForAbsenceSheetState
    extends ConsumerState<SelectTripForAbsenceSheet> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Trip> _passengerTrips = [];

  @override
  void initState() {
    super.initState();
    _loadPassengerTrips();
  }

  Future<void> _loadPassengerTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(tripRepositoryProvider);
      if (repository == null) {
        setState(() {
          _errorMessage = 'لا يمكن الاتصال بالخادم';
          _isLoading = false;
        });
        return;
      }

      // Get trips for this passenger directly
      final result = await repository.getPassengerTrips(widget.passengerId);

      result.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
        (trips) {
          // Filter to show only today's and future trips (not past ones)
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final filteredTrips = trips.where((trip) {
            final tripDate = trip.date;
            return !tripDate.isBefore(today);
          }).toList();

          // Sort by date (nearest first)
          filteredTrips.sort((a, b) {
            final aDate = a.plannedStartTime ?? a.date;
            final bDate = b.plannedStartTime ?? b.date;
            return aDate.compareTo(bDate);
          });

          setState(() {
            _passengerTrips = filteredTrips;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // Header
            _buildHeader(context),
            const Divider(height: 1),
            // Content
            Flexible(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: AppColors.warning,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تسجيل غياب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.passengerName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.border.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'جاري البحث عن الرحلات...',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPassengerTrips,
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

    if (_passengerTrips.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد رحلات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'لا توجد رحلات لهذا الراكب اليوم أو غداً',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _passengerTrips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final trip = _passengerTrips[index];
        final tripLine = trip.lines.firstWhere(
          (line) => line.passengerId == widget.passengerId,
        );

        return _TripCard(
          trip: trip,
          tripLine: tripLine,
          onTap: () => _selectTrip(trip, tripLine),
        ).animate().fadeIn(
              duration: 200.ms,
              delay: (50 * index).ms,
            );
      },
    );
  }

  void _selectTrip(Trip trip, TripLine tripLine) {
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      AbsenceSelectionResult(
        tripId: trip.id,
        tripLineId: tripLine.id,
        tripName: trip.name,
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final TripLine tripLine;
  final VoidCallback onTap;

  const _TripCard({
    required this.trip,
    required this.tripLine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAbsent = tripLine.status == TripLineStatus.absent;

    final tripDate = trip.plannedStartTime ?? trip.date;
    final tripTime = trip.plannedStartTime;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAbsent ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAbsent
                ? AppColors.warning.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAbsent
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : AppColors.border,
              width: isAbsent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Trip type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      _getTripTypeColor(trip.tripType).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTripTypeIcon(trip.tripType),
                  color: _getTripTypeColor(trip.tripType),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Trip info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.name,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAbsent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'غائب',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.date(tripDate, pattern: 'EEEE، d MMM'),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tripTime != null
                              ? Formatters.time(tripTime, use24Hour: true)
                              : '-',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusChip(
                          label: _getTripTypeLabel(trip.tripType),
                          color: _getTripTypeColor(trip.tripType),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: _getTripStateLabel(trip.state),
                          color: _getTripStateColor(trip.state),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action icon
              if (!isAbsent)
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTripTypeIcon(TripType? type) {
    switch (type) {
      case TripType.pickup:
        return Icons.login_rounded;
      case TripType.dropoff:
        return Icons.logout_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color _getTripTypeColor(TripType? type) {
    switch (type) {
      case TripType.pickup:
        return AppColors.success;
      case TripType.dropoff:
        return AppColors.primary;
      default:
        return AppColors.dispatcherPrimary;
    }
  }

  String _getTripTypeLabel(TripType? type) {
    switch (type) {
      case TripType.pickup:
        return 'صعود';
      case TripType.dropoff:
        return 'نزول';
      default:
        return 'رحلة';
    }
  }

  String _getTripStateLabel(TripState? state) {
    switch (state) {
      case TripState.draft:
        return 'مسودة';
      case TripState.planned:
        return 'مخطط';
      case TripState.ongoing:
        return 'جارية';
      case TripState.done:
        return 'منتهية';
      case TripState.cancelled:
        return 'ملغاة';
      default:
        return '-';
    }
  }

  Color _getTripStateColor(TripState? state) {
    switch (state) {
      case TripState.draft:
        return AppColors.textSecondary;
      case TripState.planned:
        return AppColors.primary;
      case TripState.ongoing:
        return AppColors.success;
      case TripState.done:
        return AppColors.dispatcherPrimary;
      case TripState.cancelled:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
