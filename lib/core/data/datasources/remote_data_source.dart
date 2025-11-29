import 'package:bridgecore_flutter/bridgecore_flutter.dart'
    hide ServerException;
import 'package:bridgecore_flutter_starter/core/error/failures.dart';

/// Base remote data source
abstract class RemoteDataSource {
  OdooService get client;

  /// Execute a remote call with error handling
  Future<T> execute<T>(
    Future<T> Function() call, {
    String? errorMessage,
  }) async {
    try {
      return await call();
    } on BridgeCoreException catch (e) {
      throw ServerException(errorMessage ?? e.message);
    } catch (e) {
      throw ServerException(errorMessage ?? e.toString());
    }
  }
}

/// Auth remote data source
class AuthRemoteDataSource extends RemoteDataSource {
  @override
  OdooService get client => BridgeCore.instance.odoo;

  Future<TenantSession> login({
    required String email,
    required String password,
  }) async {
    return execute(
      () => BridgeCore.instance.auth.login(
        email: email,
        password: password,
        odooFieldsCheck: OdooFieldsCheck(
          model: 'res.users',
          listFields: ['shuttle_role'],
        ),
      ),
      errorMessage: 'Failed to login',
    );
  }

  Future<TenantMeResponse> getCurrentUser() async {
    return execute(
      () => BridgeCore.instance.auth.me(forceRefresh: true),
      errorMessage: 'Failed to get current user',
    );
  }

  Future<void> logout() async {
    return execute(
      () => BridgeCore.instance.auth.logout(),
      errorMessage: 'Failed to logout',
    );
  }

  Future<String> refreshToken() async {
    return execute(
      () => BridgeCore.instance.auth.refreshToken(),
      errorMessage: 'Failed to refresh token',
    );
  }
}

/// Odoo remote data source
class OdooRemoteDataSource extends RemoteDataSource {
  @override
  OdooService get client => BridgeCore.instance.odoo;

  Future<List<Map<String, dynamic>>> searchRead({
    required String model,
    List<dynamic>? domain,
    List<String>? fields,
    int? limit,
    int? offset,
    String? order,
  }) async {
    return execute(
      () => client.searchRead(
        model: model,
        domain: domain ?? [],
        fields: fields ?? <String>[],
        limit: limit ?? 80,
        offset: offset ?? 0,
        order: order,
      ),
      errorMessage: 'Failed to search and read records',
    );
  }

  Future<List<int>> search({
    required String model,
    List<dynamic>? domain,
    int? limit,
    int? offset,
    String? order,
  }) async {
    return execute(
      () => client.search(
        model: model,
        domain: domain ?? [],
        limit: limit,
        offset: offset ?? 0,
        order: order,
      ),
      errorMessage: 'Failed to search records',
    );
  }

  Future<List<Map<String, dynamic>>> read({
    required String model,
    required List<int> ids,
    List<String>? fields,
  }) async {
    return execute(
      () => client.read(
        model: model,
        ids: ids,
        fields: fields ?? <String>[],
      ),
      errorMessage: 'Failed to read records',
    );
  }

  Future<int> create({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    return execute(
      () => client.create(
        model: model,
        values: values,
      ),
      errorMessage: 'Failed to create record',
    );
  }

  Future<bool> update({
    required String model,
    required List<int> ids,
    required Map<String, dynamic> values,
  }) async {
    return execute(
      () => client.update(
        model: model,
        ids: ids,
        values: values,
      ),
      errorMessage: 'Failed to update records',
    );
  }

  Future<bool> delete({
    required String model,
    required List<int> ids,
  }) async {
    return execute(
      () => client.delete(
        model: model,
        ids: ids,
      ),
      errorMessage: 'Failed to delete records',
    );
  }

  Future<int> searchCount({
    required String model,
    List<dynamic>? domain,
  }) async {
    return execute(
      () => client.searchCount(
        model: model,
        domain: domain ?? [],
      ),
      errorMessage: 'Failed to count records',
    );
  }

  /// Call custom method with BridgeCore v2.1.0
  Future<dynamic> callKw({
    required String model,
    required String method,
    List<dynamic>? args,
    Map<String, dynamic>? kwargs,
    Map<String, dynamic>? context,
  }) async {
    final response = await execute(
      () => client.custom.callKw(
        model: model,
        method: method,
        args: args ?? [],
        kwargs: kwargs ?? {},
        context: context,
      ),
      errorMessage: 'Failed to call method $method on $model',
    );

    if (response.success) {
      return response.result;
    }
    throw ServerException(response.error ?? 'Unknown callKw error');
  }

  /// Execute action methods (BridgeCore v2.1.0)
  Future<dynamic> executeAction({
    required String model,
    required List<int> ids,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    final method = action.toLowerCase();
    return callKw(
      model: model,
      method: method,
      args: [ids],
      context: context,
    );
  }
}
