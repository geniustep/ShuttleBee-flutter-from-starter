import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../stops/presentation/providers/stop_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';

/// لوحة تحكم المدير المحسنة - ShuttleBee
class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildQuickStats()),
          SliverToBoxAdapter(child: _buildTodayOverview()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildResourceCards()),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1E40AF)],
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
                  const SizedBox(height: 40),
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
                          Icons.dashboard_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'لوحة التحكم',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        color: Colors.white,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _refreshAll();
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

  Widget _buildQuickStats() {
    final statsAsync = ref.watch(dashboardStatsProvider(DateTime.now()));

    return Container(
      margin: const EdgeInsets.all(16),
      child: statsAsync.when(
        data: (stats) => Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'الرحلات اليوم',
                '${stats.totalTripsToday}',
                Icons.route_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(
                'جارية',
                '${stats.ongoingTrips}',
                Icons.play_circle_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(
                'مكتملة',
                '${stats.completedTrips}',
                Icons.check_circle_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(
                'الركاب',
                '${stats.totalPassengers}',
                Icons.people_rounded,
                Colors.purple,
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMiniStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
      ),
    );
  }

  Widget _buildTodayOverview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade400,
            Colors.purple.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'نظرة عامة اليوم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(DateTime.now()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildOverviewItem('صعود', '12', '🚌')),
              Expanded(child: _buildOverviewItem('نزول', '10', '🏠')),
              Expanded(child: _buildOverviewItem('حضور', '95%', '✅')),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildOverviewItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
            fontFamily: 'Cairo',
          ),
        ),
      ],
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
                child: _buildActionButton(
                  'رحلة جديدة',
                  Icons.add_road_rounded,
                  Colors.blue,
                  () => context.push('/trips/create'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'إرسال إشعار',
                  Icons.notifications_active_rounded,
                  Colors.orange,
                  () => _showSendNotificationDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'تقرير',
                  Icons.analytics_rounded,
                  Colors.green,
                  () => context.push('/reports'),
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

  Widget _buildActionButton(
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إدارة الموارد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildResourceCard(
                'المركبات',
                vehicleCountProvider,
                Icons.directions_bus_rounded,
                Colors.blue,
                () => context.push('/vehicles'),
              ),
              _buildResourceCard(
                'نقاط التوقف',
                stopCountProvider,
                Icons.location_on_rounded,
                Colors.green,
                () => context.push('/stops'),
              ),
              _buildResourceCard(
                'المجموعات',
                groupCountProvider,
                Icons.groups_rounded,
                Colors.purple,
                () => context.push('/groups'),
              ),
              _buildResourceCard(
                'الإشعارات',
                null,
                Icons.notifications_rounded,
                Colors.orange,
                () => context.push('/notifications'),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildResourceCard(
    String title,
    FutureProvider<int>? countProvider,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const Spacer(),
              if (countProvider != null)
                Consumer(
                  builder: (context, ref, child) {
                    final countAsync = ref.watch(countProvider);
                    return countAsync.when(
                      data: (count) => Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => const Text(
                        '--',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    );
                  },
                )
              else
                Icon(icon, color: color, size: 28),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير 👋';
    if (hour < 17) return 'مساء الخير 👋';
    return 'مساء الخير 👋';
  }

  String _formatDate(DateTime date) {
    final days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${days[date.weekday % 7]}، ${date.day} ${months[date.month - 1]}';
  }

  void _refreshAll() {
    ref.invalidate(dashboardStatsProvider(DateTime.now()));
    ref.invalidate(vehicleCountProvider);
    ref.invalidate(stopCountProvider);
    ref.invalidate(groupCountProvider);
  }

  void _showSendNotificationDialog() {
    // TODO: Implement send notification dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة نموذج إرسال إشعار قريباً'),
      ),
    );
  }
}
