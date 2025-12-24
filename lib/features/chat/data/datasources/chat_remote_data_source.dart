import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_user_model.dart';

abstract class ChatRemoteDataSource {
  /// Get all conversations for the current user
  Future<List<ChatConversationModel>> getConversations();

  /// Get a specific conversation by ID
  Future<ChatConversationModel> getConversation(String conversationId);

  /// Get messages for a conversation
  Future<List<ChatMessageModel>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  });

  /// Send a text message
  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String text, {
    String? repliedMessageId,
  });

  /// Send an image message
  Future<ChatMessageModel> sendImageMessage(
    String conversationId,
    String imageUrl, {
    String? fileName,
  });

  /// Send a file message
  Future<ChatMessageModel> sendFileMessage(
    String conversationId,
    String fileUrl,
    String fileName,
    int fileSize, {
    String? mimeType,
  });

  /// Mark messages as read
  Future<void> markAsRead(String conversationId, List<String> messageIds);

  /// Create a new conversation
  Future<ChatConversationModel> createConversation(
    String name,
    String type,
    List<String> participantIds, {
    Map<String, dynamic>? metadata,
  });

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId);

  /// Upload a file
  Future<String> uploadFile(String filePath);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ConversationService _conversationService;
  final Logger logger;

  ChatRemoteDataSourceImpl({
    required ConversationService conversationService,
    required this.logger,
  }) : _conversationService = conversationService;

  /// Get the correct model name for Odoo 18 (discuss.channel) or older versions (mail.channel)
  /// Backend handles fallback automatically, but we prefer discuss.channel for Odoo 18
  String _getChannelModel() {
    // Try discuss.channel first (Odoo 18), fallback to mail.channel for older versions
    // Backend will handle the fallback automatically
    return 'discuss.channel';
  }

  @override
  Future<List<ChatConversationModel>> getConversations() async {
    try {
      final response = await _conversationService.getChannels();
      return response.channels.map((channel) {
        return ChatConversationModel(
          id: channel.id.toString(),
          name: channel.name,
          type: channel.isDirectMessage ? 'direct' : 'group',
          participants: channel.membersPartnerIds
              .map(
                (id) => ChatUserModel(id: id.toString(), firstName: 'User $id'),
              )
              .toList(),
          unreadCount: 0,
          createdAt: DateTime.now(),
          isActive: true,
        );
      }).toList();
    } on NotFoundException {
      // Handle 404 - endpoint not available yet
      logger.w(
        'Conversations endpoint not available (404). '
        'Returning empty list. This is expected if backend feature is not deployed yet.',
      );
      return [];
    } on DioException catch (e) {
      // Handle 401 - Unauthorized (token expired or invalid)
      if (e.response?.statusCode == 401) {
        logger.w(
          'Unauthorized (401) fetching conversations. '
          'Token may have expired. Returning empty list. '
          'User may need to re-authenticate.',
        );
        return [];
      }
      // Handle 404 - endpoint not available yet
      if (e.response?.statusCode == 404) {
        logger.w(
          'Conversations endpoint not available (404). '
          'Returning empty list. This is expected if backend feature is not deployed yet.',
        );
        return [];
      }
      // Handle 500 - Internal Server Error (may be tenant/token related)
      if (e.response?.statusCode == 500) {
        final responseData = e.response?.data;
        String errorMessage = '';

        // Extract error message from different possible response formats
        if (responseData is Map) {
          errorMessage =
              (responseData['error']?.toString() ??
                      responseData['detail']?.toString() ??
                      responseData['message']?.toString() ??
                      '')
                  .toLowerCase();
        } else if (responseData is String) {
          errorMessage = responseData.toLowerCase();
        } else {
          errorMessage = (e.message ?? '').toLowerCase();
        }

        // Check if it's a tenant/token related error
        if (errorMessage.contains('tenant') ||
            errorMessage.contains('token') ||
            errorMessage.contains('authentication') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('session')) {
          logger.w(
            'Server error (500) - possible tenant/token issue. '
            'Error: ${errorMessage.isNotEmpty ? errorMessage : "Unknown error"}. '
            'Returning empty list. User may need to re-login.',
          );
          return [];
        }

        // Generic 500 error - log and return empty list
        logger.e(
          'Server error (500) fetching conversations. '
          'Error: ${errorMessage.isNotEmpty ? errorMessage : "Internal server error"}. '
          'Returning empty list.',
        );
        return [];
      }

      // Handle 503 - tenant context validation error (transient, should retry)
      if (e.response?.statusCode == 503) {
        final responseData = e.response?.data;
        String errorMessage = '';

        // Extract error message from different possible response formats
        if (responseData is Map) {
          errorMessage =
              (responseData['detail']?.toString() ??
                      responseData['message']?.toString() ??
                      '')
                  .toLowerCase();
        } else if (responseData is String) {
          errorMessage = responseData.toLowerCase();
        } else {
          errorMessage = (e.message ?? '').toLowerCase();
        }

        if (errorMessage.contains('tenant context') ||
            errorMessage.contains('failed to validate tenant context')) {
          logger.w(
            'Tenant context validation failed (503). '
            'This is a transient error. Returning empty list. '
            'The retry interceptor should handle automatic retries.',
          );
          // Return empty list instead of throwing - retry interceptor will handle retries
          // If retries fail, we gracefully return empty list
          return [];
        }
      }
      logger.e('Error fetching conversations', error: e);
      rethrow;
    } catch (e) {
      final errorString = e.toString().toLowerCase();

      // Check if it's a 404 error in the message
      if (errorString.contains('404') || errorString.contains('not found')) {
        logger.w(
          'Conversations endpoint not available (404). '
          'Returning empty list. This is expected if backend feature is not deployed yet.',
        );
        return [];
      }

      // Check if it's a tenant context validation error (503 or any format)
      if (errorString.contains('tenant context') ||
          errorString.contains('failed to validate tenant context') ||
          errorString.contains('503')) {
        logger.w(
          'Tenant context validation failed (503). '
          'This is a transient server error. Returning empty list. '
          'The retry interceptor should handle automatic retries.',
        );
        return [];
      }

      // Check if it's a 401 or 403 authentication error
      if (errorString.contains('401') ||
          errorString.contains('unauthorized') ||
          errorString.contains('403') ||
          errorString.contains('not authenticated') ||
          errorString.contains('authentication required') ||
          errorString.contains('access denied') ||
          errorString.contains('failed to authenticate')) {
        logger.w(
          'Authentication error (401/403) fetching conversations. '
          'Token may have expired or been revoked. '
          'Returning empty list to prevent UI crash. '
          'User may need to re-authenticate.',
        );
        return [];
      }

      // Check if it's a 500 server error
      if (errorString.contains('500') ||
          errorString.contains('internal server error') ||
          errorString.contains('server error')) {
        logger.e(
          'Server error (500) fetching conversations. '
          'This may indicate a backend issue or token/tenant problem. '
          'Returning empty list.',
        );
        return [];
      }

      logger.e('Error fetching conversations', error: e);
      rethrow;
    }
  }

  @override
  Future<ChatConversationModel> getConversation(String conversationId) async {
    try {
      final channelId = int.parse(conversationId);
      final response = await _conversationService.getChannels();
      final channel = response.channels.firstWhere(
        (c) => c.id == channelId,
        orElse: () => throw Exception('Channel not found'),
      );
      return ChatConversationModel(
        id: channel.id.toString(),
        name: channel.name,
        type: channel.isDirectMessage ? 'direct' : 'group',
        participants: channel.membersPartnerIds
            .map(
              (id) => ChatUserModel(id: id.toString(), firstName: 'User $id'),
            )
            .toList(),
        unreadCount: 0,
        createdAt: DateTime.now(),
        isActive: true,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        logger.w('Conversations endpoint not available (404)');
        throw Exception('Conversations feature not available');
      }
      logger.e('Error fetching conversation', error: e);
      rethrow;
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
      final channelId = int.parse(conversationId);
      final response = await _conversationService.getChannelMessages(
        channelId: channelId,
        limit: limit ?? 50,
        offset: offset ?? 0,
      );
      return response.messages.map((message) {
        return ChatMessageModel(
          id: message.id.toString(),
          author: ChatUserModel(
            id: (message.authorId ?? 0).toString(),
            firstName: message.authorName ?? 'User',
          ),
          createdAt: message.date,
          type: 'text',
          status: 'sent',
          text: _extractTextFromBody(message.body),
        );
      }).toList();
    } on NotFoundException {
      logger.w('Messages endpoint not available (404)');
      return [];
    } on DioException catch (e) {
      // Handle 404 - endpoint not available yet
      if (e.response?.statusCode == 404) {
        logger.w('Messages endpoint not available (404)');
        return [];
      }
      // Handle 500 - Internal Server Error (may be tenant/token related)
      if (e.response?.statusCode == 500) {
        final responseData = e.response?.data;
        String errorMessage = '';

        // Extract error message from different possible response formats
        if (responseData is Map) {
          errorMessage =
              (responseData['error']?.toString() ??
                      responseData['detail']?.toString() ??
                      responseData['message']?.toString() ??
                      '')
                  .toLowerCase();
        } else if (responseData is String) {
          errorMessage = responseData.toLowerCase();
        } else {
          errorMessage = (e.message ?? '').toLowerCase();
        }

        // Check if it's a tenant/token related error
        if (errorMessage.contains('tenant') ||
            errorMessage.contains('token') ||
            errorMessage.contains('authentication') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('session')) {
          logger.w(
            'Server error (500) - possible tenant/token issue. '
            'Error: ${errorMessage.isNotEmpty ? errorMessage : "Unknown error"}. '
            'Returning empty list. User may need to re-login.',
          );
          return [];
        }

        // Generic 500 error - log and return empty list
        logger.e(
          'Server error (500) fetching messages. '
          'Error: ${errorMessage.isNotEmpty ? errorMessage : "Internal server error"}. '
          'Returning empty list.',
        );
        return [];
      }

      // Handle 503 - tenant context validation error (transient, should retry)
      if (e.response?.statusCode == 503) {
        final responseData = e.response?.data;
        String errorMessage = '';

        // Extract error message from different possible response formats
        if (responseData is Map) {
          errorMessage =
              (responseData['detail']?.toString() ??
                      responseData['message']?.toString() ??
                      '')
                  .toLowerCase();
        } else if (responseData is String) {
          errorMessage = responseData.toLowerCase();
        } else {
          errorMessage = (e.message ?? '').toLowerCase();
        }

        if (errorMessage.contains('tenant context') ||
            errorMessage.contains('failed to validate tenant context')) {
          logger.w(
            'Tenant context validation failed (503). '
            'This is a transient error. Returning empty list. '
            'The retry interceptor should handle automatic retries.',
          );
          // Return empty list instead of throwing - retry interceptor will handle retries
          // If retries fail, we gracefully return empty list
          return [];
        }
      }
      logger.e('Error fetching messages', error: e);
      rethrow;
    } catch (e) {
      final errorString = e.toString().toLowerCase();

      // Check if it's a 404 error in the message
      if (errorString.contains('404') || errorString.contains('not found')) {
        logger.w('Messages endpoint not available (404)');
        return [];
      }

      // Check if it's a tenant context validation error (503 or any format)
      if (errorString.contains('tenant context') ||
          errorString.contains('failed to validate tenant context') ||
          errorString.contains('503')) {
        logger.w(
          'Tenant context validation failed (503). '
          'This is a transient server error. Returning empty list. '
          'The retry interceptor should handle automatic retries.',
        );
        return [];
      }

      // Check if it's a 500 server error
      if (errorString.contains('500') ||
          errorString.contains('internal server error') ||
          errorString.contains('server error')) {
        logger.e(
          'Server error (500) fetching messages. '
          'This may indicate a backend issue or token/tenant problem. '
          'Returning empty list.',
        );
        return [];
      }

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
      final channelId = int.parse(conversationId);
      final body = '<p>$text</p>';
      final response = await _conversationService.sendMessage(
        model: _getChannelModel(),
        resId: channelId,
        body: body,
        parentId: repliedMessageId != null
            ? int.tryParse(repliedMessageId)
            : null,
      );
      // Note: Backend should return full message, for now create placeholder
      return ChatMessageModel(
        id: response.id.toString(),
        author: const ChatUserModel(id: 'current', firstName: 'Me'),
        createdAt: DateTime.now(),
        type: 'text',
        status: 'sent',
        text: text,
      );
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
      final channelId = int.parse(conversationId);
      final body =
          '<p><img src="$imageUrl" alt="${fileName ?? 'image'}" /></p>';
      final response = await _conversationService.sendMessage(
        model: _getChannelModel(),
        resId: channelId,
        body: body,
      );
      return ChatMessageModel(
        id: response.id.toString(),
        author: const ChatUserModel(id: 'current', firstName: 'Me'),
        createdAt: DateTime.now(),
        type: 'image',
        status: 'sent',
        imageUrl: imageUrl,
        fileName: fileName,
      );
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
      final channelId = int.parse(conversationId);
      final body = '<p><a href="$fileUrl">$fileName</a></p>';
      final response = await _conversationService.sendMessage(
        model: _getChannelModel(),
        resId: channelId,
        body: body,
      );
      return ChatMessageModel(
        id: response.id.toString(),
        author: const ChatUserModel(id: 'current', firstName: 'Me'),
        createdAt: DateTime.now(),
        type: 'file',
        status: 'sent',
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
      );
    } catch (e) {
      logger.e('Error sending file message', error: e);
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(
    String conversationId,
    List<String> messageIds,
  ) async {
    // BridgeCore doesn't have mark as read endpoint yet
    // This can be implemented when backend adds it
    logger.w('markAsRead not implemented in BridgeCore yet');
  }

  @override
  Future<ChatConversationModel> createConversation(
    String name,
    String type,
    List<String> participantIds, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Only support direct messages for now (DM channels)
      if (type != 'direct') {
        throw UnimplementedError(
          'Only direct message conversations are supported. '
          'Group conversations are not available in BridgeCore yet.',
        );
      }

      if (participantIds.isEmpty) {
        throw ArgumentError('At least one participant is required');
      }

      // Convert participant IDs from String to int
      final partnerIds = participantIds
          .map((id) => int.tryParse(id))
          .whereType<int>()
          .toList();

      if (partnerIds.isEmpty) {
        throw ArgumentError('Invalid participant IDs format');
      }

      // Get or create DM channel using the new endpoint
      final response = await _conversationService.getOrCreateDmChannel(
        partnerIds,
      );

      // Extract channel data from Odoo response format
      // Odoo 18 returns: { "discuss.channel": [...], "discuss.channel.member": [...], "res.partner": [...] }
      // Older versions return: { "mail.channel": [...], "res.partner": [...] }
      final channels =
          response['discuss.channel'] as List<dynamic>? ??
          response['mail.channel'] as List<dynamic>?;
      if (channels == null || channels.isEmpty) {
        throw Exception('Failed to create or get channel: no channel returned');
      }

      final channelData = channels[0] as Map<String, dynamic>;
      final channelId = channelData['id'] as int;
      final channelName = channelData['name'] as String? ?? name;

      // Extract partner data if available
      final partners = response['res.partner'] as List<dynamic>? ?? [];
      final participants = partners.map((partner) {
        final partnerData = partner as Map<String, dynamic>;
        return ChatUserModel(
          id: (partnerData['id'] as int).toString(),
          firstName: partnerData['name'] as String? ?? 'User',
        );
      }).toList();

      // If no partners in response, create placeholder participants
      if (participants.isEmpty) {
        participants.addAll(
          partnerIds.map(
            (id) => ChatUserModel(id: id.toString(), firstName: 'User $id'),
          ),
        );
      }

      return ChatConversationModel(
        id: channelId.toString(),
        name: channelName,
        type: 'direct',
        participants: participants,
        unreadCount: 0,
        createdAt: DateTime.now(),
        isActive: true,
        metadata: metadata,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        logger.w('Get or create DM channel endpoint not available (404)');
        throw Exception('DM channel creation feature not available');
      }
      logger.e('Error creating conversation', error: e);
      rethrow;
    } catch (e) {
      logger.e('Error creating conversation', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    // BridgeCore doesn't have delete conversation endpoint yet
    throw UnimplementedError('deleteConversation not available in BridgeCore');
  }

  @override
  Future<String> uploadFile(String filePath) async {
    // BridgeCore doesn't have file upload endpoint yet
    // This should use Odoo's attachment system
    throw UnimplementedError('uploadFile not available in BridgeCore');
  }

  String? _extractTextFromBody(String? body) {
    if (body == null) return null;
    return body
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
