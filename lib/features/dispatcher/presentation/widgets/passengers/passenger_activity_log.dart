import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/theme/app_colors.dart';

/// Activity log entry model
class PassengerActivityLogEntry {
  final String id;
  final String passengerName;
  final int passengerId;
  final String action;
  final String details;
  final DateTime timestamp;
  final String? userId;
  final String? userName;

  const PassengerActivityLogEntry({
    required this.id,
    required this.passengerName,
    required this.passengerId,
    required this.action,
    required this.details,
    required this.timestamp,
    this.userId,
    this.userName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passenger_name': passengerName,
      'passenger_id': passengerId,
      'action': action,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'user_name': userName,
    };
  }

  factory PassengerActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return PassengerActivityLogEntry(
      id: json['id'] as String,
      passengerName: json['passenger_name'] as String,
      passengerId: json['passenger_id'] as int,
      action: json['action'] as String,
      details: json['details'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
    );
  }
}

/// Activity log widget
class PassengerActivityLog extends StatelessWidget {
  final List<PassengerActivityLogEntry> activities;
  final bool isLoading;

  const PassengerActivityLog({
    super.key,
    required this.activities,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'لا توجد أنشطة مسجلة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _ActivityLogItem(activity: activity);
      },
    );
  }
}

class _ActivityLogItem extends StatelessWidget {
  final PassengerActivityLogEntry activity;

  const _ActivityLogItem({required this.activity});

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create':
      case 'created':
        return Icons.add_circle_rounded;
      case 'update':
      case 'updated':
        return Icons.edit_rounded;
      case 'delete':
      case 'deleted':
        return Icons.delete_rounded;
      case 'assign':
      case 'assigned':
        return Icons.swap_horiz_rounded;
      case 'unassign':
      case 'unassigned':
        return Icons.person_off_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
      case 'created':
        return AppColors.success;
      case 'update':
      case 'updated':
        return AppColors.primary;
      case 'delete':
      case 'deleted':
        return AppColors.error;
      case 'assign':
      case 'assigned':
        return AppColors.dispatcherPrimary;
      case 'unassign':
      case 'unassigned':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getActionColor(activity.action).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getActionIcon(activity.action),
            color: _getActionColor(activity.action),
            size: 24,
          ),
        ),
        title: Text(
          activity.passengerName,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              activity.details,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  timeago.format(activity.timestamp, locale: 'ar'),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
                if (activity.userName != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.person_rounded,
                    size: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activity.userName!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getActionColor(activity.action).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            activity.action,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getActionColor(activity.action),
            ),
          ),
        ),
      ),
    );
  }
}

/// Activity log screen widget
class PassengerActivityLogScreen extends StatelessWidget {
  final int passengerId;
  final String passengerName;

  const PassengerActivityLogScreen({
    super.key,
    required this.passengerId,
    required this.passengerName,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch activities from provider/API
    final activities = <PassengerActivityLogEntry>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'سجل الأنشطة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.dispatcherPrimary,
        foregroundColor: Colors.white,
      ),
      body: PassengerActivityLog(
        activities: activities,
        isLoading: false,
      ),
    );
  }
}

