# Chat Feature - ShuttleBee

## 📋 Overview

Professional chat feature integrated into ShuttleBee using `flutter_chat_ui` library. This implementation follows Clean Architecture principles and integrates seamlessly with **BridgeCore Conversations API** for Odoo-based messaging.

**Key Integration:**
- ✅ BridgeCore `ConversationService` for REST API calls
- ✅ BridgeCore `ConversationWebSocketService` for real-time messaging
- ✅ Odoo `mail.channel` and `mail.message` models
- ✅ Support for Channels, Direct Messages, and Chatter

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
│   ├── datasources/       # Remote data sources (BridgeCore integration)
│   │   └── chat_remote_data_source.dart  # Uses ConversationService
│   ├── repositories/      # Repository implementations
│   │   └── chat_repository.dart
│   └── services/          # WebSocket integration (legacy, use BridgeCore WS)
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

# BridgeCore Integration
bridgecore_flutter:
  path: ../../package/bridgecore_flutter  # v3.3.0+ with Conversations

# Already in project
file_picker: ^8.1.4
image_picker: ^1.1.2
```

### State Management

Uses **Riverpod 3.0.3** for state management:

- `conversationServiceProvider` - BridgeCore ConversationService
- `conversationWebSocketProvider` - BridgeCore WebSocket service
- `conversationsProvider` - List of all conversations (from BridgeCore)
- `conversationProvider(id)` - Single conversation details
- `messagesProvider(id)` - **StreamProvider** with real-time WebSocket updates
- `chatUiProvider` - UI state (loading, errors, sending)
- `unreadMessagesCountProvider` - Total unread count

### WebSocket Integration (BridgeCore)

**BridgeCore WebSocket Service:**
- Automatically connects when `messagesProvider` is accessed
- Subscribes to channels for real-time message delivery
- Handles reconnection automatically

**Message Types:**
- `channel_message` - New message in channel
- `chatter_message` - New message in chatter (record thread)
- `thread_message` - Thread reply
- `channel_updated` - Channel metadata updated

**Usage:**
```dart
final ws = BridgeCore.instance.conversationsWebSocket;
await ws.connect(token: accessToken);
await ws.subscribeChannel(channelId: 123);
ws.messageStream.listen((message) {
  // Handle new message
});
```

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

#### Real-time Messages (BridgeCore WebSocket)

The `messagesProvider` automatically handles WebSocket connection:

```dart
// Provider automatically:
// 1. Loads initial messages via REST
// 2. Connects WebSocket if needed
// 3. Subscribes to channel
// 4. Streams new messages in real-time

final messagesAsync = ref.watch(messagesProvider(conversationId));
messagesAsync.when(
  data: (messages) => Chat(messages: messages),
  loading: () => CircularProgressIndicator(),
  error: (err, _) => ErrorWidget(err),
);
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

## 🔌 BridgeCore Integration

### API Endpoints (BridgeCore)

The chat feature uses BridgeCore Conversations API:

```
GET    /api/v1/conversations/channels                    # Get all channels
GET    /api/v1/conversations/direct-messages            # Get direct messages
GET    /api/v1/conversations/channels/{id}/messages      # Get channel messages
GET    /api/v1/conversations/chatter/{model}/{id}       # Get chatter messages
POST   /api/v1/conversations/messages/send              # Send message
WS     /ws/conversations?token={token}                  # WebSocket endpoint
```

**Status:**
- ✅ Channels endpoint - **Available & Ready**
- ✅ Messages endpoint - **Available & Ready**
- ✅ Send message - **Available & Ready**
- ✅ WebSocket - **Available & Ready**
- ⏳ File upload - Pending backend
- ⏳ Create/Delete - Pending backend

### Testing Endpoints

**All endpoints are registered and ready for testing!**

#### Using cURL

```bash
# 1. Login first
curl -X POST "http://localhost:8000/api/v1/auth/tenant/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@company.com", "password": "password123"}'

# 2. Get Channels (use token from login)
curl -X GET "http://localhost:8000/api/v1/conversations/channels" \
  -H "Authorization: Bearer {YOUR_ACCESS_TOKEN}"

# 3. Get Channel Messages
curl -X GET "http://localhost:8000/api/v1/conversations/channels/1/messages?limit=50&offset=0" \
  -H "Authorization: Bearer {YOUR_ACCESS_TOKEN}"

# 4. Send Message
curl -X POST "http://localhost:8000/api/v1/conversations/messages/send" \
  -H "Authorization: Bearer {YOUR_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mail.channel",
    "res_id": 1,
    "body": "<p>Hello from API!</p>"
  }'
```

#### Using FastAPI Swagger UI

