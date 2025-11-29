import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bridgecore_integration/client/bridgecore_client.dart';
import '../core/config/env_config.dart';
import '../core/network/network_info.dart';
import '../core/storage/hive_service.dart';
import '../core/storage/prefs_service.dart';
import '../core/storage/secure_storage_service.dart';

/// BridgeCore Client Provider
final bridgecoreClientProvider = Provider<BridgecoreClient>((ref) {
  return BridgecoreClient(EnvConfig.odooUrl);
});

/// Network Info Provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo();
});

/// Hive Service Provider
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

/// Preferences Service Provider
final prefsServiceProvider = Provider<PrefsService>((ref) {
  return PrefsService();
});

/// Secure Storage Service Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
