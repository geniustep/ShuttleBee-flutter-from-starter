import '../base/odoo_model_base.dart';

/// Odoo product.product model
class ProductProduct implements OdooModelBase {
  @override
  final int? id;
  final String name;
  final String? defaultCode;
  final String? barcode;
  final double listPrice;
  final double standardPrice;
  final int? categId;
  final String? categName;
  final int? uomId;
  final String? uomName;
  final String? type;
  final bool saleOk;
  final bool purchaseOk;
  final bool active;
  final double qtyAvailable;
  final double virtualAvailable;
  final String? image128;
  final String? description;
  final String? descriptionSale;
  final DateTime? createDate;
  final DateTime? writeDate;

  // Sync metadata for offline support
  final SyncMetadata? syncMetadata;

  const ProductProduct({
    this.id,
    required this.name,
    this.defaultCode,
    this.barcode,
    this.listPrice = 0.0,
    this.standardPrice = 0.0,
    this.categId,
    this.categName,
    this.uomId,
    this.uomName,
    this.type,
    this.saleOk = true,
    this.purchaseOk = true,
    this.active = true,
    this.qtyAvailable = 0.0,
    this.virtualAvailable = 0.0,
    this.image128,
    this.description,
    this.descriptionSale,
    this.createDate,
    this.writeDate,
    this.syncMetadata,
  });

  static String get modelName => 'product.product';

  static List<String> get defaultFields => [
        'id',
        'name',
        'default_code',
        'barcode',
        'list_price',
        'standard_price',
        'categ_id',
        'uom_id',
        'type',
        'sale_ok',
        'purchase_ok',
        'active',
        'qty_available',
        'virtual_available',
        'image_128',
        'description',
        'description_sale',
        'create_date',
        'write_date',
      ];

  @override
  String? get displayName =>
      defaultCode != null ? '[$defaultCode] $name' : name;

  factory ProductProduct.fromJson(Map<String, dynamic> json) {
    return ProductProduct(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      defaultCode: _getString(json['default_code']),
      barcode: _getString(json['barcode']),
      listPrice: (json['list_price'] as num?)?.toDouble() ?? 0.0,
      standardPrice: (json['standard_price'] as num?)?.toDouble() ?? 0.0,
      categId: _getRelationId(json['categ_id']),
      categName: _getRelationName(json['categ_id']),
      uomId: _getRelationId(json['uom_id']),
      uomName: _getRelationName(json['uom_id']),
      type: json['type'] as String?,
      saleOk: json['sale_ok'] as bool? ?? true,
      purchaseOk: json['purchase_ok'] as bool? ?? true,
      active: json['active'] as bool? ?? true,
      qtyAvailable: (json['qty_available'] as num?)?.toDouble() ?? 0.0,
      virtualAvailable: (json['virtual_available'] as num?)?.toDouble() ?? 0.0,
      image128: _getString(json['image_128']),
      description: _getString(json['description']),
      descriptionSale: _getString(json['description_sale']),
      createDate: _parseDateTime(json['create_date']),
      writeDate: _parseDateTime(json['write_date']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (defaultCode != null) 'default_code': defaultCode,
        if (barcode != null) 'barcode': barcode,
        'list_price': listPrice,
        'standard_price': standardPrice,
        if (categId != null) 'categ_id': categId,
        if (uomId != null) 'uom_id': uomId,
        if (type != null) 'type': type,
        'sale_ok': saleOk,
        'purchase_ok': purchaseOk,
        'active': active,
        if (description != null) 'description': description,
        if (descriptionSale != null) 'description_sale': descriptionSale,
      };

  ProductProduct copyWith({
    int? id,
    String? name,
    String? defaultCode,
    String? barcode,
    double? listPrice,
    double? standardPrice,
    int? categId,
    String? categName,
    int? uomId,
    String? uomName,
    String? type,
    bool? saleOk,
    bool? purchaseOk,
    bool? active,
    double? qtyAvailable,
    double? virtualAvailable,
    String? image128,
    String? description,
    String? descriptionSale,
    DateTime? createDate,
    DateTime? writeDate,
    SyncMetadata? syncMetadata,
  }) {
    return ProductProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultCode: defaultCode ?? this.defaultCode,
      barcode: barcode ?? this.barcode,
      listPrice: listPrice ?? this.listPrice,
      standardPrice: standardPrice ?? this.standardPrice,
      categId: categId ?? this.categId,
      categName: categName ?? this.categName,
      uomId: uomId ?? this.uomId,
      uomName: uomName ?? this.uomName,
      type: type ?? this.type,
      saleOk: saleOk ?? this.saleOk,
      purchaseOk: purchaseOk ?? this.purchaseOk,
      active: active ?? this.active,
      qtyAvailable: qtyAvailable ?? this.qtyAvailable,
      virtualAvailable: virtualAvailable ?? this.virtualAvailable,
      image128: image128 ?? this.image128,
      description: description ?? this.description,
      descriptionSale: descriptionSale ?? this.descriptionSale,
      createDate: createDate ?? this.createDate,
      writeDate: writeDate ?? this.writeDate,
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
  String toString() => 'ProductProduct(id: $id, name: $name)';
}
