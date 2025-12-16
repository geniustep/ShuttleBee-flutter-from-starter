/// Fleet Vehicle Brand Entity - كيان مُصنّع المركبة
/// يطابق نموذج fleet.vehicle.model.brand في Odoo
class FleetBrand {
  final int id;
  final String name;
  final String? image;

  const FleetBrand({
    required this.id,
    required this.name,
    this.image,
  });

  factory FleetBrand.fromOdoo(Map<String, dynamic> json) {
    return FleetBrand(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? '',
      image: _extractString(json['image_128']),
    );
  }

  factory FleetBrand.fromJson(Map<String, dynamic> json) {
    return FleetBrand(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
      };

  Map<String, dynamic> toOdoo() => {
        'name': name,
      };

  static String? _extractString(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value;
    return value.toString();
  }

  @override
  String toString() => 'FleetBrand(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FleetBrand && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
