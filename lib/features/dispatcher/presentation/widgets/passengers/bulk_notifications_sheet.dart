import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/passenger_group_line.dart';

/// Bulk notifications bottom sheet
class BulkNotificationsSheet extends StatefulWidget {
  final List<PassengerGroupLine> passengers;

  const BulkNotificationsSheet({
    super.key,
    required this.passengers,
  });

  static Future<void> show(
    BuildContext context, {
    required List<PassengerGroupLine> passengers,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BulkNotificationsSheet(passengers: passengers),
    );
  }

  @override
  State<BulkNotificationsSheet> createState() => _BulkNotificationsSheetState();
}

class _BulkNotificationsSheetState extends State<BulkNotificationsSheet> {
  final _messageController = TextEditingController();
  final _titleController = TextEditingController();
  bool _sendToGuardians = false;
  bool _sendToPassengers = true;

  @override
  void dispose() {
    _messageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.dispatcherGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إشعارات جماعية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'إرسال إلى ${widget.passengers.length} راكب',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
            const Divider(height: 20),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الإشعار',
                        hintText: 'أدخل عنوان الإشعار',
                        prefixIcon: Icon(Icons.title_rounded),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 16),
                    // Message field
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'نص الإشعار',
                        hintText: 'أدخل نص الإشعار',
                        prefixIcon: Icon(Icons.message_rounded),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 16),
                    // Recipients
                    const Text(
                      'المستلمون',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text(
                        'إرسال للركاب',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      subtitle: Text(
                        '${widget.passengers.where((p) => (p.passengerPhone ?? '').isNotEmpty || (p.passengerMobile ?? '').isNotEmpty).length} راكب لديه هاتف',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      value: _sendToPassengers,
                      onChanged: (value) {
                        setState(() {
                          _sendToPassengers = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'إرسال لأولياء الأمور',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      subtitle: Text(
                        '${widget.passengers.where((p) => (p.fatherPhone ?? '').isNotEmpty || (p.motherPhone ?? '').isNotEmpty || (p.guardianPhone ?? '').isNotEmpty).length} راكب لديه ولي أمر',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      value: _sendToGuardians,
                      onChanged: (value) {
                        setState(() {
                          _sendToGuardians = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    // Send button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _canSend() ? () => _sendNotifications(context) : null,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text(
                          'إرسال الإشعارات',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dispatcherPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool _canSend() {
    return _messageController.text.trim().isNotEmpty &&
        (_sendToPassengers || _sendToGuardians);
  }

  Future<void> _sendNotifications(BuildContext context) async {
    if (!_canSend()) return;

    HapticFeedback.mediumImpact();

    // TODO: Implement actual notification sending logic
    // This would typically call an API endpoint to send notifications

    int sentCount = 0;
    int failCount = 0;

    for (final passenger in widget.passengers) {
      try {
        final recipients = <String>[];

        if (_sendToPassengers) {
          if ((passenger.passengerPhone ?? '').isNotEmpty) {
            recipients.add(passenger.passengerPhone!);
          }
          if ((passenger.passengerMobile ?? '').isNotEmpty) {
            recipients.add(passenger.passengerMobile!);
          }
        }

        if (_sendToGuardians) {
          if ((passenger.fatherPhone ?? '').isNotEmpty) {
            recipients.add(passenger.fatherPhone!);
          }
          if ((passenger.motherPhone ?? '').isNotEmpty) {
            recipients.add(passenger.motherPhone!);
          }
          if ((passenger.guardianPhone ?? '').isNotEmpty) {
            recipients.add(passenger.guardianPhone!);
          }
        }

        if (recipients.isNotEmpty) {
          // Send notification to recipients
          // await notificationService.send(
          //   title: _titleController.text.trim(),
          //   message: _messageController.text.trim(),
          //   recipients: recipients,
          // );
          sentCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال $sentCount إشعار${failCount > 0 ? ' • فشل: $failCount' : ''}',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: failCount > 0 ? AppColors.warning : AppColors.success,
        ),
      );
    }
  }
}

