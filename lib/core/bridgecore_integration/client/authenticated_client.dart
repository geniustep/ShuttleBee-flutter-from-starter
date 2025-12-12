import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env_config.dart';
import '../../storage/prefs_service.dart';
import '../../storage/secure_storage_service.dart';
import '../../constants/storage_keys.dart';
import 'bridgecore_client.dart';

/// Provider for authenticated BridgeCore client
final authenticatedClientProvider = Provider<AuthenticatedClient>((ref) {
  return AuthenticatedClient();
});

/// Authenticated BridgeCore client with session management
class AuthenticatedClient {
  BridgecoreClient? _client;
  final PrefsService _prefs = PrefsService();
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Get the BridgeCore client
  BridgecoreClient get client {
    if (_client == null) {
      throw StateError('Client not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Check if client is initialized and authenticated
  bool get isReady => _client?.isAuthenticated ?? false;

  /// Initialize client with stored session if available
  Future<bool> initialize() async {
    final url = EnvConfig.odooUrl;

    _client = BridgecoreClient(url);

    // Try to restore session
    return await _tryRestoreSession();
  }

  /// Try to restore session from storage
  Future<bool> _tryRestoreSession() async {
    try {
      final sessionId = await _secureStorage.read(StorageKeys.sessionId);
      final database = _prefs.getString(StorageKeys.database);
      final userId = _prefs.getInt(StorageKeys.userId);

      if (sessionId != null && database != null && userId != null) {
        // Session exists, validate it
        // Note: You may need to implement session validation
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate with credentials
  Future<Map<String, dynamic>> authenticate({
    required String serverUrl,
    required String database,
    required String username,
    required String password,
    required String modelName,
    required List<String> listFields,
    bool rememberMe = false,
  }) async {
    _client = BridgecoreClient(serverUrl);

    final result = await _client!.authenticate(
      // database: database,
      modelName: modelName,
      listFields: listFields,
      username: username,
      password: password,
    );

    // Save session data
    await _saveSession(
      serverUrl: serverUrl,
      database: database,
      username: username,
      userId: result['uid'] as int,
      sessionId: result['session_id'] as String?,
      rememberMe: rememberMe,
    );

    return result;
  }

  /// Save session to storage
  Future<void> _saveSession({
    required String serverUrl,
    required String database,
    required String username,
    required int userId,
    String? sessionId,
    required bool rememberMe,
  }) async {
    await _prefs.setString(StorageKeys.serverUrl, serverUrl);
    await _prefs.setString(StorageKeys.database, database);
    await _prefs.setString(StorageKeys.username, username);
    await _prefs.setInt(StorageKeys.userId, userId);
    await _prefs.setBool(StorageKeys.rememberMe, rememberMe);

    if (sessionId != null) {
      await _secureStorage.write(StorageKeys.sessionId, sessionId);
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    try {
      await _client?.logout();
    } finally {
      await _clearSession();
      _client = null;
    }
  }

  /// Clear stored session
  Future<void> _clearSession() async {
    await _secureStorage.delete(StorageKeys.sessionId);
    await _secureStorage.delete(StorageKeys.accessToken);
    await _prefs.remove(StorageKeys.userId);
    await _prefs.remove(StorageKeys.username);
    await _prefs.remove(StorageKeys.userDisplayName);
    await _prefs.remove(StorageKeys.companyId);
    await _prefs.remove(StorageKeys.companyName);
  }

  /// Update server URL
  void setServerUrl(String url) {
    _client?.setBaseUrl(url);
    _prefs.setString(StorageKeys.serverUrl, url);
  }
}
