import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/chat_thread.dart';
import '../models/chat_message.dart';

class ChatRepository {
  static const _threadsBoxName = 'chat_threads';

  Box<ChatThread> get _box => Hive.box<ChatThread>(_threadsBoxName);

  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(_threadsBoxName)) {
      await Hive.openBox<ChatThread>(_threadsBoxName);
    }
  }

  List<ChatThread> getAll() {
    final threads = _box.values.toList();
    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return threads;
  }

  ChatThread? getById(String id) {
    return _box.values
        .cast<ChatThread?>()
        .firstWhere((t) => t?.id == id, orElse: () => null);
  }

  Future<void> save(ChatThread thread) async {
    await _box.put(thread.id, thread);
  }

  Future<void> delete(String id) async {
    final key =
        _box.keys.firstWhere((k) => _box.get(k)?.id == id, orElse: () => null);
    if (key != null) await _box.delete(key);
  }

  Future<void> updateTitle(String id, String newTitle) async {
    final thread = getById(id);
    if (thread == null) return;
    thread.title = newTitle;
    thread.updatedAt = DateTime.now();
    await thread.save();
  }

  Future<void> addMessage(String threadId, ChatMessage message) async {
    final thread = getById(threadId);
    if (thread == null) return;
    thread.messages.add(message);
    thread.updatedAt = DateTime.now();
    await thread.save();
  }

  Future<void> updateLastMessage(String threadId, String newText,
      {String? thinkingText}) async {
    final thread = getById(threadId);
    if (thread == null || thread.messages.isEmpty) return;
    final last = thread.messages.last;
    thread.messages[thread.messages.length - 1] = last.copyWith(
      text: newText,
      thinkingText: thinkingText,
    );
    await thread.save();
  }
}
