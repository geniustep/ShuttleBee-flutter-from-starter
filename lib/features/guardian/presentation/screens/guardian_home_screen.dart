import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../domain/entities/guardian_info.dart';
import '../providers/guardian_providers.dart';

/// شاشة ولي الأمر الرئيسية - ShuttleBee
class GuardianHomeScreen extends ConsumerStatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  ConsumerState<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends ConsumerState<GuardianHomeScreen> {
  int? _selectedDependentId;

  @override
  Widget build(BuildContext context) {
    final guardianAsync = ref.watch(currentGuardianProvider);
    final dependentsAsync = ref.watch(dependentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(guardianAsync),
          SliverToBoxAdapter(child: _buildDependentSelector(dependentsAsync)),
          SliverToBoxAdapter(child: _buildTodayTrips()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildDependentStats()),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar(AsyncValue<GuardianInfo?> guardianAsync) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF7C3AED),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.family_restroom_rounded,
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
                              'مرحباً',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontFamily: 'Cairo',
                              ),
                            ),
                            guardianAsync.when(
                              data: (guardian) => Text(
                                guardian?.name ?? 'ولي الأمر',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              loading: () => const SizedBox(
                                height: 24,
                                width: 100,
                                child: LinearProgressIndicator(
                                  color: Colors.white,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                              error: (_, __) => const Text(
                                'ولي الأمر',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: Colors.white,
                        onPressed: () => context.push('/notifications'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        color: Colors.white,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ref.invalidate(currentGuardianProvider);
                          ref.invalidate(dependentsProvider);
                          ref.invalidate(todayDependentTripsProvider);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDependentSelector(
    AsyncValue<List<DependentPassenger>> dependentsAsync,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أبنائي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          dependentsAsync.when(
            data: (dependents) {
              if (dependents.isEmpty) {
                return _buildNoDependents();
              }

              // تحديد أول تابع إذا لم يتم التحديد
              _selectedDependentId ??= dependents.first.id;

              return SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: dependents.length,
                  itemBuilder: (context, index) {
                    final dependent = dependents[index];
                    final isSelected = dependent.id == _selectedDependentId;

                    return _buildDependentCard(dependent, isSelected, index);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text(
                'خطأ في تحميل البيانات',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDependentCard(
    DependentPassenger dependent,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDependentId = dependent.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        margin: EdgeInsets.only(left: index == 0 ? 0 : 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : Colors.grey.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFF7C3AED).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.person_rounded,
                color: isSelected ? Colors.white : const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dependent.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDependents() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add_alt_1_rounded,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'لا يوجد أبناء مسجلين',
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

  Widget _buildTodayTrips() {
    final tripsAsync = ref.watch(todayDependentTripsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'رحلات اليوم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/trips'),
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          tripsAsync.when(
            data: (trips) {
              if (trips.isEmpty) {
                return _buildNoTripsToday();
              }

              return Column(
                children:
                    trips.take(3).map((trip) => _buildTripCard(trip)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'خطأ في تحميل الرحلات',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildNoTripsToday() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد رحلات اليوم',
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

  Widget _buildTripCard(Trip trip) {
    final isOngoing = trip.state == TripState.ongoing;
    final color = isOngoing ? Colors.green : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (isOngoing) {
            context.push('/trip-tracking/${trip.id}');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  trip.tripType == TripType.pickup
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: color,
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trip.plannedStartTime != null
                              ? _formatTime(trip.plannedStartTime!)
                              : '--:--',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStateColor(trip.state)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getStateLabel(trip.state),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStateColor(trip.state),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOngoing)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.gps_fixed_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'تسجيل غياب',
                  Icons.event_busy_rounded,
                  Colors.orange,
                  () => _showReportAbsenceDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'تتبع مباشر',
                  Icons.gps_fixed_rounded,
                  Colors.green,
                  () => _trackActiveTrip(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'الإشعارات',
                  Icons.notifications_rounded,
                  const Color(0xFF7C3AED),
                  () => context.push('/notifications'),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDependentStats() {
    if (_selectedDependentId == null) return const SizedBox.shrink();

    final dependentsAsync = ref.watch(dependentsProvider);

    return dependentsAsync
        .when(
          data: (dependents) {
            final dependent = dependents.firstWhere(
              (d) => d.id == _selectedDependentId,
              orElse: () => dependents.first,
            );

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إحصائيات ${dependent.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'إجمالي الرحلات',
                          '${dependent.stats.totalTrips}',
                          Icons.route_rounded,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'الحضور',
                          '${dependent.stats.presentTrips}',
                          Icons.check_circle_rounded,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'الغياب',
                          '${dependent.stats.absentTrips}',
                          Icons.cancel_rounded,
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'نسبة الحضور',
                          '${dependent.stats.attendanceRate.toStringAsFixed(0)}%',
                          Icons.trending_up_rounded,
                          const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStateColor(TripState state) {
    switch (state) {
      case TripState.ongoing:
        return Colors.green;
      case TripState.planned:
        return Colors.blue;
      case TripState.done:
        return Colors.grey;
      case TripState.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStateLabel(TripState state) {
    switch (state) {
      case TripState.ongoing:
        return 'جارية';
      case TripState.planned:
        return 'مخططة';
      case TripState.done:
        return 'مكتملة';
      case TripState.cancelled:
        return 'ملغاة';
      default:
        return 'مسودة';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showReportAbsenceDialog() {
    // TODO: Implement report absence dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة نموذج تسجيل الغياب قريباً'),
      ),
    );
  }

  void _trackActiveTrip() async {
    if (_selectedDependentId == null) return;

    final tripAsync =
        ref.read(activeTripForDependentProvider(_selectedDependentId!));

    tripAsync.whenData((trip) {
      if (trip != null) {
        context.push('/trip-tracking/${trip.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد رحلة نشطة حالياً'),
          ),
        );
      }
    });
  }
}
