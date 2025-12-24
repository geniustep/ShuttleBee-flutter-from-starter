import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/local_storage_repository.dart';
import '../data/mobile_local_storage_impl.dart';
import '../data/windows_local_storage_impl.dart';

// ════════════════════════════════════════════════════════════
// Platform Detection
// ════════════════════════════════════════════════════════════

/// Current platform type
enum PlatformType {
  mobile,
  windows,
  web,
  unknown,
}

/// Provider for current platform
final platformTypeProvider = Provider<PlatformType>((ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    return PlatformType.mobile;
  } else if (Platform.isWindows) {
    return PlatformType.windows;
  } else {
    return PlatformType.unknown;
  }
});

// ════════════════════════════════════════════════════════════
// Local Storage Repository Provider
// ════════════════════════════════════════════════════════════

/// Platform-specific local storage repository
///
/// Automatically selects the appropriate implementation based on platform:
/// - Mobile (Android/iOS): MobileLocalStorageImpl
/// - Windows: WindowsLocalStorageImpl
final localStorageRepositoryProvider = Provider<LocalStorageRepository>((ref) {
  final platform = ref.watch(platformTypeProvider);

  switch (platform) {
    case PlatformType.mobile:
      return MobileLocalStorageImpl();

    case PlatformType.windows:
      return WindowsLocalStorageImpl();

    default:
      throw UnsupportedError(
        'Local storage not supported on platform: $platform',
      );
  }
});

// ════════════════════════════════════════════════════════════
// Storage Initialization State
// ════════════════════════════════════════════════════════════

/// Storage initialization status provider
///
/// Automatically initializes storage on first access.
final storageInitializationProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(localStorageRepositoryProvider);

  final result = await repository.initialize();

  return result.fold(
    (failure) {
      throw Exception('Failed to initialize storage: ${failure.message}');
    },
    (success) => success,
  );
});

// ════════════════════════════════════════════════════════════
// Storage Statistics
// ════════════════════════════════════════════════════════════

/// Storage statistics provider
final storageStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Ensure storage is initialized
  await ref.watch(storageInitializationProvider.future);

  final repository = ref.watch(localStorageRepositoryProvider);
  final result = await repository.getStats();

  return result.fold(
    (failure) => throw Exception('Failed to get stats: ${failure.message}'),
    (stats) => stats,
  );
});

/// Platform information provider
final platformInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Ensure storage is initialized
  await ref.watch(storageInitializationProvider.future);

  final repository = ref.watch(localStorageRepositoryProvider);
  final result = await repository.getPlatformInfo();

  return result.fold(
    (failure) => throw Exception('Failed to get platform info: ${failure.message}'),
    (info) => info,
  );
});

// ════════════════════════════════════════════════════════════
// Storage Health Check
// ════════════════════════════════════════════════════════════

/// Storage health check provider
final storageHealthProvider = FutureProvider<bool>((ref) async {
  try {
    // Ensure storage is initialized
    await ref.watch(storageInitializationProvider.future);

    final repository = ref.watch(localStorageRepositoryProvider);
    final result = await repository.healthCheck();

    return result.fold(
      (failure) => false,
      (isHealthy) => isHealthy,
    );
  } catch (e) {
    return false;
  }
});

// ════════════════════════════════════════════════════════════
// Automatic Cleanup Provider
// ════════════════════════════════════════════════════════════

/// Automatically clear expired entries on app startup
final autoCleanupProvider = FutureProvider<int>((ref) async {
  // Ensure storage is initialized
  await ref.watch(storageInitializationProvider.future);

  final repository = ref.watch(localStorageRepositoryProvider);
  final result = await repository.clearExpired();

  return result.fold(
    (failure) {
      // Log but don't throw - cleanup is best-effort
      return 0;
    },
    (count) => count,
  );
});
