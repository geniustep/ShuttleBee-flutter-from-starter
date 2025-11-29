import 'package:bridgecore_flutter_starter/bootstrap/bootstrap.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // Handle errors during initialization
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // In release mode, log and continue
      debugPrint('Flutter Error: ${details.exception}');
    }
  };

  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
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
