import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/secure_storage_service.dart';

/// Auth helper to obtain an Odoo `session_id` for ShuttleBee REST endpoints.
///
/// When ShuttleBee REST base URL differs from the main BridgeCore/JSON-RPC server,
/// we must authenticate separately against that Odoo instance to get a valid
/// `session_id`.
class ShuttleBeeRestAuthService {
  final Logger _logger = Logger();
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Authenticate against `/web/session/authenticate` and store session cookie.
  ///
  /// Returns the stored `session_id` on success, or null on failure.
  Future<String?> ensureSession({
    required String login,
    required String password,
    String? baseUrl,
    String? database,
  }) async {
    final url = (baseUrl ?? EnvConfig.shuttleBeeApiBaseUrl).trim();
    final db = (database ?? EnvConfig.shuttleBeeApiDb).trim();

    if (url.isEmpty) return null;
    if (db.isEmpty) {
      _logger.w(
        'ShuttleBee REST DB is not set. Set SHUTTLEBEE_API_DATABASE (or ODOO_DATABASE).',
      );
      return null;
    }

    // If already present, keep it (best-effort). We still try to refresh it if needed.
    final existing = await _secureStorage.read(StorageKeys.shuttleBeeSessionId);
    if (existing != null && existing.isNotEmpty) return existing;

    final dio = Dio(
      BaseOptions(
        baseUrl: url,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    try {
      final res = await dio.post(
        '/web/session/authenticate',
        data: {
          'jsonrpc': '2.0',
          'params': {
            'db': db,
            'login': login,
            'password': password,
          },
        },
        options: Options(validateStatus: (_) => true),
      );

      // Extract session_id from Set-Cookie.
      final setCookies = res.headers.map['set-cookie'] ?? const <String>[];
      String? sessionId;
      for (final c in setCookies) {
        final idx = c.indexOf('session_id=');
        if (idx == -1) continue;
        final start = idx + 'session_id='.length;
        final end = c.indexOf(';', start);
        sessionId = (end == -1) ? c.substring(start) : c.substring(start, end);
        if (sessionId.isNotEmpty) break;
      }

      if (sessionId == null || sessionId.isEmpty) {
        _logger.w(
          'ShuttleBee REST auth did not return session_id (status=${res.statusCode}).',
        );
        return null;
      }

      await _secureStorage.write(StorageKeys.shuttleBeeSessionId, sessionId);
      return sessionId;
    } catch (e) {
      _logger.w('Failed to authenticate ShuttleBee REST session: $e');
      return null;
    }
  }
}
