import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/local_storage/domain/local_storage_repository.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

/// Local cache for Chat feature
///
/// Provides offline-first caching for chat data:
/// - Conversations list
/// - Messages per conversation
/// - Read status
/// - Local attachments metadata
class ChatLocalCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _conversationsCollection = 'chat_conversations';
  static const String _messagesCollectionPrefix = 'chat_messages_';
  static const String _readStatusCollection = 'chat_read_status';
  static const String _attachmentsCollection = 'chat_attachments';

  // Cache TTL
  static const Duration _conversationsTTL = Duration(days: 7);
  static const Duration _messagesTTL = Duration(days: 30);
  static const Duration _readStatusTTL = Duration(days: 90);
  static const Duration _attachmentsTTL = Duration(days: 30);

  ChatLocalCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Conversations Cache
  // ════════════════════════════════════════════════════════════

  /// Save conversations list to cache
  Future<Either<Failure, bool>> cacheConversations(
    List<ChatConversation> conversations,
  ) async {
    try {
      final conversationsJson = conversations
          .map((c) => ChatConversationModel.fromEntity(c).toJson())
          .toList();

      return await _storage.saveCollection(
        collectionName: _conversationsCollection,
        items: conversationsJson,
        ttl: _conversationsTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache conversations: $e'));
    }
  }

  /// Load cached conversations
  Future<Either<Failure, List<ChatConversation>>> getCachedConversations() async {
    final result = await _storage.loadCollection(_conversationsCollection);

    return result.fold(
      (failure) => Left(failure),
      (items) {
        try {
          final conversations = items
              .map((json) => ChatConversationModel.fromJson(json).toEntity())
              .toList();
          return Right(conversations);
        } catch (e) {
          return Left(CacheFailure(message: 'Failed to parse conversations: $e'));
        }
      },
    );
  }

  /// Update single conversation in cache
  Future<Either<Failure, bool>> updateCachedConversation(
    ChatConversation conversation,
  ) async {
    try {
      // First, get all conversations
      final conversationsResult = await getCachedConversations();
      return await conversationsResult.fold(
        (failure) => Left(failure),
        (conversations) async {
          // Update or add the conversation
          final index = conversations.indexWhere((c) => c.id == conversation.id);
          if (index >= 0) {
            conversations[index] = conversation;
          } else {
            conversations.add(conversation);
          }

          return await cacheConversations(conversations);
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update conversation: $e'));
    }
  }

  /// Delete conversation from cache
  Future<Either<Failure, bool>> deleteCachedConversation(
    String conversationId,
  ) async {
    try {
      // Delete conversation
      final conversationsResult = await getCachedConversations();
      return await conversationsResult.fold(
        (failure) => Left(failure),
        (conversations) async {
          conversations.removeWhere((c) => c.id == conversationId);
          await cacheConversations(conversations);

          // Delete associated messages
          await _storage.deleteCollection(
            '$_messagesCollectionPrefix$conversationId',
          );

          return const Right(true);
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete conversation: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Messages Cache
  // ════════════════════════════════════════════════════════════

  /// Save messages for a conversation
  ///
  /// Only saves last 100 messages per conversation to save space
  Future<Either<Failure, bool>> cacheMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    try {
      // Limit to last 100 messages
      final messagesToCache = messages.length > 100
          ? messages.sublist(messages.length - 100)
          : messages;

      final messagesJson = messagesToCache
          .map((m) => ChatMessageModel.fromEntity(m).toJson())
          .toList();

      return await _storage.saveCollection(
        collectionName: '$_messagesCollectionPrefix$conversationId',
        items: messagesJson,
        ttl: _messagesTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache messages: $e'));
    }
  }

  /// Load cached messages for a conversation
  Future<Either<Failure, List<ChatMessage>>> getCachedMessages(
    String conversationId,
  ) async {
    final result = await _storage.loadCollection(
      '$_messagesCollectionPrefix$conversationId',
    );

    return result.fold(
      (failure) => Left(failure),
      (items) {
        try {
          final messages = items
              .map((json) => ChatMessageModel.fromJson(json).toEntity())
              .toList();
          return Right(messages);
        } catch (e) {
          return Left(CacheFailure(message: 'Failed to parse messages: $e'));
        }
      },
    );
  }

  /// Add new message to cache
  Future<Either<Failure, bool>> addCachedMessage(
    String conversationId,
    ChatMessage message,
  ) async {
    try {
      final messagesResult = await getCachedMessages(conversationId);
      return await messagesResult.fold(
        (failure) => Left(failure),
        (messages) async {
          // Add message if not exists
          if (!messages.any((m) => m.id == message.id)) {
            messages.add(message);
            // Keep only last 100
            if (messages.length > 100) {
              messages = messages.sublist(messages.length - 100);
            }
            return await cacheMessages(conversationId, messages);
          }
          return const Right(true);
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to add message: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Read Status Cache
  // ════════════════════════════════════════════════════════════

  /// Save read status for messages
  Future<Either<Failure, bool>> cacheReadStatus(
    String conversationId,
    List<String> readMessageIds,
  ) async {
    try {
      return await _storage.save(
        key: '$_readStatusCollection$conversationId',
        data: {
          'conversationId': conversationId,
          'readMessageIds': readMessageIds,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        ttl: _readStatusTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache read status: $e'));
    }
  }

  /// Get read status for a conversation
  Future<Either<Failure, List<String>>> getCachedReadStatus(
    String conversationId,
  ) async {
    final result = await _storage.load('$_readStatusCollection$conversationId');

    return result.fold(
      (failure) => Left(failure),
      (data) {
        if (data == null) {
          return const Right([]);
        }
        try {
          final readIds = (data['readMessageIds'] as List<dynamic>?)
                  ?.map((id) => id.toString())
                  .toList() ??
              [];
          return Right(readIds);
        } catch (e) {
          return Left(CacheFailure(message: 'Failed to parse read status: $e'));
        }
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // Attachments Cache
  // ════════════════════════════════════════════════════════════

  /// Save attachment metadata
  Future<Either<Failure, bool>> cacheAttachmentMetadata({
    required String messageId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    String? localPath,
  }) async {
    try {
      return await _storage.save(
        key: '$_attachmentsCollection$messageId',
        data: {
          'messageId': messageId,
          'fileUrl': fileUrl,
          'fileName': fileName,
          'fileSize': fileSize,
          'localPath': localPath,
          'cachedAt': DateTime.now().toIso8601String(),
        },
        ttl: _attachmentsTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache attachment: $e'));
    }
  }

  /// Get attachment metadata
  Future<Either<Failure, Map<String, dynamic>?>> getCachedAttachmentMetadata(
    String messageId,
  ) async {
    final result = await _storage.load('$_attachmentsCollection$messageId');

    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all chat caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      // Delete conversations
      await _storage.deleteCollection(_conversationsCollection);

      // Delete all message collections (we need to get conversation IDs first)
      final conversationsResult = await getCachedConversations();
      await conversationsResult.fold(
        (_) => null,
        (conversations) async {
          for (final conv in conversations) {
            await _storage.deleteCollection(
              '$_messagesCollectionPrefix${conv.id}',
            );
          }
        },
      );

      // Delete read status and attachments (best effort)
      // Note: We can't enumerate all keys, so we'll rely on TTL expiration

      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear caches: $e'));
    }
  }

  /// Get cache statistics
  Future<Either<Failure, Map<String, dynamic>>> getCacheStats() async {
    return _storage.getStats();
  }
}

