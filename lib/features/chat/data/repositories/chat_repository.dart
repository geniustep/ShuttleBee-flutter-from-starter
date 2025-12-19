import 'package:dartz/dartz.dart';
import '../../../../core/error_handling/failures.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../datasources/chat_remote_data_source.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatConversation>>> getConversations();
  Future<Either<Failure, ChatConversation>> getConversation(String conversationId);
  Future<Either<Failure, List<ChatMessage>>> getMessages(String conversationId, {int? limit, int? offset});
  Future<Either<Failure, ChatMessage>> sendMessage(String conversationId, String text, {String? repliedMessageId});
  Future<Either<Failure, ChatMessage>> sendImageMessage(String conversationId, String imageUrl, {String? fileName});
  Future<Either<Failure, ChatMessage>> sendFileMessage(String conversationId, String fileUrl, String fileName, int fileSize, {String? mimeType});
  Future<Either<Failure, void>> markAsRead(String conversationId, List<String> messageIds);
  Future<Either<Failure, ChatConversation>> createConversation(String name, String type, List<String> participantIds, {Map<String, dynamic>? metadata});
  Future<Either<Failure, void>> deleteConversation(String conversationId);
  Future<Either<Failure, String>> uploadFile(String filePath);
}

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ChatConversation>>> getConversations() async {
    try {
      final conversations = await remoteDataSource.getConversations();
      return Right(conversations.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatConversation>> getConversation(String conversationId) async {
    try {
      final conversation = await remoteDataSource.getConversation(conversationId);
      return Right(conversation.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final messages = await remoteDataSource.getMessages(
        conversationId,
        limit: limit,
        offset: offset,
      );
      return Right(messages.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(
    String conversationId,
    String text, {
    String? repliedMessageId,
  }) async {
    try {
      final message = await remoteDataSource.sendMessage(
        conversationId,
        text,
        repliedMessageId: repliedMessageId,
      );
      return Right(message.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendImageMessage(
    String conversationId,
    String imageUrl, {
    String? fileName,
  }) async {
    try {
      final message = await remoteDataSource.sendImageMessage(
        conversationId,
        imageUrl,
        fileName: fileName,
      );
      return Right(message.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendFileMessage(
    String conversationId,
    String fileUrl,
    String fileName,
    int fileSize, {
    String? mimeType,
  }) async {
    try {
      final message = await remoteDataSource.sendFileMessage(
        conversationId,
        fileUrl,
        fileName,
        fileSize,
        mimeType: mimeType,
      );
      return Right(message.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(
    String conversationId,
    List<String> messageIds,
  ) async {
    try {
      await remoteDataSource.markAsRead(conversationId, messageIds);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatConversation>> createConversation(
    String name,
    String type,
    List<String> participantIds, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final conversation = await remoteDataSource.createConversation(
        name,
        type,
        participantIds,
        metadata: metadata,
      );
      return Right(conversation.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversation(String conversationId) async {
    try {
      await remoteDataSource.deleteConversation(conversationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadFile(String filePath) async {
    try {
      final url = await remoteDataSource.uploadFile(filePath);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
