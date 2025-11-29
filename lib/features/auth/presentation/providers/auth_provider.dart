import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logger/logger.dart';

import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/storage/prefs_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user.dart';

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthState>>((ref) {
  return AuthStateNotifier(ref);
});

/// BridgeCore client provider
final bridgecoreClientProvider =
    StateProvider<BridgecoreClient?>((ref) => null);

/// Auth state notifier
class AuthStateNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final Ref _ref;
  final Logger _logger = Logger();
  final PrefsService _prefs = PrefsService();
  final SecureStorageService _secureStorage = SecureStorageService();

  AuthStateNotifier(this._ref) : super(const AsyncValue.data(AuthState())) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    try {
      final userId = _prefs.getInt(StorageKeys.userId);
      final sessionId = await _secureStorage.read(StorageKeys.sessionId);

      if (userId != null && sessionId != null) {
        final userName = _prefs.getString(StorageKeys.userDisplayName) ?? '';
        final roleStr = _prefs.getString(StorageKeys.userRole);
        final role = UserRole.tryFromString(roleStr) ?? UserRole.passenger;
        _logger.d(
            'Restored user role from storage: ${role.value} for user: $userName');
        final user = User(id: userId, name: userName, role: role);
        state = AsyncValue.data(AuthState.authenticated(user));
      } else {
        state = const AsyncValue.data(AuthState());
      }
    } catch (e) {
      _logger.e('Error checking auth status', error: e);
      state = const AsyncValue.data(AuthState());
    }
  }

  /// Login with credentials
  Future<bool> login({
    required String serverUrl,
    // required String database,
    required String username,
    required String password,
    required String modelName,
    required List<String> listFields,
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Clear old session data before login to prevent role persistence issues
      await _clearSession();

      final client = BridgecoreClient(serverUrl);
      final result = await client.authenticate(
        // database: database,
        username: username,
        password: password,
        odooFieldsCheck: {"model": modelName, "list_fields": listFields},
      );

      final user = User.fromOdoo(result);
      _logger
          .i('User role detected: ${user.role.value} for user: ${user.name}');

      // Save to storage
      await _saveSession(
        serverUrl: serverUrl,
        // database: database,
        user: user,
        sessionId: result['session_id'] as String?,
        rememberMe: rememberMe,
      );

      // Update client provider
      _ref.read(bridgecoreClientProvider.notifier).state = client;

      state = AsyncValue.data(AuthState.authenticated(user));
      _logger.i(
          'Login successful for user: ${user.name} with role: ${user.role.value}');

      return true;
    } catch (e, stackTrace) {
      _logger.e('Login failed', error: e, stackTrace: stackTrace);
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// Save session to storage
  Future<void> _saveSession({
    required String serverUrl,
    // required String database,
    required User user,
    String? sessionId,
    required bool rememberMe,
  }) async {
    await _prefs.setString(StorageKeys.serverUrl, serverUrl);
    // await _prefs.setString(StorageKeys.database, database);
    await _prefs.setInt(StorageKeys.userId, user.id);
    await _prefs.setString(StorageKeys.userDisplayName, user.name);
    await _prefs.setString(StorageKeys.userRole, user.role.value);
    await _prefs.setBool(StorageKeys.rememberMe, rememberMe);
    _logger.d('Saved user role to storage: ${user.role.value}');

    if (user.companyId != null) {
      await _prefs.setInt(StorageKeys.companyId, user.companyId!);
    }
    if (user.companyName != null) {
      await _prefs.setString(StorageKeys.companyName, user.companyName!);
    }

    if (sessionId != null) {
      await _secureStorage.write(StorageKeys.sessionId, sessionId);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Clear client
      final client = _ref.read(bridgecoreClientProvider);
      await client?.logout();
      _ref.read(bridgecoreClientProvider.notifier).state = null;

      // Clear storage
      await _clearSession();

      state = const AsyncValue.data(AuthState());
      _logger.i('Logout successful');
    } catch (e, stackTrace) {
      _logger.e('Logout error', error: e, stackTrace: stackTrace);
      // Still clear session on error
      await _clearSession();
      state = const AsyncValue.data(AuthState());
    }
  }

  /// Clear session from storage
  Future<void> _clearSession() async {
    _logger.d('Clearing session data including role');
    await _secureStorage.delete(StorageKeys.sessionId);
    await _secureStorage.delete(StorageKeys.accessToken);
    await _prefs.remove(StorageKeys.userId);
    await _prefs.remove(StorageKeys.userDisplayName);
    await _prefs.remove(StorageKeys.userRole);
    await _prefs.remove(StorageKeys.companyId);
    await _prefs.remove(StorageKeys.companyName);
    // await _prefs.remove(StorageKeys.userBox);
    _logger.d('Session data cleared successfully');
  }

  /// Get current user
  User? get currentUser => state.asData?.value.user;

  /// Check if authenticated
  bool get isAuthenticated => state.asData?.value.isAuthenticated ?? false;
}
