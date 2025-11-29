import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Manager Analytics Screen - شاشة التحليلات المتقدمة - ShuttleBee
///
/// عرض تحليلات وإحصائيات متقدمة مع رسوم بيانية تفاعلية
class ManagerAnalyticsScreen extends ConsumerStatefulWidget {
  const ManagerAnalyticsScreen({super.key});

  @override
  ConsumerState<ManagerAnalyticsScreen> createState() =>
      _ManagerAnalyticsScreenState();
}

class _ManagerAnalyticsScreenState
    extends ConsumerState<ManagerAnalyticsScreen> {
  String _selectedPeriod = 'month'; // month, week, day

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(managerAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التحليلات المتقدمة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(managerAnalyticsProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) => _buildContent(analytics),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppDimensions.md),
          Text(error,
              style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.md),
          ElevatedButton(
            onPressed: () => ref.invalidate(managerAnalyticsProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ManagerAnalytics analytics) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(managerAnalyticsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(),

            const SizedBox(height: AppDimensions.lg),

            // Key Performance Indicators
            Text('مؤشرات الأداء الرئيسية', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            _buildKPICards(analytics),

            const SizedBox(height: AppDimensions.xl),

            // Trip Trend Chart
            Text('اتجاه الرحلات', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            _buildTripTrendChart(analytics),

            const SizedBox(height: AppDimensions.xl),

            // Performance Distribution
            Text('توزيع الأداء', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            _buildPerformanceDistribution(analytics),

            const SizedBox(height: AppDimensions.xl),

            // Resource Utilization Chart
            Text('استخدام الموارد', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            _buildResourceUtilizationChart(analytics),

            const SizedBox(height: AppDimensions.xl),

            // Weekly Comparison
            Text('المقارنة الأسبوعية', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            _buildWeeklyComparison(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.sm),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: AppDimensions.sm),
            const Text('الفترة:'),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'day',
                    label: Text('يوم'),
                    icon: Icon(Icons.today, size: 16),
                  ),
                  ButtonSegment(
                    value: 'week',
                    label: Text('أسبوع'),
                    icon: Icon(Icons.date_range, size: 16),
                  ),
                  ButtonSegment(
                    value: 'month',
                    label: Text('شهر'),
                    icon: Icon(Icons.calendar_month, size: 16),
                  ),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _selectedPeriod = selection.first;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards(ManagerAnalytics analytics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.md,
      crossAxisSpacing: AppDimensions.md,
      childAspectRatio: 1.3,
      children: [
        _buildKPICard(
          'معدل النجاح',
          '${analytics.completionRate.toStringAsFixed(1)}%',
          Icons.check_circle,
          AppColors.success,
          trend: 2.5,
        ),
        _buildKPICard(
          'رضا العملاء',
          '4.8/5.0',
          Icons.star,
          AppColors.warning,
          trend: 0.3,
        ),
        _buildKPICard(
          'الالتزام بالمواعيد',
          '${analytics.onTimePercentage.toStringAsFixed(1)}%',
          Icons.schedule,
          AppColors.primary,
          trend: -1.2,
        ),
        _buildKPICard(
          'متوسط التأخير',
          '${analytics.averageDelayMinutes.toStringAsFixed(0)} د',
          Icons.timer,
          AppColors.error,
          trend: -0.5,
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String label,
    String value,
    IconData icon,
    Color color, {
    double? trend,
  }) {
    final isTrendPositive = trend != null && trend > 0;
    final trendColor = isTrendPositive ? AppColors.success : AppColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 8),
                if (trend != null)
                  Icon(
                    isTrendPositive
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 16,
                    color: trendColor,
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              value,
              style: AppTypography.h4.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (trend != null) ...[
              const SizedBox(height: 4),
              Text(
                '${isTrendPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
                style: AppTypography.caption.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripTrendChart(ManagerAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('منجزة', style: AppTypography.caption),
                    const SizedBox(width: AppDimensions.md),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('ملغاة', style: AppTypography.caption),
                  ],
                ),
                Text(
                  DateFormat('MMMM yyyy', 'ar').format(DateTime.now()),
                  style: AppTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'السبت',
                            'الأحد',
                            'الاثنين',
                            'الثلاثاء',
                            'الأربعاء',
                            'الخميس',
                            'الجمعة'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                days[value.toInt()],
                                style: AppTypography.caption,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: AppTypography.caption,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Completed trips line
                    LineChartBarData(
                      spots: _generateDummyData(7, 15, 30),
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.success.withOpacity(0.1),
                      ),
                    ),
                    // Cancelled trips line
                    LineChartBarData(
                      spots: _generateDummyData(7, 2, 8),
                      isCurved: true,
                      color: AppColors.error,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.error.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceDistribution(ManagerAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: analytics.completedTripsThisMonth.toDouble(),
                      title:
                          '${analytics.completedTripsThisMonth}\nمنجزة',
                      color: AppColors.success,
                      radius: 80,
                      titleStyle: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: (analytics.totalTripsThisMonth -
                              analytics.completedTripsThisMonth)
                          .toDouble(),
                      title:
                          '${analytics.totalTripsThisMonth - analytics.completedTripsThisMonth}\nأخرى',
                      color: AppColors.warning,
                      radius: 80,
                      titleStyle: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('منجزة', AppColors.success),
                _buildLegendItem('أخرى', AppColors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceUtilizationChart(ManagerAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الاستخدام الشهري', style: AppTypography.bodyMedium),
            const SizedBox(height: AppDimensions.lg),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = [
                            'المسافة\n(كم)',
                            'الوقود\n(ريال)',
                            'الركاب'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[value.toInt()],
                                style: AppTypography.caption,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: AppTypography.caption,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: analytics.totalDistanceKm,
                          color: AppColors.primary,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: analytics.estimatedFuelCost,
                          color: AppColors.warning,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: analytics.totalPassengersTransported.toDouble(),
                          color: AppColors.success,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الأسبوع الحالي مقابل السابق',
                    style: AppTypography.bodyMedium),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'مقارنة بين أداء الأسبوع الحالي والأسبوع السابق'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            _buildComparisonRow('الرحلات المنجزة', '156', '142', true),
            const Divider(),
            _buildComparisonRow('معدل النجاح', '94.5%', '92.1%', true),
            const Divider(),
            _buildComparisonRow('متوسط التأخير', '3.2 د', '4.1 د', true),
            const Divider(),
            _buildComparisonRow('معدل الإلغاء', '5.5%', '7.9%', true),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    String currentValue,
    String previousValue,
    bool isImprovement,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTypography.bodySmall),
          ),
          Expanded(
            child: Text(
              currentValue,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
          Icon(
            isImprovement ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: isImprovement ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: AppDimensions.xs),
          Expanded(
            child: Text(
              previousValue,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  /// Generate dummy data for charts
  List<FlSpot> _generateDummyData(int count, double min, double max) {
    return List.generate(count, (index) {
      final value = min + (max - min) * (0.5 + (index % 3) * 0.2);
      return FlSpot(index.toDouble(), value);
    });
  }
}
