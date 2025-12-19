import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_user_model.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

@freezed
class ChatMessageModel with _$ChatMessageModel {
  const factory ChatMessageModel({
    required String id,
    required ChatUserModel author,
    required DateTime createdAt,
    required String type,
    @Default('sent') String status,
    String? text,
    String? imageUrl,
    String? fileName,
    String? fileUrl,
    int? fileSize,
    String? mimeType,
    String? repliedMessageId,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) = _ChatMessageModel;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      author: ChatUserModel.fromEntity(entity.author),
      createdAt: entity.createdAt,
      type: entity.type.name,
      status: entity.status.name,
      text: entity.text,
      imageUrl: entity.imageUrl,
      fileName: entity.fileName,
      fileUrl: entity.fileUrl,
      fileSize: entity.fileSize,
      mimeType: entity.mimeType,
      repliedMessageId: entity.repliedMessageId,
      metadata: entity.metadata,
      updatedAt: entity.updatedAt,
    );
  }
}

extension ChatMessageModelX on ChatMessageModel {
  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      author: author.toEntity(),
      createdAt: createdAt,
      type: _parseMessageType(type),
      status: _parseMessageStatus(status),
      text: text,
      imageUrl: imageUrl,
      fileName: fileName,
      fileUrl: fileUrl,
      fileSize: fileSize,
      mimeType: mimeType,
      repliedMessageId: repliedMessageId,
      metadata: metadata,
      updatedAt: updatedAt,
    );
  }

  MessageType _parseMessageType(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'custom':
        return MessageType.custom;
      default:
        return MessageType.text;
    }
  }

  MessageStatus _parseMessageStatus(String status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'error':
        return MessageStatus.error;
      default:
        return MessageStatus.sent;
    }
  }
}
