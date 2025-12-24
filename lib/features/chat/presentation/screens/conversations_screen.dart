import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../../shared/widgets/states/error_state.dart';
import '../providers/chat_providers.dart';
import '../widgets/conversation_list_item.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement menu
            },
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const EmptyState(
              title: 'No conversations',
              message: 'No conversations yet',
              icon: Icons.chat_bubble_outline,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(conversationsProvider);
            },
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ConversationListItem(
                  conversation: conversation,
                  onTap: () {
                    ref.read(selectedConversationIdProvider.notifier).state =
                        conversation.id;
                    context.pushNamed(
                      RouteNames.chat,
                      pathParameters: {'conversationId': conversation.id},
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewConversationDialog(context, ref);
        },
        tooltip: 'New Message',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _NewConversationDialog(ref: ref),
    );
  }
}

class _NewConversationDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _NewConversationDialog({required this.ref});

  @override
  ConsumerState<_NewConversationDialog> createState() =>
      _NewConversationDialogState();
}

class _NewConversationDialogState
    extends ConsumerState<_NewConversationDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String selectedType = 'direct';
  List<Partner> selectedPartners = [];
  List<Partner> filteredPartners = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterPartners);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterPartners);
    nameController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _filterPartners() {
    final query = searchController.text.toLowerCase();
    final partnersAsync = ref.read(partnersProvider);

    partnersAsync.whenData((partners) {
      if (mounted) {
        setState(() {
          if (query.isEmpty) {
            filteredPartners = List.from(partners);
          } else {
            filteredPartners = partners
                .where(
                  (partner) =>
                      partner.name.toLowerCase().contains(query) ||
                      (partner.email?.toLowerCase().contains(query) ?? false),
                )
                .toList();
          }
        });
      }
    });
  }

  void _togglePartner(Partner partner) {
    setState(() {
      if (selectedPartners.any((p) => p.id == partner.id)) {
        selectedPartners.removeWhere((p) => p.id == partner.id);
      } else {
        selectedPartners.add(partner);
      }
    });
  }

  Future<void> _createConversation() async {
    // Validation
    if (selectedType == 'direct' && selectedPartners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant')),
      );
      return;
    }

    if (selectedType == 'group' && nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a conversation name for group chats'),
        ),
      );
      return;
    }

    Navigator.of(context).pop();

    // Show loading
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Creating conversation...')));

    try {
      final participantIds = selectedPartners
          .map((p) => p.id.toString())
          .toList();
      final repository = ref.read(chatRepositoryProvider);
      final result = await repository.createConversation(
        nameController.text.trim().isEmpty
            ? 'New Conversation'
            : nameController.text.trim(),
        selectedType,
        participantIds,
      );

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (conversation) {
          // Success - refresh conversations and navigate to new conversation
          ref.invalidate(conversationsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation created successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to the new conversation
          Future.delayed(const Duration(milliseconds: 500), () {
            ref.read(selectedConversationIdProvider.notifier).state =
                conversation.id;
            context.pushNamed(
              RouteNames.chat,
              pathParameters: {'conversationId': conversation.id},
            );
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(partnersProvider);

    return AlertDialog(
      title: const Text('New Conversation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selectedType == 'group')
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Conversation Name',
                  hintText: 'Enter conversation name',
                  border: OutlineInputBorder(),
                ),
              ),
            if (selectedType == 'group') const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'direct',
                  child: Text('Direct Message'),
                ),
                DropdownMenuItem(value: 'group', child: Text('Group')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Participants',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            if (selectedPartners.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedPartners.map((partner) {
                  return Chip(
                    label: Text(partner.name),
                    onDeleted: () => _togglePartner(partner),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: partnersAsync.when(
                data: (partners) {
                  // Initialize filtered partners on first load
                  if (filteredPartners.isEmpty && partners.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          filteredPartners = List.from(partners);
                        });
                      }
                    });
                  }

                  // Filter based on search query
                  final query = searchController.text.toLowerCase();
                  final displayPartners = query.isEmpty
                      ? (filteredPartners.isEmpty ? partners : filteredPartners)
                      : partners
                            .where(
                              (partner) =>
                                  partner.name.toLowerCase().contains(query) ||
                                  (partner.email?.toLowerCase().contains(
                                        query,
                                      ) ??
                                      false),
                            )
                            .toList();

                  if (displayPartners.isEmpty) {
                    // Differentiate between no partners at all vs no search results
                    if (partners.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No partners available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'There are no active partners to start a conversation with.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Search returned no results
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No partners found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: displayPartners.map((partner) {
                        final isSelected = selectedPartners.any(
                          (p) => p.id == partner.id,
                        );

                        return CheckboxListTile(
                          title: Text(partner.name),
                          subtitle: partner.email != null
                              ? Text(partner.email!)
                              : null,
                          value: isSelected,
                          onChanged: (_) => _togglePartner(partner),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load partners',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          ref.invalidate(partnersProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createConversation,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
