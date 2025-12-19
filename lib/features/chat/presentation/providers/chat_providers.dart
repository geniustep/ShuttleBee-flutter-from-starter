import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';

// Data source provider
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  final logger = Logger();
  return ChatRemoteDataSourceImpl(dio: dio, logger: logger);
});

// Repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Conversations list provider
final conversationsProvider = FutureProvider.autoDispose<List<ChatConversation>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getConversations();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversations) => conversations,
  );
});

// Single conversation provider (family)
final conversationProvider = FutureProvider.autoDispose.family<ChatConversation, String>((ref, conversationId) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getConversation(conversationId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversation) => conversation,
  );
});

// Messages provider (family)
final messagesProvider = FutureProvider.autoDispose.family<List<ChatMessage>, String>((ref, conversationId) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getMessages(conversationId, limit: 50);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (messages) => messages,
  );
});

// Selected conversation ID state
final selectedConversationIdProvider = StateProvider<String?>((ref) => null);

// Unread messages count
final unreadMessagesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final conversationsAsync = ref.watch(conversationsProvider);
  return conversationsAsync.when(
    data: (conversations) {
      return conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
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

  ChatUiState({
    this.isLoading = false,
    this.error,
    this.isSending = false,
  });

  ChatUiState copyWith({
    bool? isLoading,
    String? error,
    bool? isSending,
  }) {
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

  Future<void> sendTextMessage(String conversationId, String text, {String? repliedMessageId}) async {
    state = state.copyWith(isSending: true, error: null);
    final result = await repository.sendMessage(conversationId, text, repliedMessageId: repliedMessageId);
    result.fold(
      (failure) => state = state.copyWith(isSending: false, error: failure.message),
      (_) => state = state.copyWith(isSending: false),
    );
  }

  Future<void> sendImageMessage(String conversationId, String imageUrl, {String? fileName}) async {
    state = state.copyWith(isSending: true, error: null);
    final result = await repository.sendImageMessage(conversationId, imageUrl, fileName: fileName);
    result.fold(
      (failure) => state = state.copyWith(isSending: false, error: failure.message),
      (_) => state = state.copyWith(isSending: false),
    );
  }

  Future<void> sendFileMessage(String conversationId, String fileUrl, String fileName, int fileSize, {String? mimeType}) async {
    state = state.copyWith(isSending: true, error: null);
    final result = await repository.sendFileMessage(conversationId, fileUrl, fileName, fileSize, mimeType: mimeType);
    result.fold(
      (failure) => state = state.copyWith(isSending: false, error: failure.message),
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

  Future<void> markAsRead(String conversationId, List<String> messageIds) async {
    await repository.markAsRead(conversationId, messageIds);
  }
}

final chatUiProvider = StateNotifierProvider<ChatUiNotifier, ChatUiState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatUiNotifier(repository);
});
