import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_container.dart';
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

    if (streamState.isStreaming) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _GlassAppBar(
        title: thread?.title ?? 'Gemma Chat',
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
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
          const SizedBox(width: 4),
        ],
      ),
      drawer: const ChatDrawer(),
      body: thread == null
          ? _EmptyState(onNewChat: _createNewThread)
          : _ChatBody(
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
    ref.read(activeThreadIdProvider.notifier).set(thread.id);
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

class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const _GlassAppBar({
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: AppBar(
          title: Text(title),
          leading: leading,
          actions: actions,
          backgroundColor: (isDark ? Colors.white : Colors.white)
              .withValues(alpha: isDark ? 0.06 : 0.35),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
    );
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
    final itemCount =
        messages.length + (streamState.isStreaming ? 1 : 0);

    return Column(
      children: [
        if (streamState.error != null)
          _ErrorBanner(message: streamState.error!),
        Expanded(
          child: itemCount == 0
              ? _WelcomeHint(supportsImage: supportsImage)
              : ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (streamState.isStreaming && index == 0) {
                      return StreamingBubble(streamState: streamState);
                    }
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: GlassContainer(
        tint: scheme.error,
        opacity: 0.18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewChat;
  const _EmptyState({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded,
                size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'No conversation selected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Start a new chat'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHint extends StatelessWidget {
  final bool supportsImage;
  const _WelcomeHint({required this.supportsImage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(32),
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.8),
                    scheme.tertiary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 32, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'How can I help you today?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              supportsImage
                  ? 'Send a message or attach an image to get started.'
                  : 'Send a message to get started.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
