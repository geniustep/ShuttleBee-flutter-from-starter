import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:bridgecore_flutter_starter/core/config/env_config.dart';
import 'package:bridgecore_flutter_starter/core/constants/app_constants.dart';
import 'package:bridgecore_flutter_starter/core/storage/secure_storage_service.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../constants/storage_keys.dart';

/// BridgeCore client wrapper for Odoo integration
class BridgecoreClient {
  final Logger _logger = Logger();
  late final _bridgeCore = BridgeCore.instance.odoo;

  bool _isAuthenticated = false;
  String? _sessionId;
  int? _userId;
  String? _database;
  late final FlutterSecureStorage _storage = SecureStorageService.instance;

  /// Check if client is authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Get session ID
  String? get sessionId => _sessionId;

  /// Get user ID
  int? get userId => _userId;

  /// Get database name
  String? get database => _database;

  /// Get BridgeCore instance
  OdooService get client => _bridgeCore;

  BridgecoreClient(String baseUrl) {
    // _bridgeCore = BridgeCore(baseUrl: baseUrl);
    _logger.d('BridgecoreClient initialized with URL: $baseUrl');
  }

  /// Restore session from stored credentials
  /// This method is called when the app restarts and needs to restore a previous session
  void restoreSession({required String sessionId, required int userId}) {
    _sessionId = sessionId;
    _userId = userId;
    _isAuthenticated = true;
    _logger.d('Session restored for userId: $userId');
  }

