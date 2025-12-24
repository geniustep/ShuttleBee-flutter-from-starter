import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../l10n/app_localizations.dart';

class NotesCard extends StatelessWidget {
  final TextEditingController notesController;
  final InputDecoration Function({
    required String label,
    required String hint,
    required IconData icon,
  }) buildInputDecoration;

  const NotesCard({
    super.key,
    required this.notesController,
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
          controller: notesController,
          maxLines: 4,
          decoration: buildInputDecoration(
            label: l10n.notes,
            hint: l10n.addNotesOptional,
            icon: Icons.note_rounded,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
  }
}
