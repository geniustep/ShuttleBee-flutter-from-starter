import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../widgets/notification_item.dart';

/// Notifications screen
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Demo notifications
    final notifications = [
      _Notification(
        id: '1',
        title: 'New Order Received',
        message: 'Order #1234 has been placed by John Doe.',
        time: DateTime.now().subtract(const Duration(minutes: 5)),
        type: NotificationType.order,
        isRead: false,
      ),
      _Notification(
        id: '2',
        title: 'Payment Successful',
        message: 'Payment of \$1,500 has been received for Invoice #567.',
        time: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.payment,
        isRead: false,
      ),
      _Notification(
        id: '3',
        title: 'Low Stock Alert',
        message: 'Product "Widget Pro" is running low on stock.',
        time: DateTime.now().subtract(const Duration(hours: 3)),
        type: NotificationType.alert,
        isRead: true,
      ),
      _Notification(
        id: '4',
        title: 'Sync Completed',
        message: 'All data has been synchronized successfully.',
        time: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.system,
        isRead: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                // Mark all as read
              },
              child: Text(l10n.translate('mark_all_read')),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? EmptyState(
              icon: Icons.notifications_off_outlined,
              title: l10n.translate('no_notifications'),
              message: 'You\'re all caught up!',
            )
          : ListView.builder(
              padding: AppDimensions.paddingVerticalSm,
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationItem(
                  title: notification.title,
                  message: notification.message,
                  time: notification.time,
                  type: notification.type,
                  isRead: notification.isRead,
                  onTap: () {
                    // Handle notification tap
                  },
                  onDismiss: () {
                    // Delete notification
                  },
                );
              },
            ),
    );
  }
}

class _Notification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  final bool isRead;

  const _Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });
}

enum NotificationType {
  order,
  payment,
  alert,
  system,
}