  /// Authenticate with Odoo server
  Future<Map<String, dynamic>> authenticate({
    required String modelName,
    required List<String> listFields,
    // required String database,
    required String username,
    required String password,
    Map<String, dynamic>? odooFieldsCheck, // إضافة معامل اختياري
  }) async {
    try {
      try {
        await BridgeCore.instance.auth.logout();
      } catch (_) {
        await _storage.delete(key: AppConstants.accessTokenKey);
        await _storage.delete(key: AppConstants.refreshTokenKey);
        // تجاهل خطأ logout إذا لم يكن هناك session
      }

      _logger.d('Authenticating user: $username');

      // إنشاء OdooFieldsCheck من JSON إذا تم تمريره
      OdooFieldsCheck? fieldsCheck;
      if (odooFieldsCheck != null) {
        final model = odooFieldsCheck['model'] as String?;
        final listFields = odooFieldsCheck['list_fields'] as List<dynamic>?;

        if (model != null && listFields != null) {
          fieldsCheck = OdooFieldsCheck(
            model: model,
            listFields: listFields.cast<String>(),
          );
          _logger
              .d('Using odoo_fields_check: model=$model, fields=$listFields');
        }
      }

      final session = await BridgeCore.instance.auth.login(
        email: username, // Tenant-based API يستخدم email
        password: password,
        odooFieldsCheck: fieldsCheck, // تمرير OdooFieldsCheck
      );
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: session.accessToken,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: session.refreshToken,
      );

      _isAuthenticated = true;
      _sessionId = session.accessToken; // token acts as session identifier
      _userId = session.user.odooUserId;
      _database = session.tenant.odooDatabase;

      // Legacy key expected by the rest of the app
      await _storage.write(
        key: StorageKeys.sessionId,
        value: _sessionId,
      );

      _logger.d('✅ [login] Tokens saved to SecureStorage for compatibility');

      // Convert TenantSession to Map for compatibility
      final userId = session.user.odooUserId;
      final odooFieldsData = session.odooFieldsData?.toJson();

// هذه اللائحة للعرض فقط أو للإرسال
      final List<Map<String, dynamic>> fieldsList = [];

// هنا نخزن data بالكامل
      Map<String, dynamic> data = {};

      if (odooFieldsData != null) {
        // data المجهولة القادمة من Odoo
        data = Map<String, dynamic>.from(odooFieldsData['data'] ?? {});

        // تحويلها إلى لائحة
        for (final entry in data.entries) {
          fieldsList.add({
            'key': entry.key,
            'value': entry.value,
          });
        }
      }

      // Extract shuttle_role directly from odooFieldsData if available
      final shuttleRole = odooFieldsData?['shuttle_role'] ??
          odooFieldsData?['data']?['shuttle_role'] ??
          data['shuttle_role'];

      _logger.d('🔍 [authenticate] Shuttle Role from Odoo: $shuttleRole');

      final response = <String, dynamic>{
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken,
        'token_type': 'Bearer',
        'expires_in': session.expiresIn,
        'session_id': session.accessToken,

        if (userId != null) 'uid': userId,
        if (userId != null) 'id': userId,

        'name': session.user.fullName,
        'username': session.user.email,
        'email': session.user.email,

        // نحط كل فروع data داخل response بدون ما نكتبهم
        ...data,
      };

      return response;
    } catch (e, stackTrace) {
      _logger.e('Authentication failed', error: e, stackTrace: stackTrace);
      _isAuthenticated = false;
      _userId = null;
      _sessionId = null;
      _database = null;
      rethrow;
    }
  }

  /// Logout from Odoo server
  Future<Map<String, dynamic>> logout() async {
    try {
      _logger.d('Logging out user: $_userId');
      // BridgeCore might not have a logout method, just clear local state
      _isAuthenticated = false;
      _userId = null;
      _sessionId = null;
      _database = null;
      _logger.i('Logout successful');
      // Use SDK for logout
      await BridgeCore.instance.auth.logout();

      // حذف التوكنات من SecureStorage أيضاً للتوافق
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: StorageKeys.sessionId);

      AppLogger.info('✅ [logout] Logout successful, tokens cleared');
      return {'success': true};
    } catch (e, stackTrace) {
      _logger.e('Logout failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// ✅ الحصول على معلومات المستخدم الحالي باستخدام /me endpoint (BridgeCore v0.2.0)
  Future<Map<String, dynamic>> getCurrentUser({
    required String modelName,
    required List<String> listFields,
  }) async {
    try {
      // استخدام BridgeCore مباشرة مع odoo_fields_check
      final meResponse = await BridgeCore.instance.auth.me(
        odooFieldsCheck: OdooFieldsCheck(
          model: modelName,
          listFields: listFields,
          // listFields: ['shuttle_role'],
        ),
        forceRefresh: true, // للحصول على بيانات محدثة
      );

      // تحويل الاستجابة إلى Map
      final responseJson = meResponse.toJson();

      // طباعة log للبيانات المستلمة
      AppLogger.info(
        '📥 [getCurrentUser] Received user data from /me endpoint',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] User ID: ${responseJson['user']?['id']}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] User Name: ${responseJson['user']?['name']}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] User Email: ${responseJson['user']?['email']}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] Partner ID: ${meResponse.partnerId}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] Employee ID: ${meResponse.employeeId}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] Is Admin: ${meResponse.isAdmin}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] Is Internal User: ${meResponse.isInternalUser}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] Groups: ${meResponse.groups}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] Company IDs: ${meResponse.companyIds}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] Current Company ID: ${meResponse.currentCompanyId}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] Odoo Fields Data: ${meResponse.odooFieldsData}',
      );
      AppLogger.debug(
        '📥 [getCurrentUser] Shuttle Role: ${meResponse.odooFieldsData?['shuttle_role']}',
      );

      final response = {
        'user': responseJson['user'] ?? {},
        'tenant': responseJson['tenant'] ?? {},
        'partner_id': meResponse.partnerId,
        'employee_id': meResponse.employeeId,
        'groups': meResponse.groups,
        'is_admin': meResponse.isAdmin,
        'is_internal_user': meResponse.isInternalUser,
        'company_ids': meResponse.companyIds,
        'current_company_id': meResponse.currentCompanyId,
        'odoo_fields_data': meResponse.odooFieldsData ?? {},
        // للوصول المباشر لـ shuttle_role
        'shuttle_role': meResponse.odooFieldsData?['shuttle_role'],
      };

      AppLogger.info('✅ [getCurrentUser] Successfully processed user data');
      return response;
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  /// Search and read records
  /// Search and read records
  Future<List<Map<String, dynamic>>> searchRead({
    required String model,
    List<dynamic>? domain,
    List<String>? fields,
    int? limit,
    int? offset,
    String? order,
  }) async {
    try {
      _ensureAuthenticated();

      final result = await BridgeCore.instance.odoo.searchRead(
        model: model,
        domain: domain ?? [],
        fields: fields,
        limit: limit ?? 80,
        offset: offset ?? 0,
        order: order,
      );
      _logger.d('searchRead returned ${result.length} records');
      return result;
    } catch (e, stackTrace) {
      _logger.e('searchRead failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Search for record IDs
  Future<List<int>> search({
    required String model,
    List<dynamic>? domain,
    int? limit,
    int? offset,
    String? order,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('search: $model, domain: $domain');

      final result = await BridgeCore.instance.odoo.search(
        model: model,
        domain: domain ?? [],
        limit: limit,
        offset: offset!,
        order: order,
      );

      _logger.d('search returned ${result.length} IDs');
      return result.cast<int>();
    } catch (e, stackTrace) {
      _logger.e('search failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Read records by IDs
  Future<List<Map<String, dynamic>>> read({
    required String model,
    required List<int> ids,
    List<String>? fields,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('read: $model, ids: $ids');

      final result = await _bridgeCore.read(
        model: model,
        ids: ids,
        fields: fields ?? [],
      );

      _logger.d('read returned ${result.length} records');
      return result;
    } catch (e, stackTrace) {
      _logger.e('read failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Create a new record
  Future<int> create({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('create: $model, values: $values');

      final result = await _bridgeCore.create(
        model: model,
        values: values,
      );

      _logger.i('create successful, new ID: $result');
      return result;
    } catch (e, stackTrace) {
      _logger.e('create failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update existing records
  Future<bool> write({
    required String model,
    required List<int> ids,
    required Map<String, dynamic> values,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('write: $model, ids: $ids, values: $values');

      final result = await _bridgeCore.update(
        model: model,
        ids: ids,
        values: values,
      );

      _logger.i('write successful');
      return result;
    } catch (e, stackTrace) {
      _logger.e('write failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete records
  Future<bool> unlink({
    required String model,
    required List<int> ids,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('unlink: $model, ids: $ids');

      final result = await _bridgeCore.delete(
        model: model,
        ids: ids,
      );

      _logger.i('unlink successful');
      return result;
    } catch (e, stackTrace) {
      _logger.e('unlink failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Call a model method
  Future<dynamic> callKw({
    required String model,
    required String method,
    List<dynamic>? args,
    Map<String, dynamic>? kwargs,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('callKw: $model.$method');

      final response = await _bridgeCore.custom.callKw(
        model: model,
        method: method,
        args: args ?? [],
        kwargs: kwargs ?? {},
      );

      _logger.d('callKw successful');

      if (response.success) {
        return response.result;
      }
      throw Exception(response.error ?? 'Unknown callKw error');
    } catch (e, stackTrace) {
      _logger.e('callKw failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get record count
  Future<int> searchCount({
    required String model,
    List<dynamic>? domain,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('searchCount: $model, domain: $domain');

      final result = await _bridgeCore.searchCount(
        model: model,
        domain: domain ?? [],
      );

      _logger.d('searchCount returned: $result');
      return result;
    } catch (e, stackTrace) {
      _logger.e('searchCount failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==================== Action Methods (Odoo 18) ====================

  /// Validate records (e.g., confirm a sale order)
  Future<bool> validate({
    required String model,
    required List<int> ids,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('validate: $model, ids: $ids');

      final result = await _bridgeCore.custom.actionValidate(
        model: model,
        ids: ids,
      );

      _logger.i('validate successful');
      return result.success;
    } catch (e, stackTrace) {
      _logger.e('validate failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Mark records as done
  Future<bool> done({
    required String model,
    required List<int> ids,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('done: $model, ids: $ids');

      final result = await _bridgeCore.custom.actionDone(
        model: model,
        ids: ids,
      );

      _logger.i('done successful');
      return result.success;
    } catch (e, stackTrace) {
      _logger.e('done failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Approve records
  Future<bool> approve({
    required String model,
    required List<int> ids,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('approve: $model, ids: $ids');

      final result = await _bridgeCore.custom.actionApprove(
        model: model,
        ids: ids,
      );

      _logger.i('approve successful');
      return result.success;
    } catch (e, stackTrace) {
      _logger.e('approve failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Reject records
  Future<bool> reject({
    required String model,
    required List<int> ids,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('reject: $model, ids: $ids');

      final result = await _bridgeCore.custom.actionReject(
        model: model,
        ids: ids,
      );

      _logger.i('reject successful');
      return result.success;
    } catch (e, stackTrace) {
      _logger.e('reject failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Assign records to a user
  Future<bool> assign({
    required String model,
    required List<int> ids,
    required int userId,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('assign: $model, ids: $ids, userId: $userId');

      final result = await _bridgeCore.custom.actionAssign(
        model: model,
        ids: ids,
      );

      _logger.i('assign successful');
      return result.success;
    } catch (e, stackTrace) {
      _logger.e('assign failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Unlock records
  Future<bool> unlock({
    required String model,
    required List<int> ids,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('unlock: $model, ids: $ids');

      final result = await _bridgeCore.custom.actionUnlock(
        model: model,
        ids: ids,
      );

      _logger.i('unlock successful');
      return result.success;
    } catch (e, stackTrace) {
      _logger.e('unlock failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Execute button action on records
  Future<dynamic> executeButtonAction({
    required String model,
    required List<int> ids,
    required String buttonName,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('executeButtonAction: $model, ids: $ids, button: $buttonName');

      final result = await _bridgeCore.custom.executeButtonAction(
        model: model,
        buttonMethod: buttonName,
        ids: ids,
      );

      _logger.i('executeButtonAction successful');
      return result.success;
    } catch (e, stackTrace) {
      _logger.e('executeButtonAction failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==================== Advanced Methods ====================

  /// Get fields for a model
  Future<Map<String, dynamic>> getFields({
    required String model,
    List<String>? attributes,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('getFields: $model');

      // Note: fieldsGet is not available in BridgeCore v3.0.0
      // Use views.fieldsViewGet instead or implement custom solution
      throw UnimplementedError(
        'getFields is not directly available in BridgeCore v3.0.0. '
        'Use views.fieldsViewGet or advanced operations instead.',
      );
    } catch (e, stackTrace) {
      _logger.e('getFields failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Read group (aggregation)
  Future<List<Map<String, dynamic>>> readGroup({
    required String model,
    List<dynamic>? domain,
    required List<String> fields,
    required List<String> groupBy,
    int? offset,
    int? limit,
    String? orderBy,
    bool? lazy,
  }) async {
    try {
      _ensureAuthenticated();

      _logger.d('readGroup: $model, groupBy: $groupBy');

      final result = await _bridgeCore.advanced.readGroup(
        model: model,
        domain: domain ?? [],
        fields: fields,
        groupby: groupBy,
        offset: offset ?? 0,
        limit: limit,
        orderby: orderBy,
        lazy: lazy ?? true,
      );

      _logger.d('readGroup returned ${result.groups?.length ?? 0} groups');
      return result.groups ?? [];
    } catch (e, stackTrace) {
      _logger.e('readGroup failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Ensure client is authenticated
  void _ensureAuthenticated() {
    // Check local flag - SDK handles token management internally
    if (!_isAuthenticated) {
      throw StateError(
        'Client is not authenticated. Call authenticate() first.',
      );
    }
  }

  /// Update base URL
  void setBaseUrl(String url) {
    // _bridgeCore.setBaseUrl(url);
    final url = EnvConfig.odooUrl;
    _logger.d('Base URL updated to: $url');
  }
}
