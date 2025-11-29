import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/network_info.dart';
import '../core/storage/hive_service.dart';
import '../core/storage/prefs_service.dart';
import '../core/storage/secure_storage_service.dart';

// Note: bridgecoreClientProvider is defined in auth_provider.dart
// It's a StateProvider that gets set after successful login

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
