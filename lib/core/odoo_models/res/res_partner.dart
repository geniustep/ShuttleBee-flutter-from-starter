import '../base/odoo_model_base.dart';

/// Odoo res.partner model
class ResPartner implements OdooModelBase {
  @override
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? street;
  final String? street2;
  final String? city;
  final int? countryId;
  final String? countryName;
  final int? stateId;
  final String? stateName;
  final String? zip;
  final String? vat;
  final bool isCompany;
  final int? parentId;
  final String? parentName;
  final String? image128;
  final DateTime? createDate;
  final DateTime? writeDate;
  final bool active;
  final double? creditLimit;
  final String? comment;
  final String? website;
  final String? ref;

  // Sync metadata for offline support
  final SyncMetadata? syncMetadata;

  const ResPartner({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.mobile,
    this.street,
    this.street2,
    this.city,
    this.countryId,
    this.countryName,
    this.stateId,
    this.stateName,
    this.zip,
    this.vat,
    this.isCompany = false,
    this.parentId,
    this.parentName,
    this.image128,
    this.createDate,
    this.writeDate,
    this.active = true,
    this.creditLimit,
    this.comment,
    this.website,
    this.ref,
    this.syncMetadata,
  });

  static String get modelName => 'res.partner';

  static List<String> get defaultFields => [
        'id',
        'name',
        'email',
        'phone',
        'mobile',
        'street',
        'street2',
        'city',
        'country_id',
        'state_id',
        'zip',
        'vat',
        'is_company',
        'parent_id',
        'image_128',
        'create_date',
        'write_date',
        'active',
        'credit_limit',
        'comment',
        'website',
        'ref',
      ];

  @override
  String? get displayName => name;

  factory ResPartner.fromJson(Map<String, dynamic> json) {
    return ResPartner(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      email: _getString(json['email']),
      phone: _getString(json['phone']),
      mobile: _getString(json['mobile']),
      street: _getString(json['street']),
      street2: _getString(json['street2']),
      city: _getString(json['city']),
      countryId: _getRelationId(json['country_id']),
      countryName: _getRelationName(json['country_id']),
      stateId: _getRelationId(json['state_id']),
      stateName: _getRelationName(json['state_id']),
      zip: _getString(json['zip']),
      vat: _getString(json['vat']),
      isCompany: json['is_company'] as bool? ?? false,
      parentId: _getRelationId(json['parent_id']),
      parentName: _getRelationName(json['parent_id']),
      image128: _getString(json['image_128']),
      createDate: _parseDateTime(json['create_date']),
      writeDate: _parseDateTime(json['write_date']),
      active: json['active'] as bool? ?? true,
      creditLimit: (json['credit_limit'] as num?)?.toDouble(),
      comment: _getString(json['comment']),
      website: _getString(json['website']),
      ref: _getString(json['ref']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (mobile != null) 'mobile': mobile,
        if (street != null) 'street': street,
        if (street2 != null) 'street2': street2,
        if (city != null) 'city': city,
        if (countryId != null) 'country_id': countryId,
        if (stateId != null) 'state_id': stateId,
        if (zip != null) 'zip': zip,
        if (vat != null) 'vat': vat,
        'is_company': isCompany,
        if (parentId != null) 'parent_id': parentId,
        'active': active,
        if (creditLimit != null) 'credit_limit': creditLimit,
        if (comment != null) 'comment': comment,
        if (website != null) 'website': website,
        if (ref != null) 'ref': ref,
      };

  ResPartner copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? mobile,
    String? street,
    String? street2,
    String? city,
    int? countryId,
    String? countryName,
    int? stateId,
    String? stateName,
    String? zip,
    String? vat,
    bool? isCompany,
    int? parentId,
    String? parentName,
    String? image128,
    DateTime? createDate,
    DateTime? writeDate,
    bool? active,
    double? creditLimit,
    String? comment,
    String? website,
    String? ref,
    SyncMetadata? syncMetadata,
  }) {
    return ResPartner(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      street: street ?? this.street,
      street2: street2 ?? this.street2,
      city: city ?? this.city,
      countryId: countryId ?? this.countryId,
      countryName: countryName ?? this.countryName,
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      zip: zip ?? this.zip,
      vat: vat ?? this.vat,
      isCompany: isCompany ?? this.isCompany,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      image128: image128 ?? this.image128,
      createDate: createDate ?? this.createDate,
      writeDate: writeDate ?? this.writeDate,
      active: active ?? this.active,
      creditLimit: creditLimit ?? this.creditLimit,
      comment: comment ?? this.comment,
      website: website ?? this.website,
      ref: ref ?? this.ref,
      syncMetadata: syncMetadata ?? this.syncMetadata,
    );
  }

  static String? _getString(dynamic value) {
    if (value == null || value == false) return null;
    return value.toString();
  }

  static int? _getRelationId(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is List && value.isNotEmpty) return value[0] as int;
    return null;
  }

  static String? _getRelationName(dynamic value) {
    if (value == null || value == false) return null;
    if (value is List && value.length > 1) return value[1] as String;
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null || value == false) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'ResPartner(id: $id, name: $name)';
}
