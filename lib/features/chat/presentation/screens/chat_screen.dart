import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_user.dart';
import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _uuid = const Uuid();

  // This would come from auth provider in real implementation
  final _currentUser = const types.User(
    id: 'current-user-id',
    firstName: 'Current',
    lastName: 'User',
  );

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(
      conversationProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final chatUiState = ref.watch(chatUiProvider);

    return Scaffold(
      appBar: AppBar(
        title: conversationAsync.when(
          data: (conversation) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conversation.name),
              Text(
                '${conversation.participants.length} participants',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // TODO: Implement voice call
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Show conversation info
            },
          ),
        ],
      ),
      body: messagesAsync.when(
        data: (messages) {
          // Convert domain messages to flutter_chat_ui messages
          final chatMessages = messages
              .map((msg) => msg.toFlutterChatMessage())
              .toList();

          return chat_ui.Chat(
            messages: chatMessages,
            onSendPressed: _handleSendPressed,
            onAttachmentPressed: _handleAttachmentPressed,
            onMessageTap: _handleMessageTap,
            onPreviewDataFetched: _handlePreviewDataFetched,
            user: _currentUser,
            theme: _getChatTheme(context),
            showUserAvatars: true,
            showUserNames: true,
            inputOptions: const chat_ui.InputOptions(
              sendButtonVisibilityMode:
                  chat_ui.SendButtonVisibilityMode.editing,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(messagesProvider(widget.conversationId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  chat_ui.DefaultChatTheme _getChatTheme(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return chat_ui.DefaultChatTheme(
      primaryColor: colorScheme.primary,
      secondaryColor: colorScheme.secondary,
      backgroundColor: colorScheme.surface,
      inputBackgroundColor: colorScheme.surfaceContainerHighest,
      inputTextColor: colorScheme.onSurface,
      receivedMessageBodyTextStyle: TextStyle(
        color: colorScheme.onSecondaryContainer,
        fontSize: 16,
      ),
      sentMessageBodyTextStyle: TextStyle(
        color: colorScheme.onPrimary,
        fontSize: 16,
      ),
    );
  }

  void _handleSendPressed(types.PartialText message) {
    final chatNotifier = ref.read(chatUiProvider.notifier);
    chatNotifier.sendTextMessage(widget.conversationId, message.text);

    // Refresh messages after sending
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.invalidate(messagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    });
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _handleImageSelection();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _handleCameraSelection();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(context);
                _handleFileSelection();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1440,
    );

    if (result != null) {
      _uploadAndSendImage(result.path);
    }
  }

  void _handleCameraSelection() async {
    final result = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1440,
    );

    if (result != null) {
      _uploadAndSendImage(result.path);
    }
  }

  void _uploadAndSendImage(String imagePath) async {
    final chatNotifier = ref.read(chatUiProvider.notifier);
    final url = await chatNotifier.uploadFile(imagePath);

    if (url != null) {
      final fileName = imagePath.split('/').last;
      await chatNotifier.sendImageMessage(
        widget.conversationId,
        url,
        fileName: fileName,
      );

      // Refresh messages
      ref.invalidate(messagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    }
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final fileSize = await file.length();
      final mimeType = lookupMimeType(file.path);

      final chatNotifier = ref.read(chatUiProvider.notifier);
      final url = await chatNotifier.uploadFile(file.path);

      if (url != null) {
        await chatNotifier.sendFileMessage(
          widget.conversationId,
          url,
          fileName,
          fileSize,
          mimeType: mimeType,
        );

        // Refresh messages
        ref.invalidate(messagesProvider(widget.conversationId));
        ref.invalidate(conversationsProvider);
      }
    }
  }

  void _handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      // Try to open file
      await OpenFilex.open(message.uri);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    // Handle link preview
    // In a real app, you would update the message with preview data
  }
}
