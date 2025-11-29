import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Network connectivity information service
class NetworkInfo {
  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _connectionStatusController = StreamController<bool>.broadcast();

  /// Stream of connection status changes
  Stream<bool> get onConnectionChanged => _connectionStatusController.stream;

  /// Check if device is connected to the internet
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _isConnectedFromResults(results);
  }

  /// Start listening to connectivity changes
  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final connected = _isConnectedFromResults(results);
        _connectionStatusController.add(connected);
        _logger.d('Connectivity changed: ${connected ? "Online" : "Offline"}');
      },
    );
  }

  /// Stop listening to connectivity changes
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _connectionStatusController.close();
  }

  /// Check if results indicate connectivity
  bool _isConnectedFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }

  /// Get current connection type
  Future<ConnectionType> get connectionType async {
    final results = await _connectivity.checkConnectivity();

    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectionType.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionType.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectionType.ethernet;
    } else {
      return ConnectionType.none;
    }
  }
}

/// Connection type enum
enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  none,
}
