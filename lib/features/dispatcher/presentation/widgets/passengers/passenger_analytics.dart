import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/passenger_group_line.dart';

/// Passenger analytics and statistics
class PassengerAnalytics {
  final List<PassengerGroupLine> passengers;

  const PassengerAnalytics(this.passengers);

  int get totalPassengers => passengers.length;

  int get assignedPassengers =>
      passengers.where((p) => p.groupId != null).length;

  int get unassignedPassengers =>
      passengers.where((p) => p.groupId == null).length;

  int get passengersWithPhone =>
      passengers.where((p) =>
          (p.passengerPhone ?? '').isNotEmpty ||
          (p.passengerMobile ?? '').isNotEmpty).length;

  int get passengersWithGuardian =>
      passengers.where((p) =>
          (p.fatherPhone ?? '').isNotEmpty ||
          (p.motherPhone ?? '').isNotEmpty ||
          (p.guardianPhone ?? '').isNotEmpty).length;

  Map<String, int> get groupDistribution {
    final Map<String, int> distribution = {};
    for (final passenger in passengers) {
      final groupName = passenger.groupName ?? 'غير معين';
      distribution[groupName] = (distribution[groupName] ?? 0) + 1;
    }
    return distribution;
  }

  int get totalSeats => passengers.fold<int>(
        0,
        (sum, p) => sum + p.seatCount,
      );
}

/// Analytics dashboard widget
class PassengerAnalyticsDashboard extends StatelessWidget {
  final PassengerAnalytics analytics;

  const PassengerAnalyticsDashboard({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Stats cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_rounded,
                label: 'إجمالي الركاب',
                value: analytics.totalPassengers.toString(),
                color: AppColors.dispatcherPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_rounded,
                label: 'معين',
                value: analytics.assignedPassengers.toString(),
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.person_off_rounded,
                label: 'غير معين',
                value: analytics.unassignedPassengers.toString(),
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.phone_rounded,
                label: 'لديهم هاتف',
                value: analytics.passengersWithPhone.toString(),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Group distribution chart
        const Text(
          'توزيع المجموعات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _GroupDistributionChart(
            distribution: analytics.groupDistribution,
          ),
        ),
        const SizedBox(height: 24),
        // Group list
        const Text(
          'تفاصيل المجموعات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...analytics.groupDistribution.entries.map((entry) {
          final percentage = analytics.totalPassengers > 0
              ? (entry.value / analytics.totalPassengers * 100).toStringAsFixed(1)
              : '0';
          return _GroupItem(
            groupName: entry.key,
            count: entry.value,
            percentage: percentage,
          );
        }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;

  const _GroupDistributionChart({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final entries = distribution.entries.toList();
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد بيانات',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final groupEntry = entry.value;
          final colors = [
            AppColors.dispatcherPrimary,
            AppColors.success,
            AppColors.warning,
            AppColors.error,
            AppColors.primary,
          ];
          return PieChartSectionData(
            value: groupEntry.value.toDouble(),
            title: '${groupEntry.key}\n${groupEntry.value}',
            color: colors[index % colors.length],
            radius: 80,
            titleStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}

class _GroupItem extends StatelessWidget {
  final String groupName;
  final int count;
  final String percentage;

  const _GroupItem({
    required this.groupName,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.groups_rounded,
            color: AppColors.dispatcherPrimary,
          ),
        ),
        title: Text(
          groupName,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$count راكب',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

