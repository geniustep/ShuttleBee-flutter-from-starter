/// Dispatcher Global Holiday Entity
///
/// Maps to Odoo model: `shuttle.holiday`
class DispatcherHoliday {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;
  final String? notes;
  final int? companyId;
  final String? companyName;

  const DispatcherHoliday({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.active,
    this.notes,
    this.companyId,
    this.companyName,
  });

  factory DispatcherHoliday.fromOdoo(Map<String, dynamic> json) {
    final start = _extractString(json['start_date']);
    final end = _extractString(json['end_date']);

    return DispatcherHoliday(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? '',
      startDate: start != null ? DateTime.parse(start) : DateTime(1970),
      endDate: end != null ? DateTime.parse(end) : DateTime(1970),
      active: json['active'] as bool? ?? true,
      notes: _extractString(json['notes']),
      companyId: _extractId(json['company_id']),
      companyName: _extractName(json['company_id']),
    );
  }

  /// Whether this holiday includes the given date (date-only comparison).
  bool includesDate(DateTime date) {
    if (!active) return false;
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) &&
        (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  static int? _extractId(dynamic field) {
    if (field is List && field.isNotEmpty) return field.first as int?;
    return null;
  }

  static String? _extractName(dynamic field) {
    if (field is List && field.length >= 2) return field[1] as String?;
    return null;
  }

  static String? _extractString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }
}
