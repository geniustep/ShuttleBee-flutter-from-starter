import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Line Chart Widget - رسم بياني خطي - ShuttleBee
class LineChartWidget extends StatelessWidget {
  const LineChartWidget({
    required this.data,
    required this.labels,
    this.title,
    this.color,
    this.height = 250,
    this.showDots = true,
    this.showArea = true,
    super.key,
  });

  final List<double> data;
  final List<String> labels;
  final String? title;
  final Color? color;
  final double height;
  final bool showDots;
  final bool showArea;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text('لا توجد بيانات'),
        ),
      );
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final lineColor = color ?? AppColors.primary;

    return Container(
      height: height,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
          ],
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minValue * 0.9,
                maxY: maxValue * 1.1,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        return LineTooltipItem(
                          '${labels[index]}\n${spot.y.toStringAsFixed(1)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: AppTypography.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 32,
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxValue - minValue) / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: showDots),
                    belowBarData: showArea
                        ? BarAreaData(
                            show: true,
                            color: lineColor.withValues(alpha: 0.2),
                          )
                        : BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
