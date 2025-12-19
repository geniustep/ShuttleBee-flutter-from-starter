import 'dart:async';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/utils/logger.dart';
import '../models/chat_message_model.dart';
import '../models/chat_conversation_model.dart';

/// Chat-specific WebSocket service
class ChatWebSocketService {
  static final ChatWebSocketService _instance = ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  final WebSocketService _ws = WebSocketService();
  final _newMessageController = StreamController<ChatMessageModel>.broadcast();
  final _messageUpdatedController = StreamController<ChatMessageModel>.broadcast();
  final _conversationUpdatedController = StreamController<ChatConversationModel>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();

  /// Get new messages stream
  Stream<ChatMessageModel> get newMessages => _newMessageController.stream;

  /// Get message updated stream
  Stream<ChatMessageModel> get messageUpdated => _messageUpdatedController.stream;

  /// Get conversation updated stream
  Stream<ChatConversationModel> get conversationUpdated => _conversationUpdatedController.stream;

  /// Get typing events stream
  Stream<TypingEvent> get typingEvents => _typingController.stream;

  /// Initialize chat WebSocket
  Future<void> initialize() async {
    // Setup listeners for chat events
    _ws.on('chat:message:new', (data) {
      try {
        final message = ChatMessageModel.fromJson(data);
        _newMessageController.add(message);
        AppLogger.info('New chat message received');
      } catch (e) {
        AppLogger.error('Error parsing new message: $e');
      }
    });

    _ws.on('chat:message:updated', (data) {
      try {
        final message = ChatMessageModel.fromJson(data);
        _messageUpdatedController.add(message);
        AppLogger.info('Message updated');
      } catch (e) {
        AppLogger.error('Error parsing updated message: $e');
      }
    });

    _ws.on('chat:conversation:updated', (data) {
      try {
        final conversation = ChatConversationModel.fromJson(data);
        _conversationUpdatedController.add(conversation);
        AppLogger.info('Conversation updated');
      } catch (e) {
        AppLogger.error('Error parsing updated conversation: $e');
      }
    });

    _ws.on('chat:typing', (data) {
      try {
        final typingEvent = TypingEvent.fromJson(data);
        _typingController.add(typingEvent);
      } catch (e) {
        AppLogger.error('Error parsing typing event: $e');
      }
    });

    AppLogger.info('Chat WebSocket service initialized');
  }

  /// Join a conversation room
  void joinConversation(String conversationId) {
    _ws.subscribe('chat:conversation:$conversationId');
    AppLogger.info('Joined conversation: $conversationId');
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    _ws.unsubscribe('chat:conversation:$conversationId');
    AppLogger.info('Left conversation: $conversationId');
  }

  /// Send typing indicator
  void sendTypingIndicator(String conversationId, bool isTyping) {
    _ws.emit('chat:typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  /// Mark message as read
  void markMessageAsRead(String conversationId, String messageId) {
    _ws.emit('chat:message:read', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  /// Dispose
  void dispose() {
    _newMessageController.close();
    _messageUpdatedController.close();
    _conversationUpdatedController.close();
    _typingController.close();
  }
}

/// Typing event
class TypingEvent {
  final String conversationId;
  final String userId;
  final String userName;
  final bool isTyping;

  TypingEvent({
    required this.conversationId,
    required this.userId,
    required this.userName,
    required this.isTyping,
  });

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    return TypingEvent(
      conversationId: json['conversationId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      isTyping: json['isTyping'] as bool,
    );
  }
}
