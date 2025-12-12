/// نوع الموقع - LocationType
/// يحدد مصدر إحداثيات الصعود/النزول للراكب
enum LocationType {
  /// محطة محددة
  stop('stop', 'محطة'),
  
  /// إحداثيات شخصية
  custom('custom', 'موقع مخصص'),
  
  /// غير محدد
  none('none', 'غير محدد');

  const LocationType(this.value, this.label);
  
  final String value;
  final String label;

  /// Parse from string
  static LocationType? tryFromString(String? value) {
    if (value == null) return null;
    return LocationType.values.cast<LocationType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
  
  /// هل هو محطة
  bool get isStop => this == LocationType.stop;
  
  /// هل هو موقع مخصص
  bool get isCustom => this == LocationType.custom;
  
  /// هل غير محدد
  bool get isNone => this == LocationType.none;
  
  /// هل لديه موقع فعلي
  bool get hasLocation => this != LocationType.none;
}

