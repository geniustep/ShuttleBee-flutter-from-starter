import 'package:equatable/equatable.dart';

/// Domain entity representing a chat user
class ChatUser extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final String? role;

  const ChatUser({
    required this.id,
    required this.firstName,
    this.lastName,
    this.imageUrl,
    this.metadata,
    this.role,
  });

  String get fullName {
    if (lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName;
  }

  @override
  List<Object?> get props => [id, firstName, lastName, imageUrl, metadata, role];
}
