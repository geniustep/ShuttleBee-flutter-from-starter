import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/entities/shuttle_notification.dart';

/// Notification list item - عنصر قائمة الإشعارات
class NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  final bool isRead;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationItem({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(title + time.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.lg),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: Material(
        color: isRead
            ? Colors.transparent
            : AppColors.primaryContainer.withValues(alpha: 0.3),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 20,
                  ),
                ),

                const SizedBox(width: AppDimensions.sm),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                            ),
                          ),
                          Text(
                            timeago.format(time),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xxs),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Unread indicator
                if (!isRead) ...[
                  const SizedBox(width: AppDimensions.xs),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.approaching:
        return Icons.directions_bus_rounded;
      case NotificationType.arrived:
        return Icons.location_on_rounded;
      case NotificationType.tripStarted:
        return Icons.play_circle_rounded;
      case NotificationType.tripEnded:
        return Icons.check_circle_rounded;
      case NotificationType.cancelled:
        return Icons.cancel_rounded;
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.custom:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.approaching:
        return Colors.blue;
      case NotificationType.arrived:
        return AppColors.success;
      case NotificationType.tripStarted:
        return Colors.purple;
      case NotificationType.tripEnded:
        return Colors.grey;
      case NotificationType.cancelled:
        return AppColors.error;
      case NotificationType.reminder:
        return AppColors.warning;
      case NotificationType.custom:
        return AppColors.primary;
    }
  }
}
