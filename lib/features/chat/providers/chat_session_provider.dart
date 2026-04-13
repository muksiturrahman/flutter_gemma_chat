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

final threadListProvider =
    StateNotifierProvider<ThreadListNotifier, List<ChatThread>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ThreadListNotifier(repo);
});

class ThreadListNotifier extends StateNotifier<List<ChatThread>> {
  final ChatRepository _repo;

  ThreadListNotifier(ChatRepository repo)
      : _repo = repo,
        super(repo.getAll());

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

// ── Active thread ID ──────────────────────────────────────────────────────────

final activeThreadIdProvider = StateProvider<String?>((ref) => null);

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

class ChatNotifier extends StateNotifier<ChatStreamState> {
  final ChatRepository _repo;
  final Ref _ref;

  ChatNotifier(this._repo, this._ref) : super(const ChatStreamState());

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
    _ref.read(threadListProvider.notifier).refresh();

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
    _ref.read(threadListProvider.notifier).refresh();

    state = const ChatStreamState(isStreaming: true);

    try {
      final activeModelId = _ref.read(activeModelIdProvider);
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
      _ref.read(threadListProvider.notifier).refresh();

      state = const ChatStreamState();
    } catch (e) {
      state = ChatStreamState(error: e.toString());
      await _repo.updateLastMessage(threadId, '⚠ ${e.toString()}');
      _ref.read(threadListProvider.notifier).refresh();
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
    StateNotifierProvider<ChatNotifier, ChatStreamState>((ref) {
  return ChatNotifier(ref.watch(chatRepositoryProvider), ref);
});
