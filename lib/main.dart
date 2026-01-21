import 'package:bridgecore_flutter_starter/bootstrap/bootstrap.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // Handle errors during initialization
  FlutterError.onError = (FlutterErrorDetails details) {
    // Filter out known Windows thread message errors (Flutter 3.35+ merged threads issue)
    final errorString = details.exception.toString();
    if (errorString.contains('Failed to post message to main thread')) {
      // This is a known Flutter Windows issue, ignore it
      if (kDebugMode) {
        debugPrint(
          '⚠️ Ignored Windows thread message error (known Flutter issue)',
        );
      }
      return;
    }

    FlutterError.presentError(details);
    if (kReleaseMode) {
      // In release mode, log and continue
      debugPrint('Flutter Error: ${details.exception}');
    }
  };

  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    // Filter out known Windows thread message errors
    final errorString = error.toString();
    if (errorString.contains('Failed to post message to main thread') ||
        errorString.contains('task_runner_window')) {
      // This is a known Flutter Windows issue, ignore it
      if (kDebugMode) {
        debugPrint('⚠️ Ignored Windows platform error (known Flutter issue)');
      }
      return true;
    }

    debugPrint('Platform Error: $error');
    return true; // Return true to prevent app from crashing
  };

  try {
    await bootstrap();
  } catch (e, stackTrace) {
    debugPrint('Bootstrap Error: $e');
    debugPrint('Stack Trace: $stackTrace');
    // Don't exit - let Flutter handle the error
    rethrow;
  }
}
