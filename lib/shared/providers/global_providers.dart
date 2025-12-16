import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/prefs_service.dart';
import '../../core/bridgecore_integration/services/services.dart';

/// Theme mode provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Theme mode notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final PrefsService _prefs = PrefsService();

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final savedMode = _prefs.getString(StorageKeys.themeMode);
    state = _stringToThemeMode(savedMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(StorageKeys.themeMode, _themeModeToString(mode));
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  ThemeMode _stringToThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// Locale provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Locale notifier
class LocaleNotifier extends StateNotifier<Locale> {
  final PrefsService _prefs = PrefsService();

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
  ];

  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  void _loadLocale() {
    final savedLocale = _prefs.getString(StorageKeys.languageCode);
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(StorageKeys.languageCode, locale.languageCode);
  }

  /// Toggle between supported locales (en -> ar -> fr -> en)
  Future<void> toggleLocale() async {
    final currentIndex = supportedLocales.indexWhere(
      (l) => l.languageCode == state.languageCode,
    );
    final nextIndex = (currentIndex + 1) % supportedLocales.length;
    await setLocale(supportedLocales[nextIndex]);
  }

  /// Get language name for display
  String get currentLanguageName {
    switch (state.languageCode) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  /// Check if current locale is RTL
  bool get isRtl => state.languageCode == 'ar';
}

/// Network connectivity provider
final connectivityProvider = StreamProvider<bool>((ref) {
  final networkInfo = NetworkInfo();
  networkInfo.startListening();
  ref.onDispose(() => networkInfo.dispose());
  return networkInfo.onConnectionChanged;
});

/// Is online provider (Future-based, for initial check)
final isOnlineProvider = FutureProvider<bool>((ref) async {
  final networkInfo = NetworkInfo();
  return await networkInfo.isConnected;
});

/// Is online state provider (State-based, for reactive updates)
///
/// هذا الـ Provider يُستخدم للتحديث المباشر لحالة الشبكة
/// يُحدّث من auth_provider عند تغير حالة الاتصال
final isOnlineStateProvider = StateProvider<bool>((ref) => true);

/// Loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Error message provider
final errorMessageProvider = StateProvider<String?>((ref) => null);

// ════════════════════════════════════════════════════════════
// BridgeCore Integration Providers
// ════════════════════════════════════════════════════════════

/// BridgeCore Sync Service provider
final bridgeCoreSyncProvider = Provider<BridgeCoreSyncService>((ref) {
  return BridgeCoreSyncService();
});

/// BridgeCore Trigger Service provider
final bridgeCoreTriggersProvider = Provider<BridgeCoreTriggerService>((ref) {
  return BridgeCoreTriggerService();
});

/// BridgeCore Notification Service provider
final bridgeCoreNotificationsProvider =
    Provider<BridgeCoreNotificationService>((ref) {
  return BridgeCoreNotificationService();
});

/// Event Bus Bridge provider
final eventBusBridgeProvider = Provider<EventBusBridge>((ref) {
  return EventBusBridge();
});

/// Sync status provider
final syncStatusProvider = StreamProvider<bool>((ref) async* {
  final syncService = ref.watch(bridgeCoreSyncProvider);
  while (true) {
    await Future.delayed(const Duration(seconds: 2));
    yield syncService.isSyncing;
  }
});

/// Has updates provider - checks for available updates
final hasUpdatesProvider = FutureProvider<bool>((ref) async {
  final syncService = ref.watch(bridgeCoreSyncProvider);
  if (!syncService.isInitialized) return false;
  return await syncService.hasUpdates();
});

/// Unread notifications count provider
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final notificationService = ref.watch(bridgeCoreNotificationsProvider);
  if (!notificationService.isInitialized) return 0;

  final stats = await notificationService.getStats();
  return stats.unreadCount;
});

/// BridgeCore services initialization status provider
final bridgeCoreServicesStatusProvider = Provider<Map<String, bool>>((ref) {
  return BridgeCoreServices.getServicesStatus();
});

/// Smart sync state provider
final smartSyncStateProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final syncService = ref.watch(bridgeCoreSyncProvider);
  if (!syncService.isInitialized) return null;

  try {
    return await syncService.getSmartSyncState();
  } catch (e) {
    return null;
  }
});

/// Sync health status provider
final syncHealthProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final syncService = ref.watch(bridgeCoreSyncProvider);
  if (!syncService.isInitialized) return null;

  try {
    return await syncService.checkHealth();
  } catch (e) {
    return null;
  }
});
