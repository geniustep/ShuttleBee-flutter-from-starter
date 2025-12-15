import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../trips/domain/entities/trip.dart';
import '../providers/notification_providers.dart';

/// 🔔 أزرار إجراءات الإشعارات للراكب
/// تُستخدم في شاشة تفاصيل الرحلة وقائمة الركاب
class NotificationActionButtons extends ConsumerWidget {
  final TripLine tripLine;
  final VoidCallback? onApproachingSent;
  final VoidCallback? onArrivedSent;
  final bool compact;

  const NotificationActionButtons({
    super.key,
    required this.tripLine,
    this.onApproachingSent,
    this.onArrivedSent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(
      tripLineNotificationProvider(
        TripLineNotificationParams(
          tripLineId: tripLine.id,
          approachingNotified: tripLine.approachingNotified,
          arrivedNotified: tripLine.arrivedNotified,
        ),
      ),
    );

    if (compact) {
      return _buildCompactButtons(context, ref, notificationState);
    }

    return _buildFullButtons(context, ref, notificationState);
  }

  Widget _buildCompactButtons(
    BuildContext context,
    WidgetRef ref,
    TripLineNotificationState state,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // زر إشعار الاقتراب
        _CompactNotificationButton(
          icon: Icons.directions_car_rounded,
          isLoading: state.isApproachingLoading,
          isNotified: state.approachingNotified,
          color: Colors.orange,
          tooltip: state.approachingNotified
              ? 'تم إرسال إشعار الاقتراب'
              : 'إرسال إشعار اقتراب',
          onPressed: state.approachingNotified || state.isApproachingLoading
              ? null
              : () => _sendApproaching(context, ref),
        ),
        const SizedBox(width: 8),
        // زر إشعار الوصول
        _CompactNotificationButton(
          icon: Icons.location_on_rounded,
          isLoading: state.isArrivedLoading,
          isNotified: state.arrivedNotified,
          color: Colors.green,
          tooltip: state.arrivedNotified
              ? 'تم إرسال إشعار الوصول'
              : 'إرسال إشعار وصول',
          onPressed: state.arrivedNotified || state.isArrivedLoading
              ? null
              : () => _sendArrived(context, ref),
        ),
      ],
    );
  }

  Widget _buildFullButtons(
    BuildContext context,
    WidgetRef ref,
    TripLineNotificationState state,
  ) {
    return Row(
      children: [
        // زر إشعار الاقتراب
        Expanded(
          child: _NotificationButton(
            icon: Icons.directions_car_rounded,
            label: state.approachingNotified ? 'تم الإرسال' : 'إشعار اقتراب',
            isLoading: state.isApproachingLoading,
            isNotified: state.approachingNotified,
            color: Colors.orange,
            onPressed: state.approachingNotified || state.isApproachingLoading
                ? null
                : () => _sendApproaching(context, ref),
          ),
        ),
        const SizedBox(width: 8),
        // زر إشعار الوصول
        Expanded(
          child: _NotificationButton(
            icon: Icons.location_on_rounded,
            label: state.arrivedNotified ? 'تم الإرسال' : 'إشعار وصول',
            isLoading: state.isArrivedLoading,
            isNotified: state.arrivedNotified,
            color: Colors.green,
            onPressed: state.arrivedNotified || state.isArrivedLoading
                ? null
                : () => _sendArrived(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _sendApproaching(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();

    final notifier = ref.read(
      tripLineNotificationProvider(
        TripLineNotificationParams(
          tripLineId: tripLine.id,
          approachingNotified: tripLine.approachingNotified,
          arrivedNotified: tripLine.arrivedNotified,
        ),
      ).notifier,
    );

    final success = await notifier.sendApproaching();

    if (context.mounted) {
      if (success) {
        _showSuccessSnackBar(
            context, 'تم إرسال إشعار الاقتراب لـ ${tripLine.passengerName}');
        onApproachingSent?.call();
      } else {
        final state = ref.read(
          tripLineNotificationProvider(
            TripLineNotificationParams(tripLineId: tripLine.id),
          ),
        );
        _showErrorSnackBar(context, state.lastError ?? 'فشل إرسال الإشعار');
      }
    }
  }

  Future<void> _sendArrived(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();

    final notifier = ref.read(
      tripLineNotificationProvider(
        TripLineNotificationParams(
          tripLineId: tripLine.id,
          approachingNotified: tripLine.approachingNotified,
          arrivedNotified: tripLine.arrivedNotified,
        ),
      ).notifier,
    );

    final success = await notifier.sendArrived();

    if (context.mounted) {
      if (success) {
        _showSuccessSnackBar(
            context, 'تم إرسال إشعار الوصول لـ ${tripLine.passengerName}');
        onArrivedSent?.call();
      } else {
        final state = ref.read(
          tripLineNotificationProvider(
            TripLineNotificationParams(tripLineId: tripLine.id),
          ),
        );
        _showErrorSnackBar(context, state.lastError ?? 'فشل إرسال الإشعار');
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// زر إشعار كامل
class _NotificationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final bool isNotified;
  final Color color;
  final VoidCallback? onPressed;

  const _NotificationButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.isNotified,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Material(
      color: isNotified
          ? color.withOpacity(0.1)
          : isDisabled
              ? Colors.grey.withOpacity(0.1)
              : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      isNotified ? color : Colors.white,
                    ),
                  ),
                )
              else if (isNotified)
                Icon(Icons.check_circle, size: 16, color: color)
              else
                Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: isNotified
                      ? color
                      : isDisabled
                          ? Colors.grey
                          : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر إشعار مضغوط
class _CompactNotificationButton extends StatelessWidget {
  final IconData icon;
  final bool isLoading;
  final bool isNotified;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CompactNotificationButton({
    required this.icon,
    required this.isLoading,
    required this.isNotified,
    required this.color,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isNotified ? color.withOpacity(0.1) : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )
                : isNotified
                    ? Icon(Icons.check, size: 18, color: color)
                    : Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 🔔 زر إرسال إشعار جماعي
// ============================================================

/// زر إرسال إشعار لجميع الركاب
class SendAllNotificationButton extends ConsumerWidget {
  final int tripId;
  final String notificationType;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onSuccess;

  const SendAllNotificationButton({
    super.key,
    required this.tripId,
    required this.notificationType,
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationActionsProvider);

    return ElevatedButton.icon(
      onPressed: state.isLoading ? null : () => _sendToAll(context, ref),
      icon: state.isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _sendToAll(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();

    // تأكيد الإرسال
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            const Text(
              'تأكيد الإرسال',
              style:
                  TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'هل تريد إرسال "$label" لجميع ركاب الرحلة؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('إرسال', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final notifier = ref.read(notificationActionsProvider.notifier);
    final success = await notifier.sendNotificationToAllPassengers(
      tripId: tripId,
      notificationType: notificationType,
    );

    if (context.mounted) {
      final state = ref.read(notificationActionsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? state.successMessage ?? 'تم إرسال الإشعارات بنجاح'
                      : state.errorMessage ?? 'فشل إرسال الإشعارات',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      if (success) {
        onSuccess?.call();
      }
    }
  }
}

// ============================================================
// 🔔 مؤشر حالة الإشعار
// ============================================================

/// مؤشر حالة الإشعار
class NotificationStatusIndicator extends StatelessWidget {
  final String status;
  final bool showLabel;

  const NotificationStatusIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 10 : 6,
        vertical: showLabel ? 4 : 4,
      ),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(showLabel ? 20 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: config.color,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return const _StatusConfig(
          icon: Icons.schedule,
          color: Colors.orange,
          label: 'في الانتظار',
        );
      case 'sent':
        return const _StatusConfig(
          icon: Icons.check,
          color: Colors.blue,
          label: 'تم الإرسال',
        );
      case 'delivered':
        return const _StatusConfig(
          icon: Icons.done_all,
          color: Colors.green,
          label: 'تم التسليم',
        );
      case 'read':
        return const _StatusConfig(
          icon: Icons.visibility,
          color: Colors.purple,
          label: 'تمت القراءة',
        );
      case 'failed':
        return const _StatusConfig(
          icon: Icons.error_outline,
          color: Colors.red,
          label: 'فشل',
        );
      default:
        return const _StatusConfig(
          icon: Icons.help_outline,
          color: Colors.grey,
          label: 'غير معروف',
        );
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String label;

  const _StatusConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}

// ============================================================
// 🔔 قائمة قنوات الإشعار
// ============================================================

/// قائمة منسدلة لاختيار قناة الإشعار
class NotificationChannelDropdown extends StatelessWidget {
  final String selectedChannel;
  final List<String> availableChannels;
  final ValueChanged<String> onChanged;

  const NotificationChannelDropdown({
    super.key,
    required this.selectedChannel,
    required this.availableChannels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedChannel,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: availableChannels.map((channel) {
            final config = _getChannelConfig(channel);
            return DropdownMenuItem(
              value: channel,
              child: Row(
                children: [
                  Text(config.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    config.label,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }

  _ChannelConfig _getChannelConfig(String channel) {
    switch (channel) {
      case 'whatsapp':
        return const _ChannelConfig(emoji: '💬', label: 'WhatsApp');
      case 'sms':
        return const _ChannelConfig(emoji: '📱', label: 'SMS');
      case 'push':
        return const _ChannelConfig(emoji: '🔔', label: 'إشعار فوري');
      case 'email':
        return const _ChannelConfig(emoji: '📧', label: 'بريد إلكتروني');
      default:
        return const _ChannelConfig(emoji: '📨', label: 'غير معروف');
    }
  }
}

class _ChannelConfig {
  final String emoji;
  final String label;

  const _ChannelConfig({required this.emoji, required this.label});
}
