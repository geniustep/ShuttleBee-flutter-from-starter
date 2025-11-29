/// نوع الرحلة
enum TripType {
  pickup('pickup', 'استقبال', 'Pickup'),
  dropoff('dropoff', 'توصيل', 'Drop-off');

  const TripType(this.value, this.arabicLabel, this.englishLabel);

  final String value;
  final String arabicLabel;
  final String englishLabel;

  /// تحويل من String إلى Enum
  static TripType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pickup':
        return TripType.pickup;
      case 'dropoff':
        return TripType.dropoff;
      default:
        throw ArgumentError('Invalid TripType: $value');
    }
  }

  /// محاولة التحويل مع قيمة افتراضية
  static TripType? tryFromString(String? value) {
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

  /// هل هي رحلة استقبال
  bool get isPickup => this == TripType.pickup;

  /// هل هي رحلة توصيل
  bool get isDropoff => this == TripType.dropoff;
}
