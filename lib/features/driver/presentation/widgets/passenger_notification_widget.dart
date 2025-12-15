import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../trips/domain/entities/trip.dart';

/// 🔔 Passenger Notification Widget - ويدجت إشعارات الراكب الذكي
///
/// يوفر:
/// - أزرار إشعار الاقتراب والوصول
/// - دعم الإرسال التلقائي (is_auto_notification)
/// - إعادة الإرسال
/// - مؤشرات الحالة
class PassengerNotificationWidget extends ConsumerStatefulWidget {
  final TripLine tripLine;
  final Trip? trip;
  final bool compact;
  final bool showLabels;
  final VoidCallback? onNotificationSent;
  final double? distanceToPassenger; // المسافة الحالية للراكب

  const PassengerNotificationWidget({
    super.key,
    required this.tripLine,
    this.trip,
    this.compact = false,
    this.showLabels = true,
    this.onNotificationSent,
    this.distanceToPassenger,
  });

  @override
  ConsumerState<PassengerNotificationWidget> createState() =>
      _PassengerNotificationWidgetState();
}

class _PassengerNotificationWidgetState
    extends ConsumerState<PassengerNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isApproachingLoading = false;
  bool _isArrivedLoading = false;
  bool _approachingNotified = false;
  bool _arrivedNotified = false;

  // Thresholds للإرسال التلقائي
  static const double _autoApproachingThreshold = 500; // 500 متر
  static const double _autoArrivedThreshold = 100; // 100 متر

  @override
  void initState() {
    super.initState();
    _approachingNotified = widget.tripLine.approachingNotified;
    _arrivedNotified = widget.tripLine.arrivedNotified;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PassengerNotificationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // تحديث الحالة من البيانات الجديدة
    if (widget.tripLine.approachingNotified !=
        oldWidget.tripLine.approachingNotified) {
      _approachingNotified = widget.tripLine.approachingNotified;
    }
    if (widget.tripLine.arrivedNotified != oldWidget.tripLine.arrivedNotified) {
      _arrivedNotified = widget.tripLine.arrivedNotified;
    }

    // التحقق من الإرسال التلقائي عند تحديث المسافة
    if (widget.distanceToPassenger != oldWidget.distanceToPassenger) {
      _checkAutoNotification();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// التحقق من الإرسال التلقائي
  void _checkAutoNotification() {
    if (!widget.tripLine.isAutoNotification) return;
    if (widget.distanceToPassenger == null) return;

    final distance = widget.distanceToPassenger!;

    // إرسال إشعار الاقتراب تلقائياً
    if (!_approachingNotified &&
        !_isApproachingLoading &&
        distance <= _autoApproachingThreshold &&
        distance > _autoArrivedThreshold) {
      AppLogger.info(
        '🔔 Auto-sending approaching notification for ${widget.tripLine.passengerName} (distance: ${distance.toStringAsFixed(0)}m)',
      );
      _sendApproachingNotification(isAuto: true);
    }

    // إرسال إشعار الوصول تلقائياً
    if (!_arrivedNotified &&
        !_isArrivedLoading &&
        distance <= _autoArrivedThreshold) {
      AppLogger.info(
        '🔔 Auto-sending arrived notification for ${widget.tripLine.passengerName} (distance: ${distance.toStringAsFixed(0)}m)',
      );
      _sendArrivedNotification(isAuto: true);
    }
  }

  Future<void> _sendApproachingNotification({bool isAuto = false}) async {
    if (_approachingNotified || _isApproachingLoading) return;

    setState(() => _isApproachingLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final repository = ref.read(notificationRepositoryProvider);
      final result = await repository.sendApproachingNotification(
        widget.tripLine.id,
        eta: widget.distanceToPassenger != null
            ? _estimateETA(widget.distanceToPassenger!)
            : null,
      );

      result.fold(
        (failure) {
          if (mounted) {
            _showSnackBar(
              '❌ فشل إرسال إشعار الاقتراب: ${failure.message}',
              isError: true,
            );
          }
        },
        (success) {
          setState(() => _approachingNotified = true);
          if (mounted && !isAuto) {
            _showSnackBar(
                '✅ تم إرسال إشعار الاقتراب لـ ${widget.tripLine.passengerName}');
          }
          widget.onNotificationSent?.call();
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isApproachingLoading = false);
      }
    }
  }

  Future<void> _sendArrivedNotification({bool isAuto = false}) async {
    if (_arrivedNotified || _isArrivedLoading) return;

    setState(() => _isArrivedLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final repository = ref.read(notificationRepositoryProvider);
      final result =
          await repository.sendArrivedNotification(widget.tripLine.id);

      result.fold(
        (failure) {
          if (mounted) {
            _showSnackBar(
              '❌ فشل إرسال إشعار الوصول: ${failure.message}',
              isError: true,
            );
          }
        },
        (success) {
          setState(() => _arrivedNotified = true);
          if (mounted && !isAuto) {
            _showSnackBar(
                '✅ تم إرسال إشعار الوصول لـ ${widget.tripLine.passengerName}');
          }
          widget.onNotificationSent?.call();
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isArrivedLoading = false);
      }
    }
  }

  /// إعادة إرسال الإشعار
  Future<void> _resendNotification(String type) async {
    // إعادة تعيين الحالة للسماح بإعادة الإرسال
    if (type == 'approaching') {
      setState(() => _approachingNotified = false);
      await _sendApproachingNotification();
    } else if (type == 'arrived') {
      setState(() => _arrivedNotified = false);
      await _sendArrivedNotification();
    }
  }

  int _estimateETA(double distanceMeters) {
    // تقدير الوقت بناءً على المسافة (افتراض سرعة 30 كم/ساعة في المدينة)
    const averageSpeedKmH = 30.0;
    final distanceKm = distanceMeters / 1000;
    final timeHours = distanceKm / averageSpeedKmH;
    return (timeHours * 60).ceil().clamp(1, 60);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactLayout();
    }
    return _buildFullLayout();
  }

  Widget _buildCompactLayout() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNotificationButton(
          type: 'approaching',
          icon: Icons.directions_car_rounded,
          color: Colors.orange,
          isNotified: _approachingNotified,
          isLoading: _isApproachingLoading,
          onPressed: _sendApproachingNotification,
          onLongPress: () => _resendNotification('approaching'),
        ),
        const SizedBox(width: 6),
        _buildNotificationButton(
          type: 'arrived',
          icon: Icons.location_on_rounded,
          color: Colors.green,
          isNotified: _arrivedNotified,
          isLoading: _isArrivedLoading,
          onPressed: _sendArrivedNotification,
          onLongPress: () => _resendNotification('arrived'),
        ),
        // مؤشر الإشعار التلقائي
        if (widget.tripLine.isAutoNotification) ...[
          const SizedBox(width: 4),
          _buildAutoIndicator(),
        ],
      ],
    );
  }

  Widget _buildFullLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // مؤشر الإشعار التلقائي
        if (widget.tripLine.isAutoNotification)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildAutoNotificationBanner(),
          ),

        // أزرار الإشعارات
        Row(
          children: [
            Expanded(
              child: _buildFullNotificationButton(
                type: 'approaching',
                icon: Icons.directions_car_rounded,
                label: _approachingNotified ? 'تم الإرسال' : 'إشعار اقتراب',
                color: Colors.orange,
                isNotified: _approachingNotified,
                isLoading: _isApproachingLoading,
                onPressed: _sendApproachingNotification,
                onLongPress: () => _resendNotification('approaching'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFullNotificationButton(
                type: 'arrived',
                icon: Icons.location_on_rounded,
                label: _arrivedNotified ? 'تم الإرسال' : 'إشعار وصول',
                color: Colors.green,
                isNotified: _arrivedNotified,
                isLoading: _isArrivedLoading,
                onPressed: _sendArrivedNotification,
                onLongPress: () => _resendNotification('arrived'),
              ),
            ),
          ],
        ),

        // معلومات المسافة والوقت المتوقع
        if (widget.distanceToPassenger != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildDistanceInfo(),
          ),
      ],
    );
  }

  Widget _buildNotificationButton({
    required String type,
    required IconData icon,
    required Color color,
    required bool isNotified,
    required bool isLoading,
    required VoidCallback onPressed,
    required VoidCallback onLongPress,
  }) {
    return Tooltip(
      message: isNotified
          ? 'اضغط مطولاً لإعادة الإرسال'
          : type == 'approaching'
              ? 'إرسال إشعار اقتراب'
              : 'إرسال إشعار وصول',
      child: GestureDetector(
        onLongPress: isNotified ? onLongPress : null,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final shouldPulse = !isNotified && !isLoading;
            return Transform.scale(
              scale: shouldPulse ? 1.0 + (_pulseController.value * 0.05) : 1.0,
              child: child,
            );
          },
          child: Material(
            color: isNotified
                ? color.withOpacity(0.15)
                : isLoading
                    ? Colors.grey.withOpacity(0.2)
                    : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: isNotified || isLoading ? null : () => onPressed(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: isNotified ? color : color.withOpacity(0.8),
                          ),
                          if (isNotified)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color, width: 1.5),
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 10,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullNotificationButton({
    required String type,
    required IconData icon,
    required String label,
    required Color color,
    required bool isNotified,
    required bool isLoading,
    required VoidCallback onPressed,
    required VoidCallback onLongPress,
  }) {
    return GestureDetector(
      onLongPress: isNotified ? onLongPress : null,
      child: Material(
        color: isNotified
            ? color.withOpacity(0.1)
            : isLoading
                ? Colors.grey.withOpacity(0.1)
                : color,
        borderRadius: BorderRadius.circular(12),
        elevation: isNotified ? 0 : 2,
        shadowColor: color.withOpacity(0.3),
        child: InkWell(
          onTap: isNotified || isLoading ? null : () => onPressed(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        isNotified ? color : Colors.white,
                      ),
                    ),
                  )
                else if (isNotified)
                  Icon(Icons.check_circle, size: 18, color: color)
                else
                  Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isNotified ? color : Colors.white,
                  ),
                ),
                if (isNotified) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.replay,
                    size: 12,
                    color: color.withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.5 + _pulseController.value * 0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildAutoNotificationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Icon(
                Icons.notifications_active,
                size: 14,
                color:
                    Colors.blue.withOpacity(0.7 + _pulseController.value * 0.3),
              );
            },
          ),
          const SizedBox(width: 6),
          const Text(
            'الإشعارات التلقائية مفعلة',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceInfo() {
    final distance = widget.distanceToPassenger!;
    final eta = _estimateETA(distance);
    final isNearby = distance <= _autoApproachingThreshold;
    final isVeryClose = distance <= _autoArrivedThreshold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isVeryClose
            ? Colors.green.withOpacity(0.1)
            : isNearby
                ? Colors.orange.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVeryClose
                ? Icons.location_on
                : isNearby
                    ? Icons.near_me
                    : Icons.straighten,
            size: 14,
            color: isVeryClose
                ? Colors.green
                : isNearby
                    ? Colors.orange
                    : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            distance >= 1000
                ? '${(distance / 1000).toStringAsFixed(1)} كم'
                : '${distance.toStringAsFixed(0)} م',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: isVeryClose
                  ? Colors.green
                  : isNearby
                      ? Colors.orange
                      : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.access_time,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '~$eta د',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Cairo',
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🔔 Smart Notification Manager - مدير الإشعارات الذكي
// ============================================================

/// مدير الإشعارات الذكي للرحلة
/// يتابع موقع السائق ويرسل الإشعارات تلقائياً
class TripNotificationManager {
  final NotificationRepository _repository;
  final List<TripLine> _passengers;
  final Function(TripLine, String)? onNotificationSent;

  // تتبع الإشعارات المرسلة
  final Set<int> _approachingNotifiedIds = {};
  final Set<int> _arrivedNotifiedIds = {};

  TripNotificationManager({
    required NotificationRepository repository,
    required List<TripLine> passengers,
    this.onNotificationSent,
  })  : _repository = repository,
        _passengers = passengers {
    // تهيئة الحالة من البيانات الموجودة
    for (final p in passengers) {
      if (p.approachingNotified) _approachingNotifiedIds.add(p.id);
      if (p.arrivedNotified) _arrivedNotifiedIds.add(p.id);
    }
  }

  /// تحديث موقع السائق والتحقق من الإشعارات التلقائية
  Future<void> updateDriverLocation(double lat, double lng) async {
    for (final passenger in _passengers) {
      // تجاهل الركاب الذين صعدوا أو غائبين
      if (passenger.status == TripLineStatus.boarded ||
          passenger.status == TripLineStatus.dropped ||
          passenger.status == TripLineStatus.absent) {
        continue;
      }

      // تجاهل الركاب الذين لا يريدون إشعارات تلقائية
      if (!passenger.isAutoNotification) continue;

      // حساب المسافة
      final passengerLat = passenger.effectivePickupLatitude;
      final passengerLng = passenger.effectivePickupLongitude;
      if (passengerLat == null || passengerLng == null) continue;

      final distance = _calculateDistance(lat, lng, passengerLat, passengerLng);

      // إرسال إشعار الاقتراب (500 متر)
      if (distance <= 500 &&
          distance > 100 &&
          !_approachingNotifiedIds.contains(passenger.id)) {
        await _sendApproaching(passenger, distance);
      }

      // إرسال إشعار الوصول (100 متر)
      if (distance <= 100 && !_arrivedNotifiedIds.contains(passenger.id)) {
        await _sendArrived(passenger);
      }
    }
  }

  Future<void> _sendApproaching(TripLine passenger, double distance) async {
    final eta = _estimateETA(distance);
    final result = await _repository.sendApproachingNotification(
      passenger.id,
      eta: eta,
    );

    result.fold(
      (failure) {
        AppLogger.error(
          '❌ Failed to auto-send approaching notification for ${passenger.passengerName}',
        );
      },
      (success) {
        _approachingNotifiedIds.add(passenger.id);
        onNotificationSent?.call(passenger, 'approaching');
        AppLogger.info(
          '✅ Auto-sent approaching notification for ${passenger.passengerName}',
        );
      },
    );
  }

  Future<void> _sendArrived(TripLine passenger) async {
    final result = await _repository.sendArrivedNotification(passenger.id);

    result.fold(
      (failure) {
        AppLogger.error(
          '❌ Failed to auto-send arrived notification for ${passenger.passengerName}',
        );
      },
      (success) {
        _arrivedNotifiedIds.add(passenger.id);
        onNotificationSent?.call(passenger, 'arrived');
        AppLogger.info(
          '✅ Auto-sent arrived notification for ${passenger.passengerName}',
        );
      },
    );
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    // Haversine formula simplified
    const p = 0.017453292519943295;
    final a = 0.5 -
        _cos((lat2 - lat1) * p) / 2 +
        _cos(lat1 * p) * _cos(lat2 * p) * (1 - _cos((lng2 - lng1) * p)) / 2;
    return 12742000 * _asin(_sqrt(a)); // meters
  }

  double _cos(double x) => x.abs() < 1e-10 ? 1.0 : _cosImpl(x);
  double _cosImpl(double x) {
    double sum = 1.0;
    double term = 1.0;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      sum += term;
    }
    return sum;
  }

  double _asin(double x) => x + x * x * x / 6 + 3 * x * x * x * x * x / 40;
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  int _estimateETA(double distanceMeters) {
    const averageSpeedKmH = 30.0;
    final distanceKm = distanceMeters / 1000;
    final timeHours = distanceKm / averageSpeedKmH;
    return (timeHours * 60).ceil().clamp(1, 60);
  }

  /// إعادة تعيين حالة الإشعارات
  void reset() {
    _approachingNotifiedIds.clear();
    _arrivedNotifiedIds.clear();
  }
}
