# Chat Feature - ShuttleBee

## 📋 Overview

Professional chat feature integrated into ShuttleBee using `flutter_chat_ui` library. This implementation follows Clean Architecture principles and integrates seamlessly with the existing app structure.

## 🏗️ Architecture

The chat feature is built using Clean Architecture with three layers:

```
lib/features/chat/
├── domain/
│   └── entities/           # Business entities
│       ├── chat_user.dart
│       ├── chat_message.dart
│       └── chat_conversation.dart
├── data/
│   ├── models/            # Data models with JSON serialization
│   │   ├── chat_user_model.dart
│   │   ├── chat_message_model.dart
│   │   └── chat_conversation_model.dart
│   ├── datasources/       # Remote data sources
│   │   └── chat_remote_data_source.dart
│   ├── repositories/      # Repository implementations
│   │   └── chat_repository.dart
│   └── services/          # WebSocket integration
│       └── chat_websocket_service.dart
└── presentation/
    ├── providers/         # Riverpod state management
    │   └── chat_providers.dart
    ├── screens/           # UI screens
    │   ├── conversations_screen.dart
    │   └── chat_screen.dart
    └── widgets/           # Reusable widgets
        └── conversation_list_item.dart
```

## 🎯 Features

### ✅ Implemented

1. **Conversations List**
   - Display all user conversations
   - Show unread message count badges
   - Last message preview
   - Real-time updates via WebSocket
   - Pull-to-refresh functionality

2. **Chat Screen**
   - Text messages
   - Image messages
   - File attachments
   - Message status indicators (sending, sent, delivered, read)
   - Typing indicators
   - Message replies
   - Pull-to-refresh
   - Auto-scroll to new messages

3. **Real-time Communication**
   - WebSocket integration for instant messages
   - Typing indicators
   - Message read receipts
   - Online/offline status

4. **File Handling**
   - Image selection from gallery
   - Camera integration
   - File picker for attachments
   - File upload to server
   - Image preview
   - File download/open

5. **UI/UX**
   - Material Design 3 theming
   - Responsive design (mobile/tablet/desktop)
   - Smooth animations
   - Pull-to-refresh
   - Loading states
   - Error handling
   - Empty states

## 🔧 Technical Details

### Dependencies

```yaml
# Chat UI
flutter_chat_ui: ^1.6.15
flutter_chat_types: ^3.6.2
mime: ^2.0.0
open_filex: ^4.5.0

# Already in project
file_picker: ^8.1.4
image_picker: ^1.1.2
```

### State Management

Uses **Riverpod 3.0.3** for state management:

- `conversationsProvider` - List of all conversations
- `conversationProvider(id)` - Single conversation details
- `messagesProvider(id)` - Messages for a conversation
- `chatUiProvider` - UI state (loading, errors, sending)
- `unreadMessagesCountProvider` - Total unread count

### WebSocket Events

**Listening to:**
- `chat:message:new` - New message received
- `chat:message:updated` - Message status updated
- `chat:conversation:updated` - Conversation updated
- `chat:typing` - Typing indicator

**Emitting:**
- `chat:typing` - Send typing status
- `chat:message:read` - Mark message as read

## 📱 Usage

### Navigation

1. **From Dispatcher Home:**
   - Click chat icon in header
   - Badge shows unread count

2. **Routes:**
   - `/conversations` - Conversations list
   - `/chat/:conversationId` - Chat screen

### Code Examples

#### Send a Text Message

```dart
final chatNotifier = ref.read(chatUiProvider.notifier);
await chatNotifier.sendTextMessage(conversationId, 'Hello!');
```

#### Send an Image

```dart
final chatNotifier = ref.read(chatUiProvider.notifier);
final url = await chatNotifier.uploadFile(imagePath);
if (url != null) {
  await chatNotifier.sendImageMessage(conversationId, url);
}
```

#### Mark Messages as Read

```dart
final chatNotifier = ref.read(chatUiProvider.notifier);
await chatNotifier.markAsRead(conversationId, messageIds);
```

#### Join a Conversation (WebSocket)

```dart
final wsService = ChatWebSocketService();
wsService.joinConversation(conversationId);

// Listen to new messages
wsService.newMessages.listen((message) {
  // Handle new message
});
```

## 🎨 Customization

### Theme

The chat UI automatically adapts to the Material Design 3 theme:

```dart
DefaultChatTheme(
  primaryColor: colorScheme.primary,
  secondaryColor: colorScheme.secondary,
  backgroundColor: colorScheme.surface,
  inputBackgroundColor: colorScheme.surfaceContainerHighest,
  // ...
)
```

### Conversation Types

```dart
enum ConversationType {
  direct,   // One-to-one chat
  group,    // Group chat
  trip,     // Trip-related chat
  support,  // Support chat
}
```

### Message Types

```dart
enum MessageType {
  text,
  image,
  file,
  system,
  custom,
}
```

## 🔌 Backend Integration

### API Endpoints

The chat feature expects the following API endpoints:

```
GET    /chat/conversations              # Get all conversations
GET    /chat/conversations/:id          # Get single conversation
GET    /chat/conversations/:id/messages # Get messages
POST   /chat/conversations/:id/messages # Send message
POST   /chat/conversations              # Create conversation
DELETE /chat/conversations/:id          # Delete conversation
POST   /chat/upload                     # Upload file
POST   /chat/conversations/:id/read     # Mark as read
```

### WebSocket Connection

WebSocket should be initialized in app startup:

```dart
final wsService = WebSocketService();
await wsService.connect(
  serverUrl: 'wss://your-server.com',
  auth: {'token': authToken},
);

final chatWsService = ChatWebSocketService();
await chatWsService.initialize();
```

## 🚀 Next Steps

### Recommended Enhancements

1. **Message Search**
   - Full-text search across conversations
   - Filter by date, sender, type

2. **Rich Media**
   - Video messages
   - Voice messages
   - Location sharing
   - Stickers/GIFs

3. **Advanced Features**
   - Message editing
   - Message deletion
   - Forward messages
   - Pinned messages
   - Starred messages

4. **Notifications**
   - Push notifications for new messages
   - Sound/vibration alerts
   - Notification badges

5. **Offline Support**
   - Queue messages when offline
   - Sync when connection restored
   - Local message storage with Hive

6. **Group Features**
   - Add/remove participants
   - Group admins
   - Group settings
   - Group avatar

7. **Localization**
   - Add Arabic translations
   - Add French translations
   - RTL support enhancements

## 📝 Notes

- The current implementation uses mock user data. Update `_currentUser` in `ChatScreen` to use actual authenticated user.
- File uploads require proper server endpoint configuration.
- WebSocket connection should be managed at app level for reliability.
- Consider implementing pagination for large conversation lists and message history.

## 🐛 Known Issues

None currently documented.

## 📚 References

- [flutter_chat_ui Documentation](https://pub.dev/packages/flutter_chat_ui)
- [flutter_chat_types Documentation](https://pub.dev/packages/flutter_chat_types)
- [ShuttleBee Architecture Guide](../../README.md)

---

**Created:** 2025-12-19
**Last Updated:** 2025-12-19
**Version:** 1.0.0
