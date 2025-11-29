import 'package:bridgecore_flutter_starter/core/data/datasources/local_data_source.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';
import 'package:bridgecore_flutter_starter/features/auth/domain/entities/user.dart';

/// Permission service for RBAC
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final CacheDataSource _cache = CacheDataSource();
  User? _currentUser;
  Set<String> _permissions = {};
  Set<String> _roles = {};

  /// Initialize permissions
  Future<void> initialize(User user) async {
    _currentUser = user;
    await _loadPermissions();
    await _loadRoles();
    AppLogger.info('Permissions initialized for user: ${user.name}');
  }

  /// Load permissions from cache or server
  Future<void> _loadPermissions() async {
    if (_currentUser == null) return;

    // Try to load from cache
    final cached = await _cache.get<List<dynamic>>('user_permissions');
    if (cached != null) {
      _permissions = cached.cast<String>().toSet();
      return;
    }

    // Load from user groups
    _permissions = _extractPermissionsFromGroups(_currentUser!.groups);

    // Cache permissions
    await _cache.save(
      key: 'user_permissions',
      data: _permissions.toList(),
      ttl: const Duration(hours: 1),
    );
  }

  /// Load roles from user
  Future<void> _loadRoles() async {
    if (_currentUser == null) return;

    _roles = {};

    // Add admin role
    if (_currentUser!.isAdmin) {
      _roles.add('admin');
    }

    // Add internal user role
    if (_currentUser!.isInternalUser) {
      _roles.add('internal_user');
    }

    // Extract roles from groups
    for (final groupId in _currentUser!.groups) {
      final role = _mapGroupToRole(groupId);
      if (role != null) {
        _roles.add(role);
      }
    }
  }

  /// Extract permissions from groups
  Set<String> _extractPermissionsFromGroups(List<String> groups) {
    final permissions = <String>{};

    // Map Odoo groups to permissions
    // This is a simplified example - you should map based on your Odoo groups
    for (final groupId in groups) {
      final groupPermissions = _mapGroupToPermissions(groupId);
      permissions.addAll(groupPermissions);
    }

    return permissions;
  }

  /// Map group ID to permissions
  Set<String> _mapGroupToPermissions(String groupId) {
    // This should be configured based on your Odoo groups
    // Example mapping:
    final mapping = <String, Set<String>>{
      'base.group_system': {'read_all', 'write_all', 'delete_all'},
      'sales_team.group_sale_manager': {'read_sales', 'write_sales'},
      'stock.group_stock_manager': {'read_inventory'},
      '1': {'read_all', 'write_all', 'delete_all'},
      '2': {'read_sales', 'write_sales'},
      '3': {'read_inventory'},
      // Add more mappings as needed
    };

    return mapping[groupId] ?? {};
  }

  /// Map group ID to role
  String? _mapGroupToRole(String groupId) {
    // Example mapping:
    final mapping = <String, String>{
      'base.group_system': 'admin',
      'sales_team.group_sale_manager': 'sales_manager',
      'stock.group_stock_manager': 'inventory_manager',
      'base.group_user': 'user',
      '1': 'admin',
      '2': 'sales_manager',
      '3': 'inventory_manager',
      '4': 'user',
      // Add more mappings as needed
    };

    return mapping[groupId];
  }

  /// Check if user has permission
  bool hasPermission(String permission) {
    if (_currentUser?.isAdmin == true) {
      return true; // Admin has all permissions
    }

    return _permissions.contains(permission);
  }

  /// Check if user has any of the permissions
  bool hasAnyPermission(List<String> permissions) {
    if (_currentUser?.isAdmin == true) {
      return true;
    }

    return permissions.any((p) => _permissions.contains(p));
  }

  /// Check if user has all permissions
  bool hasAllPermissions(List<String> permissions) {
    if (_currentUser?.isAdmin == true) {
      return true;
    }

    return permissions.every((p) => _permissions.contains(p));
  }

  /// Check if user has role
  bool hasRole(String role) {
    return _roles.contains(role);
  }

  /// Check if user has any of the roles
  bool hasAnyRole(List<String> roles) {
    return roles.any((r) => _roles.contains(r));
  }

  /// Check if user has all roles
  bool hasAllRoles(List<String> roles) {
    return roles.every((r) => _roles.contains(r));
  }

  /// Get all permissions
  Set<String> get permissions => _permissions;

  /// Get all roles
  Set<String> get roles => _roles;

  /// Is admin
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Clear permissions
  void clear() {
    _currentUser = null;
    _permissions.clear();
    _roles.clear();
  }
}

/// Audit trail service
class AuditTrailService {
  static final AuditTrailService _instance = AuditTrailService._internal();
  factory AuditTrailService() => _instance;
  AuditTrailService._internal();

  final CacheDataSource _cache = CacheDataSource();
  final List<AuditLog> _logs = [];

  /// Log an action
  Future<void> log({
    required String action,
    required String resource,
    String? resourceId,
    Map<String, dynamic>? data,
    AuditLogLevel level = AuditLogLevel.info,
  }) async {
    final log = AuditLog(
      action: action,
      resource: resource,
      resourceId: resourceId,
      data: data,
      level: level,
      timestamp: DateTime.now(),
      userId: PermissionService().isAdmin ? 'admin' : 'user',
    );

    _logs.add(log);
    AppLogger.info('Audit: ${log.action} on ${log.resource}');

    // Save to cache
    await _saveLogs();
  }

  /// Save logs to cache
  Future<void> _saveLogs() async {
    final logsJson = _logs.map((l) => l.toJson()).toList();
    await _cache.save(
      key: 'audit_logs',
      data: logsJson,
      ttl: const Duration(days: 7),
    );
  }

  /// Load logs from cache
  Future<void> loadLogs() async {
    final cached = await _cache.get<List<dynamic>>('audit_logs');
    if (cached != null) {
      _logs.clear();
      _logs.addAll(
        cached.map((json) => AuditLog.fromJson(json as Map<String, dynamic>)),
      );
    }
  }

  /// Get logs
  List<AuditLog> get logs => List.unmodifiable(_logs);

  /// Get logs by resource
  List<AuditLog> getLogsByResource(String resource) {
    return _logs.where((l) => l.resource == resource).toList();
  }

  /// Get logs by action
  List<AuditLog> getLogsByAction(String action) {
    return _logs.where((l) => l.action == action).toList();
  }

  /// Clear logs
  Future<void> clearLogs() async {
    _logs.clear();
    await _cache.delete('audit_logs');
  }
}

/// Audit log level
enum AuditLogLevel {
  info,
  warning,
  error,
  critical,
}

/// Audit log entry
class AuditLog {
  final String action;
  final String resource;
  final String? resourceId;
  final Map<String, dynamic>? data;
  final AuditLogLevel level;
  final DateTime timestamp;
  final String userId;

  AuditLog({
    required this.action,
    required this.resource,
    this.resourceId,
    this.data,
    required this.level,
    required this.timestamp,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'resource': resource,
        'resource_id': resourceId,
        'data': data,
        'level': level.name,
        'timestamp': timestamp.toIso8601String(),
        'user_id': userId,
      };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        action: json['action'],
        resource: json['resource'],
        resourceId: json['resource_id'],
        data: json['data'] as Map<String, dynamic>?,
        level: AuditLogLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => AuditLogLevel.info,
        ),
        timestamp: DateTime.parse(json['timestamp']),
        userId: json['user_id'],
      );
}
