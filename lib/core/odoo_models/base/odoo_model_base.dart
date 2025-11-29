/// Base class for all Odoo models
abstract class OdooModelBase {
  /// Odoo model name (e.g., 'res.partner')
  static String get modelName => throw UnimplementedError();

  /// Default fields to fetch
  static List<String> get defaultFields => ['id', 'name', 'create_date', 'write_date'];

  /// Convert to JSON map
  Map<String, dynamic> toJson();

  /// Get model ID
  int? get id;

  /// Get display name
  String? get displayName;
}

/// Sync status enum
enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  conflict,
  error,
  orphaned,
}

/// Sync metadata for offline support
class SyncMetadata {
  final int? localId;
  final int? remoteId;
  final String model;
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final DateTime? lastModifiedAt;
  final int version;
  final String? conflictData;
  final Map<String, dynamic>? pendingChanges;
  final String? errorMessage;

  const SyncMetadata({
    this.localId,
    this.remoteId,
    required this.model,
    this.status = SyncStatus.synced,
    this.lastSyncedAt,
    this.lastModifiedAt,
    this.version = 1,
    this.conflictData,
    this.pendingChanges,
    this.errorMessage,
  });

  SyncMetadata copyWith({
    int? localId,
    int? remoteId,
    String? model,
    SyncStatus? status,
    DateTime? lastSyncedAt,
    DateTime? lastModifiedAt,
    int? version,
    String? conflictData,
    Map<String, dynamic>? pendingChanges,
    String? errorMessage,
  }) {
    return SyncMetadata(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      model: model ?? this.model,
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
      conflictData: conflictData ?? this.conflictData,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'remoteId': remoteId,
        'model': model,
        'status': status.name,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'lastModifiedAt': lastModifiedAt?.toIso8601String(),
        'version': version,
        'conflictData': conflictData,
        'pendingChanges': pendingChanges,
        'errorMessage': errorMessage,
      };

  factory SyncMetadata.fromJson(Map<String, dynamic> json) => SyncMetadata(
        localId: json['localId'] as int?,
        remoteId: json['remoteId'] as int?,
        model: json['model'] as String,
        status: SyncStatus.values.byName(json['status'] as String),
        lastSyncedAt: json['lastSyncedAt'] != null
            ? DateTime.parse(json['lastSyncedAt'] as String)
            : null,
        lastModifiedAt: json['lastModifiedAt'] != null
            ? DateTime.parse(json['lastModifiedAt'] as String)
            : null,
        version: json['version'] as int? ?? 1,
        conflictData: json['conflictData'] as String?,
        pendingChanges: json['pendingChanges'] as Map<String, dynamic>?,
        errorMessage: json['errorMessage'] as String?,
      );
}
