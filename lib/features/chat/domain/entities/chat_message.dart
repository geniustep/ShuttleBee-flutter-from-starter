import 'package:equatable/equatable.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'chat_user.dart';

/// Message types supported by the chat system
enum MessageType {
  text,
  image,
  file,
  system,
  custom,
}

/// Message status
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  error,
}

/// Domain entity representing a chat message
class ChatMessage extends Equatable {
  final String id;
  final ChatUser author;
  final DateTime createdAt;
  final MessageType type;
  final MessageStatus status;
  final String? text;
  final String? imageUrl;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? mimeType;
  final String? repliedMessageId;
  final Map<String, dynamic>? metadata;
  final DateTime? updatedAt;

  const ChatMessage({
    required this.id,
    required this.author,
    required this.createdAt,
    required this.type,
    this.status = MessageStatus.sent,
    this.text,
    this.imageUrl,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.mimeType,
    this.repliedMessageId,
    this.metadata,
    this.updatedAt,
  });

  /// Convert to flutter_chat_types.Message for UI rendering
  types.Message toFlutterChatMessage() {
    switch (type) {
      case MessageType.text:
        return types.TextMessage(
          author: types.User(
            id: author.id,
            firstName: author.firstName,
            lastName: author.lastName,
            imageUrl: author.imageUrl,
            metadata: author.metadata,
            role: author.role != null ? types.Role.custom : null,
          ),
          createdAt: createdAt.millisecondsSinceEpoch,
          id: id,
          text: text ?? '',
          status: _mapStatus(status),
          metadata: metadata,
          repliedMessage: repliedMessageId != null
              ? types.TextMessage(
                  author: types.User(id: 'unknown'),
                  createdAt: 0,
                  id: repliedMessageId!,
                  text: '',
                )
              : null,
          updatedAt: updatedAt?.millisecondsSinceEpoch,
        );

      case MessageType.image:
        return types.ImageMessage(
          author: types.User(
            id: author.id,
            firstName: author.firstName,
            lastName: author.lastName,
            imageUrl: author.imageUrl,
          ),
          createdAt: createdAt.millisecondsSinceEpoch,
          id: id,
          name: fileName ?? 'image',
          size: fileSize ?? 0,
          uri: imageUrl ?? '',
          status: _mapStatus(status),
          metadata: metadata,
          updatedAt: updatedAt?.millisecondsSinceEpoch,
        );

      case MessageType.file:
        return types.FileMessage(
          author: types.User(
            id: author.id,
            firstName: author.firstName,
            lastName: author.lastName,
            imageUrl: author.imageUrl,
          ),
          createdAt: createdAt.millisecondsSinceEpoch,
          id: id,
          name: fileName ?? 'file',
          size: fileSize ?? 0,
          uri: fileUrl ?? '',
          mimeType: mimeType,
          status: _mapStatus(status),
          metadata: metadata,
          updatedAt: updatedAt?.millisecondsSinceEpoch,
        );

      case MessageType.system:
        return types.SystemMessage(
          createdAt: createdAt.millisecondsSinceEpoch,
          id: id,
          text: text ?? '',
          metadata: metadata,
        );

      case MessageType.custom:
        return types.CustomMessage(
          author: types.User(
            id: author.id,
            firstName: author.firstName,
            lastName: author.lastName,
            imageUrl: author.imageUrl,
          ),
          createdAt: createdAt.millisecondsSinceEpoch,
          id: id,
          metadata: metadata ?? {},
          status: _mapStatus(status),
          updatedAt: updatedAt?.millisecondsSinceEpoch,
        );
    }
  }

  types.Status _mapStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return types.Status.sending;
      case MessageStatus.sent:
        return types.Status.sent;
      case MessageStatus.delivered:
        return types.Status.delivered;
      case MessageStatus.read:
        return types.Status.seen;
      case MessageStatus.error:
        return types.Status.error;
    }
  }

  @override
  List<Object?> get props => [
        id,
        author,
        createdAt,
        type,
        status,
        text,
        imageUrl,
        fileName,
        fileUrl,
        fileSize,
        mimeType,
        repliedMessageId,
        metadata,
        updatedAt,
      ];

  ChatMessage copyWith({
    String? id,
    ChatUser? author,
    DateTime? createdAt,
    MessageType? type,
    MessageStatus? status,
    String? text,
    String? imageUrl,
    String? fileName,
    String? fileUrl,
    int? fileSize,
    String? mimeType,
    String? repliedMessageId,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      status: status ?? this.status,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      repliedMessageId: repliedMessageId ?? this.repliedMessageId,
      metadata: metadata ?? this.metadata,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
