import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/chat_thread.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/sources/model_registry.dart';
import '../../../services/gemma_service.dart';
import '../../model_management/providers/model_install_provider.dart';

const _uuid = Uuid();

// ── Repository ────────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// ── Thread list ───────────────────────────────────────────────────────────────

class ThreadListNotifier extends Notifier<List<ChatThread>> {
  late final ChatRepository _repo;

  @override
  List<ChatThread> build() {
    _repo = ref.read(chatRepositoryProvider);
    return _repo.getAll();
  }

  void refresh() => state = _repo.getAll();

  Future<ChatThread> createThread(String modelId) async {
    final thread = ChatThread(
      id: _uuid.v4(),
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      modelId: modelId,
    );
    await _repo.save(thread);
    state = _repo.getAll();
    return thread;
  }

  Future<void> renameThread(String id, String newTitle) async {
    await _repo.updateTitle(id, newTitle);
    state = _repo.getAll();
  }

  Future<void> deleteThread(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}

final threadListProvider =
    NotifierProvider<ThreadListNotifier, List<ChatThread>>(
  ThreadListNotifier.new,
);

// ── Active thread ID ──────────────────────────────────────────────────────────

class ActiveThreadIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final activeThreadIdProvider =
    NotifierProvider<ActiveThreadIdNotifier, String?>(
  ActiveThreadIdNotifier.new,
);

final activeThreadProvider = Provider<ChatThread?>((ref) {
  final id = ref.watch(activeThreadIdProvider);
  if (id == null) return null;
  return ref.watch(chatRepositoryProvider).getById(id);
});

// ── Streaming state ───────────────────────────────────────────────────────────

class ChatStreamState {
  final bool isStreaming;
  final String streamingText;
  final String thinkingText;
  final bool isThinking;
  final String? error;

  const ChatStreamState({
    this.isStreaming = false,
    this.streamingText = '',
    this.thinkingText = '',
    this.isThinking = false,
    this.error,
  });

  ChatStreamState copyWith({
    bool? isStreaming,
    String? streamingText,
    String? thinkingText,
    bool? isThinking,
    String? error,
  }) =>
      ChatStreamState(
        isStreaming: isStreaming ?? this.isStreaming,
        streamingText: streamingText ?? this.streamingText,
        thinkingText: thinkingText ?? this.thinkingText,
        isThinking: isThinking ?? this.isThinking,
        error: error,
      );
}

// ── Chat notifier ─────────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<ChatStreamState> {
  late final ChatRepository _repo;

  @override
  ChatStreamState build() {
    _repo = ref.read(chatRepositoryProvider);
    return const ChatStreamState();
  }

  Future<void> sendMessage({
    required String threadId,
    required String text,
    Uint8List? imageBytes,
    bool useThinking = false,
  }) async {
    if (state.isStreaming) return;

    // Persist user message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
    );
    await _repo.addMessage(threadId, userMsg);
    ref.read(threadListProvider.notifier).refresh();

    // Auto-title from first user message
    final thread = _repo.getById(threadId);
    if (thread != null && thread.messages.length == 1) {
      final title = text.length > 40 ? '${text.substring(0, 40)}…' : text;
      await _repo.updateTitle(threadId, title);
    }

    // Placeholder assistant message (updated in-place while streaming)
    final assistantMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'assistant',
      text: '',
      timestamp: DateTime.now(),
    );
    await _repo.addMessage(threadId, assistantMsg);
    ref.read(threadListProvider.notifier).refresh();

    state = const ChatStreamState(isStreaming: true);

    try {
      final activeModelId = ref.read(activeModelIdProvider);
      final modelInfo = activeModelId != null ? modelById(activeModelId) : null;
      final supportsThinking =
          useThinking && (modelInfo?.supportsThinking ?? false);

      final chat = await GemmaService.instance.chatForThread(
        threadId,
        isThinking: supportsThinking,
        systemInstruction:
            'You are a helpful, concise, and thoughtful AI assistant.',
      );

      final Message message;
      if (imageBytes != null) {
        message = Message.withImage(
          text: text,
          imageBytes: imageBytes,
          isUser: true,
        );
      } else {
        message = Message.text(text: text, isUser: true);
      }

      await chat.addQueryChunk(message);

      final accumText = StringBuffer();
      final accumThinking = StringBuffer();

      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          accumText.write(response.token);
          state = state.copyWith(
            streamingText: accumText.toString(),
            isThinking: false,
          );
        } else if (response is ThinkingResponse) {
          accumThinking.write(response.content);
          state = state.copyWith(
            thinkingText: accumThinking.toString(),
            isThinking: true,
          );
        }
      }

      // Persist final assistant response
      await _repo.updateLastMessage(
        threadId,
        accumText.toString(),
        thinkingText:
            accumThinking.isNotEmpty ? accumThinking.toString() : null,
      );
      ref.read(threadListProvider.notifier).refresh();

      state = const ChatStreamState();
    } catch (e) {
      state = ChatStreamState(error: e.toString());
      await _repo.updateLastMessage(threadId, '⚠ ${e.toString()}');
      ref.read(threadListProvider.notifier).refresh();
    }
  }

  Future<void> stopGeneration(String threadId) async {
    try {
      final chat = await GemmaService.instance.chatForThread(threadId);
      await chat.stopGeneration();
    } catch (_) {}
    state = const ChatStreamState();
  }

  void clearError() => state = const ChatStreamState();
}

final chatNotifierProvider =
    NotifierProvider<ChatNotifier, ChatStreamState>(ChatNotifier.new);
