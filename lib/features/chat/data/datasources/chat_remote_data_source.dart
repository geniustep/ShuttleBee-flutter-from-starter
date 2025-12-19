import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  /// Get all conversations for the current user
  Future<List<ChatConversationModel>> getConversations();

  /// Get a specific conversation by ID
  Future<ChatConversationModel> getConversation(String conversationId);

  /// Get messages for a conversation
  Future<List<ChatMessageModel>> getMessages(String conversationId, {int? limit, int? offset});

  /// Send a text message
  Future<ChatMessageModel> sendMessage(String conversationId, String text, {String? repliedMessageId});

  /// Send an image message
  Future<ChatMessageModel> sendImageMessage(String conversationId, String imageUrl, {String? fileName});

  /// Send a file message
  Future<ChatMessageModel> sendFileMessage(String conversationId, String fileUrl, String fileName, int fileSize, {String? mimeType});

  /// Mark messages as read
  Future<void> markAsRead(String conversationId, List<String> messageIds);

  /// Create a new conversation
  Future<ChatConversationModel> createConversation(String name, String type, List<String> participantIds, {Map<String, dynamic>? metadata});

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId);

  /// Upload a file
  Future<String> uploadFile(String filePath);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;
  final Logger logger;

  ChatRemoteDataSourceImpl({
    required this.dio,
    required this.logger,
  });

  @override
  Future<List<ChatConversationModel>> getConversations() async {
    try {
      final response = await dio.get('/chat/conversations');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ChatConversationModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching conversations', error: e);
      rethrow;
    }
  }

  @override
  Future<ChatConversationModel> getConversation(String conversationId) async {
    try {
      final response = await dio.get('/chat/conversations/$conversationId');
      return ChatConversationModel.fromJson(response.data['data']);
    } catch (e) {
      logger.e('Error fetching conversation', error: e);
      rethrow;
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await dio.get(
        '/chat/conversations/$conversationId/messages',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ChatMessageModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching messages', error: e);
      rethrow;
    }
  }

  @override
  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String text, {
    String? repliedMessageId,
  }) async {
    try {
      final response = await dio.post(
        '/chat/conversations/$conversationId/messages',
        data: {
          'type': 'text',
          'text': text,
          if (repliedMessageId != null) 'repliedMessageId': repliedMessageId,
        },
      );
      return ChatMessageModel.fromJson(response.data['data']);
    } catch (e) {
      logger.e('Error sending message', error: e);
      rethrow;
    }
  }

  @override
  Future<ChatMessageModel> sendImageMessage(
    String conversationId,
    String imageUrl, {
    String? fileName,
  }) async {
    try {
      final response = await dio.post(
        '/chat/conversations/$conversationId/messages',
        data: {
          'type': 'image',
          'imageUrl': imageUrl,
          if (fileName != null) 'fileName': fileName,
        },
      );
      return ChatMessageModel.fromJson(response.data['data']);
    } catch (e) {
      logger.e('Error sending image message', error: e);
      rethrow;
    }
  }

  @override
  Future<ChatMessageModel> sendFileMessage(
    String conversationId,
    String fileUrl,
    String fileName,
    int fileSize, {
    String? mimeType,
  }) async {
    try {
      final response = await dio.post(
        '/chat/conversations/$conversationId/messages',
        data: {
          'type': 'file',
          'fileUrl': fileUrl,
          'fileName': fileName,
          'fileSize': fileSize,
          if (mimeType != null) 'mimeType': mimeType,
        },
      );
      return ChatMessageModel.fromJson(response.data['data']);
    } catch (e) {
      logger.e('Error sending file message', error: e);
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String conversationId, List<String> messageIds) async {
    try {
      await dio.post(
        '/chat/conversations/$conversationId/read',
        data: {
          'messageIds': messageIds,
        },
      );
    } catch (e) {
      logger.e('Error marking messages as read', error: e);
      rethrow;
    }
  }

  @override
  Future<ChatConversationModel> createConversation(
    String name,
    String type,
    List<String> participantIds, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await dio.post(
        '/chat/conversations',
        data: {
          'name': name,
          'type': type,
          'participantIds': participantIds,
          if (metadata != null) 'metadata': metadata,
        },
      );
      return ChatConversationModel.fromJson(response.data['data']);
    } catch (e) {
      logger.e('Error creating conversation', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      await dio.delete('/chat/conversations/$conversationId');
    } catch (e) {
      logger.e('Error deleting conversation', error: e);
      rethrow;
    }
  }

  @override
  Future<String> uploadFile(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await dio.post('/chat/upload', data: formData);
      return response.data['data']['url'];
    } catch (e) {
      logger.e('Error uploading file', error: e);
      rethrow;
    }
  }
}
