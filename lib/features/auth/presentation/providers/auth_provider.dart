import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logger/logger.dart';

import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/prefs_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../domain/entities/user.dart';

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthState>>((ref) {
  return AuthStateNotifier(ref);
});

/// BridgeCore client provider
final bridgecoreClientProvider =
    StateProvider<BridgecoreClient?>((ref) => null);

/// Network info instance provider
final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfo());

/// Auth state notifier with smart token management
class AuthStateNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final Ref _ref;
  final Logger _logger = Logger();
  final PrefsService _prefs = PrefsService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final NetworkInfo _networkInfo = NetworkInfo();

  AuthStateNotifier(this._ref) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated with smart token handling
  Future<void> _checkAuthStatus() async {
    try {
      print('🔍 [_checkAuthStatus] Starting smart auth check...');
      
      // Check network connectivity
      final isOnline = await _networkInfo.isConnected;
      _ref.read(isOnlineProvider.notifier).state = isOnline;
      print('🌐 [_checkAuthStatus] Network status: ${isOnline ? "online" : "offline"}');

      // Get BridgeCore token state
      final bridgeCoreAuthState = await BridgeCore.instance.auth.authState;
      print('🔐 [_checkAuthStatus] BridgeCore auth state: $bridgeCoreAuthState');

      // Map BridgeCore TokenAuthState to our TokenState
      final tokenState = _mapBridgeCoreAuthState(bridgeCoreAuthState);
      
      // Get stored user data
      final userId = _prefs.getInt(StorageKeys.userId);
      final sessionId = await _secureStorage.read(StorageKeys.sessionId);
      final serverUrl = _prefs.getString(StorageKeys.serverUrl);

      print('🔍 [_checkAuthStatus] userId: $userId, sessionId: ${sessionId != null ? "exists" : "null"}, serverUrl: $serverUrl');

      // Validate that token is a proper tenant token
      if (tokenState == TokenState.valid || tokenState == TokenState.needsRefresh) {
        final isValidTenantToken = await BridgeCore.instance.auth.hasValidTenantToken();
        if (!isValidTenantToken) {
          print('⚠️ [_checkAuthStatus] Token is NOT a valid tenant token!');
          final tokenInfo = await BridgeCore.instance.auth.getDetailedTokenInfo();
          print('📋 [_checkAuthStatus] Token details: $tokenInfo');
          print('🔄 [_checkAuthStatus] Clearing invalid token and requiring re-login...');
          await _clearSession();
          await BridgeCore.instance.auth.logout();
          state = AsyncValue.data(AuthState.invalidToken());
          return;
        }
        print('✅ [_checkAuthStatus] Token is a valid tenant token');
      }

      // Handle based on token state
      switch (tokenState) {
        case TokenState.valid:
          // Fully authenticated with valid token
          await _restoreAuthenticatedSession(
            userId: userId,
            sessionId: sessionId,
            serverUrl: serverUrl,
            tokenState: TokenState.valid,
          );
          break;

        case TokenState.needsRefresh:
          if (isOnline) {
            // Online - try to refresh token
            print('🔄 [_checkAuthStatus] Token needs refresh, attempting...');
            try {
              await BridgeCore.instance.auth.refreshToken();
              await _restoreAuthenticatedSession(
                userId: userId,
                sessionId: sessionId,
                serverUrl: serverUrl,
                tokenState: TokenState.valid,
              );
            } catch (e) {
              print('❌ [_checkAuthStatus] Refresh failed: $e');
              // Refresh failed - check if we can work offline
              if (userId != null) {
                await _restoreAuthenticatedSession(
                  userId: userId,
                  sessionId: sessionId,
                  serverUrl: serverUrl,
                  tokenState: TokenState.needsRefresh,
                  isOffline: true,
                );
              } else {
                state = AsyncValue.data(AuthState.sessionExpired());
              }
            }
          } else {
            // Offline - allow access with expired token if we have user data
            if (userId != null) {
              print('📴 [_checkAuthStatus] Offline mode with stored user data');
              await _restoreAuthenticatedSession(
                userId: userId,
                sessionId: sessionId,
                serverUrl: serverUrl,
                tokenState: TokenState.needsRefresh,
                isOffline: true,
              );
            } else {
              state = const AsyncValue.data(AuthState());
            }
          }
          break;

        case TokenState.expired:
          // All tokens expired - must login again
          print('⏰ [_checkAuthStatus] Session expired');
          await _clearSession();
          state = AsyncValue.data(AuthState.sessionExpired());
          break;

        case TokenState.none:
          // No tokens - check legacy session
          if (userId != null && sessionId != null && serverUrl != null) {
            print('📦 [_checkAuthStatus] Found legacy session, migrating...');
            await _restoreAuthenticatedSession(
              userId: userId,
              sessionId: sessionId,
              serverUrl: serverUrl,
              tokenState: TokenState.valid,
            );
          } else {
            print('⚠️ [_checkAuthStatus] No session found');
            state = const AsyncValue.data(AuthState());
          }
          break;
      }
    } catch (e, stackTrace) {
      print('❌ [_checkAuthStatus] Error: $e');
      _logger.e('Error checking auth status', error: e, stackTrace: stackTrace);
      state = const AsyncValue.data(AuthState());
    }
  }

  /// Map BridgeCore TokenAuthState to our TokenState
  TokenState _mapBridgeCoreAuthState(TokenAuthState bridgeCoreState) {
    switch (bridgeCoreState) {
      case TokenAuthState.authenticated:
        return TokenState.valid;
      case TokenAuthState.needsRefresh:
        return TokenState.needsRefresh;
      case TokenAuthState.sessionExpired:
        return TokenState.expired;
      case TokenAuthState.unauthenticated:
        return TokenState.none;
    }
  }

  /// Restore authenticated session
  Future<void> _restoreAuthenticatedSession({
    required int? userId,
    required String? sessionId,
    required String? serverUrl,
    required TokenState tokenState,
    bool isOffline = false,
  }) async {
    if (userId == null || serverUrl == null) {
      state = const AsyncValue.data(AuthState());
      return;
    }

    final userName = _prefs.getString(StorageKeys.userDisplayName) ?? '';
    final roleStr = _prefs.getString(StorageKeys.userRole);
    final role = UserRole.tryFromString(roleStr) ?? UserRole.passenger;
    final partnerId = _prefs.getInt(StorageKeys.partnerId);
    final companyId = _prefs.getInt(StorageKeys.companyId);
    final companyName = _prefs.getString(StorageKeys.companyName);

    print('🔍 [_restoreSession] userName: $userName, role: ${role.value}, tokenState: $tokenState');
    _logger.d('Restoring session for user: $userName, role: ${role.value}, partnerId: $partnerId');

    // Create BridgecoreClient and restore session
    if (sessionId != null) {
      final client = BridgecoreClient(serverUrl);
      client.restoreSession(sessionId: sessionId, userId: userId);
      _ref.read(bridgecoreClientProvider.notifier).state = client;
      print('✅ [_restoreSession] BridgecoreClient created and set in provider');
    }

    final user = User(
      id: userId,
      name: userName,
      role: role,
      partnerId: partnerId,
      companyId: companyId,
      companyName: companyName,
    );

    if (isOffline) {
      state = AsyncValue.data(AuthState.needsRefresh(user, isOffline: true));
    } else {
      state = AsyncValue.data(AuthState.authenticated(user, tokenState: tokenState));
    }
    
    print('✅ [_restoreSession] Auth state set (tokenState: $tokenState, offline: $isOffline)');
  }

  /// Login with credentials
  Future<bool> login({
    required String serverUrl,
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
        username: username,
        password: password,
        odooFieldsCheck: {"model": modelName, "list_fields": listFields},
      );

      // Get complete user info including partnerId
      print('🔍 [login] Getting current user info for partnerId...');
      final meResponse = await client.getCurrentUser(
        modelName: modelName,
        listFields: listFields,
      );

      // Merge partnerId from /me endpoint into the result
      final partnerId = meResponse['partner_id'] as int?;
      print('🔍 [login] partnerId from /me: $partnerId');

      final mergedResult = {
        ...result,
        'partner_id': partnerId,
      };

      final user = User.fromOdoo(mergedResult);
      _logger.i('User role detected: ${user.role.value} for user: ${user.name}, partnerId: ${user.partnerId}');

      // Save to storage
      await _saveSession(
        serverUrl: serverUrl,
        user: user,
        sessionId: result['session_id'] as String?,
        rememberMe: rememberMe,
      );

      // Update client provider
      _ref.read(bridgecoreClientProvider.notifier).state = client;

      state = AsyncValue.data(AuthState.authenticated(user, tokenState: TokenState.valid));
      _logger.i('Login successful for user: ${user.name} with role: ${user.role.value}');

      return true;
    } catch (e, stackTrace) {
      _logger.e('Login failed', error: e, stackTrace: stackTrace);
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// Refresh token manually
  Future<bool> refreshToken() async {
    try {
      print('🔄 [refreshToken] Attempting manual token refresh...');
      await BridgeCore.instance.auth.refreshToken();
      
      // Update state to valid
      final currentState = state.asData?.value;
      if (currentState?.user != null) {
        state = AsyncValue.data(
          AuthState.authenticated(currentState!.user!, tokenState: TokenState.valid),
        );
      }
      
      print('✅ [refreshToken] Token refreshed successfully');
      return true;
    } catch (e) {
      print('❌ [refreshToken] Refresh failed: $e');
      _logger.e('Token refresh failed', error: e);
      return false;
    }
  }

  /// Update network status and handle token refresh if needed
  Future<void> updateNetworkStatus(bool isOnline) async {
    _ref.read(isOnlineProvider.notifier).state = isOnline;
    
    final currentState = state.asData?.value;
    if (currentState == null) return;

    if (isOnline && currentState.needsTokenRefresh) {
      // Back online and token needs refresh
      print('🌐 [updateNetworkStatus] Back online, attempting token refresh...');
      final refreshed = await refreshToken();
      
      if (!refreshed && currentState.user != null) {
        // Refresh failed but we have user data - stay in needsRefresh state
        state = AsyncValue.data(
          currentState.copyWith(isOffline: false),
        );
      }
    } else if (!isOnline && currentState.isAuthenticated) {
      // Gone offline
      state = AsyncValue.data(
        currentState.copyWith(isOffline: true),
      );
    }
  }

  /// Save session to storage
  Future<void> _saveSession({
    required String serverUrl,
    required User user,
    String? sessionId,
    required bool rememberMe,
  }) async {
    await _prefs.setString(StorageKeys.serverUrl, serverUrl);
    await _prefs.setInt(StorageKeys.userId, user.id);
    await _prefs.setString(StorageKeys.userDisplayName, user.name);
    await _prefs.setString(StorageKeys.userRole, user.role.value);
    await _prefs.setBool(StorageKeys.rememberMe, rememberMe);
    _logger.d('Saved user role to storage: ${user.role.value}');

    if (user.partnerId != null) {
      await _prefs.setInt(StorageKeys.partnerId, user.partnerId!);
      _logger.d('Saved partnerId to storage: ${user.partnerId}');
    }
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
      // Clear BridgeCore tokens
      await BridgeCore.instance.auth.logout();
      
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
    await _prefs.remove(StorageKeys.partnerId);
    await _prefs.remove(StorageKeys.companyId);
    await _prefs.remove(StorageKeys.companyName);
    _logger.d('Session data cleared successfully');
  }

  /// Get current user
  User? get currentUser => state.asData?.value.user;

  /// Check if authenticated
  bool get isAuthenticated => state.asData?.value.isAuthenticated ?? false;

  /// Check if can work offline
  bool get canWorkOffline => state.asData?.value.canWorkOffline ?? false;

  /// Check if token needs refresh
  bool get needsTokenRefresh => state.asData?.value.needsTokenRefresh ?? false;
}
