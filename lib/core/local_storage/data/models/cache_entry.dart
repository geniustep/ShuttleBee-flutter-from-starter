import 'dart:convert';
import 'package:hive/hive.dart';

/// Generic cache entry with TTL support
///
/// Stores any JSON-serializable data with optional expiry time.
class CacheEntry {
  /// Unique key for this entry
  final String key;

  /// Cached data as JSON map
  final Map<String, dynamic> data;

  /// When this entry was created
  final DateTime createdAt;

  /// When this entry expires (null = never expires)
  final DateTime? expiresAt;

  /// Last access time (for LRU eviction)
  DateTime lastAccessedAt;

  /// Number of times this entry was accessed
  int accessCount;

  CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    this.expiresAt,
    DateTime? lastAccessedAt,
    this.accessCount = 0,
  }) : lastAccessedAt = lastAccessedAt ?? createdAt;

  /// Check if this entry is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if this entry is valid (not expired)
  bool get isValid => !isExpired;

  /// Time remaining until expiry
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  /// Age of this entry
  Duration get age => DateTime.now().difference(createdAt);

  /// Mark this entry as accessed (update access metadata)
  void markAccessed() {
    lastAccessedAt = DateTime.now();
    accessCount++;
  }

  /// Create cache entry with TTL
  factory CacheEntry.withTTL({
    required String key,
    required Map<String, dynamic> data,
    required Duration ttl,
  }) {
    final now = DateTime.now();
    return CacheEntry(
      key: key,
      data: data,
      createdAt: now,
      expiresAt: now.add(ttl),
      lastAccessedAt: now,
      accessCount: 0,
    );
  }

  /// Create cache entry without expiry
  factory CacheEntry.permanent({
    required String key,
    required Map<String, dynamic> data,
  }) {
    final now = DateTime.now();
    return CacheEntry(
      key: key,
      data: data,
      createdAt: now,
      expiresAt: null,
      lastAccessedAt: now,
      accessCount: 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'accessCount': accessCount,
    };
  }

  /// Create from JSON
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
      accessCount: json['accessCount'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'CacheEntry(key: $key, age: ${age.inMinutes}min, '
        'expires: ${timeUntilExpiry?.inMinutes}min, '
        'accessed: $accessCount times)';
  }
}

/// Hive TypeAdapter for CacheEntry
class CacheEntryAdapter extends TypeAdapter<CacheEntry> {
  @override
  final int typeId = 0;

  @override
  CacheEntry read(BinaryReader reader) {
    final jsonString = reader.readString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return CacheEntry.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, CacheEntry obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
