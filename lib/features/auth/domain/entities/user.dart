import 'package:bridgecore_flutter/bridgecore_flutter.dart';

import '../../../../core/enums/user_role.dart';

/// User entity - ShuttleBee
class User {
  final int id;
  final String name;
  final String? email;
  final String? login;
  final int? companyId;
  final String? companyName;
  final String? lang;
  final String? tz;
  final String? avatarUrl;
  final List<int>? companyIds;
  final List<String>? companyNames;
  final int? partnerId;
  final int? employeeId;
  final bool isAdmin;
  final bool isInternalUser;
  final List<String> groups;
  final int? currentCompanyId;
  final UserRole role; // ShuttleBee role

  const User({
    required this.id,
    required this.name,
    this.email,
    this.login,
    this.companyId,
    this.companyName,
    this.lang,
    this.tz,
    this.avatarUrl,
    this.companyIds,
    this.companyNames,
    this.partnerId,
    this.employeeId,
    this.isAdmin = false,
    this.isInternalUser = false,
    this.groups = const [],
    this.currentCompanyId,
    this.role = UserRole.passenger, // Default role
  });

  factory User.fromTenantMeResponse(TenantMeResponse me) {
    return User(
      id: me.user.odooUserId ?? 0,
      name: me.user.fullName,
      email: me.user.email,
      login: me.user.email,
      partnerId: me.partnerId,
      employeeId: me.employeeId,
      isAdmin: me.isAdmin,
      isInternalUser: me.isInternalUser,
      groups: me.groups,
      companyIds: me.companyIds,
      currentCompanyId: me.currentCompanyId,
      role: _detectRoleFromGroups(me.groups, me.isAdmin),
    );
  }

  /// Detect user role from Odoo groups
  static UserRole _detectRoleFromGroups(List<String> groups, bool isAdmin) {
    // Check groups for ShuttleBee roles
    final groupsLower = groups.map((g) => g.toLowerCase()).toList();

    if (isAdmin ||
        groupsLower.any((g) => g.contains('manager') || g.contains('مدير'))) {
      return UserRole.manager;
    }
    if (groupsLower
        .any((g) => g.contains('dispatcher') || g.contains('مشغل'))) {
      return UserRole.dispatcher;
    }
    if (groupsLower.any((g) => g.contains('driver') || g.contains('سائق'))) {
      return UserRole.driver;
    }
    // Default to passenger
    return UserRole.passenger;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      login: json['login'] as String?,
      companyId: json['companyId'] as int?,
      companyName: json['companyName'] as String?,
      lang: json['lang'] as String?,
      tz: json['tz'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      companyIds: (json['companyIds'] as List?)?.cast<int>(),
      companyNames: (json['companyNames'] as List?)?.cast<String>(),
      partnerId: json['partnerId'] as int?,
      employeeId: json['employeeId'] as int?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isInternalUser: json['isInternalUser'] as bool? ?? false,
      groups: (json['groups'] as List?)?.cast<String>() ?? const [],
      currentCompanyId: json['currentCompanyId'] as int?,
      role:
          UserRole.tryFromString(json['role'] as String?) ?? UserRole.passenger,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'login': login,
      'companyId': companyId,
      'companyName': companyName,
      'lang': lang,
      'tz': tz,
      'avatarUrl': avatarUrl,
      'companyIds': companyIds,
      'companyNames': companyNames,
      'partnerId': partnerId,
      'employeeId': employeeId,
      'isAdmin': isAdmin,
      'isInternalUser': isInternalUser,
      'groups': groups,
      'currentCompanyId': currentCompanyId,
      'role': role.value,
    };
  }

  /// Create from Odoo response (legacy support)
  factory User.fromOdoo(Map<String, dynamic> json) {
    final groups = (json['groups'] as List?)?.cast<String>() ?? [];
    final isAdmin = json['is_admin'] as bool? ?? false;

    return User(
      id: json['uid'] as int? ?? json['id'] as int? ?? 0,
      name: json['name'] as String? ?? json['username'] as String? ?? '',
      email: json['email'] as String?,
      login: json['login'] as String? ?? json['username'] as String?,
      companyId: json['company_id'] is List
          ? (json['company_id'] as List).firstOrNull as int?
          : json['company_id'] as int?,
      companyName:
          json['company_id'] is List && (json['company_id'] as List).length > 1
              ? (json['company_id'] as List)[1] as String?
              : null,
      lang: json['lang'] as String?,
      tz: json['tz'] as String?,
      companyIds: (json['company_ids'] as List?)?.cast<int>(),
      partnerId: json['partner_id'] is List
          ? (json['partner_id'] as List).firstOrNull as int?
          : json['partner_id'] as int?,
      groups: groups,
      isAdmin: isAdmin,
      role: _detectRoleFromOdoo(json),
    );
  }

  /// Detect role from Odoo response
  static UserRole _detectRoleFromOdoo(Map<String, dynamic> json) {
    // Check for explicit role field (support multiple field names)
    final roleStr = json['shuttle_role'] as String? ??
        json['shuttlebee_role'] as String? ??
        json['role'] as String?;
    
    // Debug: Log what we're getting
    print('🔍 [User.fromOdoo] shuttle_role from json: ${json['shuttle_role']}');
    print('🔍 [User.fromOdoo] shuttlebee_role from json: ${json['shuttlebee_role']}');
    print('🔍 [User.fromOdoo] role from json: ${json['role']}');
    print('🔍 [User.fromOdoo] Final roleStr: $roleStr');
    
    if (roleStr != null) {
      final detectedRole = UserRole.tryFromString(roleStr) ?? UserRole.passenger;
      print('✅ [User.fromOdoo] Detected role: ${detectedRole.value}');
      return detectedRole;
    }

    // Check groups
    final groups = (json['groups'] as List?)?.cast<String>() ?? [];
    final isAdmin = json['is_admin'] as bool? ?? false;
    final groupBasedRole = _detectRoleFromGroups(groups, isAdmin);
    print('⚠️ [User.fromOdoo] No explicit role found, using group-based role: ${groupBasedRole.value}');
    return groupBasedRole;
  }

  /// Copy with
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? login,
    int? companyId,
    String? companyName,
    String? lang,
    String? tz,
    String? avatarUrl,
    List<int>? companyIds,
    List<String>? companyNames,
    int? partnerId,
    int? employeeId,
    bool? isAdmin,
    bool? isInternalUser,
    List<String>? groups,
    int? currentCompanyId,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      login: login ?? this.login,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      lang: lang ?? this.lang,
      tz: tz ?? this.tz,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      companyIds: companyIds ?? this.companyIds,
      companyNames: companyNames ?? this.companyNames,
      partnerId: partnerId ?? this.partnerId,
      employeeId: employeeId ?? this.employeeId,
      isAdmin: isAdmin ?? this.isAdmin,
      isInternalUser: isInternalUser ?? this.isInternalUser,
      groups: groups ?? this.groups,
      currentCompanyId: currentCompanyId ?? this.currentCompanyId,
      role: role ?? this.role,
    );
  }

  /// Check if user has multiple companies
  bool get hasMultipleCompanies => (companyIds?.length ?? 0) > 1;

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}

/// Authentication state
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  /// Initial state
  factory AuthState.initial() => const AuthState();

  /// Loading state
  factory AuthState.loading() => const AuthState(isLoading: true);

  /// Authenticated state
  factory AuthState.authenticated(User user) => AuthState(
        user: user,
        isAuthenticated: true,
      );

  /// Error state
  factory AuthState.error(String message) => AuthState(error: message);

  /// Copy with
  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
