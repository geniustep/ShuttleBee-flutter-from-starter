import 'package:flutter/material.dart';

/// حالة الراكب في الرحلة
enum TripLineStatus {
  pending('pending', 'معلق', 'Pending', Color(0xFFFFC107)),
  notStarted('not_started', 'لم تبدأ', 'Not Started', Color(0xFF9E9E9E)),
  absent('absent', 'غائب', 'Absent', Color(0xFFF44336)),
  boarded('boarded', 'صعد', 'Boarded', Color(0xFF2196F3)),
  dropped('dropped', 'نزل', 'Dropped', Color(0xFF4CAF50));

  const TripLineStatus(
    this.value,
    this.arabicLabel,
    this.englishLabel,
    this.color,
  );

  final String value;
  final String arabicLabel;
  final String englishLabel;
  final Color color;

  /// تحويل من String إلى Enum
  static TripLineStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return TripLineStatus.pending;
      case 'not_started':
        return TripLineStatus.notStarted;
      case 'absent':
        return TripLineStatus.absent;
      case 'boarded':
        return TripLineStatus.boarded;
      case 'dropped':
        return TripLineStatus.dropped;
      default:
        throw ArgumentError('Invalid TripLineStatus: $value');
    }
  }

  /// محاولة التحويل مع قيمة افتراضية
  static TripLineStatus? tryFromString(String? value) {
    if (value == null) return null;
    try {
      return fromString(value);
    } catch (_) {
      return null;
    }
  }

  /// الحصول على التسمية حسب اللغة
  String getLabel(String languageCode) {
    return languageCode == 'ar' ? arabicLabel : englishLabel;
  }

  /// هل هي حالة معلقة
  bool get isPending => this == TripLineStatus.pending;

  /// هل الراكب على متن الحافلة
  bool get isOnBoard => this == TripLineStatus.boarded;

  /// هل الراكب نزل
  bool get isDropped => this == TripLineStatus.dropped;

  /// هل الراكب غائب
  bool get isAbsent => this == TripLineStatus.absent;

  /// هل يمكن وضع علامة صعد
  bool get canMarkBoarded =>
      this == TripLineStatus.notStarted || this == TripLineStatus.pending;

  /// هل يمكن وضع علامة غائب
  bool get canMarkAbsent =>
      this == TripLineStatus.notStarted ||
      this == TripLineStatus.pending ||
      this == TripLineStatus.boarded;

  /// هل يمكن وضع علامة نزل
  bool get canMarkDropped => this == TripLineStatus.boarded;
}