1. Open `http://localhost:8000/docs`
2. Find **"conversations"** section
3. Click **"Authorize"** and enter: `Bearer {YOUR_ACCESS_TOKEN}`
4. Test endpoints interactively

#### Using Flutter SDK

```dart
// Get channels
final channels = await BridgeCore.instance.conversations.getChannels();
print('Total channels: ${channels.total}');

// Get messages
final messages = await BridgeCore.instance.conversations.getChannelMessages(
  channelId: 1,
  limit: 50,
);

// Send message
final result = await BridgeCore.instance.conversations.sendMessage(
  model: 'mail.channel',
  resId: 1,
  body: '<p>Test message!</p>',
);
```

### BridgeCore Services

```dart
// REST API
final conversations = BridgeCore.instance.conversations;
final channels = await conversations.getChannels();
final messages = await conversations.getChannelMessages(channelId: 123);
await conversations.sendMessage(
  model: 'mail.channel',
  resId: 123,
  body: '<p>Hello!</p>',
);

// WebSocket (automatically handled by messagesProvider)
final ws = BridgeCore.instance.conversationsWebSocket;
// Connection and subscription handled automatically
```

### Security Notes

⚠️ **Critical Security:**
- `partner_id` is extracted from JWT token automatically (not accepted from client)
- `author_id` is extracted from Odoo session automatically (not accepted from client)
- WebSocket authentication via token in query parameter
- **Never accept `user_id`, `partner_id`, or `author_id` from client input!**

### Error Handling

**404 Not Found:**
- Automatically handled - returns empty lists
- Logs warnings instead of errors
- App continues to work normally

**Other Errors:**
- Network errors are caught and handled gracefully
- User-friendly error messages displayed in UI
- Automatic retry for transient failures

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

## ⚠️ Error Handling

### 404 Not Found (Endpoint Not Available)

The implementation gracefully handles 404 errors when the Conversations endpoint is not yet deployed:

- **Automatic Fallback:** Returns empty lists instead of throwing errors
- **Warning Logs:** Logs warnings instead of errors for better debugging
- **No App Crashes:** App continues to work normally even if endpoint is unavailable

**Implementation:**
```dart
// In ChatRemoteDataSourceImpl
on NotFoundException {
  logger.w('Conversations endpoint not available (404). Returning empty list.');
  return [];
}
```

**Note:** All endpoints are now available! The 404 handling is kept for backward compatibility and future-proofing.

### Troubleshooting

**401 Unauthorized:**
- Check token is valid and not expired
- Ensure `Bearer` prefix is included
- Verify token in Authorization header

**404 Not Found:**
- Verify server is running
- Check URL format: `/api/v1/conversations/...`
- Ensure router is registered in `main.py`

**422 Validation Error:**
- Check JSON format in request body
- Verify all required fields are present
- Review request schema

**500 Internal Server Error:**
- Check server logs
- Verify Odoo connection is working
- Ensure user has permissions in Odoo

## 📝 Notes

- **Endpoints Status:** All core endpoints are **available and ready** for testing
- **404 Handling:** Gracefully handles 404 errors (kept for backward compatibility)
- **User Data:** Update `_currentUser` in `ChatScreen` to use actual authenticated user
- **File Uploads:** Not yet implemented in BridgeCore (needs backend endpoint)
- **WebSocket:** Automatically managed by `messagesProvider` - no manual connection needed
- **Pagination:** Use `limit` and `offset` parameters for message pagination
- **Security:** All user IDs extracted from JWT automatically (never accept from client)

## 🐛 Known Issues

- **File Upload:** `uploadFile()` throws `UnimplementedError` - needs backend endpoint
- **Create/Delete:** `createConversation()` and `deleteConversation()` not available in BridgeCore yet
- **Mark as Read:** `markAsRead()` is a no-op (not implemented in BridgeCore yet)

## ✅ Testing Checklist

- [x] All endpoints registered in backend router
- [x] Endpoints accessible via `/api/v1/conversations/*`
- [x] Authentication working (JWT token)
- [x] Get channels endpoint tested
- [x] Get messages endpoint tested
- [x] Send message endpoint tested
- [x] WebSocket connection tested
- [ ] File upload endpoint (pending)
- [ ] Create/Delete endpoints (pending)

## 📚 References

- [flutter_chat_ui Documentation](https://pub.dev/packages/flutter_chat_ui)
- [flutter_chat_types Documentation](https://pub.dev/packages/flutter_chat_types)
- [ShuttleBee Architecture Guide](../../README.md)

---

**Created:** 2025-12-19
**Last Updated:** 2025-12-19
**Version:** 1.0.0
