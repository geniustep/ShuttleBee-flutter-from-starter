import 'package:equatable/equatable.dart';
import 'chat_message.dart';
import 'chat_user.dart';

/// Conversation type
enum ConversationType {
  direct, // One-to-one
  group, // Multiple participants
  trip, // Trip-related conversation
  support, // Support conversation
}

/// Domain entity representing a chat conversation
class ChatConversation extends Equatable {
  final String id;
  final String name;
  final ConversationType type;
  final List<ChatUser> participants;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? tripId; // Optional trip reference
  final String? groupId; // Optional group reference

  const ChatConversation({
    required this.id,
    required this.name,
    required this.type,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.imageUrl,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.tripId,
    this.groupId,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        participants,
        lastMessage,
        lastMessageAt,
        unreadCount,
        imageUrl,
        metadata,
        createdAt,
        updatedAt,
        isActive,
        tripId,
        groupId,
      ];

  ChatConversation copyWith({
    String? id,
    String? name,
    ConversationType? type,
    List<ChatUser>? participants,
    ChatMessage? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? tripId,
    String? groupId,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      tripId: tripId ?? this.tripId,
      groupId: groupId ?? this.groupId,
    );
  }
}
