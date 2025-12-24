import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../core/enums/enums.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';

class TripTypeCard extends StatelessWidget {
  final TripType tripType;
  final ValueChanged<TripType> onTripTypeChanged;

  const TripTypeCard({
    super.key,
    required this.tripType,
    required this.onTripTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildTripTypeOption(
                context: context,
                type: TripType.pickup,
                icon: Icons.arrow_upward_rounded,
                label: l10n.pickup,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTripTypeOption(
                context: context,
                type: TripType.dropoff,
                icon: Icons.arrow_downward_rounded,
                label: l10n.dropoff,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildTripTypeOption({
    required BuildContext context,
    required TripType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = tripType == type;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTripTypeChanged(type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.dispatcherPrimary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.dispatcherPrimary
                : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.dispatcherPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isSelected
                    ? AppColors.dispatcherPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
