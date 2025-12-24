import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';

class GenerationOptionsCard extends StatelessWidget {
  final int weeksAhead;
  final ValueChanged<int> onWeeksAheadChanged;

  const GenerationOptionsCard({
    super.key,
    required this.weeksAhead,
    required this.onWeeksAheadChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Weeks Selection
            Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.weeksToGenerate,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded),
                        onPressed: weeksAhead > 1
                            ? () => onWeeksAheadChanged(weeksAhead - 1)
                            : null,
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$weeksAhead',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: weeksAhead < 4
                            ? () => onWeeksAheadChanged(weeksAhead + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${l10n.willGenerateTrips} $weeksAhead ${weeksAhead == 1 ? l10n.week : l10n.weeks} ${l10n.weeksAhead}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Cairo',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }
}
