/// دور المستخدم في النظام
enum UserRole {
  driver('driver', 'سائق', 'Driver'),
  dispatcher('dispatcher', 'مشغل', 'Dispatcher'),
  passenger('passenger', 'راكب', 'Passenger'),
  manager('manager', 'مدير', 'Manager');

  const UserRole(this.value, this.arabicLabel, this.englishLabel);

  final String value;
  final String arabicLabel;
  final String englishLabel;

  /// تحويل من String إلى Enum
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'dispatcher':
        return UserRole.dispatcher;
      case 'passenger':
        return UserRole.passenger;
      case 'manager':
        return UserRole.manager;
      default:
        throw ArgumentError('Invalid UserRole: $value');
    }
  }

  /// محاولة التحويل مع قيمة افتراضية
  static UserRole? tryFromString(String? value) {
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

  /// هل المستخدم لديه صلاحية إدارية
  bool get isAdmin => this == UserRole.dispatcher || this == UserRole.manager;

  /// هل المستخدم سائق
  bool get isDriver => this == UserRole.driver;

  /// هل المستخدم راكب
  bool get isPassenger => this == UserRole.passenger;

  /// هل المستخدم مدير
  bool get isManager => this == UserRole.manager;

  /// هل المستخدم مشغل
  bool get isDispatcher => this == UserRole.dispatcher;
}
