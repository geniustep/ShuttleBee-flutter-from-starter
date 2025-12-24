import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/chat_conversation.dart';
import 'chat_message_model.dart';
import 'chat_user_model.dart';

part 'chat_conversation_model.freezed.dart';
part 'chat_conversation_model.g.dart';

@freezed
abstract class ChatConversationModel with _$ChatConversationModel {
  const ChatConversationModel._();

  const factory ChatConversationModel({
    required String id,
    required String name,
    required String type,
    required List<ChatUserModel> participants,
    ChatMessageModel? lastMessage,
    DateTime? lastMessageAt,
    @Default(0) int unreadCount,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(true) bool isActive,
    String? tripId,
    String? groupId,
  }) = _ChatConversationModel;

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationModelFromJson(json);

  factory ChatConversationModel.fromEntity(ChatConversation entity) {
    return ChatConversationModel(
      id: entity.id,
      name: entity.name,
      type: entity.type.name,
      participants: entity.participants
          .map((user) => ChatUserModel.fromEntity(user))
          .toList(),
      lastMessage: entity.lastMessage != null
          ? ChatMessageModel.fromEntity(entity.lastMessage!)
          : null,
      lastMessageAt: entity.lastMessageAt,
      unreadCount: entity.unreadCount,
      imageUrl: entity.imageUrl,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
      tripId: entity.tripId,
      groupId: entity.groupId,
    );
  }
}

extension ChatConversationModelX on ChatConversationModel {
  ChatConversation toEntity() {
    return ChatConversation(
      id: id,
      name: name,
      type: _parseConversationType(type),
      participants: participants.map((user) => user.toEntity()).toList(),
      lastMessage: lastMessage?.toEntity(),
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      imageUrl: imageUrl,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      tripId: tripId,
      groupId: groupId,
    );
  }

  ConversationType _parseConversationType(String type) {
    switch (type) {
      case 'direct':
        return ConversationType.direct;
      case 'group':
        return ConversationType.group;
      case 'trip':
        return ConversationType.trip;
      case 'support':
        return ConversationType.support;
      default:
        return ConversationType.direct;
    }
  }
}
