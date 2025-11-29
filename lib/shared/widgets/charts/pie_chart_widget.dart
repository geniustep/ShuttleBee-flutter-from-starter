import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Pie Chart Widget - رسم بياني دائري - ShuttleBee
class PieChartWidget extends StatelessWidget {
  const PieChartWidget({
    required this.data,
    required this.labels,
    this.title,
    this.colors,
    this.height = 250,
    super.key,
  });

  final List<double> data;
  final List<String> labels;
  final String? title;
  final List<Color>? colors;
  final double height;

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

    final total = data.reduce((a, b) => a + b);
    final chartColors = colors ?? AppColors.chartColors;

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
            child: Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: data
                          .asMap()
                          .entries
                          .map(
                            (e) => PieChartSectionData(
                              color: chartColors[e.key % chartColors.length],
                              value: e.value,
                              title:
                                  '${((e.value / total) * 100).toStringAsFixed(1)}%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                // Legend
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data
                        .asMap()
                        .entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color:
                                        chartColors[e.key % chartColors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    labels[e.key],
                                    style: AppTypography.caption,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
