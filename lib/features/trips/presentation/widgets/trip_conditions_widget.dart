import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/services/gps_tracking_service.dart';
import '../../../../core/theme/app_colors.dart';

/// ويدجت عرض حالة الطقس والمرور - ShuttleBee
class TripConditionsWidget extends StatelessWidget {
  final WeatherStatus? weatherStatus;
  final TrafficStatus? trafficStatus;
  final RiskLevel? riskLevel;
  final VoidCallback? onWeatherTap;
  final VoidCallback? onTrafficTap;
  final bool isCompact;

  const TripConditionsWidget({
    super.key,
    this.weatherStatus,
    this.trafficStatus,
    this.riskLevel,
    this.onWeatherTap,
    this.onTrafficTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (weatherStatus != null)
          _buildCompactChip(
            weatherStatus!.icon,
            weatherStatus!.arabicLabel,
            _getWeatherColor(weatherStatus!),
          ),
        if (trafficStatus != null) ...[
          const SizedBox(width: 8),
          _buildCompactChip(
            trafficStatus!.icon,
            trafficStatus!.arabicLabel,
            _getTrafficColor(trafficStatus!),
          ),
        ],
        if (riskLevel != null) ...[
          const SizedBox(width: 8),
          _buildRiskIndicator(riskLevel!),
        ],
      ],
    );
  }

  Widget _buildCompactChip(String icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicator(RiskLevel risk) {
    final color = Color(risk.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            risk.arabicLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'ظروف الرحلة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              if (riskLevel != null) _buildRiskBadge(riskLevel!),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildWeatherCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildTrafficCard()),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWeatherCard() {
    final weather = weatherStatus ?? WeatherStatus.unknown;
    final color = _getWeatherColor(weather);

    return GestureDetector(
      onTap: onWeatherTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              weather.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              'الطقس',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              weather.arabicLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficCard() {
    final traffic = trafficStatus ?? TrafficStatus.unknown;
    final color = _getTrafficColor(traffic);

    return GestureDetector(
      onTap: onTrafficTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              traffic.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              'المرور',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              traffic.arabicLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(RiskLevel risk) {
    final color = Color(risk.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            risk == RiskLevel.high
                ? Icons.warning_rounded
                : risk == RiskLevel.medium
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            'خطورة ${risk.arabicLabel}ة',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Color _getWeatherColor(WeatherStatus status) {
    switch (status) {
      case WeatherStatus.clear:
        return Colors.amber;
      case WeatherStatus.rain:
        return Colors.blue;
      case WeatherStatus.storm:
        return Colors.deepPurple;
      case WeatherStatus.fog:
        return Colors.grey;
      case WeatherStatus.snow:
        return Colors.lightBlue;
      case WeatherStatus.unknown:
        return Colors.grey;
    }
  }

  Color _getTrafficColor(TrafficStatus status) {
    switch (status) {
      case TrafficStatus.normal:
        return Colors.green;
      case TrafficStatus.heavy:
        return Colors.orange;
      case TrafficStatus.jam:
        return Colors.red;
      case TrafficStatus.accident:
        return Colors.red.shade900;
      case TrafficStatus.unknown:
        return Colors.grey;
    }
  }
}

/// محدد حالة الطقس
class WeatherStatusSelector extends StatelessWidget {
  final WeatherStatus? currentStatus;
  final ValueChanged<WeatherStatus> onStatusChanged;

  const WeatherStatusSelector({
    super.key,
    this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WeatherStatus.values
          .where((s) => s != WeatherStatus.unknown)
          .map((status) => _buildOption(status))
          .toList(),
    );
  }

  Widget _buildOption(WeatherStatus status) {
    final isSelected = status == currentStatus;
    return GestureDetector(
      onTap: () => onStatusChanged(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              status.arabicLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// محدد حالة المرور
class TrafficStatusSelector extends StatelessWidget {
  final TrafficStatus? currentStatus;
  final ValueChanged<TrafficStatus> onStatusChanged;

  const TrafficStatusSelector({
    super.key,
    this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TrafficStatus.values
          .where((s) => s != TrafficStatus.unknown)
          .map((status) => _buildOption(status))
          .toList(),
    );
  }

  Widget _buildOption(TrafficStatus status) {
    final isSelected = status == currentStatus;
    return GestureDetector(
      onTap: () => onStatusChanged(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              status.arabicLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// نافذة تحديث ظروف الرحلة
class TripConditionsDialog extends StatefulWidget {
  final WeatherStatus? initialWeather;
  final TrafficStatus? initialTraffic;
  final Function(WeatherStatus?, TrafficStatus?) onSave;

  const TripConditionsDialog({
    super.key,
    this.initialWeather,
    this.initialTraffic,
    required this.onSave,
  });

  @override
  State<TripConditionsDialog> createState() => _TripConditionsDialogState();
}

class _TripConditionsDialogState extends State<TripConditionsDialog> {
  WeatherStatus? _selectedWeather;
  TrafficStatus? _selectedTraffic;

  @override
  void initState() {
    super.initState();
    _selectedWeather = widget.initialWeather;
    _selectedTraffic = widget.initialTraffic;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'تحديث ظروف الرحلة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // حالة الطقس
            const Text(
              'حالة الطقس',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 12),
            WeatherStatusSelector(
              currentStatus: _selectedWeather,
              onStatusChanged: (status) {
                setState(() => _selectedWeather = status);
              },
            ),

            const SizedBox(height: 24),

            // حالة المرور
            const Text(
              'حالة المرور',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 12),
            TrafficStatusSelector(
              currentStatus: _selectedTraffic,
              onStatusChanged: (status) {
                setState(() => _selectedTraffic = status);
              },
            ),

            const SizedBox(height: 24),

            // أزرار
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(_selectedWeather, _selectedTraffic);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'حفظ',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

