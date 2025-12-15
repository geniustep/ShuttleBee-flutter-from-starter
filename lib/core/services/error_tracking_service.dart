import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// Error tracking service with Sentry and Firebase Crashlytics
class ErrorTrackingService {
  static final ErrorTrackingService _instance =
      ErrorTrackingService._internal();
  factory ErrorTrackingService() => _instance;
  ErrorTrackingService._internal();

  bool _initialized = false;

  /// Initialize error tracking
  Future<void> initialize({
    required String sentryDsn,
    required String environment,
  }) async {
    if (_initialized) {
      AppLogger.warning('Error tracking already initialized');
      return;
    }

    // Initialize Sentry
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = environment;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
        options.enableAutoPerformanceTracing = true;
        options.beforeSend = _beforeSend;
      },
    );

    // Initialize Firebase Crashlytics
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Set up Flutter error handling
    FlutterError.onError = (details) {
      AppLogger.error('Flutter Error: ${details.exceptionAsString()}');
      recordFlutterError(details);
    };

    // Set up async error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('Async Error: $error');
      recordError(error, stack);
      return true;
    };

    _initialized = true;
    AppLogger.info('Error tracking initialized');
  }

  /// Before send callback for Sentry
  FutureOr<SentryEvent?> _beforeSend(SentryEvent event, Hint hint) {
    // Customize filtering if needed (currently forwarding all events)
    return event;
  }

  /// Record Flutter error
  void recordFlutterError(FlutterErrorDetails details) {
    // Send to Sentry
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
    );

    // Send to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordFlutterError(details);
  }

  /// Record error
  void recordError(
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? extras,
    String? reason,
  }) {
    // Send to Sentry
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({
        if (extras != null) 'extras': extras,
        if (reason != null) 'reason': reason,
      }),
    );

    // Send to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      information:
          extras?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
    );

    AppLogger.error('Error recorded: $error', error, stackTrace);
  }

  /// Log message
  void log(String message, {SentryLevel level = SentryLevel.info}) {
    Sentry.captureMessage(message, level: level);
    FirebaseCrashlytics.instance.log(message);
  }

  /// Set user
  void setUser({
    required String id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  }) {
    // Set user in Sentry
    Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          id: id,
          email: email,
          username: username,
          data: extras,
        ),
      );
    });

    // Set user in Firebase Crashlytics
    FirebaseCrashlytics.instance.setUserIdentifier(id);
  }

  /// Clear user
  void clearUser() {
    Sentry.configureScope((scope) => scope.setUser(null));
    FirebaseCrashlytics.instance.setUserIdentifier('');
  }

  /// Set custom key
  void setCustomKey(String key, dynamic value) {
    Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });

    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Add breadcrumb
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
      ),
    );
  }
}

/// Performance monitoring service
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  final FirebasePerformance _performance = FirebasePerformance.instance;

  /// Start trace
  Future<Trace> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    AppLogger.debug('Trace started: $name');
    return trace;
  }

  /// Stop trace
  Future<void> stopTrace(Trace trace) async {
    await trace.stop();
    AppLogger.debug('Trace stopped');
  }

  /// Track operation
  Future<T> track<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    final trace = await startTrace(name);

    if (attributes != null) {
      attributes.forEach((key, value) {
        trace.setMetric(key, value as int);
      });
    }

    try {
      final result = await operation();
      await stopTrace(trace);
      return result;
    } catch (e) {
      trace.putAttribute('error', e.toString());
      await stopTrace(trace);
      rethrow;
    }
  }

  /// Create HTTP metric
  HttpMetric createHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  /// Set performance collection enabled
  Future<void> setEnabled(bool enabled) async {
    await _performance.setPerformanceCollectionEnabled(enabled);
  }
}

/// Transaction wrapper for Sentry
class TransactionWrapper {
  final ISentrySpan _transaction;

  TransactionWrapper._(this._transaction);

  /// Start a transaction
  static TransactionWrapper start({
    required String name,
    required String operation,
  }) {
    final transaction = Sentry.startTransaction(name, operation);
    return TransactionWrapper._(transaction);
  }

  /// Start a child span
  ISentrySpan startChild(String operation, {String? description}) {
    return _transaction.startChild(operation, description: description);
  }

  /// Finish transaction
  Future<void> finish() async {
    await _transaction.finish();
  }

  /// Set tag
  void setTag(String key, String value) {
    _transaction.setTag(key, value);
  }

  /// Set data
  void setData(String key, dynamic value) {
    _transaction.setData(key, value);
  }
}
