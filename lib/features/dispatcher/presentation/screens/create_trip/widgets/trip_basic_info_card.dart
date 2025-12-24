import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../l10n/app_localizations.dart';

class TripBasicInfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final InputDecoration Function({
    required String label,
    required String hint,
    required IconData icon,
  }) buildInputDecoration;

  const TripBasicInfoCard({
    super.key,
    required this.nameController,
    required this.buildInputDecoration,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: nameController,
          decoration: buildInputDecoration(
            label: l10n.tripName,
            hint: l10n.tripNameExample,
            icon: Icons.route_rounded,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.fieldRequired;
            }
            return null;
          },
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }
}
