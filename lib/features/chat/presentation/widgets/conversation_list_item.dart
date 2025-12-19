import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/entities/chat_conversation.dart';

class ConversationListItem extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      leading: _buildAvatar(context),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessageAt != null)
            Text(
              timeago.format(conversation.lastMessageAt!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              _getLastMessageText(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      trailing: _buildTypeIcon(context),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);

    if (conversation.imageUrl != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(conversation.imageUrl!),
      );
    }

    // Get first letter of conversation name
    final initial = conversation.name.isNotEmpty
        ? conversation.name[0].toUpperCase()
        : '?';

    return CircleAvatar(
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget? _buildTypeIcon(BuildContext context) {
    final theme = Theme.of(context);
    IconData? icon;

    switch (conversation.type) {
      case ConversationType.group:
        icon = Icons.group;
        break;
      case ConversationType.trip:
        icon = Icons.directions_bus;
        break;
      case ConversationType.support:
        icon = Icons.support_agent;
        break;
      case ConversationType.direct:
        return null;
    }

    if (icon == null) return null;

    return Icon(
      icon,
      size: 16,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  String _getLastMessageText() {
    if (conversation.lastMessage == null) {
      return 'No messages yet';
    }

    final message = conversation.lastMessage!;
    final authorName = message.author.firstName;

    switch (message.type) {
      case MessageType.text:
        return '${authorName}: ${message.text ?? ''}';
      case MessageType.image:
        return '$authorName sent an image';
      case MessageType.file:
        return '$authorName sent a file';
      case MessageType.system:
        return message.text ?? 'System message';
      case MessageType.custom:
        return '$authorName sent a message';
    }
  }
}
