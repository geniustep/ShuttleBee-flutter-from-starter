import 'package:flutter/material.dart';

/// حالة الرحلة
enum TripState {
  draft('draft', 'مسودة', 'Draft', Color(0xFF9E9E9E)),
  planned('planned', 'مخطط لها', 'Planned', Color(0xFF2196F3)),
  ongoing('ongoing', 'جارية', 'Ongoing', Color(0xFFFF9800)),
  done('done', 'منتهية', 'Done', Color(0xFF1976D2)), // أزرق جميل للرحلة المكتملة
  cancelled('cancelled', 'ملغاة', 'Cancelled', Color(0xFFF44336));

  const TripState(
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
  static TripState fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return TripState.draft;
      case 'planned':
        return TripState.planned;
      case 'ongoing':
        return TripState.ongoing;
      case 'done':
        return TripState.done;
      case 'cancelled':
        return TripState.cancelled;
      default:
        throw ArgumentError('Invalid TripState: $value');
    }
  }

  /// محاولة التحويل مع قيمة افتراضية
  static TripState? tryFromString(String? value) {
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

  /// هل الرحلة نشطة (ongoing)
  bool get isOngoing => this == TripState.ongoing;

  /// هل الرحلة منتهية
  bool get isCompleted => this == TripState.done || this == TripState.cancelled;

  /// هل يمكن بدء الرحلة
  bool get canStart => this == TripState.planned;

  /// هل يمكن إنهاء الرحلة
  bool get canComplete => this == TripState.ongoing;

  /// هل يمكن إلغاء الرحلة
  bool get canCancel => this == TripState.draft || this == TripState.planned;
}
