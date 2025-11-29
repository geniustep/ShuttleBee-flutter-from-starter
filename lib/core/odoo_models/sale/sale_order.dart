import '../base/odoo_model_base.dart';

/// Odoo sale.order model
class SaleOrder implements OdooModelBase {
  @override
  final int? id;
  final String name;
  final int? partnerId;
  final String? partnerName;
  final DateTime? dateOrder;
  final String state;
  final double amountUntaxed;
  final double amountTax;
  final double amountTotal;
  final int? userId;
  final String? userName;
  final int? companyId;
  final String? companyName;
  final String? note;
  final String? clientOrderRef;
  final DateTime? commitmentDate;
  final DateTime? createDate;
  final DateTime? writeDate;

  // Sync metadata for offline support
  final SyncMetadata? syncMetadata;

  const SaleOrder({
    this.id,
    required this.name,
    this.partnerId,
    this.partnerName,
    this.dateOrder,
    this.state = 'draft',
    this.amountUntaxed = 0.0,
    this.amountTax = 0.0,
    this.amountTotal = 0.0,
    this.userId,
    this.userName,
    this.companyId,
    this.companyName,
    this.note,
    this.clientOrderRef,
    this.commitmentDate,
    this.createDate,
    this.writeDate,
    this.syncMetadata,
  });

  static String get modelName => 'sale.order';

  static List<String> get defaultFields => [
        'id',
        'name',
        'partner_id',
        'date_order',
        'state',
        'amount_untaxed',
        'amount_tax',
        'amount_total',
        'user_id',
        'company_id',
        'note',
        'client_order_ref',
        'commitment_date',
        'create_date',
        'write_date',
      ];

  @override
  String? get displayName => name;

  /// Get state display text
  String get stateDisplay {
    switch (state) {
      case 'draft':
        return 'Quotation';
      case 'sent':
        return 'Quotation Sent';
      case 'sale':
        return 'Sales Order';
      case 'done':
        return 'Locked';
      case 'cancel':
        return 'Cancelled';
      default:
        return state;
    }
  }

  factory SaleOrder.fromJson(Map<String, dynamic> json) {
    return SaleOrder(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      partnerId: _getRelationId(json['partner_id']),
      partnerName: _getRelationName(json['partner_id']),
      dateOrder: _parseDateTime(json['date_order']),
      state: json['state'] as String? ?? 'draft',
      amountUntaxed: (json['amount_untaxed'] as num?)?.toDouble() ?? 0.0,
      amountTax: (json['amount_tax'] as num?)?.toDouble() ?? 0.0,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      userId: _getRelationId(json['user_id']),
      userName: _getRelationName(json['user_id']),
      companyId: _getRelationId(json['company_id']),
      companyName: _getRelationName(json['company_id']),
      note: _getString(json['note']),
      clientOrderRef: _getString(json['client_order_ref']),
      commitmentDate: _parseDateTime(json['commitment_date']),
      createDate: _parseDateTime(json['create_date']),
      writeDate: _parseDateTime(json['write_date']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (partnerId != null) 'partner_id': partnerId,
        if (dateOrder != null) 'date_order': dateOrder?.toIso8601String(),
        'state': state,
        if (userId != null) 'user_id': userId,
        if (companyId != null) 'company_id': companyId,
        if (note != null) 'note': note,
        if (clientOrderRef != null) 'client_order_ref': clientOrderRef,
        if (commitmentDate != null)
          'commitment_date': commitmentDate?.toIso8601String(),
      };

  SaleOrder copyWith({
    int? id,
    String? name,
    int? partnerId,
    String? partnerName,
    DateTime? dateOrder,
    String? state,
    double? amountUntaxed,
    double? amountTax,
    double? amountTotal,
    int? userId,
    String? userName,
    int? companyId,
    String? companyName,
    String? note,
    String? clientOrderRef,
    DateTime? commitmentDate,
    DateTime? createDate,
    DateTime? writeDate,
    SyncMetadata? syncMetadata,
  }) {
    return SaleOrder(
      id: id ?? this.id,
      name: name ?? this.name,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      dateOrder: dateOrder ?? this.dateOrder,
      state: state ?? this.state,
      amountUntaxed: amountUntaxed ?? this.amountUntaxed,
      amountTax: amountTax ?? this.amountTax,
      amountTotal: amountTotal ?? this.amountTotal,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      note: note ?? this.note,
      clientOrderRef: clientOrderRef ?? this.clientOrderRef,
      commitmentDate: commitmentDate ?? this.commitmentDate,
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
  String toString() => 'SaleOrder(id: $id, name: $name)';
}
