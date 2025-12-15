import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/states/empty_state.dart';

/// Pending operations screen
class PendingOperationsScreen extends ConsumerWidget {
  const PendingOperationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Demo pending operations (empty for now)
    final operations = <_PendingOperation>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('pending_operations')),
        actions: [
          if (operations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                // Sync all
              },
              tooltip: 'Sync All',
            ),
        ],
      ),
      body: operations.isEmpty
          ? EmptyState(
              icon: Icons.check_circle_outline,
              title: l10n.translate('no_pending_operations'),
              message: 'All operations have been synced',
            )
          : ListView.builder(
              padding: AppDimensions.screenPadding,
              itemCount: operations.length,
              itemBuilder: (context, index) {
                final operation = operations[index];
                return _OperationCard(operation: operation);
              },
            ),
    );
  }
}

class _PendingOperation {
  final String id;
  final String model;
  final String operation;
  final DateTime timestamp;
  final String status;
  final Map<String, dynamic> data;

  const _PendingOperation({
    required this.id,
    required this.model,
    required this.operation,
    required this.timestamp,
    required this.status,
    required this.data,
  });
}

class _OperationCard extends StatelessWidget {
  final _PendingOperation operation;

  const _OperationCard({required this.operation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Padding(
        padding: AppDimensions.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.xs),
                  decoration: BoxDecoration(
                    color: _getOperationColor(operation.operation)
                        .withValues(alpha: 0.1),
                    borderRadius: AppDimensions.borderRadiusSm,
                  ),
                  child: Icon(
                    _getOperationIcon(operation.operation),
                    color: _getOperationColor(operation.operation),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        operation.model,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        operation.operation.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getOperationColor(operation.operation),
                            ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    operation.status,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: AppColors.warningLight,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.xxs),
                Text(
                  operation.timestamp.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Retry operation
                  },
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () {
                    // Delete operation
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getOperationIcon(String operation) {
    switch (operation.toLowerCase()) {
      case 'create':
        return Icons.add;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.sync;
    }
  }

  Color _getOperationColor(String operation) {
    switch (operation.toLowerCase()) {
      case 'create':
        return AppColors.success;
      case 'update':
        return AppColors.primary;
      case 'delete':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }
}
