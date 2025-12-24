import 'package:flutter/material.dart';

class PerformanceInsights extends StatelessWidget {
  final int totalTrips;
  final int completedTrips;
  final int activeTrips;
  final int delayedTrips;

  const PerformanceInsights({
    super.key,
    required this.totalTrips,
    required this.completedTrips,
    required this.activeTrips,
    required this.delayedTrips,
  });

  @override
  Widget build(BuildContext context) {
    final completionRate = totalTrips > 0
        ? (completedTrips / totalTrips * 100).toStringAsFixed(1)
        : '0.0';
    final onTimeRate = totalTrips > 0
        ? ((totalTrips - delayedTrips) / totalTrips * 100).toStringAsFixed(1)
        : '100.0';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.purple.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Performance Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    label: 'Completion Rate',
                    value: '$completionRate%',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildInsightItem(
                    label: 'On-Time Rate',
                    value: '$onTimeRate%',
                    icon: Icons.schedule,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    label: 'Active Now',
                    value: '$activeTrips',
                    icon: Icons.directions_bus,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildInsightItem(
                    label: 'Delayed',
                    value: '$delayedTrips',
                    icon: Icons.warning,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
