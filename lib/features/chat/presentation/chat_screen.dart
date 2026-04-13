import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/chat_thread.dart';
import '../../../data/sources/model_registry.dart';
import '../providers/chat_session_provider.dart';
import '../../model_management/providers/model_install_provider.dart';
import 'chat_drawer.dart';
import 'widgets/message_bubble.dart';
import 'widgets/streaming_bubble.dart';
import 'widgets/chat_input_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(activeThreadProvider);
    final streamState = ref.watch(chatNotifierProvider);
    final activeModelId = ref.watch(activeModelIdProvider);
    final modelInfo =
        activeModelId != null ? modelById(activeModelId) : null;

    // Auto-scroll to bottom when streaming
    if (streamState.isStreaming) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(thread?.title ?? 'Gemma Chat'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          if (thread == null)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New chat',
              onPressed: () => _createNewThread(),
            ),
          IconButton(
            icon: const Icon(Icons.storage_outlined),
            tooltip: 'Change model',
            onPressed: () => context.go('/models'),
          ),
        ],
      ),
      drawer: const ChatDrawer(),
      body: thread == null ? _EmptyState(onNewChat: _createNewThread) : _ChatBody(
        thread: thread,
        streamState: streamState,
        scrollController: _scrollController,
        supportsImage: modelInfo?.supportsImage ?? false,
        onSend: (text, image) => _send(thread.id, text, image),
        onStop: () => ref
            .read(chatNotifierProvider.notifier)
            .stopGeneration(thread.id),
      ),
    );
  }

  Future<void> _createNewThread() async {
    final modelId =
        ref.read(activeModelIdProvider) ?? 'gemma-4-e2b-it';
    final thread = await ref
        .read(threadListProvider.notifier)
        .createThread(modelId);
    ref.read(activeThreadIdProvider.notifier).state = thread.id;
  }

  Future<void> _send(
      String threadId, String text, Uint8List? image) async {
    await ref.read(chatNotifierProvider.notifier).sendMessage(
          threadId: threadId,
          text: text,
          imageBytes: image,
          useThinking: false,
        );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }
}

class _ChatBody extends StatelessWidget {
  final ChatThread thread;
  final ChatStreamState streamState;
  final ScrollController scrollController;
  final bool supportsImage;
  final void Function(String, Uint8List?) onSend;
  final VoidCallback onStop;

  const _ChatBody({
    required this.thread,
    required this.streamState,
    required this.scrollController,
    required this.supportsImage,
    required this.onSend,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final messages = thread.messages;
    // Total items: persisted messages + (1 streaming bubble if active)
    final itemCount =
        messages.length + (streamState.isStreaming ? 1 : 0);

    return Column(
      children: [
        if (streamState.error != null)
          MaterialBanner(
            content: Text(streamState.error!),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            actions: [
              TextButton(
                onPressed: () {},
                child: const Text('Dismiss'),
              ),
            ],
          ),
        Expanded(
          child: itemCount == 0
              ? _WelcomeHint(supportsImage: supportsImage)
              : ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    // index 0 = bottom = newest
                    if (streamState.isStreaming && index == 0) {
                      return StreamingBubble(streamState: streamState);
                    }
                    // offset index when streaming bubble occupies slot 0
                    final msgIndex = messages.length -
                        1 -
                        (streamState.isStreaming ? index - 1 : index);
                    if (msgIndex < 0 || msgIndex >= messages.length) {
                      return const SizedBox.shrink();
                    }
                    return MessageBubble(message: messages[msgIndex]);
                  },
                ),
        ),
        ChatInputBar(
          isStreaming: streamState.isStreaming,
          supportsImage: supportsImage,
          onSend: onSend,
          onStop: onStop,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewChat;
  const _EmptyState({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined,
              size: 72, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text('No conversation selected',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onNewChat,
            icon: const Icon(Icons.add),
            label: const Text('Start a new chat'),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHint extends StatelessWidget {
  final bool supportsImage;
  const _WelcomeHint({required this.supportsImage});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: 56, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'How can I help you today?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              supportsImage
                  ? 'Send a message or attach an image to get started.'
                  : 'Send a message to get started.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
