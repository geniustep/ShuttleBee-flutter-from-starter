import 'dart:convert';
import 'package:hive/hive.dart';

/// Metadata about cached collections
///
/// Tracks information about entire collections (e.g., list of trips).
class CacheMetadata {
  /// Collection name (e.g., 'trips', 'passengers')
  final String collectionName;

  /// Number of items in collection
  int itemCount;

  /// When collection was last updated
  DateTime lastUpdated;

  /// When collection expires
  final DateTime? expiresAt;

  /// Total size in bytes (approximate)
  int sizeBytes;

  /// Version number for migration support
  final int version;

  /// Custom metadata
  final Map<String, dynamic>? customData;

  CacheMetadata({
    required this.collectionName,
    this.itemCount = 0,
    required this.lastUpdated,
    this.expiresAt,
    this.sizeBytes = 0,
    this.version = 1,
    this.customData,
  });

  /// Check if collection is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if collection is valid
  bool get isValid => !isExpired;

  /// Age of this collection
  Duration get age => DateTime.now().difference(lastUpdated);

  /// Update item count
  void updateItemCount(int count) {
    itemCount = count;
    lastUpdated = DateTime.now();
  }

  /// Update size
  void updateSize(int bytes) {
    sizeBytes = bytes;
  }

  /// Mark as updated
  void markUpdated() {
    lastUpdated = DateTime.now();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'collectionName': collectionName,
      'itemCount': itemCount,
      'lastUpdated': lastUpdated.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'sizeBytes': sizeBytes,
      'version': version,
      'customData': customData,
    };
  }

  /// Create from JSON
  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      collectionName: json['collectionName'] as String,
      itemCount: json['itemCount'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
      customData: json['customData'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'CacheMetadata(collection: $collectionName, '
        'items: $itemCount, age: ${age.inMinutes}min, '
        'size: ${(sizeBytes / 1024).toStringAsFixed(2)}KB)';
  }
}

/// Hive TypeAdapter for CacheMetadata
class CacheMetadataAdapter extends TypeAdapter<CacheMetadata> {
  @override
  final int typeId = 1;

  @override
  CacheMetadata read(BinaryReader reader) {
    final jsonString = reader.readString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return CacheMetadata.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, CacheMetadata obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
