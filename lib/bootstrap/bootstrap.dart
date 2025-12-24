import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import 'package:bridgecore_flutter/bridgecore_flutter.dart';

import '../app.dart';
import '../core/config/env_config.dart';
import '../core/storage/prefs_service.dart';
import '../core/storage/secure_storage_service.dart';

/// Bootstrap the application
Future<void> bootstrap() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // ====================================
  // 🎯 Logger Configuration
  // ====================================
  // Uncomment one of these lines to filter logs:

  // LoggerConfig.development();     // Show all logs (default)
  // LoggerConfig.minimal();         // Show only important logs
  // LoggerConfig.networkOnly();     // Show only network logs
  // LoggerConfig.authOnly();        // Show only auth logs
  // LoggerConfig.trackingOnly();    // Show only tracking logs
  // LoggerConfig.syncOnly();        // Show only sync logs
  // LoggerConfig.errorsOnly();      // Show only errors
  // LoggerConfig.production();      // Production preset

  // Print current logger configuration
  // LoggerConfig.printConfig();
  // ====================================
  // إخفاء الأزرار + الشاشة كاملة بوضع Immersive Sticky
  // SystemChrome.setEnabledSystemUIMode(
  //   SystemUiMode.immersiveSticky,
  // );
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Non-fatal: the app has safe defaults in EnvConfig.
    // This also helps in dev setups where `.env` isn't present as an asset yet.
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Create logger instance with proper configuration
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // لا تظهر stack frames للرسائل العادية
      errorMethodCount: 5, // عدد محدود من stack frames للأخطاء
      lineLength: 80,
      colors: true,
      printEmojis: false,
      excludeBox: {
        Level.debug: true,
        Level.info: true,
      },
    ),
  );

  // Initialize Secure Storage
  logger.d('🔐 Initializing SecureStorage...');
  await SecureStorageService.init();
  logger.d('✅ SecureStorage initialized successfully');

  // Initialize Prefs Service
  logger.d('💾 Initializing PrefsService...');
  await PrefsService.init();
  logger.d('✅ PrefsService initialized successfully');

  // Initialize BridgeCore
  logger.d('🌉 Initializing BridgeCore...');
  BridgeCore.initialize(
    baseUrl: EnvConfig.odooUrl,
    debugMode: EnvConfig.debugMode,
    enableLogging: EnvConfig.debugMode,
  );
  logger.d('✅ BridgeCore initialized successfully');

  // Initialize Local Storage (platform-specific)
  // Note: Full initialization happens via storageInitializationProvider
  // This is just a placeholder - actual init happens in ProviderScope
  logger.d('💾 Local Storage will be initialized via Riverpod providers');

  // Setup global error handling
  FlutterError.onError = (details) {
    logger.e(
      'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Run the app with Riverpod
  runApp(const ProviderScope(child: App()));
}
