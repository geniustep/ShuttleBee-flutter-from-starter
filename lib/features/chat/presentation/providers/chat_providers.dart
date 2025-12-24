import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logger/logger.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_user.dart';

// BridgeCore conversation service provider
final conversationServiceProvider = Provider<ConversationService>((ref) {
  return BridgeCore.instance.conversations;
});

// BridgeCore WebSocket service provider
final conversationWebSocketProvider = Provider<ConversationWebSocketService>((
  ref,
) {
  return BridgeCore.instance.conversationsWebSocket;
});

// Data source provider
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final conversationService = ref.watch(conversationServiceProvider);
  final logger = Logger();
  return ChatRemoteDataSourceImpl(
    conversationService: conversationService,
    logger: logger,
  );
});

// Repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Conversations list provider
// Note: Removed autoDispose to prevent excessive requests
// The provider will cache results and only refresh when explicitly invalidated
final conversationsProvider =
    FutureProvider<List<ChatConversation>>((ref) async {
      final repository = ref.watch(chatRepositoryProvider);
      final result = await repository.getConversations();
      return result.fold(
        (failure) => throw Exception(failure.message),
        (conversations) => conversations,
      );
    });

// Single conversation provider (family)
final conversationProvider = FutureProvider.autoDispose
    .family<ChatConversation, String>((ref, conversationId) async {
      final repository = ref.watch(chatRepositoryProvider);
      final result = await repository.getConversation(conversationId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (conversation) => conversation,
      );
    });

// Messages provider (family) with WebSocket real-time updates
final messagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, conversationId) async* {
      final repository = ref.watch(chatRepositoryProvider);
      final ws = ref.watch(conversationWebSocketProvider);

      // Initial load
      final initialResult = await repository.getMessages(
        conversationId,
        limit: 50,
      );
      final initialMessages = initialResult.fold(
        (failure) => throw Exception(failure.message),
        (messages) => messages,
      );

      // Keep track of current messages
      List<ChatMessage> currentMessages = List.from(initialMessages);
      yield currentMessages;

      // Connect WebSocket if not connected
      if (!ws.isConnected) {
        try {
          final token = await BridgeCore.instance.auth.tokenManager
              .getAccessToken();
          if (token != null) {
            await ws.connect(token: token);
          }
        } catch (e) {
          // WebSocket connection failed, continue with REST only
        }
      }

      // Subscribe to channel
      try {
        final channelId = int.parse(conversationId);
        if (!ws.subscribedChannels.contains(channelId)) {
          await ws.subscribeChannel(channelId: channelId);
        }
      } catch (e) {
        // Invalid channel ID or subscription failed
      }

      // Listen for new messages
      final messageStream = ws.messageStream;
      await for (final mailMessage in messageStream) {
        // Check if message belongs to this conversation
        final channelId = int.tryParse(conversationId);
        if (channelId != null && mailMessage.channelIds.contains(channelId)) {
          // Convert MailMessage to ChatMessage
          final chatMessage = ChatMessage(
            id: mailMessage.id.toString(),
            author: ChatUser(
              id: (mailMessage.authorId ?? 0).toString(),
              firstName: mailMessage.authorName ?? 'User',
            ),
            createdAt: mailMessage.date,
            type: MessageType.text,
            status: MessageStatus.sent,
            text: _extractTextFromBody(mailMessage.body),
          );

          // Add new message to list (avoid duplicates)
          if (!currentMessages.any((m) => m.id == chatMessage.id)) {
            currentMessages = [chatMessage, ...currentMessages];
            yield currentMessages;
          }
        }
      }
    });

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

// Selected conversation ID state
final selectedConversationIdProvider = StateProvider<String?>((ref) => null);

// Unread messages count
final unreadMessagesCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final conversationsAsync = ref.watch(conversationsProvider);
  return conversationsAsync.when(
    data: (conversations) {
      return conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Chat UI state notifier
class ChatUiState {
  final bool isLoading;
  final String? error;
  final bool isSending;

  ChatUiState({this.isLoading = false, this.error, this.isSending = false});

  ChatUiState copyWith({bool? isLoading, String? error, bool? isSending}) {
    return ChatUiState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatUiNotifier extends StateNotifier<ChatUiState> {
  final ChatRepository repository;

  ChatUiNotifier(this.repository) : super(ChatUiState());

  Future<void> sendTextMessage(
    String conversationId,
    String text, {
    String? repliedMessageId,
  }) async {
    state = state.copyWith(isSending: true, error: null);
    final result = await repository.sendMessage(
      conversationId,
      text,
      repliedMessageId: repliedMessageId,
    );
    result.fold(
      (failure) =>
          state = state.copyWith(isSending: false, error: failure.message),
      (_) => state = state.copyWith(isSending: false),
    );
  }

  Future<void> sendImageMessage(
    String conversationId,
    String imageUrl, {
    String? fileName,
  }) async {
    state = state.copyWith(isSending: true, error: null);
    final result = await repository.sendImageMessage(
      conversationId,
      imageUrl,
      fileName: fileName,
    );
    result.fold(
      (failure) =>
          state = state.copyWith(isSending: false, error: failure.message),
      (_) => state = state.copyWith(isSending: false),
    );
  }

  Future<void> sendFileMessage(
    String conversationId,
    String fileUrl,
    String fileName,
    int fileSize, {
    String? mimeType,
  }) async {
    state = state.copyWith(isSending: true, error: null);
    final result = await repository.sendFileMessage(
      conversationId,
      fileUrl,
      fileName,
      fileSize,
      mimeType: mimeType,
    );
    result.fold(
      (failure) =>
          state = state.copyWith(isSending: false, error: failure.message),
      (_) => state = state.copyWith(isSending: false),
    );
  }

  Future<String?> uploadFile(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await repository.uploadFile(filePath);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return null;
      },
      (url) {
        state = state.copyWith(isLoading: false);
        return url;
      },
    );
  }

  Future<void> markAsRead(
    String conversationId,
    List<String> messageIds,
  ) async {
    await repository.markAsRead(conversationId, messageIds);
  }
}

final chatUiProvider = StateNotifierProvider<ChatUiNotifier, ChatUiState>((
  ref,
) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatUiNotifier(repository);
});

// Partner model for selection
class Partner {
  final int id;
  final String name;
  final String? email;

  Partner({required this.id, required this.name, this.email});

  factory Partner.fromJson(Map<String, dynamic> json) {
    // Handle name which might be false from Odoo
    String name = 'Unknown';
    final nameValue = json['name'];
    if (nameValue != null && nameValue is String) {
      name = nameValue;
    } else if (nameValue is bool && !nameValue) {
      // Odoo returns false for empty fields
      name = 'Unknown';
    }

    // Handle email which might be false from Odoo
    String? email;
    final emailValue = json['email'];
    if (emailValue != null && emailValue is String) {
      email = emailValue;
    } else if (emailValue is bool && !emailValue) {
      // Odoo returns false for empty fields, convert to null
      email = null;
    }

    return Partner(id: json['id'] as int, name: name, email: email);
  }
}

// Partners list provider
final partnersProvider = FutureProvider.autoDispose<List<Partner>>((ref) async {
  final result = await BridgeCore.instance.odoo.searchRead(
    model: 'res.partner',
    domain: [
      ['is_company', '=', false], // Only individuals, not companies
      ['active', '=', true], // Only active partners
    ],
    fields: ['id', 'name', 'email'],
    limit: 500,
  );

  return result.map((partner) => Partner.fromJson(partner)).toList();
});
