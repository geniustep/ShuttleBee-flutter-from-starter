import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/chat_user.dart';

part 'chat_user_model.freezed.dart';
part 'chat_user_model.g.dart';

@freezed
class ChatUserModel with _$ChatUserModel {
  const factory ChatUserModel({
    required String id,
    required String firstName,
    String? lastName,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    String? role,
  }) = _ChatUserModel;

  factory ChatUserModel.fromJson(Map<String, dynamic> json) =>
      _$ChatUserModelFromJson(json);

  factory ChatUserModel.fromEntity(ChatUser entity) {
    return ChatUserModel(
      id: entity.id,
      firstName: entity.firstName,
      lastName: entity.lastName,
      imageUrl: entity.imageUrl,
      metadata: entity.metadata,
      role: entity.role,
    );
  }
}

extension ChatUserModelX on ChatUserModel {
  ChatUser toEntity() {
    return ChatUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      imageUrl: imageUrl,
      metadata: metadata,
      role: role,
    );
  }
}
