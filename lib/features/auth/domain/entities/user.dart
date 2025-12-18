import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import '../../../../core/enums/user_role.dart';

/// User entity
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
  final UserRole? role;
  final List<int>
      shuttleDispatcherGroupIds; // NEW: المجموعات المصرح للـ Dispatcher بها

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
    this.role,
    this.shuttleDispatcherGroupIds =
        const [], // NEW: المجموعات المصرح للـ Dispatcher بها
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
      shuttleDispatcherGroupIds: const [], // Will be loaded separately if needed
    );
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
      role: json['role'] != null
          ? UserRole.tryFromString(json['role'] as String)
          : null,
      shuttleDispatcherGroupIds:
          (json['shuttleDispatcherGroupIds'] as List?)?.cast<int>() ??
              const [], // NEW
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
      'role': role?.value,
      'shuttleDispatcherGroupIds': shuttleDispatcherGroupIds, // NEW
    };
  }

  /// Create from Odoo response (legacy support)
  factory User.fromOdoo(Map<String, dynamic> json) {
    // Extract role from shuttle_role field
    final roleStr = json['shuttle_role'] as String?;
    final role = roleStr != null ? UserRole.tryFromString(roleStr) : null;

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
      role: role,
      shuttleDispatcherGroupIds:
          (json['shuttle_dispatcher_group_ids'] as List?)?.cast<int>() ??
              const [], // NEW
    );
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
    List<int>? shuttleDispatcherGroupIds, // NEW
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
      shuttleDispatcherGroupIds:
          shuttleDispatcherGroupIds ?? this.shuttleDispatcherGroupIds, // NEW
    );
  }

  /// Check if user has multiple companies
  bool get hasMultipleCompanies => (companyIds?.length ?? 0) > 1;

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}

/// Token state for offline-aware authentication
///
/// هذه الحالات تمثل "آلة الحالة" للجلسة:
/// - valid: التوكن صالح - يمكن العمل بشكل طبيعي
/// - needsRefresh: التوكن منتهي لكن يمكن تجديده - يمكن العمل أوفلاين
/// - expired: كل التوكنات منتهية - يجب تسجيل الدخول
/// - none: لا توجد توكنات - المستخدم لم يسجل دخوله
enum TokenState {
  /// Valid access token - fully authenticated
  valid,

  /// Access token expired but can be refreshed
  needsRefresh,

  /// All tokens expired - must login again
  expired,

  /// No tokens stored
  none,
}

/// Authentication state with offline support
///
/// هذا الكلاس يدعم:
/// - حالات التوكن المتعددة (valid, needsRefresh, expired, none)
/// - العمل أوفلاين مع بيانات مخزنة محلياً
/// - التفريق بين "الجلسة انتهت" و "يمكن تجديد التوكن"
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final TokenState tokenState;
  final bool isOffline;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.tokenState = TokenState.none,
    this.isOffline = false,
  });

  /// Initial state
  factory AuthState.initial() => const AuthState();

  /// Loading state
  factory AuthState.loading() => const AuthState(isLoading: true);

  /// Authenticated state with valid token
  factory AuthState.authenticated(
    User user, {
    TokenState tokenState = TokenState.valid,
  }) =>
      AuthState(
        user: user,
        isAuthenticated: true,
        tokenState: tokenState,
      );

  /// Authenticated but needs token refresh (offline mode)
  factory AuthState.needsRefresh(User user, {bool isOffline = false}) =>
      AuthState(
        user: user,
        isAuthenticated: true,
        tokenState: TokenState.needsRefresh,
        isOffline: isOffline,
      );

  /// Session expired - must login again
  factory AuthState.sessionExpired() => const AuthState(
        tokenState: TokenState.expired,
      );

  /// Invalid token - token exists but is not a valid tenant token
  /// User must logout and login again to get a proper token
  factory AuthState.invalidToken() => const AuthState(
        tokenState: TokenState.expired,
        error: 'انتهت صلاحية الجلسة. يرجى تسجيل الخروج وإعادة تسجيل الدخول',
      );

  /// Error state
  factory AuthState.error(String message) => AuthState(error: message);

  /// Check if can work offline (has user data even if token expired)
  ///
  /// هذا مهم لـ ShuttleBee: السماح للسائق بالعمل أوفلاين
  /// حتى لو التوكن منتهي، طالما لديه بيانات محلية
  bool get canWorkOffline => user != null && tokenState != TokenState.none;

  /// Check if token needs refresh before API calls
  bool get needsTokenRefresh => tokenState == TokenState.needsRefresh;

  /// Check if session is completely expired
  bool get isSessionExpired => tokenState == TokenState.expired;

  /// Copy with
  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    TokenState? tokenState,
    bool? isOffline,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tokenState: tokenState ?? this.tokenState,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
