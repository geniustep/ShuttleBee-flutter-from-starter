import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// WebSocket service for real-time updates
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _serverUrl;

  final _messageController = StreamController<SocketMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  /// Get message stream
  Stream<SocketMessage> get messages => _messageController.stream;

  /// Get connection status stream
  Stream<bool> get connectionStatus => _connectionController.stream;

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Initialize and connect to WebSocket server
  Future<void> connect({
    required String serverUrl,
    Map<String, dynamic>? auth,
    Map<String, dynamic>? extraHeaders,
  }) async {
    if (_isConnected) {
      AppLogger.warning('WebSocket already connected');
      return;
    }

    _serverUrl = serverUrl;

    final optionsBuilder =
        io.OptionBuilder().setTransports(['websocket']).disableAutoConnect();

    if (auth != null) {
      optionsBuilder.setAuth(auth);
    }

    if (extraHeaders != null) {
      optionsBuilder.setExtraHeaders(extraHeaders);
    }

    _socket = io.io(
      serverUrl,
      optionsBuilder.build(),
    );

    _setupEventHandlers();
    _socket!.connect();

    AppLogger.info('Connecting to WebSocket: $serverUrl');
  }

  /// Setup event handlers
  void _setupEventHandlers() {
    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionController.add(true);
      AppLogger.info('WebSocket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
      AppLogger.warning('WebSocket disconnected');
    });

    _socket!.onConnectError((error) {
      AppLogger.error('WebSocket connection error: $error');
    });

    _socket!.onError((error) {
      AppLogger.error('WebSocket error: $error');
    });

    // Listen to all events
    _socket!.onAny((event, data) {
      _messageController.add(
        SocketMessage(
          event: event,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _connectionController.add(false);
      AppLogger.info('WebSocket disconnected');
    }
  }

  /// Send message
  void emit(String event, [dynamic data]) {
    if (!_isConnected) {
      AppLogger.warning('WebSocket not connected. Cannot send message.');
      return;
    }

    _socket!.emit(event, data);
    AppLogger.debug('Sent message: $event');
  }

  /// Send JSON message
  void emitJson(String event, Map<String, dynamic> data) {
    emit(event, jsonEncode(data));
  }

  /// Listen to specific event
  void on(String event, void Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Remove listener
  void off(String event, [void Function(dynamic)? callback]) {
    _socket?.off(event, callback);
  }

  /// Subscribe to channel/room
  void subscribe(String channel) {
    emit('subscribe', {'channel': channel});
    AppLogger.info('Subscribed to channel: $channel');
  }

  /// Unsubscribe from channel/room
  void unsubscribe(String channel) {
    emit('unsubscribe', {'channel': channel});
    AppLogger.info('Unsubscribed from channel: $channel');
  }

  /// Reconnect
  Future<void> reconnect() async {
    await disconnect();
    if (_serverUrl != null) {
      await connect(serverUrl: _serverUrl!);
    }
  }

  /// Dispose
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}

/// Socket message
class SocketMessage {
  final String event;
  final dynamic data;
  final DateTime timestamp;

  SocketMessage({
    required this.event,
    required this.data,
    required this.timestamp,
  });

  /// Parse data as JSON
  Map<String, dynamic>? get dataAsJson {
    if (data is String) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    } else if (data is Map) {
      return data as Map<String, dynamic>;
    }
    return null;
  }

  @override
  String toString() =>
      'SocketMessage(event: $event, data: $data, timestamp: $timestamp)';
}

/// Real-time updates service
class RealtimeUpdatesService {
  static final RealtimeUpdatesService _instance =
      RealtimeUpdatesService._internal();
  factory RealtimeUpdatesService() => _instance;
  RealtimeUpdatesService._internal();

  final WebSocketService _ws = WebSocketService();
  final Map<String, StreamController<dynamic>> _channelControllers = {};

  /// Initialize real-time updates
  Future<void> initialize({
    required String serverUrl,
    Map<String, dynamic>? auth,
  }) async {
    await _ws.connect(serverUrl: serverUrl, auth: auth);

    // Listen to messages and route to appropriate channels
    _ws.messages.listen((message) {
      _routeMessage(message);
    });
  }

  /// Route message to appropriate channel
  void _routeMessage(SocketMessage message) {
    final data = message.dataAsJson;
    if (data != null && data.containsKey('channel')) {
      final channel = data['channel'] as String;
      if (_channelControllers.containsKey(channel)) {
        _channelControllers[channel]!.add(data['data']);
      }
    }
  }

  /// Subscribe to updates for a specific model
  Stream<dynamic> subscribeToModel(String model, {List<int>? ids}) {
    final channel = ids != null ? '$model:${ids.join(',')}' : model;
    return subscribeToChannel(channel);
  }

  /// Subscribe to channel
  Stream<dynamic> subscribeToChannel(String channel) {
    if (!_channelControllers.containsKey(channel)) {
      _channelControllers[channel] = StreamController<dynamic>.broadcast();
      _ws.subscribe(channel);
    }

    return _channelControllers[channel]!.stream;
  }

  /// Unsubscribe from channel
  void unsubscribeFromChannel(String channel) {
    _ws.unsubscribe(channel);
    _channelControllers[channel]?.close();
    _channelControllers.remove(channel);
  }

  /// Dispose
  void dispose() {
    for (final controller in _channelControllers.values) {
      controller.close();
    }
    _channelControllers.clear();
    _ws.dispose();
  }
}
