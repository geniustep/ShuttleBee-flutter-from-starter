import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';

/// Dashboard screen with KPIs and charts
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards
            const Row(
              children: [
                Expanded(
                  child: _KPICard(
                    title: 'Revenue',
                    value: '\$45,231',
                    change: '+20.1%',
                    isPositive: true,
                    icon: Icons.attach_money,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(width: AppDimensions.md),
                Expanded(
                  child: _KPICard(
                    title: 'Orders',
                    value: '2,350',
                    change: '+15.2%',
                    isPositive: true,
                    icon: Icons.shopping_cart,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.md),

            const Row(
              children: [
                Expanded(
                  child: _KPICard(
                    title: 'Customers',
                    value: '1,247',
                    change: '+5.7%',
                    isPositive: true,
                    icon: Icons.people,
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(width: AppDimensions.md),
                Expanded(
                  child: _KPICard(
                    title: 'Pending',
                    value: '12',
                    change: '-3.2%',
                    isPositive: true,
                    icon: Icons.pending_actions,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.xl),

            // Sales Chart
            Text(
              'Sales Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.md),
            SizedBox(
              height: 200,
              child: _SalesChart(),
            ),

            const SizedBox(height: AppDimensions.xl),

            // Order Status
            Text(
              'Order Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.md),
            SizedBox(
              height: 200,
              child: _OrderStatusChart(),
            ),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: AppDimensions.borderRadiusSm,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimensions.xxs),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  ' vs last month',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingMd,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: _bottomTitleWidgets,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 3),
                  FlSpot(1, 4),
                  FlSpot(2, 3.5),
                  FlSpot(3, 5),
                  FlSpot(4, 4),
                  FlSpot(5, 6),
                  FlSpot(6, 5.5),
                ],
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _bottomTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(fontSize: 10, color: AppColors.textSecondary);
  String text;
  switch (value.toInt()) {
    case 0:
      text = 'Mon';
      break;
    case 1:
      text = 'Tue';
      break;
    case 2:
      text = 'Wed';
      break;
    case 3:
      text = 'Thu';
      break;
    case 4:
      text = 'Fri';
      break;
    case 5:
      text = 'Sat';
      break;
    case 6:
      text = 'Sun';
      break;
    default:
      text = '';
  }
  return SideTitleWidget(
    meta: meta,
    child: Text(text, style: style),
  );
}

class _OrderStatusChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingMd,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: 35,
                      color: AppColors.success,
                      title: '35%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 25,
                      color: AppColors.primary,
                      title: '25%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 20,
                      color: AppColors.warning,
                      title: '20%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 20,
                      color: AppColors.error,
                      title: '20%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(color: AppColors.success, label: 'Completed'),
                SizedBox(height: 8),
                _LegendItem(color: AppColors.primary, label: 'Processing'),
                SizedBox(height: 8),
                _LegendItem(color: AppColors.warning, label: 'Pending'),
                SizedBox(height: 8),
                _LegendItem(color: AppColors.error, label: 'Cancelled'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
